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

### ⑫ 時間割ノート風のタイムライン詳細背景 (Timeline Schedule Note Background)
スマホ画面や詳細ログの背景として使用する、手書きの時間割表が印刷された、少しインク染みのあるノート風の背景です。
```text
Flat 2D top-down view of a page from a Japanese student's schedule notebook. Soft grid lines, handwritten Japanese text columns for classroom periods (e.g., "1時限目", "2時限目"), clean pencil borders, and light margins. Polished anime webcomic style, soft beige cream paper texture, thick uniform outlines, isolated on a solid clean white background
```

### ⑬ ミニ文房具/役割スタンプアイコンセット (Miniature Stationery & Role Badges)
タイムライン詳細でドロー数や役割を表すための、極小サイズのゴムスタンプ風のイラストアイコン集です。
```text
A set of six miniature hand-drawn style ink stamps for school stationery: a small green pencil stub, a tiny red heart mark, a tiny blue gear, a small green shield symbol, a tiny orange fire flame, and a small purple speech bubble. Flat 2D vector style, thick bold outlines, bright flat colors, isolated on a solid clean white background
```

### ⑭ ダウト/セーフの赤・黄インクスタンプ (Doubted / Safe Ink Stamps)
答え合わせ黒板やタイムラインで結果を確定させる際に押される、インクかすれのあるゴム印調スタンプです。
```text
Flat 2D vector graphic of rubber ink stamps: one red stamp saying "ダウト" (Doubt) in Japanese gothic font inside a thick rectangle, and one yellow stamp saying "セーフ" (Safe) in Japanese font inside a round circle. Organic stamp texture, slight ink bleed, bold outlines, isolated on a solid clean white background
```

### ⑮ チョーク調の手書き点数カード (Chalkboard Chalk Score Cards)
答え合わせ黒板の上で各プレイヤーのスコアを表示するための、粉っぽさのあるチョーク風手書きカードです。
```text
Flat 2D vector design of a small dark green chalkboard card with chalk-written Japanese numbers and names. Powdered white and yellow chalk handwriting style, rough border outlines, polished school cartoon style, isolated on a solid clean white background
```

---

## 💡 生成と適用のコツ（統一感を出すための設定）
1. **「 isolated on a solid clean white background 」の徹底**:
   背景画像以外のすべてのアセットプロンプトにこの一文を入れています。これにより、白い背景部分をPhotoshopや透過ツールで一瞬できれいに透過（アルファチャンネル化）させ、Godot内で自在に配置することが可能になります。
2. **太い黒い縁取り（Thick bold clean dark outlines）の威力**:
   DALL-E 3 等に生成させる際、このフレーズが入っていることで、絵全体がぼやけず、パキッとした「ゲームのイラスト」として最高に機能するようになります。お使いの背景画像のタッチと100%合致するため、画面の一体感が飛躍的に向上します。

---

## 🎒 5. 全25アイテムの画像生成プロンプト個別一覧

すべてのプロンプトには、統一スタイルを維持するための以下のキーワードが組み込まれています。
`Flat 2D vector art style, thick bold clean dark outlines, bright flat colors, minimal clean cell-shading, polished anime webcomic look, isolated on a solid clean white background`

### ① 付箋 (Sticky Note - item_sticky_note)
```text
Flat 2D vector icon of a single bright neon-yellow paper sticky note, slightly curled on the bottom edge. Flat 2D vector art style, thick bold clean dark outlines, bright flat colors, minimal clean cell-shading, polished anime webcomic look, isolated on a solid clean white background
```

### ② 消しゴム (Eraser - item_eraser)
```text
Flat 2D vector icon of a classic blue and white cardboard sleeve block school eraser. Flat 2D vector art style, thick bold clean dark outlines, bright flat colors, minimal clean cell-shading, polished anime webcomic look, isolated on a solid clean white background
```

### ③ 定規 (Ruler - item_ruler)
```text
Flat 2D vector icon of a transparent plastic 15cm school ruler with black scale markings. Flat 2D vector art style, thick bold clean dark outlines, bright flat colors, minimal clean cell-shading, polished anime webcomic look, isolated on a solid clean white background
```

### ④ 単語帳 (Wordbook - item_wordbook)
```text
Flat 2D vector icon of a colorful student ring-bound wordbook (flash cards). Flat 2D vector art style, thick bold clean dark outlines, bright flat colors, minimal clean cell-shading, polished anime webcomic look, isolated on a solid clean white background
```

### ⑤ シャーペン (Mechanical Pencil - item_mech_pencil)
```text
Flat 2D vector icon of a sleek yellow mechanical pencil with silver metallic accents. Flat 2D vector art style, thick bold clean dark outlines, bright flat colors, minimal clean cell-shading, polished anime webcomic look, isolated on a solid clean white background
```

### ⑥ 暗記カード (Memo Cards - item_memo_cards)
```text
Flat 2D vector icon of a small stack of white study index cards bound together by a silver binder ring. Flat 2D vector art style, thick bold clean dark outlines, bright flat colors, minimal clean cell-shading, polished anime webcomic look, isolated on a solid clean white background
```

### ⑦ 蛍光ペン (Highlighter - item_highlighter)
```text
Flat 2D vector icon of a bright pink highlighter pen, cap off, revealing the chisel tip. Flat 2D vector art style, thick bold clean dark outlines, bright flat colors, minimal clean cell-shading, polished anime webcomic look, isolated on a solid clean white background
```

### ⑧ 青ペン (Blue Pen - item_blue_pen)
```text
Flat 2D vector icon of a blue ballpoint ink pen with a clear plastic body. Flat 2D vector art style, thick bold clean dark outlines, bright flat colors, minimal clean cell-shading, polished anime webcomic look, isolated on a solid clean white background
```

