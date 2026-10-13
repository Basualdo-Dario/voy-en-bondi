extends Node
## Sonido del juego (autoload "Audio"): efectos, música de fondo y el motor del colectivo.
## Los efectos están en assets/audio/ (ver CREDITOS.md). Se usa así: Audio.play("coins").

const DIR := "res://assets/audio/"
const SFX := [
	"ui_click", "ui_open", "ui_close", "card", "coins", "coins_lost", "buy", "prize", "alert", "win", "lose",
	"trip_ok", "trip_fail", "fall", "jolt", "splat", "tug1", "tug2", "tap", "hold", "breath", "offer",
	"nogracias", "lock", "bill", "cafe", "perfume", "horn", "start", "door",
]
# Volumen de cada efecto (dB); los que no están van a 0
const VOL := {"engine": -14.0, "ui_click": -6.0, "tap": -8.0, "tug1": -4.0, "tug2": -4.0, "horn": -8.0, "door": -6.0, "start": -8.0, "jolt": -4.0}
const MUSIC_MENU_DB := -10.0
const MUSIC_TRIP_DB := -19.0
# Voces para el balbuceo de los personajes: 4 sílabas de cada una en assets/audio/voices/
const VOICES := ["whisper", "male_deep", "male_standard", "female_standard", "female_light", "quick"]

var streams := {}
var voices := {}
var pool: Array[AudioStreamPlayer] = []
var music := AudioStreamPlayer.new()
var engine := AudioStreamPlayer.new()
var muted := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for id in SFX:
		streams[id] = load(DIR + id + ".ogg")
	for v in VOICES:
		voices[v] = []
		for n in range(1, 5):
			voices[v].append(load("%svoices/%s_%d.ogg" % [DIR, v, n]))
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)
	var eng: AudioStreamOggVorbis = load(DIR + "engine.ogg")
	eng.loop = true
	engine.stream = eng
	engine.volume_db = VOL["engine"]
	add_child(engine)
	var mus: AudioStreamWAV = load(DIR + "music_cumbia.wav")
	mus.loop_mode = AudioStreamWAV.LOOP_FORWARD
	mus.loop_begin = 0
	mus.loop_end = mus.data.size() / 2
	music.stream = mus
	music.volume_db = MUSIC_MENU_DB
	add_child(music)
	set_muted(bool(Game.profile.get("mute", false)))
	if not Game.testing:
		music.play()


## Efecto de sonido. pitch_var agrega una variación al azar del tono para que no suene siempre igual
func play(id: String, db := 0.0, pitch := 1.0, pitch_var := 0.06) -> void:
	if muted or not streams.has(id):
		return
	for p in pool:
		if not p.playing:
			p.stream = streams[id]
			p.volume_db = db + float(VOL.get(id, 0.0))
			p.pitch_scale = pitch * randf_range(1.0 - pitch_var, 1.0 + pitch_var)
			p.play()
			return


## Balbuceo tipo videojuego: encadena sílabas al azar de una voz. Si se pasa "at" (un personaje),
## suena desde su lugar en el colectivo (más lejos = más bajito).
func babble(voice: String, syllables: int, pitch := 1.0, db := 0.0, at: Node3D = null, gap := 0.11) -> void:
	if muted or not voices.has(voice):
		return
	var player: Node = null
	if at != null:
		player = at.get_node_or_null("Voz")
		if player == null:
			var p3 := AudioStreamPlayer3D.new()
			p3.name = "Voz"
			p3.position = Vector3(0, 1.6, 0)
			p3.unit_size = 4.0
			p3.max_polyphony = 2
			at.add_child(p3)
			player = p3
	for i in syllables:
		var p = player
		if p == null:
			p = _free_player()
		if p == null or muted or not is_instance_valid(p):
			return
		p.stream = voices[voice].pick_random()
		p.pitch_scale = pitch * randf_range(0.9, 1.12)
		p.volume_db = db
		p.play()
		await get_tree().create_timer(gap * randf_range(0.8, 1.3)).timeout


func _free_player() -> AudioStreamPlayer:
	for p in pool:
		if not p.playing:
			return p
	return null


## Prende o apaga el motor del colectivo (suena de fondo durante el viaje)
func set_engine(on: bool) -> void:
	if on and not engine.playing and not muted:
		engine.play()
	elif not on:
		engine.stop()


## El motor acelera y frena con el colectivo: 0 = parado, 1 = andando normal
func engine_speed(v: float) -> void:
	engine.pitch_scale = lerpf(0.75, 1.15, clampf(v, 0.0, 1.0))


## En el viaje la música baja para que se escuchen los eventos
func music_for_trip(trip: bool) -> void:
	var tw := create_tween()
	tw.tween_property(music, "volume_db", MUSIC_TRIP_DB if trip else MUSIC_MENU_DB, 0.6)


func set_muted(m: bool) -> void:
	muted = m
	Game.profile["mute"] = m
	AudioServer.set_bus_mute(0, m)
	if m:
		engine.stop()
