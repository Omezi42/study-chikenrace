# テスト勉強チキンレース

放課後の机の上で、嘘と引きの心理戦を楽しむ **Godot 4.6** ブラウザ向けカジュアルゲーム。

## クイックスタート

1. [Godot 4.6](https://godotengine.org/) をインストール
2. プロジェクトルートの `project.godot` を開く
3. **F5** で実行（起動シーン: `Title.tscn`）

### Web ビルド（Windows）

```bat
build.bat
```

`dist/index.html` が生成され、`http://localhost:8000` でプレビューできます。初回は Web エクスポートテンプレートが必要です。

## ドキュメント一覧

| ファイル | 内容 |
|----------|------|
| [study_chikenrace_GDD.md](study_chikenrace_GDD.md) | ゲームルール・企画の正 |
| [project_progress.md](project_progress.md) | 実装進捗・構成・既知課題 |
| [asset_prompts.md](asset_prompts.md) | 画像生成 AI 用プロンプト集 |

## ゲームの流れ（実装ベース）

**1プレイ = 5日間 × 1日3時間**

```
タイトル → プロフィール（初回のみ） → メインゲーム
  └ 1日のループ（×5）
       アイテム選択 → チキンレース（×3時間） → 学習報告 → 日めくり
  └ 5日目終了後 → 最終結果（Showdown）
```

タイトルから **デッキ編成 / 図鑑 / ガチャ** にも遷移できます（メタ進行）。

## プレイモード

| モード | 状態 | 説明 |
|--------|------|------|
| CPU戦 | **実装済み** | 通信なし。`AIManager` がライバルをシミュレート |
| 全世界対戦 | 準備中 | Supabase ランキング連携の土台あり |
| 友達対戦 | 準備中 | ルーム方式は未実装 |

## 技術構成

- **言語:** GDScript
- **UI:** ほぼコード生成（`VBoxContainer` / `HBoxContainer` + `DeskTheme`）
- **アーキテクチャ:** `GameScene` がフェーズを切り替えるオーケストレーター方式
- **永続化:** `user://savegame.json`（`Global.gd`）
- **オンライン:** Supabase REST（`BackendManager.gd`）

## ディレクトリ構成

```
study-chikenrace/
├── project.godot
├── Title.tscn / Main.tscn / Profile.tscn / ResultScene.tscn
├── LoadoutScene.tscn / GachaScene.tscn / ZukanScene.tscn
├── scripts/
│   ├── core/       # Global, GameSession, StudyDeck, BackendManager, AIManager…
│   ├── data/       # CardData
│   └── ui/         # シーン・DeskTheme・phases・components
└── assets/         # 画像・SE・BGM・フォント
```

## 開発方針

- 仕様変更は **先に GDD を更新**してからコードを直す
- UI 手動配置は最小限。レイアウト・アニメは AI 生成コードで完結
- 進捗・残タスクは `project_progress.md` に追記

## ライセンス

（未記載 — 必要に応じて追記）
