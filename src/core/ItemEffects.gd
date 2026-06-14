# ItemEffects.gd
class_name ItemEffects
extends RefCounted

# 基底クラス
class ItemEffect extends RefCounted:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		pass

	func show_item_toast(phase: Control, item_id: String, text: String) -> void:
		var color = Color()
		var item_info = CardData.ITEMS.get(item_id, null)
		if item_info:
			color = CardData.get_role_color(item_info["role"])
		DeskTheme.show_toast(phase, text, 1.8, color)

# 1. 付箋
class StickyNoteEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		deck.next_draw_bonus_points += 1
		show_item_toast(phase, "item_sticky_note", "付箋の効果！次に引く1枚の得点＋3点！")

# 2. 消しゴム
class EraserEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		deck.eraser_charges = 1
		show_item_toast(phase, "item_eraser", "消しゴムの効果！次に被ったカードを山札に戻して引き直す！")

# 3. 定規
class RulerEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		var peeked = deck.peek_cards(1)
		if peeked.size() > 0:
			phase.show_peek_sticky(peeked)
			show_item_toast(phase, "item_ruler", "定規の効果！山札の次の一枚をのぞき見した！")

# 4. 単語帳
class WordbookEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		var peeked = deck.peek_cards(3)
		if peeked.size() > 0:
			phase.show_peek_sticky(peeked)
			show_item_toast(phase, "item_wordbook", "単語帳の効果！山札の次の三枚をのぞき見した！")

# 5. シャーペン
class MechPencilEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		deck.next_draw_bonus_points += 2
		show_item_toast(phase, "item_mech_pencil", "シャーペンの効果！次に引く2枚の得点＋3点！")

# 6. 暗記カード
class MemoCardsEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		phase.start_card_selection("memo_cards", "【暗記カード】入れ替える手札のカードを選んでください。")

# 7. 蛍光ペン
class HighlighterEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		deck.highlighter_active = true
		show_item_toast(phase, "item_highlighter", "蛍光ペンの効果！この時限で引いたすべてのカードに得点＋1点！")

# 8. 青ペン
class BluePenEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		deck.blue_pen_active = true
		show_item_toast(phase, "item_blue_pen", "青ペンの効果！この時限で引いたすべてのカードに得点＋2点！")

# 9. 座布団
class CushionEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		show_item_toast(phase, "item_cushion", "座布団の効果！ダウト失敗時のペナルティ失点が半減！")

# 10. メモアプリ
class MemoAppEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		phase.is_selecting_card = true
		var card1 = deck.draw_card()
		var card2 = deck.draw_card()
		var msg = "メモアプリの効果！カードを2枚引いた！"
		show_item_toast(phase, "item_memo_app", msg)
		
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
		show_item_toast(phase, "item_cheat_sheet", "ズルいカンペの効果！本日のブラフ上限が＋16点！")

# 12. コンパス
class CompassEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		deck.compass_active = true
		var indices = deck.activate_compass_indices()
		if indices.size() > 0:
			var idx_strs = []
			for idx in indices:
				idx_strs.append(str(idx) + "枚目")
			var show_limit = min(3, idx_strs.size())
			var msg = "コンパスの効果！山札の上から " + ", ".join(idx_strs.slice(0, show_limit)) + " にコンパスカードを探知！"
			if indices.size() > 3:
				msg += " (他 %d 枚)" % (indices.size() - 3)
			show_item_toast(phase, "item_compass", msg)
		else:
			show_item_toast(phase, "item_compass", "コンパスの効果！山札にコンパスカードはありません！")

# 13. エナジードリンク
class EnergyDrinkEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		deck.energy_drink_active = true
		var burst_chance = deck.get_energy_drink_burst_chance()
		if burst_chance > 0 and randf() < burst_chance:
			show_item_toast(phase, "item_energy_drink", "エナジードリンクの副作用！睡魔に耐えきれず寝落ちした！")
			phase.trigger_burst_sequence()
		else:
			show_item_toast(phase, "item_energy_drink", "エナジードリンクの効果！この時限の獲得点数2倍！")

