#Registry
extends Resource
class_name Registry

signal done_loading_reg

var items:Array = []
var idx_id:Array = []
var idx_name:Array = []
var idx_creator:Array = []
var idx_difficulty:Array = []
var idx_rarity:Array = []
var idx_type:Array = []

var has_subregistries:bool = false

func check_and_remove_id(id:String):
	var v:int = idx_id.find(id)
	if v >= 0:
		items.remove(v)
		idx_id.remove(v)
		idx_name.remove(v)
		idx_creator.remove(v)
		idx_difficulty.remove(v)
		idx_rarity.remove(v)
		idx_type.remove(v)

func get_items():
	if has_subregistries:
		var found:Array = []
		for i in range(items.size()):
			if idx_type[i] == "Registry": found.append_array(items[i].get_items())
			else: found.append(items[i])
		return found
	else:
		return items

func add_item(item,subregistry:bool=false,replaceSongs:bool=false):
	if subregistry:
		has_subregistries = true
		items.append(item)
		idx_id.append(null)
		idx_name.append(null)
		idx_creator.append(null)
		idx_difficulty.append(null)
		idx_rarity.append(null)
		idx_type.append("Registry")
		return true
	elif item is ColorSet:
		check_and_remove_id(item.id)
		items.append(item)
		idx_id.append(item.id)
		idx_name.append(item.name)
		idx_creator.append(item.creator)
		idx_difficulty.append(null)
		idx_rarity.append(null)
		idx_type.append("ColorSet")
		return true
	elif item is BackgroundWorld:
		check_and_remove_id(item.id)
		items.append(item)
		idx_id.append(item.id)
		idx_name.append(item.name)
		idx_creator.append(item.creator)
		idx_difficulty.append(null)
		idx_rarity.append(null)
		idx_type.append("BackgroundWorld")
		return true
	elif item is NoteMesh:
		check_and_remove_id(item.id)
		items.append(item)
		idx_id.append(item.id)
		idx_name.append(item.name)
		idx_creator.append(item.creator)
		idx_difficulty.append(null)
		idx_rarity.append(null)
		idx_type.append("NoteMesh")
		return true
	elif item is NoteEffect:
		check_and_remove_id(item.id)
		items.append(item)
		idx_id.append(item.id)
		idx_name.append(item.name)
		idx_creator.append(item.creator)
		idx_difficulty.append(null)
		idx_rarity.append(null)
		idx_type.append("NoteEffect")
		return true
	elif item is Song:
		if replaceSongs: check_and_remove_id(item.id)
		elif idx_id.has(item.id): return false
		items.append(item)
		idx_id.append(item.id)
		idx_name.append(item.name)
		idx_creator.append(item.creator)
		idx_difficulty.append(item.difficulty)
		idx_rarity.append(null)
		idx_type.append("Song")
		return true
	else: assert(false,"Invalid asset type for registry")

func add_sspm_map(path:String):
	var song:Song = Song.new()
	var res = song.load_from_sspm(path)
	if res is String:
		print(path + ": " + res)
		return
	add_item(song)
	return song

func add_sspm_cached_map(path:String, cache:Dictionary):
	var song:Song = Song.new()
	var res = song.load_from_cache(cache)
	if res is String:
		print(path + " [CACHE]: " + res)
		return false
	add_item(song)
	return true

func make_sspm_cache(_v:int):
	var caches:Dictionary = {
		_v = _v
	}
	for song in items:
		if not song.songType in [Globals.MAP_SSPM, Globals.MAP_SSPM2]: continue
		caches[song.filePath] = song.make_cache()
	return caches

func add_vulnus_map(folder_path:String):
	var songBase:Song = Song.new()
	var song = songBase.load_from_vulnus_map(folder_path)
	if song:
		add_item(song)

		var difflist = song.get_vulnus_map_difficulty_list(folder_path)
		if difflist.size() > 1:
			for i in range(1, difflist.size()):
				songBase = Song.new()
				song = songBase.load_from_vulnus_map(folder_path, i)
				if song: add_item(song)
				else: songBase = null

		return song
	else:
		songBase = null

func load_registry_file(path:String,regtype:int,regDisplayName:String=""):
	if regDisplayName == "": regDisplayName = path.get_base_dir().get_file()
	print(path)
	var file:File = File.new()
	file.open(path,File.READ)
	if regtype == Globals.REGISTRY_MAP:
		var home_path:String = path.get_base_dir() + "/"
		var rawRegData:String = file.get_as_text()
		var lines:Array = rawRegData.split("\n")
		print(lines.size())
		for i in range(lines.size()):
			var l = lines[i]
			if fmod(i,12) == 0: yield(Globals.get_tree(),"idle_frame")
			# type:~:id:~:name:~:creator:~:difficulty:~:rarity:~:musicPath:~:dataOrPath
			var split:Array = l.split(":~:")
			if split.size() == 8 and !split[0].begins_with("#"):
				var type:int = int(split[0])
				var song:Song = Song.new(split[1],split[2],split[3])
				song.difficulty = int(split[4])
				song.source_registry = regDisplayName
				match type:
					Globals.MAPR_FILE: song.setup_from_file(home_path+split[7],home_path+split[6])
					Globals.MAPR_FILE_ABSOLUTE: song.setup_from_file(split[7],split[6])
					Globals.MAPR_FILE_SONG_ABSOLUTE: song.setup_from_file(home_path+split[7],split[6])
					Globals.MAPR_EMBEDDED: song.setup_from_data(split[7],home_path+split[6])
					Globals.MAPR_EMBEDDED_SONG_ABSOLUTE: song.setup_from_data(split[7],split[6])

				add_item(song)
				song.discard_notes()
	emit_signal("done_loading_reg")

func get_item(value,searchType:int=Globals.SEARCH_ID):
	match searchType:
		Globals.SEARCH_ID:
			var f = idx_id.find(value)
			if f >= 0: return items[f]
			for i in range(items.size()):
				if idx_id[i] == null: continue
				if String(idx_id[i]) == String(value): return items[i]
				if idx_type[i] == "Registry":
					var result = items[i].get_item(value,searchType)
					if result: return result
	return false
