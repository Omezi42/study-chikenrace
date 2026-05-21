class_name CardData
extends RefCounted

var item_type: int 
var number: int # バースト判定用の数字（通常カードの場合は点数も兼ねる）
var id: int # デッキ内での識別用ID
var is_active: bool = true # 消しゴム等で無効化されたか

static var next_id: int = 0

func _init(_item_type: int, _number: int = 0):
	item_type = _item_type
	number = _number
	id = next_id
	CardData.next_id += 1