# 14. 赤シート
class RedSheetEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		deck.red_sheet_active = true
		show_item_toast(phase, "item_red_sheet", "赤シートの効果！次に被ったカードをバーストせずにそのまま引く！")

# 15. 分厚い参考書
class ThickBookEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		deck.activate_thick_book()
		show_item_toast(phase, "item_thick_book", "分厚い参考書の効果！高得点(+15点)を山札に3枚追加！")

# 16. お守り
class AmuletEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		deck.amulet_active = true
		show_item_toast(phase, "item_amulet", "お守りの効果！寝落ち（バースト）しても点数の50%をキープ！")

# 17. 追込みノート
class NightNoteEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		deck.activate_night_note()
		phase.session.max_hours_today = 4
		show_item_toast(phase, "item_night_note", "追込みノートの効果！本日の時限が4時限に増加した！")

# 18. 解答写し
class CopyAnswerEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		show_item_toast(phase, "item_copy_answer", "解答写しの効果！ブラフ上限＋25点（嘘バレペナルティ2倍）！")

# 19. タイマー
class TimerEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		deck.timer_active = true
		phase.update_ui()
		show_item_toast(phase, "item_timer", "タイマーの効果！正確な眠気確率（%）が常時表示された！")

# 20. 勉強会チャット
class StudyChatEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		show_item_toast(phase, "item_study_chat", "勉強会チャットの効果！ダウト成功点＋6点！")

# 21. 予想問題集
class ExpectedQuestionsEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		deck.next_draw_bonus_points += 3
		show_item_toast(phase, "item_expected_questions", "予想問題集の効果！次に引く3枚 of 得点＋3点！")

# 22. カフェラテ
class CafeLatteEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		phase.draw_btn.disabled = true
		phase.stop_btn.disabled = true
		var latte_card = deck.activate_cafe_latte()
		if not latte_card.is_empty():
			show_item_toast(phase, "item_cafe_latte", "カフェラテの効果！安全に【%s (%d点)】を引いた！" % [latte_card["name"], latte_card["value"]])
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
		show_item_toast(phase, "item_earplugs", "耳栓の効果！ダウト失敗時のペナルティを10点軽減！")

# 24. 塾プリント
class CramSchoolPrintEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		deck.cram_school_print_active = true
		show_item_toast(phase, "item_cram_school_print", "塾プリントの効果！この時限の最終得点＋10点！")

# 25. 忘却のノート
class ForgetNotebookEffect extends ItemEffect:
	func execute(phase: Control, deck: StudyDeck, card: Dictionary) -> void:
		var val = deck.activate_forget_notebook()
		if val > 0:
			show_item_toast(phase, "item_forget_notebook", "忘却のノートの効果！不要なカード（%d点）を手札から捨てた！" % val)
			if phase.has_method("repopulate_hand_visuals"):
				phase.repopulate_hand_visuals()
		else:
			show_item_toast(phase, "item_forget_notebook", "忘却のノートの効果！手札からカードを捨てた！")

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
		# Play dynamic stationery SE on item activation (Loop 17)
		var se_path = AudioManager.SE_CLICK
		var place_items = [
			"item_ruler", "item_wordbook", "item_memo_cards", "item_memo_app",
			"item_compass", "item_thick_book", "item_amulet", "item_night_note",
			"item_study_chat", "item_cafe_latte", "item_forget_notebook"
		]
		if item_id in place_items:
			se_path = AudioManager.SE_PLACE
			
		if phase.has_node("/root/AudioManager"):
			phase.get_node("/root/AudioManager").play_se(se_path)
			
		var effect_class = EFFECT_MAP[item_id]
		var effect_instance = effect_class.new()
		effect_instance.execute(phase, deck, card)
