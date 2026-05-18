class_name CardData
extends RefCounted

var item_type: int 
var subject: int 
var weight: int

func _init(_item_type: int, _subject: int = 8, _weight: int = 0):
	item_type = _item_type
	subject = _subject
	weight = _weight

