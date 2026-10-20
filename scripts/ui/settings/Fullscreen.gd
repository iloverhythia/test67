#Fullscreen
extends CheckBox

func _pressed():
	if pressed != OS.window_fullscreen:
		OS.window_fullscreen = pressed

func _ready():
	visible = true
	# keep checkbox in sync if fullscreen is toggled elsewhere (F11, etc.)
	pressed = OS.window_fullscreen
