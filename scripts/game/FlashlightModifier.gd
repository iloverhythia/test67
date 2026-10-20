#FlashlightModifier
extends Spatial

export var lspd = 0.025 # lerp speed
var target:Vector3 # general target
var tps:float # target pixel scale
onready var Game:SongPlayerManager = $".." # game instance (to detect combo)

func _process(delta):
	target = Vector3(
		$"../Spawn/Cursor/Mesh".global_translation.x,
		$"../Spawn/Cursor/Mesh".global_translation.y,
		-0.1
	)
	if Rhythia.get("cam_unlock") == true:
		if Game.combo >= 100:
			tps = 0.05
		elif Game.combo >= 50:
			tps = 0.055
		else:
			tps = 0.06
	else:
		if Game.combo >= 100:
			tps = 0.025
		elif Game.combo >= 50:
			tps = 0.03
		else:
			tps = 0.04

	global_translation = lerp(global_translation,target,lspd*40)
	$Sprite.pixel_size = lerp($Sprite.pixel_size,tps,lspd/2)
	$Sprite.opacity = 1
