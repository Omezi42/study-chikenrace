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

    // Helper function to complete one study hour safely (0 draw and stop)
    const completeOneHour = async (hourNum) => {
      console.log(`--- Starting Hour ${hourNum} ---`);
      // Click "休憩する" (Stop)
      console.log("Clicking Stop (休憩する) button...");
      await page.mouse.click(858, 428);
      await new Promise(resolve => setTimeout(resolve, 5000)); // Wait for result evaluation
    };

    // Day 1 has 3 hours
    await completeOneHour(1);
    await page.screenshot({ path: 'screenshot_hour1_end.png' });
    await completeOneHour(2);
    await page.screenshot({ path: 'screenshot_hour2_end.png' });
    await completeOneHour(3);
    
    // Now we should be in ReportPhase (Score declaration screen)
    console.log("Waiting for Report Phase (score declaration)...");
    await new Promise(resolve => setTimeout(resolve, 6000));
    await page.screenshot({ path: 'screenshot_report_phase.png' });
    
    // Click "タイムラインに投稿" (Submit to timeline) button (try multiple coordinates around it with delay)
    console.log("Clicking Submit to timeline (タイムラインに投稿) button...");
    await page.mouse.click(576, 495, { delay: 200 });
    await new Promise(resolve => setTimeout(resolve, 800));
    await page.mouse.click(576, 515, { delay: 200 });
    await new Promise(resolve => setTimeout(resolve, 800));
    await page.mouse.click(576, 535, { delay: 200 });
    await new Promise(resolve => setTimeout(resolve, 6000)); // wait for transition through transition phase

    // Now we should be in DailyLikesPhase (Timeline)
    await page.screenshot({ path: 'screenshot_day1_likes.png' });
    console.log("Saved screenshot_day1_likes.png (Daily Likes Phase)");

    // Click "詳細確認" (Inspect details of first rival)
    console.log("Clicking Inspect details (詳細確認) of first rival...");
    await page.mouse.click(355, 240, { delay: 150 });
    await new Promise(resolve => setTimeout(resolve, 2000));
    await page.screenshot({ path: 'screenshot_inspected.png' });
    console.log("Saved screenshot_inspected.png");

    // Click "ダウト！" (Doubt first rival)
    console.log("Clicking Doubt (ダウト！) button of first rival...");
    await page.mouse.click(412, 240, { delay: 150 });
    await new Promise(resolve => setTimeout(resolve, 3000));
    await page.screenshot({ path: 'screenshot_doubt_result.png' });
    console.log("Saved screenshot_doubt_result.png");

    // Click "明日の勉強へ進む" (Next Day)
    console.log("Clicking Next Day (明日の勉強へ進む) button...");
    await page.mouse.click(1050, 680);
    await new Promise(resolve => setTimeout(resolve, 5000));
    await page.screenshot({ path: 'screenshot_day2_start.png' });
    console.log("Saved screenshot_day2_start.png (Day 2 Started)");

  } catch (e) {
    console.error("Error during test play:", e);
  } finally {
    await browser.close();
    console.log("Browser closed.");
  }
})();
