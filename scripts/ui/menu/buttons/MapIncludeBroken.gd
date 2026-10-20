#MapIncludeBroken
extends CheckBox

onready var map_list = get_parent().get_parent().get_node("MapRegistry/S/VBoxContainer")

func _pressed():
	map_list.update_search_showbroken(!map_list.show_broken_maps)
	Rhythia.last_search_incl_broken = pressed

func _ready():
	pressed = Rhythia.last_search_incl_broken
	map_list.update_search_showbroken(Rhythia.last_search_incl_broken)
