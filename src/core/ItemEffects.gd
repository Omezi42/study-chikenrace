# ItemEffects.gd
class_name ItemEffects
extends RefCounted

# 基底クラス
class ItemEffect extends RefCounted:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		pass

# 1. 付箋
class StickyNoteEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		var sub = deck.activate_sticky_note()
		var sub_jp = "なし"
		match sub:
			CardData.SUBJECT_MATH: sub_jp = "数学"
			CardData.SUBJECT_ENGLISH: sub_jp = "英語"
			CardData.SUBJECT_JAPANESE: sub_jp = "国語"
			CardData.SUBJECT_SCIENCE: sub_jp = "理科"
			CardData.SUBJECT_SOCIAL: sub_jp = "社会"
		DeskTheme.show_toast(phase, "付箋の効果！次のドローは【%s】が出やすくなった！" % sub_jp)

# 2. 消しゴム
class EraserEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		deck.eraser_charges += 1
		DeskTheme.show_toast(phase, "消しゴムの効果！眠気回避（被り無効化）をチャージ！")

# 3. 定規
class RulerEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		var peeked = deck.peek_cards(1)
		if peeked.size() > 0:
			phase.show_peek_sticky(peeked)
			DeskTheme.show_toast(phase, "定規の効果！山札の次の一枚をのぞき見した！")

# 4. 単語帳
class WordbookEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		var peeked = deck.peek_cards(3)
		if peeked.size() > 0:
			phase.show_peek_sticky(peeked)
			DeskTheme.show_toast(phase, "単語帳の効果！山札の次の三枚をのぞき見した！")

# 5. シャーペン
class MechPencilEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		deck.next_draw_bonus_points = 2
		DeskTheme.show_toast(phase, "シャーペンの効果！次に引く2枚の得点＋3点！")

# 6. 暗記カード
class MemoCardsEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		phase.start_card_selection("memo_cards", "【暗記カード】入れ替える手札のカードを選んでください。")

# 7. 蛍光ペン
class HighlighterEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		deck.highlighter_active = true
		DeskTheme.show_toast(phase, "蛍光ペンの効果！この時限のコンボボーナスが1.5倍！")

# 8. 青ペン
class BluePenEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		deck.blue_pen_active = true
		DeskTheme.show_toast(phase, "青ペンの効果！場に出ている国語・英語の得点が1.5倍！")

# 9. 座布団
class CushionEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		DeskTheme.show_toast(phase, "座布団の効果！ダウト失敗時のペナルティ失点が半減！")

# 10. メモアプリ
class MemoAppEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		var card1 = deck.draw_card()
		var card2 = deck.draw_card()
		var msg = "メモアプリの効果！カードを2枚引いた！"
		DeskTheme.show_toast(phase, msg)
		
		phase.draw_btn.disabled = true
		phase.stop_btn.disabled = true
		
		if not card1.is_empty():
			phase.perform_animated_draw(card1, func():
				if not card2.is_empty():
					phase.perform_animated_draw(card2, func():
						phase.start_card_selection("memo_app", "【メモアプリ】捨てるカードを1枚選んでください。")
					)
				else:
					phase.start_card_selection("memo_app", "【メモアプリ】捨てるカードを1枚選んでください。")
			)
		else:
			phase.start_card_selection("memo_app", "【メモアプリ】捨てるカードを1枚選んでください。")

# 11. ズルいカンペ
class CheatSheetEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		DeskTheme.show_toast(phase, "ズルいカンペの効果！本日のブラフ上限が＋16点！")

# 12. コンパス
class CompassEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		var count = deck.activate_compass()
		DeskTheme.show_toast(phase, "コンパスの効果！被り候補カードが山札に %d 枚残っています！" % count)

# 13. エナジードリンク
class EnergyDrinkEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		deck.energy_drink_active = true
		var draw_count = deck.hand.size()
		var burst_chance = max(0.0, float(draw_count - 3) * 0.10)
		if burst_chance > 0 and randf() < burst_chance:
			DeskTheme.show_toast(phase, "エナジードリンクの副作用！睡魔に耐えきれず寝落ちした！")
			phase.trigger_burst_sequence()
		else:
			DeskTheme.show_toast(phase, "エナジードリンクの効果！この時限の獲得点数2倍！")

# 14. 赤シート
class RedSheetEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		deck.red_sheet_active = true
		DeskTheme.show_toast(phase, "赤シートの効果！バースト札を一度だけ自動で捨てる！")

# 15. 分厚い参考書
class ThickBookEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		deck.activate_thick_book()
		DeskTheme.show_toast(phase, "分厚い参考書の効果！高得点(+15点)を山札に3枚追加！")

