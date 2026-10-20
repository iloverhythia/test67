extends ColorRect

func _ready():
	Engine.target_fps = 30 # Don't use the entire GPU for the error screen
	$Info.text = """-- song player load error --
rhythia version: %s
platform: %s
error info: %s""" % [
		ProjectSettings.get_setting("application/config/version"),
		OS.get_name(),
		Rhythia.errorstr,
	]
	if OS.has_feature("mobile"):
		$Info.get("custom_fonts/font").size = 28
