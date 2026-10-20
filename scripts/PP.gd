#PP
extends Node

const BEST_PATH = "user://pp_scores.json"
const HISTORY_PATH = "user://pp_history.jsonl"

# Aim skill
const AIM_STRAIN_DECAY = 0.1
const AIM_SPEED_EXP = 1.06
const AIM_ANGLE_WEIGHT = 0.6
const AIM_WIDE_WEIGHT = 0.4
const AIM_STAR_SCALE = 0.0035

# Speed skill
const SPEED_STRAIN_DECAY = 0.1
const SPEED_RATE_EXP = 1.3
const SPEED_RATE_BASE = 5.0
const SPEED_STREAM_MULT = 1.15
const SPEED_STAR_SCALE = 0.0035

# Aggregation
const SECTION_MS = 400.0
const SECTION_WEIGHT_DECAY = 0.9

# PP scalars
const AIM_PP_SCALE = 12.0
const SPEED_PP_SCALE = 10.0
const ACC_PP_SCALE = 8.0
const ACC_PP_EXPONENT = 12.0
const ACC_STAR_EXP = 1.1
const PP_NORM_EXP = 1.1

# Miss / combo
const MISS_PENALTY_MAX = 0.05
const MISS_PENALTY_FLOOR = 0.35
const COMBO_SCALE_EXP = 0.8

# Eligibility
const MAX_HITWINDOW = 55.0
const MAX_HITBOX = 1.1401

const MIN_DT_S = 0.012

const MERGE_GAP_MS = 5.0

var plays:Dictionary = {}
var diff_cache:Dictionary = {}

func _ready():
	load_best()

# === Star Rating ===

func get_star_ratings(song:Song, speed:float) -> Dictionary:
	var key = "%s|%.2f" % [song.id, speed]
	print("[STARS] %s speed=%.2f cached=%s" % [song.id, speed, diff_cache.has(key)])
	
	if diff_cache.has(key): return diff_cache[key]

	var notes:Array = _merge_notes(song.read_notes())
	
	if notes.size() < 2:
		var empty = {aim = 0.0, speed = 0.0, overall = 0.0}
		diff_cache[key] = empty
		return empty

	var aim = _calc_aim_stars(notes, speed)
	var spd = _calc_speed_stars(notes, speed)
	var result = {aim = aim, speed = spd, overall = aim + spd * 0.7}
	diff_cache[key] = result
	return result

func _calc_aim_stars(notes:Array, speed:float) -> float:
	var strain:float = 0.0
	var peaks:Dictionary = {}
	for i in range(1, notes.size()):
		var dt_ms:float = (notes[i][2] - notes[i-1][2]) / speed
		var dt_s:float = max(dt_ms / 1000.0, MIN_DT_S)
		var dx = notes[i][0] - notes[i-1][0]
		var dy = notes[i][1] - notes[i-1][1]
		var dist = sqrt(dx*dx + dy*dy)
		var vel_diff = (dist + 0.3) * pow(1.0 / dt_s, 0.55)

		var angle_mult = 1.0
		if i > 1:
			var pdx = notes[i-1][0] - notes[i-2][0]
			var pdy = notes[i-1][1] - notes[i-2][1]
			var delta = abs(_angle_diff(atan2(dy, dx), atan2(pdy, pdx)))
			angle_mult = 1.0 + AIM_ANGLE_WEIGHT * (delta / PI)

		var wide_mult = 1.0 + AIM_WIDE_WEIGHT * clamp(dist / 1.5, 0, 1)
		var cluster_mult = 1.0 if dt_ms >= 40 else 0.5

		strain = strain * pow(AIM_STRAIN_DECAY, dt_s) + vel_diff * angle_mult * wide_mult * cluster_mult
		var section = int(notes[i][2] / SECTION_MS)
		peaks[section] = max(peaks.get(section, 0.0), strain)

	return _aggregate(peaks) * AIM_STAR_SCALE

func _calc_speed_stars(notes:Array, speed:float) -> float:
	var strain:float = 0.0
	var peaks:Dictionary = {}
	for i in range(1, notes.size()):
		var dt_ms:float = (notes[i][2] - notes[i-1][2]) / speed
		var dt_s:float = max(dt_ms / 1000.0, MIN_DT_S)
		var tap_rate = 1.0 / dt_s
		var base_diff = pow(tap_rate / SPEED_RATE_BASE, 1.15)

		var stream_mult = 1.0
		if i + 1 < notes.size():
			var dt_next = (notes[i+1][2] - notes[i][2]) / speed
			if abs(dt_ms - dt_next) < dt_ms * 0.25:
				stream_mult = SPEED_STREAM_MULT

		strain = strain * pow(SPEED_STRAIN_DECAY, dt_s) + base_diff * stream_mult
		var section = int(notes[i][2] / SECTION_MS)
		peaks[section] = max(peaks.get(section, 0.0), strain)

	return _aggregate(peaks) * SPEED_STAR_SCALE

