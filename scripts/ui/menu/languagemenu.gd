#languagemenu
extends ColorRect

onready var languageselect = $ChangeLanguage/SelectLanguageWindow/languageselector

# locale table for Globals.locale
# en = 0
# jp = 1
# fr = 2
# es = 3
# it = 4
# pl = 5

# # Called when the node enters the scene tree for	 the first time.
func _ready():
	add_items()
	Rhythia.language = 0
	languageselect.selected = 0

func add_items():
	languageselect.add_item("ENGLISH")

func _on_languageselector_item_selected(index):
	Rhythia.language = index
	TranslationServer.set_locale(Globals.locale[Rhythia.language])
