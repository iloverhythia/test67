extends ColorRect

func _ready():
	Engine.target_fps = 30 # Don't use the entire GPU for the error screen
	$Info.text = """-- user folder open error --
rhythia version: %s
platform: %s
error code: %s""" % [
		ProjectSettings.get_setting("application/config/version"),
		OS.get_name(),
		Globals.errornum,
	]
	if OS.has_feature("Android"):
		OS.request_permissions()
		$Info.get("custom_fonts/font").size = 28
		$Info.text += "\n\nNote: Rhythia currently needs storage permissions to create its user folder.\nYou can remove the permission afterwards.\n(this'll be fixed when godot 3.5 releases)"
