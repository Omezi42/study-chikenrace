const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch({
    headless: "new",
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--enable-features=SharedArrayBuffer'
    ]
  });
  const page = await browser.newPage();
  await page.setCacheEnabled(false);
  await page.setViewport({ width: 1152, height: 648 });
  
  page.on('console', msg => {
    console.log(`[BROWSER CONSOLE] ${msg.type().toUpperCase()}: ${msg.text()}`);
  });
  
  page.on('pageerror', err => {
    console.error(`[BROWSER ERROR] ${err.toString()}`);
  });

  try {
    console.log("Navigating to http://127.0.0.1:8000 for cache clearing...");
    await page.goto('http://127.0.0.1:8000', { waitUntil: 'domcontentloaded', timeout: 30000 });
    
    await page.evaluate(async () => {
      localStorage.clear();
      sessionStorage.clear();
      if (window.indexedDB && window.indexedDB.databases) {
        const dbs = await window.indexedDB.databases();
        for (const db of dbs) {
          window.indexedDB.deleteDatabase(db.name);
        }
      }
    });
    
    console.log("Reloading clean page...");
    await page.goto('http://127.0.0.1:8000', { waitUntil: 'load', timeout: 90000 });
    
    console.log("Waiting 6 seconds (initial title screen)...");
    await new Promise(resolve => setTimeout(resolve, 6000));
    await page.screenshot({ path: 'screenshot_title.png' });
    console.log("Saved screenshot_title.png");

    // Click "ゲーム開始" (Game Start)
    console.log("Clicking Game Start button...");
    await page.mouse.click(576, 380); 
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Click "模試" (National Exam mode)
    console.log("Selecting National Exam mode...");
    await page.mouse.click(576, 246);
    await new Promise(resolve => setTimeout(resolve, 3000));

    // Click "これで記帳する" (Register name)
    console.log("Confirming profile name...");
    await page.mouse.click(576, 405);
    await new Promise(resolve => setTimeout(resolve, 4000)); // wait extra for fade-in transition
    await page.screenshot({ path: 'screenshot_day1.png' });
    console.log("Saved screenshot_day1.png (Chicken Race Started)");

    // Click "勉強カードを引く" (Draw Card)
    console.log("Clicking Draw Card button (First draw)...");
    await page.mouse.click(682, 428);
    await new Promise(resolve => setTimeout(resolve, 4000));
    await page.screenshot({ path: 'screenshot_draw1.png' });
    console.log("Saved screenshot_draw1.png");

    // Click "勉強カードを引く" (Draw Card) again
    console.log("Clicking Draw Card button (Second draw)...");
    await page.mouse.click(682, 428);
    await new Promise(resolve => setTimeout(resolve, 4000));
    await page.screenshot({ path: 'screenshot_draw2.png' });
    console.log("Saved screenshot_draw2.png");

    // Click "休憩する" (Stop)
    console.log("Clicking Stop (休憩する) button...");
    await page.mouse.click(858, 428);
    await new Promise(resolve => setTimeout(resolve, 4000));
    await page.screenshot({ path: 'screenshot_stopped.png' });
    console.log("Saved screenshot_stopped.png");

  } catch (e) {
    console.error("Error during test play:", e);
  } finally {
    await browser.close();
    console.log("Browser closed.");
  }
})();
