@echo off
if not exist dist mkdir dist
echo Importing project assets...
"C:\Users\omezi\Documents\Godot_v4.6.2-stable_win64.exe" --headless --editor --quit
echo Building Web version...
"C:\Users\omezi\Documents\Godot_v4.6.2-stable_win64.exe" --headless --export-release "Web" dist/index.html
if %errorlevel% neq 0 (
    echo Build failed. Please ensure Web export templates are installed.
    pause
    exit /b %errorlevel%
)
echo Build completed successfully.
echo Starting local web server on http://localhost:8000 ...
start http://localhost:8000
python -m http.server 8000 --directory dist
