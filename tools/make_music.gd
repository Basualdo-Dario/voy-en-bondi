extends SceneTree
## Genera la música de fondo (cumbia villera instrumental en loop) y la guarda en assets/audio/music_cumbia.wav.
## Se corre una sola vez, cuando se quiere cambiar la música:
##   godot --headless --path . -s res://tools/make_music.gd
## Todo sale de este script (sin samples de nadie), así que no hay temas de licencia.
##
## Lo que la hace "villera": el teclado berreta (dos sierras desafinadas, con vibrato y deslizando
## de nota a nota) tocando un riff que se repite, la guacharaca bien al frente, timbales con redobles
## y el bajo marcando el 1 y el 3.

const SR := 22050
const BPM := 100.0
const OUT := "res://assets/audio/music_cumbia.wav"

var beat := 60.0 / BPM
var buf := PackedFloat32Array()
var rng := RandomNumberGenerator.new()

# 16 compases: parte A (el riff) y parte B (la melodía que sube). Un acorde por compás.
const ROOTS := [45, 45, 43, 43, 45, 45, 40, 40, 41, 41, 43, 43, 45, 45, 40, 40]
const CHORDS := {45: [57, 60, 64], 43: [55, 59, 62], 41: [53, 57, 60], 40: [52, 56, 59]}
# Teclado: [nota midi, tiempo dentro del compás, duración en tiempos]
const LEAD := [
	# A: Lam
	[[76, 0, .5], [76, .5, .5], [74, 1, .5], [72, 1.5, .5], [74, 2, .75], [72, 2.75, .25], [69, 3, 1]],
	[[72, 0, .5], [74, .5, .5], [76, 1, 1], [79, 2, .5], [76, 2.5, .5], [74, 3, 1]],
	# A: Sol
	[[74, 0, .5], [74, .5, .5], [72, 1, .5], [71, 1.5, .5], [72, 2, .75], [71, 2.75, .25], [67, 3, 1]],
	[[71, 0, .5], [72, .5, .5], [74, 1, 1], [79, 2, .5], [74, 2.5, .5], [71, 3, 1]],
	# A: Lam otra vez
	[[76, 0, .5], [76, .5, .5], [74, 1, .5], [72, 1.5, .5], [74, 2, .75], [72, 2.75, .25], [69, 3, 1]],
	[[72, 0, .5], [74, .5, .5], [76, 1, 1], [81, 2, .5], [79, 2.5, .5], [76, 3, 1]],
	# A: Mi
	[[71, 0, .5], [72, .5, .5], [71, 1, .5], [68, 1.5, .5], [71, 2, 1], [74, 3, 1]],
	[[76, 0, 2], [74, 2, .5], [72, 2.5, .5], [71, 3, 1]],
	# B: Fa
	[[72, 0, 1], [69, 1, .5], [72, 1.5, .5], [77, 2, 1.5], [76, 3.5, .5]],
	[[74, 0, .5], [72, .5, .5], [69, 1, 2]],
	# B: Sol
	[[74, 0, 1], [71, 1, .5], [74, 1.5, .5], [79, 2, 1.5], [77, 3.5, .5]],
	[[76, 0, .5], [74, .5, .5], [71, 1, 2]],
	# B: Lam
	[[76, 0, .5], [76, .5, .5], [77, 1, .5], [76, 1.5, .5], [74, 2, .5], [72, 2.5, .5], [74, 3, 1]],
	[[72, 0, .5], [71, .5, .5], [69, 1, 2]],
	# B: Mi (vuelve al principio)
	[[68, 0, .5], [71, .5, .5], [74, 1, .5], [76, 1.5, .5], [77, 2, 1], [76, 3, 1]],
	[[76, 0, 1.5], [74, 1.5, .5], [71, 2, 1], [68, 3, 1]],
]


func _initialize() -> void:
	rng.seed = 7
	var bars := ROOTS.size()
	buf.resize(int(bars * 4 * beat * SR))
	buf.fill(0.0)
	for bar in bars:
		var t0 := bar * 4 * beat
		var root: int = ROOTS[bar]
		# Bajo: 1 y 3, con un pique de corchea antes del compás siguiente
		_bass(t0, beat * .5, root, .4)
		_bass(t0 + 1.5 * beat, beat * .3, root, .22)
		_bass(t0 + 2 * beat, beat * .5, root + 7, .36)
		_bass(t0 + 3.5 * beat, beat * .3, root + 12, .25)
		for b in 4:
			var tb := t0 + b * beat
			# Teclado acompañando en contratiempo
			for n in CHORDS[root]:
				_saw(tb + beat * .5, beat * .18, n, .028, false)
			# Guacharaca al frente: raspado largo y dos cortitos (chiqui-chiqui)
			_scrape(tb, beat * .26, .3)
			_scrape(tb + beat * .5, beat * .1, .17)
			_scrape(tb + beat * .75, beat * .14, .22)
			# Cencerro suave en cada tiempo
			_bell(tb, .05 if b % 2 == 0 else .035)
		# Bombo en 1 y 3; timbal en el "y" del 2 y en el 4
		_drum(t0, 100, 48, .16, .45)
		_drum(t0 + 2 * beat, 100, 48, .16, .38)
		_timbal(t0 + 1.5 * beat, 520, .22)
		_timbal(t0 + 3 * beat, 430, .26)
		# Redoble de timbales al final de cada parte
		if bar % 8 == 7:
			for k in 8:
				_timbal(t0 + (2 + k * .25) * beat, 560 if k % 2 == 0 else 440, .12 + k * .02)
		# El teclado villero
		for m in LEAD[bar]:
			_saw(t0 + float(m[1]) * beat, float(m[2]) * beat * .95, int(m[0]), .1, true)
	_save()
	quit()


