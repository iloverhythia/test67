#MaxPPPanel
extends PanelContainer

const BLACK = "res://assets/font/Lato/Lato-Black.ttf"
const BOLD = "res://assets/font/Lato/Lato-Bold.ttf"
const REG = "res://assets/font/Lato/Lato-Regular.ttf"

const GOLD = Color("#ffe08a")
const DIM = Color("#8a8aa8")

var caption:Label
var number:Label
var detail:Label
var extra:Label
var target_pp:float = 0.0
var shown_pp:float = 0.0
var counting:bool = false

func _font(path:String, size:int) -> DynamicFont:
	var f:DynamicFont = DynamicFont.new()
	f.font_data = load(path)
	f.size = size
	f.use_filter = true
	return f

func _label(font:DynamicFont, color:Color) -> Label:
	var l:Label = Label.new()
	l.align = Label.ALIGN_CENTER
	l.add_font_override("font", font)
	l.add_color_override("font_color", color)
	return l

func _ready():
	var style:StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.105882, 0.0784314, 0.235294, 1)
	style.set_corner_radius_all(20)
	style.corner_detail = 10
	style.shadow_color = Color(0.368627, 0.466667, 1, 0.45)
	style.shadow_size = 6
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 10
	style.content_margin_bottom = 12
	add_stylebox_override("panel", style)
	rect_min_size = Vector2(0, 120)

	var box:VBoxContainer = VBoxContainer.new()
	box.add_constant_override("separation", 0)
	add_child(box)

	caption = _label(_font(BOLD, 15), Color("#ffc1f5"))
	caption.text = "MAX PERFORMANCE"
	box.add_child(caption)

	number = _label(_font(BLACK, 54), GOLD)
	box.add_child(number)

	detail = _label(_font(REG, 16), Color("#d9d9ee"))
	box.add_child(detail)

	extra = _label(_font(BOLD, 15), Color("#91fffa"))
	box.add_child(extra)

	Rhythia.connect("selected_song_changed", self, "update_info")
	Rhythia.connect("mods_changed", self, "update_info")
	Rhythia.connect("speed_mod_changed", self, "update_info")
	update_info()

func update_info(_a = null):
	var info:Dictionary = PP.max_pp_info(Rhythia.selected_song)
	if info.state == "hidden":
		visible = false
		counting = false
		return
	visible = true
	if info.state == "blocked":
		counting = false
		number.text = "No pp"
		number.add_color_override("font_color", DIM)
		detail.text = "Hitbox, hitwindow or mods are easier than default"
		extra.text = ""
		return

	number.add_color_override("font_color", GOLD)
	target_pp = info.pp
	counting = true
	detail.text = "at 100%% accuracy   -   %.2f stars   -   %.2fx speed" % [info.overall_stars, info.speed]
	var txt:String = ""
	if info.best > 0:
		txt = "Your best: %.0f pp" % info.best
	else:
		txt = "No score yet"
	if info.gain >= 0.05:
		txt += "   -   +%.1f total pp" % info.gain
	extra.text = txt

func _process(delta):
	if !counting: return
	shown_pp = lerp(shown_pp, target_pp, clamp(delta * 12.0, 0.0, 1.0))
	if abs(shown_pp - target_pp) < 0.5: shown_pp = target_pp
	number.text = "%d pp" % int(round(shown_pp))
