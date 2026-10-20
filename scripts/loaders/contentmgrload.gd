#contentmgrload
extends Node

var leaving:bool = false
var target:String = "res://scenes/menu/contentmgr.tscn"
var black_fade_target:bool = false
var black_fade:float = 0

func _ready():
	get_tree().paused = false
	$BlackFade.visible = true
	black_fade = 1
	$BlackFade.color = Color(0,0,0,black_fade)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	var res = RQueue.queue_resource(target)
	if res != OK:
		Rhythia.errorstr = "queue_resource returned %s" % res
		Rhythia.menu_target = "res://scenes/menu/contentmgr.tscn"
		get_tree().change_scene("res://scenes/errors/menuload.tscn")

var result

func _process(delta):
	$Music.volume_db = -8 - (40*black_fade)
	if black_fade_target && black_fade != 1:
		black_fade = min(black_fade + (delta/0.3),1)
		$BlackFade.color = Color(0,0,0,black_fade)
	elif !black_fade_target && black_fade != 0:
		black_fade = max(black_fade - (delta/0.5),0)
		$BlackFade.color = Color(0,0,0,black_fade)

	if !leaving:
		if RQueue.is_ready(target):
			result = RQueue.get_resource(target)
			leaving = true
			black_fade_target = true
			if !(result is Object):
				Rhythia.errorstr = "get_resource returned non-object (probably null)"
				Rhythia.menu_target = "res://scenes/menu/contentmgr.tscn"
				get_tree().change_scene("res://scenes/errors/menuload.tscn")

	if leaving and result and black_fade == 1:
		get_tree().change_scene_to(result)
