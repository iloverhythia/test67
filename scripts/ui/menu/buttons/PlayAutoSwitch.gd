#PlayAutoSwitch
extends CheckBox

onready var target_node = get_parent().get_parent().get_node("S/G")

func _pressed():
	target_node.auto_switch_to_play = pressed

func _ready():
	target_node.auto_switch_to_play = Rhythia.was_auto_play_switch
	pressed = Rhythia.was_auto_play_switch
