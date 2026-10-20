#ResultsHolder
extends HBoxContainer

var centered:bool = false

func set_centered(val:bool):
	centered = val
	Rhythia.was_map_screen_centered = val
	$VSeparator.visible = val
	$VSeparator2.visible = val
	$"../MapRegistry".visible = false
	$"../ScrollControl".visible = false
	$"../Filters".visible = false

func center():   set_centered(true)
func uncenter(): set_centered(false)

func _ready():
	centered = Rhythia.was_map_screen_centered
	if Rhythia.single_map_mode:
		center()