func _aggregate(peaks:Dictionary) -> float:
	if peaks.size() == 0: return 0.0
	var values:Array = peaks.values()
	values.sort()
	values.invert()
	var total:float = 0.0
	for i in range(values.size()):
		total += values[i] * pow(SECTION_WEIGHT_DECAY, i)
	return total

func _angle_diff(a:float, b:float) -> float:
	var d = fmod(a - b, TAU)
	if d > PI: d -= TAU
	elif d < -PI: d += TAU
	return d

# === PP ===

func calc_pp(song:Song, speed:float, accuracy:float, max_combo:int, miss_positions:Array, total_notes:int) -> float:
	var r = get_star_ratings(song, speed)

	var aim_pp = pow(r.aim, 2.0) * AIM_PP_SCALE
	var spd_pp = pow(r.speed, 2.0) * SPEED_PP_SCALE
	var acc_pp = pow(accuracy, ACC_PP_EXPONENT) * ACC_PP_SCALE * pow(r.overall, ACC_STAR_EXP)

	var base_pp = pow(
		pow(aim_pp, PP_NORM_EXP) + pow(spd_pp, PP_NORM_EXP) + pow(acc_pp, PP_NORM_EXP),
		1.0 / PP_NORM_EXP
	)

	var miss_mult = _miss_penalty(miss_positions, song, speed)
	var combo_mult = 1.0
	if total_notes > 0:
		combo_mult = pow(float(max_combo) / float(total_notes), COMBO_SCALE_EXP)

	return base_pp * miss_mult * combo_mult * get_mod_multiplier()

func _miss_penalty(miss_positions:Array, song:Song, speed:float) -> float:
	if miss_positions.size() == 0: return 1.0
	var peaks = _section_peaks(song.read_notes(), speed)
	if peaks.size() == 0: return 1.0
	var max_peak:float = 0.0
	for v in peaks.values():
		if v > max_peak: max_peak = v
	if max_peak <= 0: return 1.0

	var penalty:float = 1.0
	for miss_ms in miss_positions:
		var weight = peaks.get(int(miss_ms / SECTION_MS), 0.0) / max_peak
		penalty *= (1.0 - MISS_PENALTY_MAX * weight)
	return max(penalty, MISS_PENALTY_FLOOR)

func _section_peaks(notes:Array, speed:float) -> Dictionary:
	var strain:float = 0.0
	var peaks:Dictionary = {}
	for i in range(1, notes.size()):
		var dt_s:float = max(((notes[i][2] - notes[i-1][2]) / speed) / 1000.0, MIN_DT_S)
		var dx = notes[i][0] - notes[i-1][0]
		var dy = notes[i][1] - notes[i-1][1]
		var dist = sqrt(dx*dx + dy*dy)
		strain = strain * pow(AIM_STRAIN_DECAY, dt_s) + (dist + 0.3) * pow(1.0 / dt_s, 0.55)
		var section = int(notes[i][2] / SECTION_MS)
		peaks[section] = max(peaks.get(section, 0.0), strain)
	return peaks

func get_mod_multiplier() -> float:
	# TODO: SD/HR/FL/Ghost multipliers
	return 1.0
		
func _merge_notes(notes:Array) -> Array:
	if notes.size() < 2: return notes
	var merged:Array = []
	var cluster:Array = [notes[0]]
	for i in range(1, notes.size()):
		if notes[i][2] - cluster[cluster.size()-1][2] <= MERGE_GAP_MS:
			cluster.append(notes[i])
		else:
			merged.append(_cluster_center(cluster))
			cluster = [notes[i]]
	if cluster.size() > 0:
		merged.append(_cluster_center(cluster))
	return merged

func _cluster_center(cluster:Array) -> Array:
	if cluster.size() == 1: return cluster[0]
	var sx = 0.0
	var sy = 0.0
	for n in cluster:
		sx += n[0]
		sy += n[1]
	return [sx / cluster.size(), sy / cluster.size(), cluster[cluster.size()-1][2]]
	
	

# === Recording ===

