#WarningBar
extends ColorRect

onready var version_a = get_parent().get_node("VersionNumber")
onready var version_b = get_parent().get_node("VersionNumberB")

var entry:float = 0
var state:bool = false
var scroll:float = 0

var check:float = 0
var switch:float = -1
var last_color:Color = Color("#ffffff")

var current_warning:String = "none"
var bar_enable:bool = true # Used for controller check bar

func display_warning(id:String):
	match id:
		"none":
			state = false
		"test":
			state = true
			$L.text = "You are holding Alt+Shift+W."
			color = Color("#5cb76e")
		"smm":
			state = true
			$L.text = "Running in single map mode. Online features, PBs, and most map actions are disabled."
			color = Color("#ffbb19")
		"spawn":
			state = true
			$L.text = "Note spawn effects may be buggy."
			color = Color("#fc794e")
		"debug":
			state = true
			$L.text = "Development mode is active, game mods will not be used."
			color = Color("#477d94")
		"controllercheck":
			state = true
			$L.text = "Controller checking disabled. Press C to hide this bar."
			color = Color("#8400ff")
		"experimental":
			state = true
			$L.text = "You are currently using experimental settings. Expect bugs."
			color = Color("#c1c1ac")
		"experimental_mod":
			state = true
			$L.text = "One or more mods you selected are currently experimental. Expect bugs."
			color = Color("#77c1d1")
		_:
			assert(false)
	$L2.text = $L.text

var experimental_settings = [
	"show_stats",
	"retain_song_pitch",
]

func check_experimental_settings():
	for k in experimental_settings:
		if Rhythia.get(k): return true
	return false

func check_warnings():
	if Input.is_action_pressed("warning_test"):
		return "test"
	elif Rhythia.single_map_mode:
		return "smm"
	elif Rhythia.note_spawn_effect:
		return "spawn"
	elif OS.has_feature("debug"):
		return "debug"
	elif check_experimental_settings():
		return "experimental"
	elif Rhythia.ignore_controller_detection:
		if bar_enable:
			return "controllercheck"
		else:
			return "none"
	else:
		return "none"

func _process(delta):
	var width:float = rect_size.x

	if switch != -1:
		if entry == 0:
			switch = max(switch - delta, 0)
		if switch == 0:
			switch = -1
			scroll = clamp(scroll, 0.25, 0.75)
			display_warning(current_warning)
	else:
		check += delta
		if check >= 0.5:
			check -= 0.5
			var prev = current_warning
			current_warning = check_warnings()
			if current_warning != prev:
				switch = 0.35
				state = false

	scroll = scroll + (delta * (20.0/1200.0)) * (
		1.5 + (3.0 * float(Input.is_key_pressed(KEY_CONTROL))))
	if scroll >= 1.0: scroll -= 1.0

	$L.rect_position = Vector2(width * scroll, 0)
	$L2.rect_position = Vector2((width * scroll) - width, 0)

	var target_entry:float = 1.0 if state else 0.0
	if entry != target_entry:
		if state:
			entry = min(entry + (delta/0.8), 1.0)
		else:
			entry = max(entry - (delta/0.8), 0.0)
		modulate = Color(1.0, 1.0, 1.0, entry)
		var sine = Dance.InOutSine(entry)
		margin_top = sine * -30
		margin_bottom = (1.0 - sine) * 30
		version_a.margin_top = -45 - (sine * 30)
		version_a.margin_bottom = -15 - (sine * 30)
		version_b.margin_top = -45 - (sine * 30)
		version_b.margin_bottom = -15 - (sine * 30)

	visible = (entry != 0)

func _ready():
	current_warning = check_warnings()
	display_warning(current_warning)
	if state == true: entry = 0.99
