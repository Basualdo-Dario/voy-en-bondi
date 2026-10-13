extends SceneTree
## Genera la música de fondo (cumbia chiptune en loop) y la guarda en assets/audio/music_cumbia.wav.
## Se corre una sola vez, cuando se quiere cambiar la música:
##   godot --headless --path . -s res://tools/make_music.gd
## Todo sale de este script (sin samples de nadie), así que no hay temas de licencia.

const SR := 22050
const BPM := 96.0
const OUT := "res://assets/audio/music_cumbia.wav"

var beat := 60.0 / BPM
var buf := PackedFloat32Array()
var rng := RandomNumberGenerator.new()

# Un acorde por compás: La menor, La menor, Sol, Sol, Fa, Fa, Mi, Mi
const ROOTS := [45, 45, 43, 43, 41, 41, 40, 40]
const CHORDS := [[57, 60, 64], [57, 60, 64], [55, 59, 62], [55, 59, 62], [53, 57, 60], [53, 57, 60], [52, 56, 59], [52, 56, 59]]
# Melodía: [nota midi, tiempo dentro del compás, duración en tiempos]
const MELODY := [
	[[76, 0, 1], [74, 1, .5], [72, 1.5, .5], [71, 2, .5], [72, 2.5, 1.5]],
	[[69, 0, 1.5], [72, 1.5, .5], [76, 2, 1], [74, 3, 1]],
	[[74, 0, 1], [72, 1, .5], [71, 1.5, .5], [67, 2, .5], [71, 2.5, 1.5]],
	[[74, 0, 1.5], [71, 1.5, .5], [67, 2, 2]],
	[[72, 0, 1], [69, 1, .5], [72, 1.5, .5], [77, 2, 1], [76, 3, 1]],
	[[74, 0, .5], [72, .5, .5], [69, 1, 1], [65, 2, 2]],
	[[71, 0, 1], [68, 1, .5], [71, 1.5, .5], [74, 2, 1], [72, 3, 1]],
	[[71, 0, 1.5], [69, 1.5, .5], [68, 2, 2]],
]


func _initialize() -> void:
	rng.seed = 42
	var bars := ROOTS.size()
	buf.resize(int(bars * 4 * beat * SR))
	buf.fill(0.0)
	for bar in bars:
		var t0 := bar * 4 * beat
		var root: int = ROOTS[bar]
		# Bajo: fundamental en el 1, quinta en el 3 y un pique antes del compás siguiente
		_tone(t0, beat * .45, _hz(root), .42, "tri")
		_tone(t0 + 2 * beat, beat * .45, _hz(root + 7), .38, "tri")
		_tone(t0 + 3.5 * beat, beat * .3, _hz(root), .3, "tri")
		for b in 4:
			var tb := t0 + b * beat
			# Acordes en contratiempo (el "chiqui" de la cumbia)
			for n in CHORDS[bar]:
				_tone(tb + beat * .5, beat * .2, _hz(n), .045, "square")
			# Guacharaca: raspado largo en el tiempo y dos cortitos
			_scrape(tb, beat * .24, .2)
			_scrape(tb + beat * .5, beat * .12, .12)
			_scrape(tb + beat * .75, beat * .12, .14)
		# Bombo suave en 1 y 3, tambora en el "y" del 2 y en el 4
		_drum(t0, 95, 50, .14, .38)
		_drum(t0 + 2 * beat, 95, 50, .14, .3)
		_drum(t0 + 1.5 * beat, 190, 130, .12, .28)
		_drum(t0 + 3 * beat, 230, 160, .1, .24)
		_drum(t0 + 3.75 * beat, 260, 190, .08, .18)
		# Melodía chiptune
		for m in MELODY[bar]:
			_tone(t0 + float(m[1]) * beat, float(m[2]) * beat * .92, _hz(int(m[0])), .11, "lead")
	_save()
	quit()


func _hz(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


## Nota con envolvente corta de ataque y caída. wave: tri, square o lead (cuadrada finita con vibrato)
func _tone(start: float, dur: float, hz: float, amp: float, wave: String) -> void:
	var i0 := int(start * SR)
	var n := int((dur + .05) * SR)
	var phase := 0.0
	for k in n:
		var i := i0 + k
		if i >= buf.size():
			break
		var t := float(k) / SR
		var f := hz
		if wave == "lead" and t > .12:
			f *= 1.0 + .006 * sin(TAU * 5.5 * t)
		phase = fmod(phase + f / SR, 1.0)
		var s := 0.0
		match wave:
			"tri":
				s = 4.0 * absf(phase - .5) - 1.0
			"square":
				s = 1.0 if phase < .5 else -1.0
			"lead":
				s = 1.0 if phase < .25 else -1.0
		var env := minf(1.0, t / .008)
		if t > dur:
			env *= maxf(0.0, 1.0 - (t - dur) / .05)
		elif wave == "square":
			env *= exp(-t * 14.0)
		elif wave == "tri":
			env *= exp(-t * 3.0)
		buf[i] += s * amp * env


## Raspado de guacharaca: ruido agudo cortado en dientitos
func _scrape(start: float, dur: float, amp: float) -> void:
	var i0 := int(start * SR)
	var prev := 0.0
	for k in int(dur * SR):
		var i := i0 + k
		if i >= buf.size():
			break
		var t := float(k) / SR
		var nz := rng.randf_range(-1.0, 1.0)
		var hp := nz - prev
		prev = nz
		var teeth := .55 + .45 * signf(sin(TAU * 110.0 * t))
		var env := minf(1.0, t / .004) * (1.0 - t / dur)
		buf[i] += hp * .5 * amp * teeth * env


## Golpe de parche: seno que baja de tono y se apaga rápido
func _drum(start: float, hz0: float, hz1: float, dur: float, amp: float) -> void:
	var i0 := int(start * SR)
	var phase := 0.0
	for k in int(dur * SR):
		var i := i0 + k
		if i >= buf.size():
			break
		var t := float(k) / SR
		var f := lerpf(hz0, hz1, t / dur)
		phase += f / SR
		buf[i] += sin(TAU * phase) * amp * exp(-t * 22.0)


func _save() -> void:
	var peak := 0.0
	for s in buf:
		peak = maxf(peak, absf(s))
	var gain := 0.85 / maxf(peak, 0.001)
	var data := PackedByteArray()
	data.resize(buf.size() * 2)
	for i in buf.size():
		data.encode_s16(i * 2, int(clampf(buf[i] * gain, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SR
	wav.stereo = false
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = buf.size()
	var err := wav.save_to_wav(ProjectSettings.globalize_path(OUT))
	print("Música guardada en %s (%.1f s, error=%d)" % [OUT, float(buf.size()) / SR, err])