### ⑨ 座布団 (Cushion - item_cushion)
```text
Flat 2D vector icon of a soft green fabric school chair cushion with neat stitch patterns. Flat 2D vector art style, thick bold clean dark outlines, bright flat colors, minimal clean cell-shading, polished anime webcomic look, isolated on a solid clean white background
```

### ⑩ メモアプリ (Memo App - item_memo_app)
```text
Flat 2D vector icon of a smartphone screen showing a cute yellow memo notepad application with checkmarks. Flat 2D vector art style, thick bold clean dark outlines, bright flat colors, minimal clean cell-shading, polished anime webcomic look, isolated on a solid clean white background
```

### ⑪ ズルいカンペ (Cheat Sheet - item_cheat_sheet)
```text
Flat 2D vector icon of a tiny folded white scrap of paper with microscopic handwritten math formulas. Flat 2D vector art style, thick bold clean dark outlines, bright flat colors, minimal clean cell-shading, polished anime webcomic look, isolated on a solid clean white background
```

### ⑫ コンパス (Compass - item_compass)
```text
Flat 2D vector icon of a silver metal school drawing compass holding a small graphite pencil. Flat 2D vector art style, thick bold clean dark outlines, bright flat colors, minimal clean cell-shading, polished anime webcomic look, isolated on a solid clean white background
```

### ⑬ エナジードリンク (Energy Drink - item_energy_drink)
```text
Flat 2D vector icon of a neon blue energy drink can with a yellow lightning bolt logo. Flat 2D vector art style, thick bold clean dark outlines, bright flat colors, minimal clean cell-shading, polished anime webcomic look, isolated on a solid clean white background
```

### ⑭ 赤シート (Red Sheet - item_red_sheet)
```text
Flat 2D vector icon of a translucent red plastic sheet used for hiding answer text during studying. Flat 2D vector art style, thick bold clean dark outlines, bright flat colors, minimal clean cell-shading, polished anime webcomic look, isolated on a solid clean white background
```

### ⑮ 分厚い参考書 (Thick Reference Book - item_thick_book)
```text
Flat 2D vector icon of a thick, heavy student reference book with a dark blue cover and orange spine. Flat 2D vector art style, thick bold clean dark outlines, bright flat colors, minimal clean cell-shading, polished anime webcomic look, isolated on a solid clean white background
```

### ⑯ お守り (Amulet - item_amulet)
```text
Flat 2D vector icon of a traditional Japanese fabric amulet (Omamori) in red silk with gold embroidered strings. Flat 2D vector art style, thick bold clean dark outlines, bright flat colors, minimal clean cell-shading, polished anime webcomic look, isolated on a solid clean white background
```

### ⑰ 徹夜ノート (All-Nighter Notebook - item_night_note)
```text
Flat 2D vector icon of a dark purple notebook titled 'ALL NIGHT' with a small crescent moon sticker. Flat 2D vector art style, thick bold clean dark outlines, bright flat colors, minimal clean cell-shading, polished anime webcomic look, isolated on a solid clean white background
```

### ⑱ 解答写し (Copy Answer - item_copy_answer)
```text
Flat 2D vector icon of a cheat sheet pamphlet showing identical copied exam answers in red circle marks. Flat 2D vector art style, thick bold clean dark outlines, bright flat colors, minimal clean cell-shading, polished anime webcomic look, isolated on a solid clean white background
```

### ⑲ タイマー (Timer - item_timer)
```text
Flat 2D vector icon of a round white digital kitchen timer displaying a percentage numbers '03:00'. Flat 2D vector art style, thick bold clean dark outlines, bright flat colors, minimal clean cell-shading, polished anime webcomic look, isolated on a solid clean white background
```

### ⑳ 勉強会チャット (Study Chat - item_study_chat)
```text
Flat 2D vector icon of a tablet screen displaying a cute school study group chat room with text bubbles. Flat 2D vector art style, thick bold clean dark outlines, bright flat colors, minimal clean cell-shading, polished anime webcomic look, isolated on a solid clean white background
```

### ㉑ 予想問題集 (Expected Questions - item_expected_questions)
```text
Flat 2D vector icon of a printed student exam sheet titled 'EXPECTED QUESTIONS' in bold hand-lettering. Flat 2D vector art style, thick bold clean dark outlines, bright flat colors, minimal clean cell-shading, polished anime webcomic look, isolated on a solid clean white background
```

### ㉒ カフェラテ (Cafe Latte - item_cafe_latte)
```text
Flat 2D vector icon of a takeout paper coffee cup of hot café latte with a white lid and brown sleeve. Flat 2D vector art style, thick bold clean dark outlines, bright flat colors, minimal clean cell-shading, polished anime webcomic look, isolated on a solid clean white background
```

### ㉓ 耳栓 (Earplugs - item_earplugs)
```text
Flat 2D vector icon of a pair of orange soft foam earplugs connected by a thin yellow cord. Flat 2D vector art style, thick bold clean dark outlines, bright flat colors, minimal clean cell-shading, polished anime webcomic look, isolated on a solid clean white background
```

### ㉔ 塾プリント (Cram School Print - item_cram_school_print)
```text
Flat 2D vector icon of a student cram school printed worksheet with a large red Hanamaru stamp. Flat 2D vector art style, thick bold clean dark outlines, bright flat colors, minimal clean cell-shading, polished anime webcomic look, isolated on a solid clean white background
```

### ㉕ 忘却のノート (Forget Notebook - item_forget_notebook)
```text
Flat 2D vector icon of a worn-out gray pocket notebook, cover slightly creased and torn. Flat 2D vector art style, thick bold clean dark outlines, bright flat colors, minimal clean cell-shading, polished anime webcomic look, isolated on a solid clean white background
```

