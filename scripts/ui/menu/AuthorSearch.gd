#AuthorSearch
extends LineEdit

onready var map_vbox = get_parent().get_parent().get_node("S/VBoxContainer")
onready var run_button = get_parent().get_parent().get_parent().get_node("Results/Results/RS/H1/Info/Run")

func update_txt(_v=null):
	map_vbox.update_author_search_text(text)
	Rhythia.last_author_search_str = text

func _ready():
	connect("text_changed",self,"update_txt")
	text = Rhythia.last_author_search_str
	update_txt()
	map_vbox.connect("reset_filters",self,"_on_reset_filters")
	map_vbox.connect("lock_type",self,"_on_lock_type")
	run_button.connect("lock_type",self,"_on_lock_type")

func _on_reset_filters():
	text = ""
	update_txt()

func _on_lock_type():
	set_editable(false)
