#SettingsColorPicker
extends ColorPickerButton

export(String) var target

func upd():
	yield(get_tree(),"idle_frame")
	Rhythia.set(target,color)
	
func _ready():
	color = Rhythia.get(target)
	connect("popup_closed",self,"upd")
