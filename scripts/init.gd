#init.gd
extends Node

var thread:Thread = Thread.new()
var target:String = Rhythia.menu_target
var leaving:bool = false

func stage(text:String,done:bool=false):
	$Label2.text = text
	if done:
#		black_fade_target = true
		$Label2.text = "Loading menu"
		var res = RQueue.queue_resource(target)
		if res != OK:
			Rhythia.errorstr = "queue_resource returned %s" % res
			get_tree().change_scene("res://scenes/errors/menuload.tscn")
#		leaving = true

var black_fade_target:bool = false
var black_fade:float = 0

func _ready():
	get_tree().paused = false
	$BlackFade.visible = true
	black_fade = 1
	$BlackFade.color = Color(0,0,0,black_fade)
	Rhythia.connect("init_stage_reached",self,"stage")
	yield(get_tree().create_timer(0.5),"timeout")
	if Rhythia.auto_maximize: OS.window_maximized = true
	yield(get_tree().create_timer(0.5),"timeout")

	if not Rhythia.is_init:
		stage("",true)
		return
	elif Rhythia.first_init_done:
		if OS.can_use_threads(): thread.start(Rhythia,"do_init")
		else: Rhythia.do_init()

	Rhythia.is_init = false

func _exit_tree():
	if thread.is_active():
		thread.wait_to_finish()

var result

func _process(delta):
#	$AudioStreamPlayer.volume_db = -3 - (40*black_fade)
	$Music.volume_db = -8 - (40*black_fade)
	if black_fade_target && black_fade != 1:
		black_fade = min(black_fade + (delta/0.3),1)
		$BlackFade.color = Color(0,0,0,black_fade)
	elif !black_fade_target && black_fade != 0:
		black_fade = max(black_fade - (delta/0.3),0)
		$BlackFade.color = Color(0,0,0,black_fade)

	if !leaving:
		if RQueue.is_ready(target):
			result = RQueue.get_resource(target)
			leaving = true
			black_fade_target = true
			if !(result is Object):
				Rhythia.errorstr = "get_resource returned non-object (probably null)"
				get_tree().change_scene("res://scenes/errors/menuload.tscn")

	if leaving and result and black_fade == 1:
		get_tree().change_scene_to(result)
