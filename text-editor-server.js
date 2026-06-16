const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 3000;
const LOCALIZATION_PATH = path.join(__dirname, 'src', 'autoload', 'Localization.gd');
const CARD_DATA_PATH = path.join(__dirname, 'src', 'data', 'CardData.gd');

const UI_FILES = [
  'src/ui/TitleScene.gd',
  'src/ui/ProfileScene.gd',
  'src/ui/ResultScene.gd',
  'src/ui/GachaScene.gd',
  'src/ui/ZukanScene.gd',
  'src/ui/LoadoutScene.gd',
  'src/ui/GameScene.gd'
].map(p => path.join(__dirname, p));

// ==========================================
// 1. パーサ＆セーバー ロジック
// ==========================================

function parseLocalization(content) {
  const result = {
    constants: {},
    textData: {}
  };

  const constRegex = /const\s+([A-Za-z0-9_]+)\s*=\s*"([^"]*)"/g;
  let match;
  while ((match = constRegex.exec(content)) !== null) {
    if (match[1] !== 'TEXT_DATA') {
      result.constants[match[1]] = match[2];
    }
  }

  const textDataBlockMatch = content.match(/const\s+TEXT_DATA\s*=\s*\{([\s\S]*?)\}/);
  if (textDataBlockMatch) {
    const blockContent = textDataBlockMatch[1];
    const dictRegex = /"([A-Za-z0-9_]+)"\s*:\s*"([^"]*)"/g;
    let dictMatch;
    while ((dictMatch = dictRegex.exec(blockContent)) !== null) {
      result.textData[dictMatch[1]] = dictMatch[2];
    }
  }

  return result;
}

function saveLocalization(content, updatedData) {
  let newContent = content;

  for (const [key, val] of Object.entries(updatedData.constants)) {
    const escapedVal = val.replace(/"/g, '\\"');
    const regex = new RegExp(`(const\\s+${key}\\s*=\\s*)"[^"]*"`);
    newContent = newContent.replace(regex, `$1"${escapedVal}"`);
  }

  const textDataBlockMatch = newContent.match(/const\s+TEXT_DATA\s*=\s*\{([\s\S]*?)\}/);
  if (textDataBlockMatch) {
    const oldBlock = textDataBlockMatch[0];
    let newBlockContent = textDataBlockMatch[1];

    for (const [key, val] of Object.entries(updatedData.textData)) {
      const escapedVal = val.replace(/"/g, '\\"');
      const regex = new RegExp(`("${key}"\\s*:\\s*)"[^"]*"`);
      newBlockContent = newBlockContent.replace(regex, `$1"${escapedVal}"`);
    }

    newContent = newContent.replace(oldBlock, `const TEXT_DATA = {${newBlockContent}}`);
  }

  return newContent;
}

function parseCardData(content) {
  const items = {};
  const itemBlockRegex = /"item_[a-z_0-9]+"\s*:\s*\{([\s\S]*?)\}/g;
  let match;
  while ((match = itemBlockRegex.exec(content)) !== null) {
    const block = match[0];
    const blockContent = match[1];

    const idMatch = blockContent.match(/"id"\s*:\s*"([^"]+)"/);
    const nameMatch = blockContent.match(/"name"\s*:\s*"([^"]+)"/);
    const descMatch = blockContent.match(/"description"\s*:\s*"([^"]+)"/);

    if (idMatch && nameMatch && descMatch) {
      items[idMatch[1]] = {
        name: nameMatch[1],
        description: descMatch[1]
      };
    }
  }
  return items;
}

