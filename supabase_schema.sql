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
