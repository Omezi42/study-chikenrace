# Study Chicken Race 技術評価＆リファクタリングレポート

Godot 4とSupabaseを駆使した「Study Chicken Race」のコードおよびアーキテクチャを詳細に解析しました。
非常に野心的でありながら、WebGL特有の制約やオンラインゲームの非同期性を深く理解した上で設計されている素晴らしいプロトタイプです。特に、同期ズレや切断リスクを嫌って「HTTPポーリングベースのターン進行」を採用した点は、インディーゲームのWeb展開において極めて現実的かつクレバーな判断です。

しかし、「超一流のアーキテクト」の視点から見ると、**「将来的な機能拡張（保守性）」と「セキュリティ（チート対策）」の2点において重大なボトルネック**を抱えています。各項目を厳密に採点し、妥協のないリファクタリング案を提示します。

---

## 1. エグゼクティブ・サマリー

*   **総合評価**: **81.4 / 100 点**（非常に優秀だが、スケール時に破綻するリスクあり）
*   **総評**:
    GDScript 2.0の型指定やTweenを用いたリッチなUI表現など、クライアント側の「手触り（Game Feel）」はすでに商用レベルに達しています。しかし、コードベース全体として**「UIの構築ロジック」と「ゲームのコアルール」が密結合**しており、新カードや新ルールの追加時にコードの肥大化（God Object化）を招く構造になっています。また、SupabaseのDB設計において、クライアントを信用しすぎているため、悪意あるユーザーによる改ざんが容易な状態です。これらを改善することで、完璧なアーキテクチャへと昇華します。

---

## 2. 各項目の詳細評価

### 項目1: ゲームループと状態遷移設計 (Architecture & State Transition)
*   **評価スコア**: **85 / 100 点**
*   **評価の理由**:
    *   **【強み】**: `PhaseBase` を継承したフェーズノード群と、それらをまたぐデータを保持する `GameSession` の分離は美しく、State（状態）の切り出しとして非常に機能しています。
    *   **【ボトルネック】**: `GameScene.gd` の `change_phase()` 内で、`match` 文によるハードコードされた状態遷移が行われています（BagBuilder → ChickenRace → Reportなど）。これにより、例えば「特定のアイテムを使った時だけ発生する特殊フェーズ」や「チュートリアル専用の分岐」を追加する際、`GameScene.gd` がカオスになります。
*   **満点（100点）にするためのステップ**:
    *   **ステートマシンの導入**: `change_phase` の呼び出し元を `GameScene` にハードコードするのではなく、各Phase自身が「次に遷移すべきPhaseのID」を `phase_finished` シグナルに乗せて返す「Push型ステートマシン」に変更してください。

### 項目2: Supabase API 連携とマルチプレイヤー同期の堅牢性 (Backend & Sync Robustness)
*   **評価スコア**: **65 / 100 点**
*   **評価の理由**:
    *   **【強み】**: WebSocketを使わず、HTTPポーリングと UPSERT（`Prefer: resolution=merge-duplicates`）による冪等な状態更新を行っている点は、モバイル回線やブラウザ環境での安定稼働において最高の選択です。
    *   **【ボトルネック】**: `WaitingPhase.gd` で固定の3秒間隔ポーリング（`Timer.wait_time = 3.0`）を行っています。プレイヤーが同期待ちで放置した場合、SupabaseのAPIリクエスト数を無駄に消費し、無料枠のCompute Unitを圧迫します。また、エラーハンドリング時に `HTTPRequest` ノードの破棄漏れリスクが僅かにあります。
*   **満点（100点）にするためのステップ**:
    *   **指数的バックオフ（Exponential Backoff）の実装**: ポーリング間隔を3秒から開始し、変化がない場合は4.5秒、6秒、最大15秒と間隔を広げ、サーバー負荷を劇的に下げるロジックを組み込むこと。

### 項目3: WebGL（HTML5）対応とクライアント最適化 (Web Export & Client Optimization)
*   **評価スコア**: **88 / 100 点**
*   **評価の理由**:
    *   **【強み】**: `gl_compatibility` レンダラーの選択、CORSを意識したHTTP実装など、WebGLに向けた最適化が十分意識されています。
    *   **【ボトルネック】**: ブラウザ（特にChromeやSafari）の厳格な「AudioContextの自動再生ポリシー」に対するセーフティが不足しています。ユーザーが画面をクリックする前に `AudioManager.play_bgm()` が呼ばれるとエラーになります。また、UIノードをスクリプトから大量に `new()` して生成しているため（例: `ChickenRacePhase.gd` 内で何百行ものUI構築）、低スペックPCのブラウザではフェーズ切り替え時に一瞬のフリーズ（Layout Thrashing）が発生します。
*   **満点（100点）にするためのステップ**:
    *   UIの構築は極力 `.tscn` ファイルで行い、スクリプトでは `@export` や `%Node`（Scene Unique Node）で参照を取得する形にリファクタリングし、インスタンス化のコストを下げること。
    *   タイトル画面の「画面のどこかをクリック」を検知して初めてAudioContextをアンロックする処理を入れること。

### 項目4: コードの保守性と拡張性 (Clean Code & Scalability)
*   **評価スコア**: **75 / 100 点**
*   **評価の理由**:
    *   **【強み】**: GDScriptの型宣言を徹底している点は素晴らしいです。
    *   **【ボトルネック】**: `StudyDeck.gd` の `activate_item_effect()` が巨大な `match item_id:` の塊（神メソッド）になっています。「オープン・クローズドの原則（OCP）」に完全に違反しており、アイテムを1つ追加するたびにこのコアクラスを修正しなければなりません。また、カードデータが `Dictionary` で管理されており、エディタでの型補完やインスペクタからの調整が効きません。
