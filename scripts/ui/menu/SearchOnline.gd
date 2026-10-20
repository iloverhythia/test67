#SearchOnline
extends CheckBox

export(String) var target

onready var map_list = get_parent().get_parent().get_node("MapRegistry/S/VBoxContainer")

func upd():
	pressed = Rhythia.get(target)
	map_list.show_online_maps = pressed

func _pressed():
	if pressed != Rhythia.get(target):
		Rhythia.set(target,pressed)
	map_list.update_search_showonline(Rhythia.last_search_incl_online)
	map_list.show_online_maps = pressed

func _ready():
	upd()
	map_list.update_search_showonline(Rhythia.last_search_incl_online)
