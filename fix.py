
with open('c:/Users/omezi/OneDrive/ドキュメント/study-chikenrace/scripts/ui/GameScene.gd', 'r', encoding='utf-8') as f:
    lines = f.readlines()
new_lines = lines[:345] + [
    '\t\t\t\n',
    '\t\t\tif audio_manager:\n',
    '\t\t\t\taudio_manager.play_se(\'place\')\n',
    '\t\t\t\n',
    '\t\t\tif is_bluffing:\n',
    '\t\t\t\t_show_toast(\'💢 いいね！で見破りのプレッシャーを送った！\', DeskTheme.COLOR_BLUFF_RED)\n',
    '\t\t\telse:\n',
    '\t\t\t\t_show_toast(\'👍 いいね！で正直な努力を応援！\\n(相手に正直ボーナス！)\', DeskTheme.COLOR_SAFE)\n',
    '\t\t)\n'
] + lines[369:]
with open('c:/Users/omezi/OneDrive/ドキュメント/study-chikenrace/scripts/ui/GameScene.gd', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
print('Done!')

