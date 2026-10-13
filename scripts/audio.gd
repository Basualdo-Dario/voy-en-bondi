extends Node
## Sonido del juego (autoload "Audio"): efectos, música de fondo y el ambiente del colectivo
## (motor y gente hablando bajito). Los sonidos están en assets/audio/ (ver CREDITOS.md).
## Se usa así: Audio.play("coins").

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
const CROWD_DB := -16.0          # murmullo de la gente en el viaje (sube y baja un poco)

var streams := {}
var pool: Array[AudioStreamPlayer] = []
var music := AudioStreamPlayer.new()
var engine := AudioStreamPlayer.new()
var crowd := AudioStreamPlayer.new()
var muted := false
var _t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for id in SFX:
		streams[id] = load(DIR + id + ".ogg")
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)
	engine.stream = _loop_ogg("engine")
	engine.volume_db = VOL["engine"]
	add_child(engine)
	# La gente suena "apagada", como desde los asientos: va por un canal con filtro de agudos
	var bus := AudioServer.bus_count
	AudioServer.add_bus(bus)
	AudioServer.set_bus_name(bus, "Gente")
	var lp := AudioEffectLowPassFilter.new()
	lp.cutoff_hz = 1800.0
	AudioServer.add_bus_effect(bus, lp)
	crowd.stream = _loop_ogg("crowd")
	crowd.bus = "Gente"
	crowd.volume_db = CROWD_DB
	add_child(crowd)
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


func _loop_ogg(id: String) -> AudioStreamOggVorbis:
	var s: AudioStreamOggVorbis = load(DIR + id + ".ogg")
	s.loop = true
	return s


func _process(delta: float) -> void:
	# El murmullo sube y baja despacio, como cuando la gente charla más o menos
	_t += delta
	crowd.volume_db = CROWD_DB + sin(_t * 0.23) * 2.5 + sin(_t * 0.61) * 1.5


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


## Prende o apaga el ambiente del colectivo (motor y gente) que suena durante el viaje
func set_engine(on: bool) -> void:
	if on and not engine.playing and not muted:
		engine.play()
		# El murmullo arranca en un punto al azar para que no empiece siempre igual
		crowd.play(randf() * crowd.stream.get_length() * 0.8)
	elif not on:
		engine.stop()
		crowd.stop()


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
		crowd.stop()
