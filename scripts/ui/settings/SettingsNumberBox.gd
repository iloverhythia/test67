#SettingsNumberBox
extends SpinBox

export(String) var target

func upd(v:float):
	Rhythia.set(target, v)

func _ready():
	value = Rhythia.get(target)
	connect("value_changed", self, "upd")
