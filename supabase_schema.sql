-- Supabase Database Schema for Study Chicken Race
-- This file defines the tables required for cloud saves, daily mock exams, and friend multiplayer.
-- Paste this script into your Supabase SQL Editor (https://supabase.com) and run it.

-- Enable Row Level Security (RLS) or setup simple policies if necessary.
-- By default, for a prototype, you can allow all authenticated/anon requests or customize policies.

---------------------------------------------------------
-- 1. Saves Table (Cloud Save / Load)
---------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.saves (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    data JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RLS for Saves
ALTER TABLE public.saves ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert/update their own save data."
    ON public.saves FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

---------------------------------------------------------
-- 2. Daily Scores Table (Daily Ranking & Ghost Records)
---------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.daily_scores (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    username TEXT NOT NULL,
    day_idx INT NOT NULL,
    score INT NOT NULL,
    record JSONB NOT NULL DEFAULT '{}'::jsonb,
    season INT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RLS for Daily Scores
ALTER TABLE public.daily_scores ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read daily scores"
    ON public.daily_scores FOR SELECT
    TO anon, authenticated
    USING (true);

CREATE POLICY "Allow authenticated users insert daily scores"
    ON public.daily_scores FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

---------------------------------------------------------
-- 3. Friend Rooms Table (Lobby Management)
---------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.friend_rooms (
    room_code TEXT PRIMARY KEY,
    status TEXT NOT NULL DEFAULT 'waiting', -- 'waiting', 'playing', 'finished'
    current_day INT NOT NULL DEFAULT 1,
    participants JSONB NOT NULL DEFAULT '[]'::jsonb,
    host_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RLS for Friend Rooms
ALTER TABLE public.friend_rooms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated read friend rooms"
    ON public.friend_rooms FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Allow authenticated users to create/update friend rooms"
    ON public.friend_rooms FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

---------------------------------------------------------
-- 4. Friend Room Moves Table (Turn Submissions)
---------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.friend_room_moves (
    id BIGSERIAL PRIMARY KEY,
    room_code TEXT NOT NULL REFERENCES public.friend_rooms(room_code) ON DELETE CASCADE,
    user_id TEXT NOT NULL, -- Keep as TEXT to support both UUIDs and CPU mock ids (e.g. cpu_sato)
    username TEXT NOT NULL,
    day_idx INT NOT NULL,
    actual_score INT NOT NULL DEFAULT 0,
    declared_score INT NOT NULL DEFAULT 0,
    hours_history JSONB NOT NULL DEFAULT '[]'::jsonb,
    doubts_made JSONB NOT NULL DEFAULT '[]'::jsonb,
    doubts_submitted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    
    -- Composite unique key to support UPSERT (resolution=merge-duplicates)
    CONSTRAINT unique_room_user_day UNIQUE (room_code, user_id, day_idx)
);

-- RLS for Friend Room Moves
ALTER TABLE public.friend_room_moves ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated users to read moves"
    ON public.friend_room_moves FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Allow authenticated users to submit/update moves"
    ON public.friend_room_moves FOR ALL
    TO authenticated
    USING (auth.uid()::text = user_id OR user_id LIKE 'cpu_%')
    WITH CHECK (auth.uid()::text = user_id OR user_id LIKE 'cpu_%');

---------------------------------------------------------
-- 5. Performance Indexes
---------------------------------------------------------
-- インデックスにより、ルームコードによるポーリングクエリを高速化する
CREATE INDEX IF NOT EXISTS idx_friend_room_moves_room_day
    ON public.friend_room_moves (room_code, day_idx);

CREATE INDEX IF NOT EXISTS idx_daily_scores_season_day
    ON public.daily_scores (season, day_idx, score DESC);

-- savesテーブルのupdated_atを自動更新するトリガー
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_saves_updated_at
    BEFORE UPDATE ON public.saves
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

---------------------------------------------------------
-- 6. RPC: アトミックなルーム参加（レースコンディション対策）
---------------------------------------------------------
-- 複数のユーザーが同時に参加しようとしても、
-- サーバー側でアトミックにJSONB配列を更新するため、
-- クライアント側でのGET→PATCHパターンによるデータ消失を防ぐ。
CREATE OR REPLACE FUNCTION join_friend_room_safe(
    p_room_code TEXT,
    p_user_id TEXT,
    p_username TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_participants JSONB;
    v_new_participant JSONB;
    v_is_in_room BOOLEAN;
BEGIN
    -- 最新のparticipantsを排他ロック付きで取得
    SELECT participants INTO v_participants
    FROM public.friend_rooms
    WHERE room_code = p_room_code
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('error', 'room_not_found');
    END IF;

    -- 既に参加しているか確認
    SELECT EXISTS(
        SELECT 1 FROM jsonb_array_elements(v_participants) AS elem
        WHERE elem->>'user_id' = p_user_id
    ) INTO v_is_in_room;

    IF v_is_in_room THEN
        -- 既参加の場合はそのまま現在のリストを返す
        RETURN jsonb_build_object('participants', v_participants, 'already_joined', true);
    END IF;

    -- 参加人数チェック（最大4人）
    IF jsonb_array_length(v_participants) >= 4 THEN
        RETURN jsonb_build_object('error', 'room_full');
    END IF;

    -- 新しい参加者を配列にアトミックに追加
    v_new_participant := jsonb_build_object('user_id', p_user_id, 'username', p_username);
    v_participants := v_participants || jsonb_build_array(v_new_participant);

    UPDATE public.friend_rooms
    SET participants = v_participants
    WHERE room_code = p_room_code;

    RETURN jsonb_build_object('participants', v_participants, 'already_joined', false);
END;
$$;

---------------------------------------------------------
-- 7. CHECK制約: チート対策スコア上限バリデーション
---------------------------------------------------------
-- クライアントから異常なスコアが送信されても、
-- DBレベルで弾くことでデータの信頼性を保証する。
ALTER TABLE public.daily_scores
    ADD CONSTRAINT chk_score_reasonable CHECK (score >= 0 AND score <= 9999);

ALTER TABLE public.friend_room_moves
    ADD CONSTRAINT chk_actual_score_range CHECK (actual_score >= 0 AND actual_score <= 9999),
    ADD CONSTRAINT chk_declared_score_range CHECK (declared_score >= 0 AND declared_score <= 9999);
