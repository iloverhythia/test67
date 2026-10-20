#SongInfoScreen
extends Control

onready var warning_box = $RS/H1/Info/Warning
onready var warning_label = $RS/H1/Info/Warning/Warning

onready var id_label = $RS/H1/Info/Id/Id
onready var id_box = $RS/H1/Info/Id
onready var name_label = $RS/H1/Info/Name/Name
onready var song_name_label = $RS/H1/Info/SongName/SongName
onready var mapper_label = $RS/H1/Info/Mapper/Mapper
onready var mapper_box = $RS/H1/Info/Mapper
onready var smm_label = $RS/H1/Info/SMM
onready var data_label = $RS/H1/Info/Data/Data

onready var difficulty_label = $RS/HMid/Difficulty
onready var hitboxes_label = $RS/HMid/Hitboxes

onready var run_btn = $RS/H1/Info/Run
onready var actions_btn = $RS/H1/Info/Control/Actions
onready var preview_btn = $RS/H1/Info/Control/PreviewMusic

onready var convert_btn = $Actions/Convert
onready var setdiff_btn = $Actions/Difficulty

onready var difficulty_btns:Array = [
	$RS/H1/ButtonDisp/NODIF,
	$RS/H1/ButtonDisp/EASY,
	$RS/H1/ButtonDisp/MEDIUM,
	$RS/H1/ButtonDisp/HARD,
	$RS/H1/ButtonDisp/LOGIC,
	$RS/H1/ButtonDisp/TASUKETE
]

func comma_sep(number):
	var string = str(number)
	var mod = string.length() % 3
	var res = ""
	for i in range(0, string.length()):
		if i != 0 && i % 3 == mod:
			res += ","
		res += string[i]
	return res

func get_time_ms(ms:float):
	var s = max(floor(ms / 1000),0)
	var m = floor(s / 60)
	var rs = fmod(s,60)
	return "%d:%02d" % [m,rs]

func update(_s=null):
	if !Rhythia.selected_song: return
	var map:Song = Rhythia.selected_song
	$RS.visible = (map.id != "!DELETED")
	$RS/H2/EndInfo.visible = true
	actions_btn.visible = true

	id_label.text = map.id
	name_label.text = map.name
	song_name_label.text = map.song
	mapper_label.text = map.creator
	difficulty_label.text = map.custom_data.get("difficulty_name",
		Globals.difficulty_names.get(map.difficulty,"INVALID DIFFICULTY ID")
	)
	difficulty_label.modulate = Globals.difficulty_colors.get(map.difficulty,Color("#ffffff"))
	data_label.text = "%s - %s notes" % [get_time_ms(map.last_ms),comma_sep(map.note_count)]

	difficulty_label.visible = true

	mapper_box.visible = !Rhythia.single_map_mode_txt
	id_box.visible = !Rhythia.single_map_mode_txt
	smm_label.visible = Rhythia.single_map_mode

	var txt = ""
	if Rhythia.note_hitbox_size == 1.140: txt += tr("Default hitboxes, ")
	else: txt += tr("Hitboxes: %s, ") % Rhythia.note_hitbox_size
	if Rhythia.hitwindow_ms == 55: txt += tr("default hitwindow")
	else: txt += tr("hitwindow: %s ms") % Rhythia.hitwindow_ms
	hitboxes_label.text = txt

	for i in range(difficulty_btns.size()):
		var n:Panel = difficulty_btns[i]
		n.visible = (map.difficulty == i-1)
		n.get_node("F").visible = Rhythia.is_favorite(map.id)
		if map.has_cover:
			n.get_node("Name").visible = false
			n.get_node("Cover").visible = true
			n.get_node("Cover").texture = map.cover
		else:
			n.get_node("Cover").visible = false
			n.get_node("Name").visible = true
			n.get_node("Name").text = map.name

	if map.warning != "":
		warning_box.visible = true
		warning_label.text = map.warning
		if map.is_broken:
			warning_label.set("custom_colors/font_color",Color(1,0,0))
		else:
			warning_label.set("custom_colors/font_color",Color(1,1,0))
	else:
		warning_box.visible = false

	run_btn.disabled = false
	actions_btn.disabled = false
	preview_btn.disabled = false

	convert_btn.disabled = (
		convert_btn.debounce or
		Rhythia.selected_song.is_broken or
		Rhythia.selected_song.is_builtin or
		Rhythia.selected_song.converted or
		Rhythia.selected_song.songType == Globals.MAP_SSPM2 or
		Rhythia.selected_song.is_online
	)

	convert_btn.visible = (
		!Rhythia.selected_song.is_builtin and
		!Rhythia.selected_song.is_online and
		Rhythia.selected_song.songType != Globals.MAP_SSPM2
	)

	setdiff_btn.visible = (
		!Rhythia.selected_song.is_builtin and
		!Rhythia.selected_song.is_online and (
			Rhythia.selected_song.songType == Globals.MAP_SSPM or
			Rhythia.selected_song.songType == Globals.MAP_SSPM2
		)
	)

	if Rhythia.selected_song.songType == Globals.MAP_SSPM:
		convert_btn.text = "Upgrade map to SSPM v2"
	else:
		convert_btn.text = "Convert map to .sspm"

	if is_inside_tree():
		yield(get_tree(),"idle_frame")
		yield(get_tree(),"idle_frame")

func return_to_song_select():
	get_viewport().get_node("Menu/Sidebar").press(0,false)

func _ready():
	Rhythia.connect("selected_song_changed",self,"update")
	Rhythia.connect("mods_changed",self,"update")
	Rhythia.connect("favorite_songs_changed",self,"update")
	if Rhythia.selected_song: update()
	else:
		$RS.visible = false
		$RS/H2/EndInfo.visible = false
		run_btn.disabled = true
		actions_btn.disabled = true
		preview_btn.disabled = true
