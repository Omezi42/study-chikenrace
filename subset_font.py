import os
import glob
import re

def extract_chars_from_godot_project(project_path):
    chars = set()
    # Also include standard ASCII characters (alphanumeric and symbols)
    for i in range(32, 127):
        chars.add(chr(i))
    # Basic hiragana, katakana
    for i in range(0x3041, 0x3097):
        chars.add(chr(i))
    for i in range(0x30A1, 0x30FB):
        chars.add(chr(i))
    # Some common punctuations
    common_puncts = "、。！？「」『』（）［］【】・…ー〜"
    for c in common_puncts:
        chars.add(c)
    
    # Read all .gd, .tscn, .tres files
    for ext in ('*.gd', '*.tscn', '*.tres'):
        for filepath in glob.glob(os.path.join(project_path, '**', ext), recursive=True):
            try:
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                    for char in content:
                        # Add any non-ascii character
                        if ord(char) > 127:
                            chars.add(char)
            except Exception as e:
                pass
    return ''.join(chars)

if __name__ == '__main__':
    text = extract_chars_from_godot_project('.')
    with open('chars.txt', 'w', encoding='utf-8') as f:
        f.write(text)
    print(f"Extracted {len(text)} unique characters.")
