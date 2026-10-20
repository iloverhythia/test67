#DifficultySort
extends CheckBox

onready var map_list = get_parent().get_parent().get_node("MapRegistry/S/VBoxContainer")

func _pressed():
	map_list.update_search_flipped(!map_list.flip_display)
	Rhythia.last_search_flip_sort = pressed

func _ready():
	pressed = Rhythia.last_search_flip_sort
	map_list.update_search_flipped(Rhythia.last_search_flip_sort)
