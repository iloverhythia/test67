#menu2
extends Node

func _ready():
	get_tree().paused = false

	# fix audio pitchshifts
	if AudioServer.get_bus_effect_count(AudioServer.get_bus_index("Music")) > 0:
		AudioServer.remove_bus_effect(AudioServer.get_bus_index("Music"),0)

	$BlackFade.visible = true
	$BlackFade.color = Color(0,0,0,black_fade)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# max pp panel under the modifiers
	var h2 = get_node_or_null("Main/Maps/Results/Results/RS/H2")
	if h2:
		var panel:PanelContainer = PanelContainer.new()
		panel.set_script(load("res://scripts/ui/menu/MaxPPPanel.gd"))
		var rs = h2.get_parent()
		rs.add_child(panel)
		rs.move_child(panel, h2.get_index() + 1)

var black_fade_target:bool = false
var black_fade:float = 1

func _process(delta):
	if Input.is_action_just_pressed("ui_end") and Input.is_key_pressed(KEY_SHIFT):
		get_tree().change_scene("res://scenes/loaders/menuload.tscn")

	if black_fade_target && black_fade != 1:
		black_fade = min(black_fade + (delta/0.3),1)
		$BlackFade.color = Color(0,0,0,black_fade)
	elif !black_fade_target && black_fade != 0:
		black_fade = max(black_fade - (delta/0.5),0)
		$BlackFade.color = Color(0,0,0,black_fade)
	$BlackFade.visible = (black_fade != 0)
