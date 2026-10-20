#PerformancePage
extends Control

const BLACK = "res://assets/font/Lato/Lato-Black.ttf"
const BOLD = "res://assets/font/Lato/Lato-Bold.ttf"
const REG = "res://assets/font/Lato/Lato-Regular.ttf"
const JP = "res://assets/font/Noto_Sans_JP/NotoSansJP-Medium.otf"

const MAX_ROWS = 30
const RECENT_ROWS = 20
const BAR_W = 150

const C_TEXT = Color("#e9e9f7")
const C_DIM = Color("#8a8aa8")
const C_PINK = Color("#ffc1f5")
const C_CYAN = Color("#91fffa")
const C_GOLD = Color("#ffe08a")
const C_RED = Color("#ff8282")
const RANK_COLORS = [Color("#ffe08a"), Color("#d0d6e6"), Color("#e8a977")]

enum { MODE_TOP, MODE_RECENT }

var fonts:Dictionary = {}
var mode:int = MODE_TOP

var total_label:Label
var sub_label:Label
var plays_value:Label
var acc_value:Label
var best_value:Label
var fc_value:Label
var list:VBoxContainer
var tab_group:ButtonGroup = ButtonGroup.new()

var shown_total:float = 0.0
var target_total:float = 0.0
var rainbow_labels:Array = []
var _tween

# === Helpers ===

func _font(path:String, size:int) -> DynamicFont:
	var key = "%s|%d" % [path, size]
	if fonts.has(key): return fonts[key]
	var f:DynamicFont = DynamicFont.new()
	f.font_data = load(path)
	f.size = size
	f.use_filter = true
	f.add_fallback(load(JP))
	fonts[key] = f
	return f

func _label(text:String, font:DynamicFont, color:Color, align:int = Label.ALIGN_LEFT, min_w:float = 0.0, clip:bool = false) -> Label:
	var l:Label = Label.new()
	l.text = text
	l.add_font_override("font", font)
	l.add_color_override("font_color", color)
	l.align = align
	l.rect_min_size = Vector2(min_w, 0)
	l.clip_text = clip
	return l

func _box(bg:Color, radius:int, pad_h:int, pad_v:int) -> StyleBoxFlat:
	var s:StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.corner_detail = 8
	s.content_margin_left = pad_h
	s.content_margin_right = pad_h
	s.content_margin_top = pad_v
	s.content_margin_bottom = pad_v
	return s

func _chip(text:String, fg:Color, bg:Color) -> PanelContainer:
	var p:PanelContainer = PanelContainer.new()
	p.add_stylebox_override("panel", _box(bg, 8, 8, 2))
	p.add_child(_label(text, _font(BOLD, 14), fg))
	return p

func _card_style(accent:Color, hover:bool) -> StyleBoxFlat:
	var bg:Color = Color(0.075, 0.058, 0.17, 1)
	if hover: bg = Color(0.12, 0.09, 0.27, 1)
	var s:StyleBoxFlat = _box(bg, 14, 16, 10)
	s.border_width_left = 6
	s.border_color = accent
	s.shadow_color = Color(accent.r, accent.g, accent.b, 0.22 if hover else 0.08)
	s.shadow_size = 8
	return s

func _ignore_children(n:Node):
	for c in n.get_children():
		if c is Control: c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_children(c)

func _grade(acc:float) -> Dictionary:
	if acc >= 1.0:
		return {t = "SS", c = Color.from_hsv(Rhythia.rainbow_t * 0.1, 0.5, 1), rainbow = true}
	elif acc >= 0.98: return {t = "S", c = Rhythia.grade_s_color, rainbow = false}
	elif acc >= 0.95: return {t = "A", c = Rhythia.grade_a_color, rainbow = false}
	elif acc >= 0.90: return {t = "B", c = Rhythia.grade_b_color, rainbow = false}
	elif acc >= 0.85: return {t = "C", c = Rhythia.grade_c_color, rainbow = false}
	elif acc >= 0.80: return {t = "D", c = Rhythia.grade_d_color, rainbow = false}
	return {t = "F", c = Rhythia.grade_f_color, rainbow = false}