function saveCardData(content, updatedItems) {
  let newContent = content;
  const itemBlockRegex = /"item_([a-z_0-9]+)"\s*:\s*\{([\s\S]*?)\}/g;
  
  newContent = newContent.replace(itemBlockRegex, (block, id, blockContent) => {
    const idMatch = blockContent.match(/"id"\s*:\s*"([^"]+)"/);
    if (idMatch && updatedItems[idMatch[1]]) {
      const updated = updatedItems[idMatch[1]];
      const escapedName = updated.name.replace(/"/g, '\\"');
      const escapedDesc = updated.description.replace(/"/g, '\\"');
      
      let newBlockContent = blockContent;
      newBlockContent = newBlockContent.replace(/"name"\s*:\s*"[^"]*"/, `"name": "${escapedName}"`);
      newBlockContent = newBlockContent.replace(/"description"\s*:\s*"[^"]*"/, `"description": "${escapedDesc}"`);
      return `"item_${id}": {${newBlockContent}}`;
    }
    return block;
  });
  return newContent;
}

function parseUIScripts() {
  const result = {};
  for (const filepath of UI_FILES) {
    if (!fs.existsSync(filepath)) continue;
    const content = fs.readFileSync(filepath, 'utf-8');
    const lines = content.split('\n');
    const fileTexts = [];
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      if (line.trim().startsWith('#')) continue;
      
      // ダブルクォートの日本語文字列
      const doubleQuoteRegex = /"([^"\n]*[\u3040-\u30ff\u4e00-\u9faf\uff00-\uffef][^"\n]*)"/g;
      let match;
      while ((match = doubleQuoteRegex.exec(line)) !== null) {
        fileTexts.push({
          lineIndex: i,
          originalText: match[1],
          currentText: match[1],
          quoteChar: '"'
        });
      }
      
      // シングルクォートの日本語文字列
      const singleQuoteRegex = /'([^'\n]*[\u3040-\u30ff\u4e00-\u9faf\uff00-\uffef][^'\n]*)'/g;
      let sMatch;
      while ((sMatch = singleQuoteRegex.exec(line)) !== null) {
        fileTexts.push({
          lineIndex: i,
          originalText: sMatch[1],
          currentText: sMatch[1],
          quoteChar: "'"
        });
      }
    }
    
    if (fileTexts.length > 0) {
      const relativePath = path.relative(__dirname, filepath).replace(/\\/g, '/');
      result[relativePath] = fileTexts;
    }
  }
  return result;
}

function saveUIScripts(updatedTexts) {
  for (const [relPath, textList] of Object.entries(updatedTexts)) {
    const filepath = path.join(__dirname, relPath);
    if (!fs.existsSync(filepath)) continue;
    
    let content = fs.readFileSync(filepath, 'utf-8');
    const lines = content.split('\n');
    
    for (const item of textList) {
      const line = lines[item.lineIndex];
      if (!line) continue;
      
      const escapedOriginal = item.originalText.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');
      const quote = item.quoteChar || '"';
      const regex = new RegExp(quote + escapedOriginal + quote, 'g');
      
      lines[item.lineIndex] = line.replace(regex, quote + item.currentText + quote);
    }
    
    fs.writeFileSync(filepath, lines.join('\n'), 'utf-8');
  }
}

// ==========================================
// 2. HTTP サーバー & エンドポイント
// ==========================================

const server = http.createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // GET /api/texts - テキストデータの読み込み
  if (req.method === 'GET' && req.url === '/api/texts') {
    try {
      const locContent = fs.readFileSync(LOCALIZATION_PATH, 'utf-8');
      const cardContent = fs.readFileSync(CARD_DATA_PATH, 'utf-8');

      const locData = parseLocalization(locContent);
      const cardData = parseCardData(cardContent);
      const uiScriptsData = parseUIScripts();

      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({
        localization: locData,
        cards: cardData,
        uiScripts: uiScriptsData
      }));
    } catch (err) {
      console.error(err);
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Failed to read gdscript files.' }));
    }
    return;
  }

  // POST /api/texts - テキストデータの保存
  if (req.method === 'POST' && req.url === '/api/texts') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try {
        const { localization, cards, uiScripts } = JSON.parse(body);

        // Localization.gd の保存
        if (localization) {
          const locContent = fs.readFileSync(LOCALIZATION_PATH, 'utf-8');
          const updatedLocContent = saveLocalization(locContent, localization);
          fs.writeFileSync(LOCALIZATION_PATH, updatedLocContent, 'utf-8');
        }

        // CardData.gd の保存
        if (cards) {
          const cardContent = fs.readFileSync(CARD_DATA_PATH, 'utf-8');
          const updatedCardContent = saveCardData(cardContent, cards);
          fs.writeFileSync(CARD_DATA_PATH, updatedCardContent, 'utf-8');
        }

        // UIスクリプトの保存
        if (uiScripts) {
          saveUIScripts(uiScripts);
        }

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: true, message: 'Saved successfully!' }));
      } catch (err) {
        console.error(err);
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Failed to save gdscript files.' }));
      }
    });
    return;
  }

  // GET / - Web UI の提供
  if (req.method === 'GET' && (req.url === '/' || req.url === '/index.html')) {
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(getHTMLContent());
    return;
  }

  res.writeHead(404, { 'Content-Type': 'text/plain' });
  res.end('Not Found');
});