*   **満点（100点）にするためのステップ**:
    *   アイテム効果を「Strategyパターン」でクラス化するか、Godotの `Resource` クラスを用いて、各アイテム効果をポリモーフィズムで解決するように書き換えること。

### 項目5: UI/UXの実装手法と動的制御 (UI/UX Code Quality)
*   **評価スコア**: **94 / 100 点**
*   **評価の理由**:
    *   **【強み】**: `DeskTheme.gd` に集約されたTweenアニメーション群（Hover時のバウンス、ページめくり、ビネットの脈動）は傑作です。ゲームの手触りを劇的に向上させています。
    *   **【ボトルネック】**: わずかな欠点として、Tween実行中に該当ノードが `queue_free()` された場合の `bind_node()` による保護はありますが、シーン遷移時に「Orphan Tween（孤児になったTween）」の警告が出る余地が一部残っています。
*   **満点（100点）にするためのステップ**:
    *   既存の仕組みで十分高いクオリティですが、複雑なアニメーションチェインを行う際は `tween.kill()` を安全に呼べる設計にしておくと完璧です。

---

## 3. セキュリティ＆高負荷耐性の診断レポート

本システムをオンラインに公開した場合、**即座に破壊される2つの致命的な脆弱性**があります。

1.  **【超危険】Row Level Security (RLS) のガバガバ設定**
    `supabase_schema.sql` の `friend_room_moves` テーブルにおいて、以下のポリシーが設定されています。
    ```sql
    CREATE POLICY "Allow authenticated users to submit/update moves"
        ON public.friend_room_moves FOR ALL TO authenticated USING (true) WITH CHECK (true);
    ```
    これは「認証さえしていれば、**他人のスコアや他人の部屋のデータを自由に上書き・削除できる**」ことを意味します。悪意あるユーザーがHTTP POSTを直接叩けば、全員のスコアを0にできます。
    **【対策】**: `USING (auth.uid()::text = user_id OR user_id LIKE 'cpu_%')` のように、自身のIDまたはCPUのIDのみ更新できるように制限を強固にしてください。

2.  **【危険】クライアントトラストによるチート**
    `BackendManager.gd` の `upload_daily_record` や `upload_friend_move` において、`actual_score`（実点）と `declared_score`（申告点）をクライアントで計算し、そのまま送信しています。パケットを改ざんされると「実点 99999点」のチーターが全国ランキングを埋め尽くします。
    **【対策】**: 本来はSupabase Edge Functions（サーバーサイド）でドロー履歴の整合性を検証すべきですが、プロトタイプであれば、最低限「履歴配列から再計算したスコアと合致するか」をDBのトリガー（PostgreSQL関数）でチェックするバリデーションをSQL側に持たせるべきです。

---

## 4. 満点化のためのベスト・リファクタリングコード例

### 改善例1: 指数的バックオフを用いたポーリング（WaitingPhase.gd）
DBへの負荷を劇的に下げるためのポーリング最適化実装です。

```gdscript
# WaitingPhase.gd の一部を修正
var base_poll_interval: float = 2.0
var current_poll_interval: float = 2.0
var max_poll_interval: float = 12.0

func _on_setup(setup_data: Dictionary) -> void:
    # ... 前略 ...
    poll_timer = Timer.new()
    poll_timer.wait_time = current_poll_interval
    poll_timer.autostart = true
    poll_timer.timeout.connect(_on_poll_timeout)
    add_child(poll_timer)
    _on_poll_timeout()

func _on_poll_timeout() -> void:
    if has_node("/root/BackendManager"):
        get_node("/root/BackendManager").poll_day_moves(Global.friend_room_code, target_day)
    
    # 指数的バックオフ: ポーリング間隔を徐々に広げる
    current_poll_interval = min(current_poll_interval * 1.5, max_poll_interval)
    poll_timer.wait_time = current_poll_interval
    poll_timer.start()

# データに更新があった場合は間隔をリセットする処理を _on_day_moves_polled 内に追加
func _on_day_moves_polled(success: bool, moves: Array) -> void:
    if success:
        # 新しい手が提出されているかチェックし、変化があればインターバルを戻す
        current_poll_interval = base_poll_interval
        poll_timer.wait_time = current_poll_interval
```

### 改善例2: Strategyパターンによるアイテム効果の分離（拡張性の確保）
`StudyDeck.gd` に巨大な `match` 文を書くのではなく、アイテム効果を独立したクラスに切り出します。

```gdscript
# ItemEffect.gd (基底クラス)
class_name ItemEffect extends RefCounted
func execute(deck: StudyDeck, session: GameSession) -> void:
    pass

# EraserEffect.gd (消しゴムの効果)
class_name EraserEffect extends ItemEffect
func execute(deck: StudyDeck, session: GameSession) -> void:
    deck.eraser_charges += 1
    DeskTheme.show_toast(session.active_phase_node, "消しゴムの効果！眠気回避をチャージ！")

# HighLighterEffect.gd (蛍光ペンの効果)
class_name HighlighterEffect extends ItemEffect
func execute(deck: StudyDeck, session: GameSession) -> void:
    deck.highlighter_active = true
    DeskTheme.show_toast(session.active_phase_node, "蛍光ペンの効果！コンボボーナス1.5倍！")

# StudyDeck.gd 側の呼び出し (劇的にシンプルになる)
var item_strategies: Dictionary = {
    "item_eraser": EraserEffect.new(),
    "item_highlighter": HighlighterEffect.new()
    # 新しいアイテムを追加する際はここに登録するだけ（またはResource化する）
}

func activate_item_effect(card: Dictionary, session: GameSession) -> void:
    var item_id = card.get("item_id", "")
    if item_strategies.has(item_id):
        item_strategies[item_id].execute(self, session)
```