func _ago(unix:int) -> String:
	if unix <= 0: return ""
	var d:int = OS.get_unix_time() - unix
	if d < 60: return "just now"
	if d < 3600: return "%dm ago" % (d / 60)
	if d < 86400: return "%dh ago" % (d / 3600)
	if d < 86400 * 30: return "%dd ago" % (d / 86400)
	var dt:Dictionary = OS.get_datetime_from_unix_time(unix)
	return "%04d-%02d-%02d" % [dt.year, dt.month, dt.day]

# === Page layout ===

func _ready():
	set_anchors_and_margins_preset(Control.PRESET_WIDE)

	var margin:MarginContainer = MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	margin.add_constant_override("margin_left", 40)
	margin.add_constant_override("margin_right", 40)
	margin.add_constant_override("margin_top", 28)
	margin.add_constant_override("margin_bottom", 24)

	var root:VBoxContainer = VBoxContainer.new()
	root.add_constant_override("separation", 14)
	margin.add_child(root)

	_build_header(root)
	_build_tabs(root)

	var scroll:ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.scroll_horizontal_enabled = false
	root.add_child(scroll)

	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_constant_override("separation", 10)
	scroll.add_child(list)

	connect("visibility_changed", self, "refresh")
	refresh()

func _build_header(parent:Node):
	var card:PanelContainer = PanelContainer.new()
	var st:StyleBoxFlat = _box(Color(0.105882, 0.0784314, 0.235294, 1), 24, 28, 18)
	st.shadow_color = Color(0.368627, 0.466667, 1, 0.45)
	st.shadow_size = 8
	card.add_stylebox_override("panel", st)
	parent.add_child(card)

	var row:HBoxContainer = HBoxContainer.new()
	row.add_constant_override("separation", 24)
	card.add_child(row)

	var left:VBoxContainer = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_constant_override("separation", 0)
	row.add_child(left)
	left.add_child(_label("PERFORMANCE", _font(BOLD, 16), C_PINK))

	var num_row:HBoxContainer = HBoxContainer.new()
	num_row.add_constant_override("separation", 10)
	left.add_child(num_row)
	total_label = _label("0", _font(BLACK, 64), C_CYAN)
	num_row.add_child(total_label)
	var pp_tag:Label = _label("pp", _font(BOLD, 28), C_DIM)
	pp_tag.size_flags_vertical = Control.SIZE_SHRINK_END
	num_row.add_child(pp_tag)

	sub_label = _label("", _font(REG, 16), C_DIM)
	left.add_child(sub_label)

	var tiles:HBoxContainer = HBoxContainer.new()
	tiles.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tiles.add_constant_override("separation", 12)
	row.add_child(tiles)
	plays_value = _tile(tiles, "MAPS")
	acc_value = _tile(tiles, "AVG ACCURACY")
	best_value = _tile(tiles, "BEST PLAY")
	fc_value = _tile(tiles, "FULL COMBOS")

func _tile(parent:Node, caption:String) -> Label:
	var p:PanelContainer = PanelContainer.new()
	p.add_stylebox_override("panel", _box(Color(0.05, 0.04, 0.13, 1), 14, 16, 10))
	p.rect_min_size = Vector2(120, 0)
	parent.add_child(p)
	var v:VBoxContainer = VBoxContainer.new()
	v.add_constant_override("separation", 0)
	p.add_child(v)
	var value:Label = _label("-", _font(BLACK, 26), C_TEXT, Label.ALIGN_CENTER)
	v.add_child(value)
	v.add_child(_label(caption, _font(BOLD, 12), C_DIM, Label.ALIGN_CENTER))
	return value

func _build_tabs(parent:Node):
	var row:HBoxContainer = HBoxContainer.new()
	row.add_constant_override("separation", 8)
	parent.add_child(row)
	row.add_child(_tab("TOP PLAYS", MODE_TOP, true))
	row.add_child(_tab("RECENT", MODE_RECENT, false))
	var spacer:Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var hint:Label = _label("Click a play to jump to its map", _font(REG, 15), C_DIM)
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(hint)