server.listen(PORT, () => {
  console.log(`====================================================`);
  console.log(`Study Chickenrace Text Editor Server is running!`);
  console.log(`URL: http://localhost:${PORT}`);
  console.log(`Press Ctrl+C to stop the server.`);
  console.log(`====================================================`);
});

// ==========================================
// 3. Web UI HTML (ライトモード)
// ==========================================
function getHTMLContent() {
  return `<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Study Chickenrace - Game Text Editor</title>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Outfit:wght@400;600;800&family=Noto+Sans+JP:wght@400;500;700&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg-base: #F3F4F6;
      --bg-surface: #FFFFFF;
      --bg-surface-hover: #F9FAFB;
      --primary: #4F46E5;
      --primary-hover: #4338CA;
      --primary-glow: rgba(79, 70, 229, 0.15);
      --accent: #10B981;
      --accent-glow: rgba(16, 185, 129, 0.1);
      --text-main: #1F2937;
      --text-muted: #4B5563;
      --text-dark: #9CA3AF;
      --border: #E5E7EB;
      --danger: #EF4444;
      --warning: #F59E0B;
    }

    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    body {
      background-color: var(--bg-base);
      color: var(--text-main);
      font-family: 'Inter', 'Noto Sans JP', sans-serif;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
    }

    header {
      background-color: var(--bg-surface);
      border-bottom: 1px solid var(--border);
      padding: 1.25rem 2rem;
      display: flex;
      justify-content: space-between;
      align-items: center;
      position: sticky;
      top: 0;
      z-index: 100;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
      backdrop-filter: blur(10px);
    }

    .logo-container {
      display: flex;
      align-items: center;
      gap: 0.75rem;
    }

    .logo-text {
      font-family: 'Outfit', sans-serif;
      font-size: 1.5rem;
      font-weight: 800;
      background: linear-gradient(135deg, #4F46E5 0%, #6366F1 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      letter-spacing: -0.5px;
    }

    .badge-dev {
      background-color: rgba(79, 70, 229, 0.1);
      border: 1px solid var(--primary);
      color: var(--primary);
      font-size: 0.75rem;
      padding: 0.2rem 0.5rem;
      border-radius: 999px;
      font-weight: 600;
    }

    .header-actions {
      display: flex;
      align-items: center;
      gap: 1rem;
    }

    .btn {
      padding: 0.6rem 1.25rem;
      font-size: 0.9rem;
      font-weight: 600;
      border-radius: 8px;
      cursor: pointer;
      transition: all 0.2s ease;
      display: flex;
      align-items: center;
      gap: 0.5rem;
      border: none;
    }

    .btn-primary {
      background-color: var(--primary);
      color: white;
      box-shadow: 0 4px 14px var(--primary-glow);
    }

    .btn-primary:hover {
      background-color: var(--primary-hover);
      transform: translateY(-1px);
      box-shadow: 0 6px 20px var(--primary-glow);
    }

    .btn-primary:disabled {
      background-color: var(--border);
      color: var(--text-dark);
      cursor: not-allowed;
      transform: none;
      box-shadow: none;
    }

    main {
      flex: 1;
      padding: 2rem;
      max-width: 1400px;
      width: 100%;
      margin: 0 auto;
      display: flex;
      flex-direction: column;
      gap: 1.5rem;
    }

    .toolbar {
      background-color: var(--bg-surface);
      border: 1px solid var(--border);
      padding: 1rem;
      border-radius: 12px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 1rem;
      flex-wrap: wrap;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.02);
    }

    .tabs {
      display: flex;
      gap: 0.5rem;
      flex-wrap: wrap;
    }

    .tab {
      background: none;
      border: none;
      color: var(--text-muted);
      padding: 0.5rem 1rem;
      font-weight: 500;
      font-size: 0.95rem;
      cursor: pointer;
      border-radius: 6px;
      transition: all 0.2s;
    }

    .tab:hover {
      color: var(--text-main);
      background-color: rgba(0, 0, 0, 0.05);
    }

    .tab.active {
      color: white;
      background-color: var(--primary);
    }

    .search-container {
      position: relative;
      flex: 1;
      max-width: 400px;
      min-width: 250px;
    }

    .search-input {
      width: 100%;
      background-color: #FAFAFA;
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 0.6rem 1rem 0.6rem 2.5rem;
      color: var(--text-main);
      font-size: 0.9rem;
      outline: none;
      transition: border-color 0.2s;
    }

    .search-input:focus {
      border-color: var(--primary);
      background-color: #FFFFFF;
    }

    .search-icon {
      position: absolute;
      left: 0.85rem;
      top: 50%;
      transform: translateY(-50%);
      color: var(--text-muted);
      pointer-events: none;
    }

    .text-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
      gap: 1.5rem;
    }

    .card {
      background-color: var(--bg-surface);
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 1.5rem;
      display: flex;
      flex-direction: column;
      gap: 1rem;
      transition: all 0.2s ease;
      position: relative;
      overflow: hidden;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.03);
    }

    .card:hover {
      border-color: rgba(79, 70, 229, 0.4);
      transform: translateY(-2px);
      box-shadow: 0 6px 20px rgba(0, 0, 0, 0.06);
    }

    .card.modified {
      border-color: var(--accent);
      background-color: #F0FDF4;
    }

    .card.modified::before {
      content: '';
      position: absolute;
      top: 0;
      left: 0;
      width: 4px;
      height: 100%;
      background-color: var(--accent);
    }

    .card-header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
    }

    .card-key {
      font-family: 'Outfit', monospace;
      font-size: 0.85rem;
      color: var(--primary);
      font-weight: 600;
      word-break: break-all;
      padding-right: 1rem;
    }

    .card-badge {
      font-size: 0.7rem;
      padding: 0.15rem 0.4rem;
      border-radius: 4px;
      font-weight: 600;
      white-space: nowrap;
    }

    .badge-ui {
      background-color: rgba(79, 70, 229, 0.1);
      color: var(--primary);
      border: 1px solid rgba(79, 70, 229, 0.2);
    }

    .badge-const {
      background-color: rgba(245, 158, 11, 0.1);
      color: #D97706;
      border: 1px solid rgba(245, 158, 11, 0.2);
    }

    .badge-card {
      background-color: rgba(16, 185, 129, 0.1);
      color: #059669;
      border: 1px solid rgba(16, 185, 129, 0.2);
    }

    .badge-script {
      background-color: rgba(107, 114, 128, 0.1);
      color: #4B5563;
      border: 1px solid rgba(107, 114, 128, 0.2);
    }

    .card-body {
      display: flex;
      flex-direction: column;
      gap: 0.5rem;
    }

    .input-label {
      font-size: 0.75rem;
      color: var(--text-muted);
      font-weight: 500;
    }

    .text-input {
      background-color: #FAFAFA;
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 0.75rem;
      color: var(--text-main);
      font-size: 0.95rem;
      outline: none;
      transition: all 0.2s;
      width: 100%;
      font-family: inherit;
    }

    .text-input:focus {
      background-color: #FFFFFF;
      border-color: var(--primary);
      box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.15);
    }

    textarea.text-input {
      resize: vertical;
      min-height: 80px;
    }

    .card-footer {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-top: auto;
      padding-top: 0.5rem;
      border-top: 1px solid rgba(0, 0, 0, 0.05);
    }

    .char-count {
      font-size: 0.75rem;
      color: var(--text-dark);
    }

    .status-badge {
      font-size: 0.75rem;
      color: var(--accent);
      display: none;
      align-items: center;
      gap: 0.25rem;
      font-weight: 500;
    }

    .card.modified .status-badge {
      display: flex;
    }

    .toast-container {
      position: fixed;
      bottom: 2rem;
      right: 2rem;
      display: flex;
      flex-direction: column;
      gap: 0.75rem;
      z-index: 1000;
    }

    .toast {
      background-color: var(--bg-surface);
      border-left: 4px solid var(--accent);
      border-top: 1px solid var(--border);
      border-right: 1px solid var(--border);
      border-bottom: 1px solid var(--border);
      padding: 1rem 1.5rem;
      border-radius: 6px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
      display: flex;
      align-items: center;
      gap: 0.75rem;
      transform: translateX(120%);
      transition: all 0.3s cubic-bezier(0.68, -0.55, 0.27, 1.55);
      min-width: 300px;
      color: var(--text-main);
    }

    .toast.show {
      transform: translateX(0);
    }

    .toast-error {
      border-left-color: var(--danger);
    }

    .skeleton {
      background: linear-gradient(90deg, var(--bg-surface) 25%, var(--bg-surface-hover) 50%, var(--bg-surface) 75%);
      background-size: 200% 100%;
      animation: loading 1.5s infinite;
      height: 180px;
      border-radius: 12px;
      border: 1px solid var(--border);
    }

    @keyframes loading {
      0% { background-position: 200% 0; }
      100% { background-position: -200% 0; }
    }
  </style>
</head>
<body>
  <header>
    <div class="logo-container">
      <span class="logo-text">STUDY CHICKENRACE</span>
      <span class="badge-dev">Text Editor</span>
    </div>
    <div class="header-actions">
      <span id="unsaved-indicator" style="font-size: 0.85rem; color: var(--warning); display: none; font-weight: 500;">
        ⚠️ 未保存の変更があります
      </span>
      <button id="save-btn" class="btn btn-primary" disabled>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path><polyline points="17 21 17 13 7 13 7 21"></polyline><polyline points="7 3 7 8 15 8"></polyline></svg>
        変更を保存
      </button>
    </div>
  </header>

  <main>
    <div class="toolbar">
      <div class="tabs">
        <button class="tab active" data-tab="all">すべて</button>
        <button class="tab" data-tab="ui">UIテキスト(辞書)</button>
        <button class="tab" data-tab="const">システム定数</button>
        <button class="tab" data-tab="card">カードデータ</button>
        <button class="tab" data-tab="script">UIスクリプト内文言</button>
      </div>
      <div class="search-container">
        <span class="search-icon">🔍</span>
        <input type="text" id="search-input" class="search-input" placeholder="キーまたはテキストで検索...">
      </div>
    </div>

    <div id="editor-grid" class="text-grid">
      <div class="skeleton"></div>
      <div class="skeleton"></div>
      <div class="skeleton"></div>
      <div class="skeleton"></div>
      <div class="skeleton"></div>
      <div class="skeleton"></div>
    </div>
  </main>

  <div class="toast-container" id="toast-container"></div>

  <script>
    let originalData = null;
    let currentData = null;
    let activeTab = 'all';
    let searchQuery = '';

    async function loadData() {
      try {
        const res = await fetch('/api/texts');
        if (!res.ok) throw new Error('APIからデータを取得できませんでした。');
        const data = await res.json();
        originalData = JSON.parse(JSON.stringify(data));
        currentData = data;
        renderGrid();
      } catch (err) {
        showToast(err.message, true);
      }
    }

    function showToast(message, isError = false) {
      const container = document.getElementById('toast-container');
      const toast = document.createElement('div');
      toast.className = \`toast \${isError ? 'toast-error' : ''}\`;
      toast.innerHTML = \`
        <span>\${isError ? '❌' : '✨'}</span>
        <span>\${message}</span>
      \`;
      container.appendChild(toast);
      
      setTimeout(() => toast.classList.add('show'), 50);
      
      setTimeout(() => {
        toast.classList.remove('show');
        setTimeout(() => toast.remove(), 300);
      }, 3000);
    }

    function checkUnsavedChanges() {
      const isChanged = JSON.stringify(originalData) !== JSON.stringify(currentData);
      const saveBtn = document.getElementById('save-btn');
      const indicator = document.getElementById('unsaved-indicator');
      
      saveBtn.disabled = !isChanged;
      indicator.style.display = isChanged ? 'inline' : 'none';
    }

    function handleValueChange(category, key, index, value) {
      if (category === 'ui') {
        currentData.localization.textData[key] = value;
      } else if (category === 'const') {
        currentData.localization.constants[key] = value;
      } else if (category === 'card') {
        const [itemId, field] = key.split(':');
        currentData.cards[itemId][field] = value;
      } else if (category === 'script') {
        const fileKey = key;
        currentData.uiScripts[fileKey][index].currentText = value;
      }

      // カード要素の見た目更新
      const cardEl = document.getElementById(\`card-\${category}-\${key.replace(/:/g, '-')}-\${index || 0}\`);
      if (cardEl) {
        let isModified = false;
        if (category === 'ui') {
          isModified = originalData.localization.textData[key] !== value;
        } else if (category === 'const') {
          isModified = originalData.localization.constants[key] !== value;
        } else if (category === 'card') {
          const [itemId, field] = key.split(':');
          isModified = originalData.cards[itemId][field] !== value;
        } else if (category === 'script') {
          isModified = originalData.uiScripts[key][index].originalText !== value;
        }

        if (isModified) {
          cardEl.classList.add('modified');
        } else {
          cardEl.classList.remove('modified');
        }
      }

      checkUnsavedChanges();
    }

    function renderGrid() {
      const grid = document.getElementById('editor-grid');
      grid.innerHTML = '';

      const items = [];

      // 1. UIテキスト
      for (const [key, val] of Object.entries(currentData.localization.textData)) {
        items.push({
          category: 'ui',
          badgeText: 'UIテキスト',
          badgeClass: 'badge-ui',
          key: key,
          index: 0,
          val: val,
          label: '表示テキスト (Localization.gd)'
        });
      }

      // 2. 定数
      for (const [key, val] of Object.entries(currentData.localization.constants)) {
        items.push({
          category: 'const',
          badgeText: '定数',
          badgeClass: 'badge-const',
          key: key,
          index: 0,
          val: val,
          label: '定数値 (Localization.gd)'
        });
      }

      // 3. カードデータ
      for (const [itemId, item] of Object.entries(currentData.cards)) {
        items.push({
          category: 'card',
          badgeText: 'カード名',
          badgeClass: 'badge-card',
          key: \`\${itemId}:name\`,
          index: 0,
          val: item.name,
          label: \`カード名 (\${itemId})\`
        });
        items.push({
          category: 'card',
          badgeText: 'カード説明',
          badgeClass: 'badge-card',
          key: \`\${itemId}:description\`,
          index: 0,
          val: item.description,
          label: \`カード説明 (\${itemId})\`
        });
      }

      // 4. UIスクリプト
      for (const [filepath, textList] of Object.entries(currentData.uiScripts)) {
        textList.forEach((textItem, idx) => {
          items.push({
            category: 'script',
            badgeText: filepath.split('/').pop(),
            badgeClass: 'badge-script',
            key: filepath,
            index: idx,
            val: textItem.currentText,
            label: \`L\${textItem.lineIndex + 1}: \${filepath}\`
          });
        });
      }

      // フィルタリング
      const filtered = items.filter(item => {
        if (activeTab !== 'all' && item.category !== activeTab) return false;
        
        if (searchQuery) {
          const lowerQuery = searchQuery.toLowerCase();
          const matchesKey = item.key.toLowerCase().includes(lowerQuery);
          const matchesVal = item.val.toLowerCase().includes(lowerQuery);
          const matchesLabel = item.label.toLowerCase().includes(lowerQuery);
          return matchesKey || matchesVal || matchesLabel;
        }

        return true;
      });

      if (filtered.length === 0) {
        grid.innerHTML = '<div style="grid-column: 1/-1; text-align: center; padding: 3rem; color: var(--text-muted);">一致する項目が見つかりません</div>';
        return;
      }

      filtered.forEach(item => {
        const isModified = checkIfModified(item);
        const cardId = \`card-\${item.category}-\${item.key.replace(/:/g, '-')}-\${item.index}\`;
        
        const card = document.createElement('div');
        card.className = \`card \${isModified ? 'modified' : ''}\`;
        card.id = cardId;

        const isLongText = item.val.length > 25 || item.key.includes('description') || item.category === 'script';

        const inputHTML = isLongText 
          ? \`<textarea class="text-input" oninput="handleInputChange(event, '\${item.category}', '\${item.key}', \${item.index})">\${escapeHtml(item.val)}</textarea>\`
          : \`<input type="text" class="text-input" value="\${escapeHtml(item.val)}" oninput="handleInputChange(event, '\${item.category}', '\${item.key}', \${item.index})">\`;

        card.innerHTML = \`
          <div class="card-header">
            <span class="card-key">\${item.label}</span>
            <span class="card-badge \${item.badgeClass}">\${item.badgeText}</span>
          </div>
          <div class="card-body">
            \${inputHTML}
          </div>
          <div class="card-footer">
            <span class="char-count">文字数: <span class="count-num">\${item.val.length}</span></span>
            <span class="status-badge">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>
              変更あり
            </span>
          </div>
        \`;
        grid.appendChild(card);
      });
    }

    function checkIfModified(item) {
      if (!originalData) return false;
      if (item.category === 'ui') {
        return originalData.localization.textData[item.key] !== item.val;
      } else if (item.category === 'const') {
        return originalData.localization.constants[item.key] !== item.val;
      } else if (item.category === 'card') {
        const [itemId, field] = item.key.split(':');
        return originalData.cards[itemId][field] !== item.val;
      } else if (item.category === 'script') {
        return originalData.uiScripts[item.key][item.index].originalText !== item.val;
      }
      return false;
    }

    function handleInputChange(e, category, key, index) {
      const val = e.target.value;
      
      const cardEl = e.target.closest('.card');
      if (cardEl) {
        cardEl.querySelector('.count-num').textContent = val.length;
      }

      handleValueChange(category, key, index, val);
    }

    function escapeHtml(string) {
      return String(string).replace(/[&<>"']/g, function (s) {
        return {
          '&': '&amp;',
          '<': '&lt;',
          '>': '&gt;',
          '"': '&quot;',
          "'": '&#39;'
        }[s];
      });
    }

    async function saveAll() {
      const saveBtn = document.getElementById('save-btn');
      saveBtn.disabled = true;
      saveBtn.innerHTML = '保存中...';

      try {
        const res = await fetch('/api/texts', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(currentData)
        });

        if (!res.ok) throw new Error('保存時にエラーが発生しました。');

        originalData = JSON.parse(JSON.stringify(currentData));
        showToast('テキストの変更を保存しました！ゲームに即時反映されます。');
      } catch (err) {
        showToast(err.message, true);
      } finally {
        saveBtn.innerHTML = \`
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path><polyline points="17 21 17 13 7 13 7 21"></polyline><polyline points="7 3 7 8 15 8"></polyline></svg>
          変更を保存
        \`;
        checkUnsavedChanges();
        renderGrid();
      }
    }

    document.querySelectorAll('.tab').forEach(tab => {
      tab.addEventListener('click', (e) => {
        document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
        e.target.classList.add('active');
        activeTab = e.target.dataset.tab;
        renderGrid();
      });
    });

    document.getElementById('search-input').addEventListener('input', (e) => {
      searchQuery = e.target.value;
      renderGrid();
    });

    document.getElementById('save-btn').addEventListener('click', saveAll);

    window.addEventListener('beforeunload', (e) => {
      const isChanged = JSON.stringify(originalData) !== JSON.stringify(currentData);
      if (isChanged) {
        e.preventDefault();
        e.returnValue = '未保存の変更がありますが、移動してもよろしいですか？';
      }
    });

    loadData();
  </script>
</body>
</html>`;
}
