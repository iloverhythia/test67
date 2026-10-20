#ModToggle
extends CheckBox

const PROPERTY_MAP = {
	"NoFail":      "mod_nofail",
	"SuddenDeath": "mod_sudden_death",
	"EasyMode":    "mod_extra_energy",
	"HardMode":    "mod_no_regen",
	"MirrorX":     "mod_mirror_x",
	"MirrorY":     "mod_mirror_y",
	"Earthquake":  "mod_earthquake",
	"Chaos":       "mod_chaos",
	"Flashlight":  "mod_flashlight",
	"Ghost":       "mod_ghost",
	"HardRock":    "mod_hardrock",
	"VisualMode":  "visual_mode",
	"InvertMouse": "invert_mouse",
}

var mod_property:String = ""

func _process(_d):
	if mod_property == "": return
	if pressed != Rhythia.get(mod_property):
		Rhythia.set(mod_property, pressed)

func upd():
	if mod_property == "": return
	pressed = Rhythia.get(mod_property)

func _ready():
	mod_property = PROPERTY_MAP.get(name, "")
	upd()
	Rhythia.connect("mods_changed",self,"upd")