func _tab(text:String, m:int, on:bool) -> Button:
	var b:Button = Button.new()
	b.text = text
	b.toggle_mode = true
	b.group = tab_group
	b.pressed = on
	b.focus_mode = Control.FOCUS_NONE
	b.rect_min_size = Vector2(120, 34)
	b.add_font_override("font", _font(BOLD, 15))
	b.add_stylebox_override("normal", _box(Color(0.105882, 0.0784314, 0.235294, 1), 17, 16, 4))
	b.add_stylebox_override("hover", _box(Color(0.17, 0.13, 0.34, 1), 17, 16, 4))
	b.add_stylebox_override("pressed", _box(C_PINK, 17, 16, 4))
	b.add_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_color_override("font_color", C_TEXT)
	b.add_color_override("font_color_hover", Color(1, 1, 1))
	b.add_color_override("font_color_pressed", Color(0.12, 0.05, 0.17))
	b.add_color_override("font_color_hover_pressed", Color(0.12, 0.05, 0.17))
	b.connect("pressed", self, "_set_mode", [m])
	return b

func _set_mode(m:int):
	mode = m
	_populate()

# === Refresh ===

func refresh():
	if list == null or !is_visible_in_tree(): return
	_update_header()
	_populate()

func _update_header():
	target_total = PP.total_pp()
	shown_total = 0.0
	total_label.text = "0"

	var vals:Array = PP.plays.values()
	var n:int = vals.size()
	var acc_sum:float = 0.0
	var fcs:int = 0
	var best:float = 0.0
	for p in vals:
		acc_sum += float(p.get("accuracy", 0.0))
		if int(p.get("misses", 1)) == 0: fcs += 1
		best = max(best, float(p.get("pp", 0.0)))

	plays_value.text = str(n)
	fc_value.text = str(fcs)
	if n > 0:
		acc_value.text = "%.2f%%" % (acc_sum / n * 100.0)
		best_value.text = "%.0f pp" % best
		sub_label.text = "%d maps with a pp score" % n
	else:
		acc_value.text = "-"
		best_value.text = "-"
		sub_label.text = "Pass a map to start earning pp"

func _populate():
	if _tween and _tween.is_valid(): _tween.kill()
	rainbow_labels.clear()
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()

	var data:Array = []
	if mode == MODE_TOP:
		data = PP.get_top_plays(MAX_ROWS)
	else:
		data = PP.load_history(RECENT_ROWS)
		data.invert() # newest first

	if data.empty():
		list.add_child(_empty_state())
		return

	var top_pp:float = 0.0
	for p in data:
		top_pp = max(top_pp, float(p.get("pp", 0.0)))

	_tween = get_tree().create_tween().set_parallel(true)
	var i:int = 0
	for p in data:
		var card:PanelContainer = _build_card(p, i, top_pp, mode == MODE_RECENT)
		list.add_child(card)
		card.modulate.a = 0.0
		_tween.tween_property(card, "modulate:a", 1.0, 0.25).set_delay(i * 0.035)
		i += 1

func _empty_state() -> Control:
	var p:PanelContainer = PanelContainer.new()
	p.add_stylebox_override("panel", _box(Color(0.075, 0.058, 0.17, 1), 14, 24, 28))
	var v:VBoxContainer = VBoxContainer.new()
	v.add_constant_override("separation", 6)
	p.add_child(v)
	v.add_child(_label("No plays yet", _font(BLACK, 26), C_TEXT, Label.ALIGN_CENTER))
	v.add_child(_label("Pass a map with the default hitbox and hit window to earn pp.", _font(REG, 17), C_DIM, Label.ALIGN_CENTER))
	return p

# === Play card ===

func _cover(song, map_name:String, accent:Color) -> Control:
	var box:Control = Control.new()
	box.rect_min_size = Vector2(76, 76)
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var tex = null
	if song and song.has_cover: tex = song.cover
	if tex:
		var img:TextureRect = TextureRect.new()
		img.texture = tex
		img.expand = true
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		box.add_child(img)
		img.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	else:
		var bg:ColorRect = ColorRect.new()
		bg.color = Color(accent.r, accent.g, accent.b, 0.28)
		box.add_child(bg)
		bg.set_anchors_and_margins_preset(Control.PRESET_WIDE)
		var letter:Label = _label("♪", _font(BLACK, 34), accent.linear_interpolate(Color(1, 1, 1), 0.35), Label.ALIGN_CENTER)
		letter.valign = Label.VALIGN_CENTER
		bg.add_child(letter)
		letter.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	return box

