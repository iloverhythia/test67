#ExportTxt
extends Button

var debounce = false

func _pressed():
	if debounce or !Rhythia.selected_song: return
	debounce = true
	text = "Saving"
	Globals.file_sel.save_file(
		self,
		"_on_path_selected",
		PoolStringArray(["*.txt ; Text files"]),
		OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	)

func _on_path_selected(path:String):
	# the picker reports an empty string when it is cancelled
	if path != "":
		if path.get_extension() == "":
			path += ".txt"
		disabled = true
		Rhythia.selected_song.export_text(path)
	text = "Export map data"
	disabled = false
	debounce = false
