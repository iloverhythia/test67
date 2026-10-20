#DownloadScreen
extends ColorRect

func start_download():
	$Cancel.grab_focus()
	visible = true

func end_download(_v:bool=false):
	$Cancel.release_focus()
	visible = false

func _process(_delta):
	var amt:float = Online.mapdl_hr.get_downloaded_bytes()
	var total:float = Online.mapdl_bs
	if total > 0:
		$Label.text = "Downloading map...\n%.02f%%" % [(amt/total) * 100]

func _ready():
	Rhythia.connect("download_start",self,"start_download")
	Rhythia.connect("download_done",self,"end_download")
	pause_mode = PAUSE_MODE_PROCESS
	$Cancel.connect("pressed",Online,"cancel")