func _build_card(p:Dictionary, idx:int, top_pp:float, recent:bool) -> PanelContainer:
	# map info (live from the library when possible, stored values as fallback)
	var id:String = str(p.get("id", ""))
	var song = Rhythia.registry_song.get_item(id)
	var map_name:String = str(p.get("name", id))
	var creator:String = str(p.get("creator", ""))
	var diff:int = int(p.get("difficulty", -1))
	var diff_name:String = ""
	if song:
		map_name = song.name
		if song.creator != "": creator = song.creator
		diff = song.difficulty
		diff_name = str(song.custom_data.get("difficulty_name", ""))
	if diff_name == "":
		diff_name = str(Globals.difficulty_names.get(diff, "N/A"))
	var accent:Color = Globals.difficulty_colors.get(diff, C_DIM)
	if diff < 0: accent = C_DIM
	var accent_text:Color = accent.linear_interpolate(Color(1, 1, 1), 0.35)

	# play stats
	var pp:float = float(p.get("pp", 0.0))
	var acc:float = float(p.get("accuracy", 0.0))
	var misses:int = int(p.get("misses", 0))
	var speed:float = float(p.get("speed", 1.0))
	var max_combo:int = int(p.get("max_combo", -1))
	var stars:float = float(p.get("overall_stars", p.get("stars", 0.0)))
	var grade:Dictionary = _grade(acc)

	var card:PanelContainer = PanelContainer.new()
	card.add_stylebox_override("panel", _card_style(accent, false))
	card.hint_tooltip = map_name
	card.mouse_filter = Control.MOUSE_FILTER_PASS

	var row:HBoxContainer = HBoxContainer.new()
	row.add_constant_override("separation", 14)
	card.add_child(row)

	# rank
	if !recent:
		var rc:Color = C_DIM
		if idx < RANK_COLORS.size(): rc = RANK_COLORS[idx]
		var rank:Label = _label("#%d" % (idx + 1), _font(BLACK, 22), rc, Label.ALIGN_CENTER, 52)
		rank.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(rank)

	# cover
	row.add_child(_cover(song, map_name, accent))

	# name, meta, chips
	var info:VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGN_CENTER
	info.add_constant_override("separation", 6)
	row.add_child(info)

	var name_l:Label = _label(map_name, _font(BLACK, 21), Color(1, 1, 1), Label.ALIGN_LEFT, 0.0, true)
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(name_l)

	var meta:HBoxContainer = HBoxContainer.new()
	meta.add_constant_override("separation", 8)
	info.add_child(meta)
	meta.add_child(_chip(diff_name, accent_text, Color(accent.r, accent.g, accent.b, 0.22)))
	var bits:Array = []
	if creator != "": bits.append("by " + creator)
	var ago:String = _ago(int(p.get("date", 0)))
	if ago != "": bits.append(ago)
	if bits.size() > 0:
		var ml:Label = _label(PoolStringArray(bits).join("  -  "), _font(REG, 15), C_DIM, Label.ALIGN_LEFT, 0.0, true)
		ml.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ml.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		meta.add_child(ml)

	var chips:HBoxContainer = HBoxContainer.new()
	chips.add_constant_override("separation", 6)
	info.add_child(chips)
	chips.add_child(_chip("%.2f%%" % (acc * 100.0), grade.c, Color(1, 1, 1, 0.07)))
	if misses == 0:
		chips.add_child(_chip("FULL COMBO", C_CYAN, Color(0.57, 0.98, 0.98, 0.14)))
	else:
		chips.add_child(_chip("%d miss%s" % [misses, "" if misses == 1 else "es"], C_RED, Color(1, 0.51, 0.51, 0.14)))
		if max_combo >= 0:
			chips.add_child(_chip("%dx combo" % max_combo, C_TEXT, Color(1, 1, 1, 0.07)))
	if abs(speed - 1.0) > 0.001:
		chips.add_child(_chip("%.2fx" % speed, C_GOLD, Color(1, 0.88, 0.54, 0.12)))
	chips.add_child(_chip("%.2f stars" % stars, C_GOLD, Color(1, 0.88, 0.54, 0.12)))
	if p.has("aim_stars") and p.has("speed_stars"):
		chips.add_child(_chip("aim %.1f / spd %.1f" % [float(p.aim_stars), float(p.speed_stars)], C_DIM, Color(1, 1, 1, 0.05)))

	# grade
	var gl:Label = _label(grade.t, _font(BLACK, 36), grade.c, Label.ALIGN_CENTER, 62)
	gl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(gl)
	if grade.rainbow: rainbow_labels.append(gl)

	# pp block
	var pb:VBoxContainer = VBoxContainer.new()
	pb.rect_min_size = Vector2(BAR_W, 0)
	pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pb.add_constant_override("separation", 2)
	row.add_child(pb)

	var pr:HBoxContainer = HBoxContainer.new()
	pr.alignment = BoxContainer.ALIGN_END
	pr.add_constant_override("separation", 6)
	pb.add_child(pr)
	pr.add_child(_label("%.0f" % pp, _font(BLACK, 34), C_CYAN))
	var ptag:Label = _label("pp", _font(BOLD, 16), C_DIM)
	ptag.size_flags_vertical = Control.SIZE_SHRINK_END
	pr.add_child(ptag)

	var weighted_text:String = ""
	if !recent: weighted_text = "%.1f weighted" % (pp * pow(0.95, idx))
	pb.add_child(_label(weighted_text, _font(REG, 14), C_DIM, Label.ALIGN_RIGHT))

	var bar:ColorRect = ColorRect.new()
	bar.color = Color(1, 1, 1, 0.08)
	bar.rect_min_size = Vector2(BAR_W, 5)
	pb.add_child(bar)
	var fill:ColorRect = ColorRect.new()
	fill.color = accent_text
	bar.add_child(fill)
	var ratio:float = 0.0
	if top_pp > 0: ratio = clamp(pp / top_pp, 0.0, 1.0)
	fill.rect_position = Vector2(0, 0)
	fill.rect_size = Vector2(BAR_W * ratio, 5)

	# interaction: only the card itself receives mouse events
	card.connect("mouse_entered", self, "_hover", [card, accent, true])
	card.connect("mouse_exited", self, "_hover", [card, accent, false])
	card.connect("gui_input", self, "_card_input", [id])
	if song: card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_ignore_children(card)
	return card

