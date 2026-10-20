#FileSelector
extends ColorRect
class_name FileSelector2D

var target_object:Object
var target_method:String

func _apply_scale(dialog):
	var s = clamp(Rhythia.render_scale * 0.9, 0.5, 0.9)
	dialog.rect_pivot_offset = get_viewport_rect().size / 2
	dialog.rect_scale = Vector2(s, s)

func _finish(value):
	if target_object == null:
		return
	var obj = target_object
	var meth = target_method
	target_object = null
	target_method = ""
	visible = false
	obj.call(meth, value)

func save_sel(file:String):
	_finish(file)

func files_single(file:String):
	_finish(PoolStringArray([file]))

func files_sel(files:PoolStringArray):
	_finish(files)

func folder_sel(folder:String):
	_finish(folder)

func _ready():
	visible = false
	$C/SaveFile.connect("file_selected",self,"save_sel")
	$C/OpenFile.connect("file_selected",self,"files_single")
	$C/OpenFile.connect("files_selected",self,"files_sel")
	$C/Folder.connect("dir_selected",self,"folder_sel")

	$C/OpenFile.connect("hide",self,"files_sel",[PoolStringArray()])
	$C/SaveFile.connect("hide",self,"save_sel",[""])
	$C/Folder.connect("hide",self,"folder_sel",[""])

func open_file(
	obj:Object,
	method:String,
	filters:PoolStringArray = PoolStringArray(["* ; All Files"]),
	multiselect:bool = false,
	initial_path:String = "user://"
):
	target_object = obj
	target_method = method

	_apply_scale($C/OpenFile)

	$C/OpenFile.filters = filters
	if multiselect:
		$C/OpenFile.mode = $C/OpenFile.MODE_OPEN_FILES
		$C/OpenFile.window_title = "Select files..."
	else:
		$C/OpenFile.mode = $C/OpenFile.MODE_OPEN_FILE
		$C/OpenFile.window_title = "Select file..."
	$C/OpenFile.show()
	$C/OpenFile.call_deferred("set_current_dir",Globals.p(initial_path))
	visible = true
	raise()

func save_file(
	obj:Object,
	method:String,
	filters:PoolStringArray = PoolStringArray(["* ; All Files"]),
	initial_path:String = "user://"
):
	target_object = obj
	target_method = method

	_apply_scale($C/SaveFile)

	$C/SaveFile.filters = filters
	$C/SaveFile.show()
	$C/SaveFile.call_deferred("set_current_dir",Globals.p(initial_path))
	visible = true
	raise()

func open_folder(
	obj:Object,
	method:String,
	initial_path:String = "user://"
):
	target_object = obj
	target_method = method

	_apply_scale($C/Folder)

	$C/Folder.show()
	$C/Folder.call_deferred("set_current_dir",Globals.p(initial_path))
	visible = true
	raise()