# 16. お守り
class AmuletEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		DeskTheme.show_toast(phase, "お守りの効果！寝落ち（バースト）しても点数の50%をキープ！")

# 17. 追込みノート
class NightNoteEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		deck.activate_night_note()
		phase.session.max_hours_today = 4
		DeskTheme.show_toast(phase, "追込みノートの効果！本日の時限が4時限に増加した！")

# 18. 解答写し
class CopyAnswerEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		DeskTheme.show_toast(phase, "解答写しの効果！ブラフ上限＋25点（嘘バレペナルティ2倍）！")

# 19. タイマー
class TimerEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		DeskTheme.show_toast(phase, "タイマーの効果！正確なバースト確率が常時表示された！")

# 20. 勉強会チャット
class StudyChatEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		DeskTheme.show_toast(phase, "勉強会チャットの効果！ダウト成功点＋6点！")

# 21. 予想問題集
class ExpectedQuestionsEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		var sub = deck.activate_expected_questions()
		var sub_jp = "なし"
		match sub:
			CardData.SUBJECT_MATH: sub_jp = "数学"
			CardData.SUBJECT_ENGLISH: sub_jp = "英語"
			CardData.SUBJECT_JAPANESE: sub_jp = "国語"
			CardData.SUBJECT_SCIENCE: sub_jp = "理科"
			CardData.SUBJECT_SOCIAL: sub_jp = "社会"
		DeskTheme.show_toast(phase, "予想問題集の効果！次の3枚が【%s】で固定された！" % sub_jp)

# 22. カフェラテ
class CafeLatteEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		phase.draw_btn.disabled = true
		phase.stop_btn.disabled = true
		var latte_card = deck.activate_cafe_latte()
		if not latte_card.is_empty():
			DeskTheme.show_toast(phase, "カフェラテの効果！安全に【%s (%d点)】を引いた！" % [latte_card["name"], latte_card["value"]])
			phase.perform_animated_draw(latte_card, func():
				phase.update_ui()
				phase.draw_btn.disabled = false
				phase.stop_btn.disabled = false
			)
		else:
			phase.draw_btn.disabled = false
			phase.stop_btn.disabled = false

# 23. 耳栓
class EarplugsEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		DeskTheme.show_toast(phase, "耳栓の効果！ダウト失敗時のペナルティを10点軽減！")

# 24. 塾プリント
class CramSchoolPrintEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		DeskTheme.show_toast(phase, "塾プリントの効果！5教科コンボのワイルドカードとして機能！")

# 25. 忘却のノート
class ForgetNotebookEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		var val = deck.activate_forget_notebook()
		if val > 0:
			DeskTheme.show_toast(phase, "忘却のノートの効果！不要なカード（%d点）をデッキから削除！" % val)
		else:
			DeskTheme.show_toast(phase, "忘却のノートの効果！不要なカードを削除した！")

# 各アイテムエフェクトマッピング
const EFFECT_MAP = {
	"item_sticky_note": StickyNoteEffect,
	"item_eraser": EraserEffect,
	"item_ruler": RulerEffect,
	"item_wordbook": WordbookEffect,
	"item_mech_pencil": MechPencilEffect,
	"item_memo_cards": MemoCardsEffect,
	"item_highlighter": HighlighterEffect,
	"item_blue_pen": BluePenEffect,
	"item_cushion": CushionEffect,
	"item_memo_app": MemoAppEffect,
	"item_cheat_sheet": CheatSheetEffect,
	"item_compass": CompassEffect,
	"item_energy_drink": EnergyDrinkEffect,
	"item_red_sheet": RedSheetEffect,
	"item_thick_book": ThickBookEffect,
	"item_amulet": AmuletEffect,
	"item_night_note": NightNoteEffect,
	"item_copy_answer": CopyAnswerEffect,
	"item_timer": TimerEffect,
	"item_study_chat": StudyChatEffect,
	"item_expected_questions": ExpectedQuestionsEffect,
	"item_cafe_latte": CafeLatteEffect,
	"item_earplugs": EarplugsEffect,
	"item_cram_school_print": CramSchoolPrintEffect,
	"item_forget_notebook": ForgetNotebookEffect
}

# アイテム効果の発動エントリーポイント
static func execute_effect(item_id: String, phase: Control, deck: StudyDeck, card: Dictionary) -> void:
	if EFFECT_MAP.has(item_id):
		var effect_class = EFFECT_MAP[item_id]
		var effect_instance = effect_class.new()
		effect_instance.execute(phase, deck, card)
