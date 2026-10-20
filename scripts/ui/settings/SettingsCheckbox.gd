#SettingsCheckbox
extends CheckBox

export(String) var target

func upd():
	pressed = Rhythia.get(target)

func _pressed():
	if pressed != Rhythia.get(target):
		Rhythia.set(target, pressed)

func _ready():
	upd()
