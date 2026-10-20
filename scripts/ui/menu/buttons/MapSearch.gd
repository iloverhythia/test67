#MapSearch
extends LineEdit

onready var map_list = get_parent().get_parent().get_node("S/VBoxContainer")
onready var author_box = get_parent().get_parent().get_node("T/AuthorSearch")
onready var custom_speed_edit = get_node_or_null("/root/Menu/Main/Maps/Results/Results/RS/H2/Mods/SpeedMod/C/CustomSpeed")
onready var time_box = get_node_or_null("/root/Menu/Main/Maps/Results/Results/RS/H2/Mods/StartOffset/TimeTextBox")

func update_txt(_v=null):
	map_list.update_search_text(text)
	Rhythia.last_search_str = text

func _ready():
	connect("text_changed",self,"update_txt")
	text = Rhythia.last_search_str
	update_txt()
	map_list.connect("reset_filters",self,"_on_reset_filters")
	map_list.connect("lock_type",self,"_on_lock_type")
	get_parent().get_parent().get_parent().get_node("Results/Results/RS/H1/Info/Run").connect("lock_type",self,"_on_lock_type")

func _on_reset_filters():
	text = ""
	update_txt()

func _on_lock_type():
	set_editable(false)

func _input(event):
	if get_focus_owner() == self: return
	if get_focus_owner() == author_box: return
	if custom_speed_edit and get_focus_owner() == custom_speed_edit.get_line_edit(): return
	if time_box and get_focus_owner() == time_box: return

	if not is_visible_in_tree(): return
	if event is InputEventKey and event.is_pressed():
		if event.scancode == KEY_SPACE: return
		if event.scancode == KEY_BACKSPACE:
			if len(text) == 0: return
			else:
				clear()
				grab_focus()
		if event.get_unicode() != 0:
			grab_focus()
