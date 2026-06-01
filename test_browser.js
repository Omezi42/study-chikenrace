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
    console.log("Navigating to http://localhost:8000 for cache clearing...");
    await page.goto('http://localhost:8000', { waitUntil: 'domcontentloaded', timeout: 30000 });
    
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
    await page.goto('http://localhost:8000', { waitUntil: 'load', timeout: 90000 });
    
    // Wait 6 seconds for load & first day reveal
    console.log("Waiting 6 seconds (initial state)...");
    await new Promise(resolve => setTimeout(resolve, 6000));
    await page.screenshot({ path: 'screenshot_day1.png' });
    console.log("Saved screenshot_day1.png");

    // Wait another 5 seconds (sorting / bar graph race in progress)
    console.log("Waiting another 5 seconds (bar graph sorting)...");
    await new Promise(resolve => setTimeout(resolve, 5000));
    await page.screenshot({ path: 'screenshot_sorting.png' });
    console.log("Saved screenshot_sorting.png");

    // Wait another 5 seconds (chalk deviation animation should play now)
    console.log("Waiting another 5 seconds (chalk deviation animation)...");
    await new Promise(resolve => setTimeout(resolve, 5000));
    await page.screenshot({ path: 'screenshot_chalk.png' });
    console.log("Saved screenshot_chalk.png");

    // Wait another 4 seconds (notebook overlay should be complete)
    console.log("Waiting another 4 seconds (final notebook spread)...");
    await new Promise(resolve => setTimeout(resolve, 4000));
    await page.screenshot({ path: 'screenshot_final.png' });
    console.log("Saved screenshot_final.png");

  } catch (e) {
    console.error("Error during test play:", e);
  } finally {
    await browser.close();
    console.log("Browser closed.");
  }
})();