func _hover(card:PanelContainer, accent:Color, on:bool):
	if is_instance_valid(card):
		card.add_stylebox_override("panel", _card_style(accent, on))

func _card_input(ev:InputEvent, id:String):
	if !(ev is InputEventMouseButton) or !ev.pressed or ev.button_index != BUTTON_LEFT: return
	var song = Rhythia.registry_song.get_item(id)
	if song == null or song.is_broken: return
	Rhythia.select_song(song)
	var lst = get_viewport().get_node_or_null("Menu/Main/Maps/MapRegistry/S/VBoxContainer")
	if lst and lst.has_method("switch_to_play_screen"):
		lst.switch_to_play_screen()
	else:
		var sb = get_viewport().get_node_or_null("Menu/Sidebar")
		if sb: sb.press(0, false)

# === Animation ===

func _process(delta):
	if !is_visible_in_tree(): return
	if shown_total != target_total:
		shown_total = lerp(shown_total, target_total, clamp(delta * 7.0, 0.0, 1.0))
		if abs(shown_total - target_total) < 0.5: shown_total = target_total
		total_label.text = Globals.comma_sep(int(round(shown_total)))
	if !rainbow_labels.empty():
		var c:Color = Color.from_hsv(Rhythia.rainbow_t * 0.1, 0.5, 1)
		for l in rainbow_labels:
			if is_instance_valid(l): l.add_color_override("font_color", c)
