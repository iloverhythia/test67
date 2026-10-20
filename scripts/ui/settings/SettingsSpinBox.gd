#SettingsSpinBox
extends SpinBox

export(String) var target = ""
export(float) var multiplier = 1.0
export(bool) var string_cast = false
export(bool) var use_engine = false
export(bool) var clamp_enabled = false
export(float) var clamp_min = 0.0
export(float) var clamp_max = 1.0

func _get_target():
	if use_engine: return Engine.get(target) * multiplier
	return Rhythia.get(target) * multiplier

func upd():
	var actual = value / multiplier
	if clamp_enabled: actual = clamp(actual, clamp_min, clamp_max)
	if string_cast: actual = float(str(actual))
	if use_engine: Engine.set(target, actual)
	else: Rhythia.set(target, actual)

func _process(_d):
	if target == "": return
	var trg = _get_target()
	if string_cast:
		if float(str(value)) != float(str(trg)): upd()
	else:
		if !is_equal_approx(value, trg): upd()

func _ready():
	if target == "": return
	value = _get_target()
	connect("changed",self,"upd")
