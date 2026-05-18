@echo off
if not exist dist mkdir dist
"C:\Users\omezi\OneDrive\ドキュメント\Godot\Godot_v4.6.2-stable_win64.exe" --headless --export-release "Web" dist/index.html
echo Build completed.
