#NameSort
extends CheckBox

onready var map_list = get_parent().get_parent().get_node("MapRegistry/S/VBoxContainer")

func _pressed():
	map_list.update_search_flip_name(!map_list.flip_name)
	Rhythia.last_search_flip_name_sort = pressed

func _ready():
	pressed = Rhythia.last_search_flip_name_sort
	map_list.update_search_flip_name(Rhythia.last_search_flip_name_sort)
