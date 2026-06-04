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
    
    await page.evaluate(() => {
      window.is_antigravity_test = true;
    });
    
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

    // Click "一般クラス" (Regular Class difficulty)
    console.log("Selecting Regular Class difficulty...");
    await page.mouse.click(576, 278);
    await new Promise(resolve => setTimeout(resolve, 3000));

    // Click "これで記帳する" (Register name)
    console.log("Confirming profile name...");
    await page.mouse.click(576, 405);
    await new Promise(resolve => setTimeout(resolve, 4000)); // wait extra for fade-in transition
    await page.screenshot({ path: 'screenshot_day1.png' });
    console.log("Saved screenshot_day1.png (Chicken Race Started)");

    // Helper function to complete one study hour safely (0 draw and stop)
    const completeOneHour = async (hourNum) => {
      console.log(`  - Starting Hour ${hourNum} -`);
      // Click "休憩する" (Stop)
      console.log("    Clicking Stop (休憩する) button...");
      await page.mouse.click(858, 428);
      await new Promise(resolve => setTimeout(resolve, 3500)); // Wait for result evaluation
    };

    const playOneFullDay = async (dayNum) => {
      console.log(`================ PLAYING DAY ${dayNum} ================`);
      // 3 hours of chicken race
      await completeOneHour(1);
      await completeOneHour(2);
      await completeOneHour(3);
      
      // Wait for Report Phase (auto-submits due to window.is_antigravity_test)
      console.log("  Waiting for Report Phase auto-submit...");
      await new Promise(resolve => setTimeout(resolve, 5000)); // Wait for auto-submit & transition
      
      // Now we should be in DailyLikesPhase (Timeline)
      console.log("  In Daily Likes Phase (timeline)...");
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // Optional: on Day 1, take screenshots and do one doubt
      if (dayNum === 1) {
        await page.screenshot({ path: 'screenshot_day1_likes.png' });
        console.log("  Day 1 timeline screenshot saved.");
        
        console.log("  Clicking Inspect details (詳細確認) of first rival...");
        await page.mouse.click(355, 240, { delay: 150 });
        await new Promise(resolve => setTimeout(resolve, 2000));
        await page.screenshot({ path: 'screenshot_inspected.png' });
        
        console.log("  Clicking Doubt (ダウト！) button of first rival...");
        await page.mouse.click(412, 240, { delay: 150 });
        await new Promise(resolve => setTimeout(resolve, 2000));
        await page.screenshot({ path: 'screenshot_doubt_result.png' });
      }
      
      // Click "明日の勉強へ進む" (Next Day / Show Results) button
      console.log("  Clicking Next Day (明日の勉強へ進む) button...");
      await page.mouse.click(1050, 680);
      
      // Wait for day transition / results transition
      await new Promise(resolve => setTimeout(resolve, 5500));
    };

    // Play all 5 days
    for (let day = 1; day <= 5; day++) {
      await playOneFullDay(day);
      await page.screenshot({ path: `screenshot_day${day}_end.png` });
      console.log(`Saved screenshot_day${day}_end.png`);
    }

    // Now we should be in ResultScene.
    console.log("================ WAITING FOR RESULT SCENE ================");
    // Wait for the blackboard reveal animations to start
    await new Promise(resolve => setTimeout(resolve, 8000));
    
    // We can also click "結果へスキップ" to fast-track, 
    // The skip button is at bottom right, coordinates roughly (1020, 600)
    console.log("Clicking Skip to results (結果へスキップ)...");
    await page.mouse.click(1020, 600);
    await new Promise(resolve => setTimeout(resolve, 4000));
    
    await page.screenshot({ path: 'screenshot_final_results.png' });
    console.log("Saved screenshot_final_results.png");

  } catch (e) {
    console.error("Error during test play:", e);
  } finally {
    await browser.close();
    console.log("Browser closed.");
  }
})();
