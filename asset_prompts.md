# 統一絵タッチ画像生成プロンプト集：テスト勉強チキンレース

既存の理想的な背景画像 **`c:\Users\omezi\OneDrive\ドキュメント\study-chikenrace\assets\机の背景画像.png`** の持つ極上のタッチを徹底的に解析し、すべてのゲーム内イラスト（カバン、カード、スタンプ、アイテム）が**「全く同じ一人のイラストレーターによって描かれた」**ような完璧なビジュアル統一性を実現するための、極めて堅牢で実用的なプロンプト集です。

---

## 🎨 解析された「理想の絵のタッチ」の定義（プロンプト共通コア）
このビジュアルスタイルをAIに迷いなく描かせるための絶対ルールです。
* **表現スタイル**: `Flat 2D vector art style`（フラットな2Dベクターアート調）
* **輪郭線**: `Thick bold clean dark outlines`（均一で太く鮮明な暗い輪郭線。これが一番重要です！）
* **色使いと影**: `Bright flat colors, minimal clean cell-shading`（グラデーションやノイズのない平塗り、シンプルな陰影）
* **雰囲気**: `Polished anime webcomic look`（洗練されたアニメ・ウェブコミック調のすっきりとしたデザイン）
* **質感**: **3Dクレイ、リアルな木目、水彩テクスチャ、複雑な3Dレンダリングは100%排除**します。

---

## 1. 📂 背景・大物アセット用プロンプト

### ① 木の勉強机と見開きノートの背景 (`res://assets/机の背景画像.png`)
お使いの理想的な背景画像を、AIで再生成またはバリエーション作成する際の「極めて頑強な」プロンプトです。
```text
Flat 2D top-down view of a cozy Japanese student wooden desk. In the center, a large, clean, blank open ring notebook with white pages and a silver metal spiral binding. On the notebook's top and right edges, several cute, colorful sticky index tabs (pink, yellow, green, blue) are neatly sticking out. Scattered around the desk edges are clean, simple school items: a classic blue and white block eraser, a green wooden pencil, a pink zippered pencil case in the corner, a couple of stacked yellow and blue textbooks, and a red wooden pencil. Crisp flat vector illustration style, polished anime webcomic look, thick bold clean dark outlines, bright flat colors with minimal cell shading, smooth warm orange-yellow wood grain texture, high-res --ar 16:9
```

### ② 形状統一・学生用スクールバッグ (`res://assets/カバン画像.png`)
カバン構築画面で使用する、カバンの中身を真上から覗き込んだ、統一タッチのイラストです。
```text
Flat 2D top-down view of a classic Japanese high school student nylon school bag, opened up flat. Polished anime webcomic illustration style, thick bold clean dark outlines, bright flat vibrant colors. Inside the bag are five clean, colorful plastic divider slots (red, blue, yellow, green, purple). Crisp flat vector art, isolated on a solid clean white background, no gradients, no photorealism, no 3D clay
```

---

## 2. 🎴 カード・ゲームプレイ用プロンプト

### ③ 学習カードの表面フレーム (`res://assets/カード背景画像.png`)
数字やテキストが入る、シンプルで統一されたカードフレームです。
```text
Flat 2D vector design of a blank rounded rectangular study card. A clean, smooth cream-colored paper surface surrounded by a thick bold solid color border, crisp uniform dark outlines. Polished anime cartoon style, simple geometric layout, clean and cute, isolated on a solid clean white background
```

### ④ カード裏面のパターンデザイン (`res://assets/カード裏面画像.png`)
山札の裏面となる、文房具がちりばめられた愛らしいパターンです。
```text
Flat 2D repeating seamless pattern of cute classroom stationery doodles: tiny pencils, erasers, books, and rulers in bold clean outlines. Placed on a light sky-blue background with a subtle, clean grid pattern. Polished anime webcomic style, vibrant flat colors, thick uniform dark outlines, clean and cheerful game card back texture, isolated on a solid clean white background
```

---

## 3. 💮 スタンプ・報酬バッジ用プロンプト

### ⑤ 提出完了 ＆ 嘘バレ・インクスタンプ (`res://assets/はなまるスタンプ.png` / doubts)
『チキスタ』アプリやノートの上にドン！と押される、手書き調のインクスタンプです。
```text
Flat 2D red ink stamp print on paper, featuring a classic Japanese hand-drawn "Hanamaru" (flower circle) mark. Bold organic red ink outline, slight clean ink bleed texture, polished retro cartoon style, isolated on a solid clean white background
```

