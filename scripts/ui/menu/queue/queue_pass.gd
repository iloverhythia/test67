#queue_pass
extends Node

const WAIT_TIME:float = 10.0
const PREVIEW_START:float = 0.3

var leaving:bool = false
var black_fade_target:bool = false
var black_fade:float = 0
var next_song
var t:float = 0

func leave():
	leaving = true
	black_fade_target = true

func _update_black_fade(delta:float):
	var prev:float = black_fade
	if black_fade_target && black_fade != 1:
		black_fade = min(black_fade + (delta/0.3), 1)
	elif !black_fade_target && black_fade != 0:
		black_fade = max(black_fade - (delta/0.3), 0)
	if black_fade != prev:
		$BlackFade.color = Color(0,0,0,black_fade)
		$Music.volume_db = -12 - (40*black_fade)

func _ready():
	get_tree().paused = false

	$BlackFade.visible = true
	black_fade = 1
	$BlackFade.color = Color(0,0,0,black_fade)
	$Music.volume_db = -12 - (40*black_fade)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	next_song = Rhythia.get_next()
	$C/V/H/Queue/EndInfo.upd()

	if next_song:
		$C/V/Next/H/V/Next.text = "Next: %s" % [next_song.name]
		$Music.stream = next_song.stream()
		if $Music.stream:
			$Music.play($Music.stream.get_length() * PREVIEW_START)
	else:
		var msg:String = "End of queue - returning to menu"
		if Rhythia.song_end_type == Globals.END_FAIL:
			msg = "Failed - returning to menu"
		elif Rhythia.song_end_type == Globals.END_GIVEUP:
			msg = "Gave up - returning to menu"
		$C/V/Next/H/V/Next.text = msg

func _process(delta):
	_update_black_fade(delta)

	t += delta
	$C/V/Next/H/ProgressBar.value = t
	$C/V/Next/H/V/Time.text = String(max(ceil(WAIT_TIME - t), 0))

	if t >= WAIT_TIME:
		leaving = true
		black_fade_target = true

	if leaving and black_fade == 1:
		if Rhythia.queue_active:
			Rhythia.select_song(next_song)
			get_tree().change_scene("res://scenes/loaders/songload.tscn")
		else:
			get_tree().change_scene("res://scenes/loaders/menuload.tscn")
