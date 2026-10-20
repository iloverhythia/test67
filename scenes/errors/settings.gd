extends ColorRect

func _ready():
	Engine.target_fps = 30 # Don't use the entire GPU for the error screen
	$Info.text = """-- settings load error --
rhythia version: %s
platform: %s
error code: %s""" % [
		ProjectSettings.get_setting("application/config/version"),
		OS.get_name(),
		Rhythia.errornum,
	]