func _hz(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


## Teclado: dos sierras un poquito desafinadas. lead = vibrato y entrada deslizando desde abajo
func _saw(start: float, dur: float, midi: int, amp: float, lead: bool) -> void:
	var i0 := int(start * SR)
	var rel := .06
	var n := int((dur + rel) * SR)
	var ph1 := 0.0
	var ph2 := 0.0
	for k in n:
		var i := i0 + k
		if i >= buf.size():
			break
		var t := float(k) / SR
		var m := float(midi)
		if lead:
			m -= 1.0 * maxf(0.0, 1.0 - t / .05)          # desliza hasta la nota
			if t > .1:
				m += .28 * sin(TAU * 6.0 * t)            # vibrato de teclado berreta
		var f := _hz(m)
		ph1 = fmod(ph1 + f * 1.004 / SR, 1.0)
		ph2 = fmod(ph2 + f * 0.996 / SR, 1.0)
		var s := (ph1 * 2.0 - 1.0) + (ph2 * 2.0 - 1.0)
		if lead:
			s += .6 * (1.0 if fmod(ph1 * 2.0, 1.0) < .5 else -1.0)   # una octava arriba, más "chillón"
		var env := minf(1.0, t / .006)
		if t > dur:
			env *= maxf(0.0, 1.0 - (t - dur) / rel)
		elif not lead:
			env *= exp(-t * 16.0)
		buf[i] += s * .5 * amp * env


func _bass(start: float, dur: float, midi: int, amp: float) -> void:
	var i0 := int(start * SR)
	var ph := 0.0
	var f := _hz(midi)
	for k in int((dur + .04) * SR):
		var i := i0 + k
		if i >= buf.size():
			break
		var t := float(k) / SR
		ph = fmod(ph + f / SR, 1.0)
		var tri := 4.0 * absf(ph - .5) - 1.0
		var sq := 1.0 if ph < .5 else -1.0
		var env := minf(1.0, t / .005) * exp(-t * 2.5)
		if t > dur:
			env *= maxf(0.0, 1.0 - (t - dur) / .04)
		buf[i] += (tri * .8 + sq * .2) * amp * env


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
		var teeth := .5 + .5 * signf(sin(TAU * 120.0 * t))
		var env := minf(1.0, t / .004) * (1.0 - t / dur)
		buf[i] += hp * .5 * amp * teeth * env


## Golpe de parche grave (bombo): seno que baja de tono
func _drum(start: float, hz0: float, hz1: float, dur: float, amp: float) -> void:
	var i0 := int(start * SR)
	var ph := 0.0
	for k in int(dur * SR):
		var i := i0 + k
		if i >= buf.size():
			break
		var t := float(k) / SR
		ph += lerpf(hz0, hz1, t / dur) / SR
		buf[i] += sin(TAU * ph) * amp * exp(-t * 20.0)


## Timbal: parche agudo con un poco de ruido metálico
func _timbal(start: float, hz: float, amp: float) -> void:
	var i0 := int(start * SR)
	var ph := 0.0
	for k in int(.18 * SR):
		var i := i0 + k
		if i >= buf.size():
			break
		var t := float(k) / SR
		ph += hz * (1.0 - t * .6) / SR
		var s := sin(TAU * ph) * .8 + rng.randf_range(-1.0, 1.0) * .35 * exp(-t * 60.0)
		buf[i] += s * amp * exp(-t * 18.0)


## Cencerro: dos tonos cuadrados que no combinan del todo
func _bell(start: float, amp: float) -> void:
	var i0 := int(start * SR)
	var p1 := 0.0
	var p2 := 0.0
	for k in int(.09 * SR):
		var i := i0 + k
		if i >= buf.size():
			break
		var t := float(k) / SR
		p1 = fmod(p1 + 560.0 / SR, 1.0)
		p2 = fmod(p2 + 845.0 / SR, 1.0)
		var s := (1.0 if p1 < .5 else -1.0) + (1.0 if p2 < .5 else -1.0)
		buf[i] += s * .5 * amp * exp(-t * 35.0)


func _save() -> void:
	# Un poco de saturación suave para que suene "pegado", como grabado de un teclado
	var peak := 0.0
	for i in buf.size():
		buf[i] = tanh(buf[i] * 1.4)
		peak = maxf(peak, absf(buf[i]))
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