### ⑥ トップ順位用・ご褒美の王冠 (`res://assets/王冠.png`)
暫定トップやタイムラインを飾る、ぷっくりしたフラットなアニメ調の王冠です。
```text
Flat 2D cartoon icon of a cute, simple golden king's crown. Polished anime webcomic style, bold thick clean dark outline, bright flat yellow-gold and red colors, simple cell-shading. Cute rewards sticker design, isolated on a solid clean white background
```

### ⑦ お助け文房具アイテムアイコンセット (`res://assets/アイテム.png`)
お助けアイテムに使用する、統一タッチの文房具単体イラストセットです。
```text
A set of four simple 2D game UI item icons of school stationery: a blocky blue eraser, a yellow mechanical pencil, a clear ruler, and a pink keychain charm. Flat top-down view, polished anime webcomic style, thick bold clean dark outlines, bright flat vibrant colors, isolated on a solid clean white background
```

---

## 4. 🚀 さらなるクオリティアップのための追加アセット（推奨）

既存のUIのプログラム（コード描画）部分を、さらに「おもちゃ感・絵としてのリッチさ」へと引き上げるための、世界観に合わせた新規アセットのプロンプト案です。

### ⑧ 学校の黒板風ダイアログフレーム（タイトル・説明用）
現在コードで描画している深緑のパネルを、イラストとしての「木枠の黒板」に置き換えるための画像です。
```text
Flat 2D vector design of a classic Japanese classroom chalkboard UI frame. A dark green board surface enclosed by a warm, chunky light-brown wooden frame with tiny screws in the corners. At the bottom edge, a small chalk ledge with a white chalk piece and a yellow and black blackboard eraser. Polished anime webcomic style, thick bold clean dark outlines, bright flat colors with minimal cell-shading, cute and clean, isolated on a solid clean white background
```

### ⑨ スマートフォン端末フレーム（チキスタアプリの外枠用）
チキスタのアプリコンテナの周囲に被せることで、実際に机の上に「スマホが置かれている」実在感を爆発的に高めるアイテムです。
```text
Flat 2D top-down view of a sleek modern smartphone casing with a blank transparent screen area. The phone has a cute pastel-colored protective case (mint green or soft pink) and subtle camera lenses on the back edge. Polished anime webcomic style, thick bold clean dark outlines, bright flat colors, minimal cell-shading, cute simple aesthetic, isolated on a solid clean white background
```

### ⑩ 期末テストの成績表・通知表ベース（最終リザルト画面用）
7日目の最終結果発表を、ただのパネルではなく「本物の通知表」のように見せる紙のベース枠です。
```text
Flat 2D top-down view of a Japanese school report card document lying flat. Thick folded crisp white paper with a light blue classic grid and thick ruled lines. At the top right, a cute classic school logo. Polished anime webcomic style, thick bold clean dark outlines, bright flat colors, simple and clean UI panel design, isolated on a solid clean white background
```

### ⑪ エナジードリンク缶（睡魔回復・徹夜アイテム案）
「消しゴム（回避）」とは異なる、回復系のアイテム案です。
```text
Flat 2D cartoon icon of a cute, bright neon-blue and silver energy drink can with a lightning bolt symbol. Polished anime webcomic style, thick bold clean dark outlines, bright flat vibrant colors, minimal clean cell-shading, isolated on a solid clean white background
```

---

## 💡 生成と適用のコツ（統一感を出すための設定）
1. **「 isolated on a solid clean white background 」の徹底**:
   背景画像以外のすべてのアセットプロンプトにこの一文を入れています。これにより、白い背景部分をPhotoshopや透過ツールで一瞬できれいに透過（アルファチャンネル化）させ、Godot内で自在に配置することが可能になります。
2. **太い黒い縁取り（Thick bold clean dark outlines）の威力**:
   DALL-E 3 等に生成させる際、このフレーズが入っていることで、絵全体がぼやけず、パキッとした「ゲームのイラスト」として最高に機能するようになります。お使いの背景画像のタッチと100%合致するため、画面の一体感が飛躍的に向上します。