func record_play():
	var r = Rhythia
	if r.song_end_type != Globals.END_PASS: return
	if r.was_replay or r.just_ended_queue: return
	if !settings_allow_pp(): return
	var song:Song = r.selected_song
	if song == null or song.note_count < 2: return

	var total:float = max(float(r.song_end_total_notes), 1.0)
	var acc:float = float(r.song_end_hits) / total
	var speed:float = Globals.speed_multi[r.mod_speed_level]
	var ratings = get_star_ratings(song, speed)
	var pp:float = calc_pp(song, speed, acc, r.song_end_combo, r.song_end_miss_positions, r.song_end_total_notes)

	var play = {
		id = song.id,
		name = song.name,
		creator = song.creator,
		difficulty = song.difficulty,
		difficulty_name = song.custom_data.get("difficulty_name", ""),
		pp = pp,
		aim_stars = ratings.aim,
		speed_stars = ratings.speed,
		overall_stars = ratings.overall,
		stars = ratings.overall,
		accuracy = acc,
		misses = r.song_end_misses,
		miss_positions = r.song_end_miss_positions.duplicate(),
		max_combo = r.song_end_combo,
		total_notes = r.song_end_total_notes,
		speed = speed,
		date = OS.get_unix_time()
	}

	var old = plays.get(song.id)
	if old == null or pp > old.pp:
		plays[song.id] = play
		save_best()
	_append_history(play)
	Globals.notify(Globals.NOTIFY_SUCCEED, "%.1f pp  (%.2f stars)" % [pp, ratings.overall], "Performance")

func _append_history(play:Dictionary):
	var f:File = File.new()
	if f.file_exists(Globals.p(HISTORY_PATH)):
		if f.open(Globals.p(HISTORY_PATH), File.READ_WRITE) != OK: return
		f.seek_end()
	else:
		if f.open(Globals.p(HISTORY_PATH), File.WRITE) != OK: return
	f.store_line(JSON.print(play))
	f.close()

# === Total PP ===

func total_pp() -> float:
	var list:Array = plays.values()
	list.sort_custom(self, "_sort_pp")
	var total:float = 0.0
	for i in range(list.size()):
		total += list[i].pp * pow(0.95, i)
	return total

func _sort_pp(a, b):
	return a.pp > b.pp

# === Storage ===

func save_best():
	var f:File = File.new()
	if f.open(Globals.p(BEST_PATH), File.WRITE) != OK: return
	f.store_string(JSON.print(plays, "\t"))
	f.close()

func load_best():
	var f:File = File.new()
	if !f.file_exists(Globals.p(BEST_PATH)): return
	if f.open(Globals.p(BEST_PATH), File.READ) != OK: return
	var res = parse_json(f.get_as_text())
	f.close()
	if res is Dictionary: plays = res

func load_history(limit:int=-1) -> Array:
	var f:File = File.new()
	if !f.file_exists(Globals.p(HISTORY_PATH)): return []
	if f.open(Globals.p(HISTORY_PATH), File.READ) != OK: return []
	var result:Array = []
	while !f.eof_reached():
		var line = f.get_line()
		if line.strip_edges() == "": continue
		var res = parse_json(line)
		if res is Dictionary: result.append(res)
	f.close()
	if limit > 0 and result.size() > limit:
		return result.slice(result.size() - limit, result.size())
	return result

# === Query ===

func get_top_plays(n:int=10) -> Array:
	var list:Array = plays.values()
	list.sort_custom(self, "_sort_pp")
	var out:Array = []
	for i in range(min(n, list.size())):
		out.append(list[i])
	return out

func max_pp_info(song:Song) -> Dictionary:
	if song == null or song.is_online or song.is_broken or song.note_count < 2:
		return {state = "hidden"}
	if !settings_allow_pp():
		return {state = "blocked"}
	var speed:float = Globals.speed_multi[Rhythia.mod_speed_level]
	var ratings = get_star_ratings(song, speed)
	var total_notes:int = max(song.note_count, 2)
	var pp:float = calc_pp(song, speed, 1.0, total_notes, [], total_notes)
	
	print("[PP-CALC] aim=%.3f spd=%.3f overall=%.3f pp=%.3f" % [ratings.aim, ratings.speed, ratings.overall, pp])
	
	var best:float = 0.0
	var old = plays.get(song.id)
	if old != null: best = old.pp
	var gain:float = 0.0
	if pp > best: gain = total_pp_with(song.id, pp) - total_pp()
	return {
		state = "ok",
		pp = pp,
		aim_stars = ratings.aim,
		speed_stars = ratings.speed,
		overall_stars = ratings.overall,
		stars = ratings.overall,
		speed = speed,
		best = best,
		gain = gain
	}

func total_pp_with(song_id:String, new_pp:float) -> float:
	var list:Array = []
	for id in plays.keys():
		if id != song_id: list.append(plays[id].pp)
	list.append(new_pp)
	list.sort()
	list.invert()
	var total:float = 0.0
	for i in range(list.size()):
		total += list[i] * pow(0.95, i)
	return total

func settings_allow_pp() -> bool:
	var r = Rhythia
	return not (r.mod_nofail or r.start_offset != 0 or r.hitwindow_ms > MAX_HITWINDOW or r.note_hitbox_size > MAX_HITBOX)
