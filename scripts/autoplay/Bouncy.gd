#Bouncy
extends DanceMover
class_name BouncyDanceMover

var jmult:float = 1
var nmult:float = 1
var offsetMult:float = 1
var skipstacks:bool = true
var offset:float

var p1:Vector2
var p2:Vector2
var last:Vector2

func same(o1:Vector2, o2:Vector2): return o1 == o2
func same3(o1:Vector3, o2:Vector3): return (Vector2(o1.x,o1.y) == Vector2(o2.x,o2.y))

var Start:Vector3
var End:Vector3

var StartPos:Vector2
var StartTime:float
var EndPos:Vector2
var EndTime:float
var Duration:float

func T(time:float) -> float:
	return abs(time - StartTime) / max(Duration,0.01)

var notes:PoolVector3Array = PoolVector3Array()

func v2(v:Vector3) -> Vector2:
	return Vector2(v.x,v.y)

func _mirror(note:Vector3) -> Vector3:
	if Rhythia.mod_mirror_x: note.x = 2 - note.x
	if Rhythia.mod_mirror_y: note.y = 2 - note.y
	return note

func _init(song:Song):
	for n in song.read_notes():
		var note = _mirror(Vector3(n[0],n[1],n[2]))
		if notes.size() != 0 and (note.z - notes[notes.size()-1].z) < 10:
			var new:Vector3 = (note + notes[notes.size()-1]) / 2
			notes[notes.size()-1] = Vector3(new.x, new.y, notes[notes.size()-1].z)
		else:
			notes.append(note)

var noteNum = 1
var t
var r
var tme

func np(note:int) -> Vector2:
	note = clamp(note,0,notes.size()-1)
	return v2(notes[note])

func ti(note:int) -> float:
	note = clamp(note,0,notes.size()-1)
	return notes[note].z

func n(note:int) -> Vector3:
	note = clamp(note,0,notes.size()-1)
	return notes[note]

func bezier(t:float,p0:Vector2,p1:Vector2,p2:Vector2,p3:Vector2) -> Vector2:
	var res = (pow(1-t,2) * p0) + (2 * (1-t) * t * p1) + (pow(t,2) * p2)
	var final = lerp(
		lerp(p0,p2,t),
		res,
		clamp(
			smoothstep(
				25,
				300,
				(Duration / Globals.speed_multi[Rhythia.mod_speed_level]) * (StartPos.distance_to(EndPos))
			),0,1
		)
	)
	return Vector2(clamp(final.x,-0.5,2.5),clamp(final.y,-0.5,2.5))

func dir(p0:Vector2,p1:Vector2) -> Vector2:
	return p1 - ((p1-p0))

func dirR(p0:Vector2,p1:Vector2) -> Vector2:
	return p1 + ((p1-p0))

func _update(ms:float) -> Vector2:
	if noteNum != 0 and ms < notes[noteNum].z:
		for i in range(noteNum, -1, -1):
			if notes[i].z - ms <= 0:
				noteNum = i
				break
		if ms < notes[noteNum].z:
			noteNum = 0

	for i in range(noteNum, notes.size()):
		if notes[i].z > ms:
			noteNum = max(i-1,0)
			Start = notes[i-1]
			End = notes[i]
			StartPos = v2(Start)
			EndPos = v2(End)
			StartTime = Start.z
			EndTime = End.z
			Duration = EndTime - StartTime
			break

	if ms < notes[0].z: return v2(notes[0])

	t = clamp((ms - Start.z) / (End.z - Start.z),0,1)

	var m1 = 0
	if ti(noteNum)-ti(noteNum-1) != 0:
		m1 = 0.75*(n(noteNum).distance_to(n(noteNum-1)))/1000

	var m2 = 0
	if ti(noteNum+2)-ti(noteNum+1)!= 0:
		m2 = 0.75*(n(noteNum+2).distance_to(n(noteNum+1)))/1000

	var p0 = np(noteNum)
	var p1 = lerp(dirR(np(noteNum-1),np(noteNum)),np(noteNum),m1)
	var p2 = lerp(dirR(np(noteNum+2),np(noteNum+1)),np(noteNum+1),m2)
	var p3 = np(noteNum+1)

	return bezier(Dance.Linear(t),p0,p1,p3,p2)
