extends Node
## Estado global del juego: progreso del jugador, guardado y reglas de economía.
## Se carga solo (autoload "Game"), así que desde cualquier script se usa como Game.profile, Game.save(), etc.

const SAVE_PATH := "user://save.json"

# Vergüenza que suma cada falla (antes de aplicar la habilidad de resistencia)
const SHAME := {
	"caer": 32, "robo": 32, "vomito": 36, "visto": 36, "dormir": 36, "desmayo": 40,
}

const TRIP_SECONDS := 75.0

const TRIPS := [
	{"from": "Casa", "to": "Trabajo"},
	{"from": "Trabajo", "to": "Facu"},
	{"from": "Facu", "to": "Gym"},
	{"from": "Gym", "to": "Casa"},
]

const DAYS := ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes"]

# ---------- Modo historia: capítulos y barrios ----------
# Cada barrio es una semana (5 días) con su línea de colectivo. Al terminarlo te llevás su camiseta y monedas.
const BARRIO_COINS := 200
const CHAPTER_COINS := 500

const CHAPTERS := [
	{
		"title": "La moto", "goal": "Juntar para la moto y dejar el bondi",
		"intro": "Estás harto del bondi: apretado, con olor a gym y el choro de siempre. Decidiste juntar para una moto. Cuatro barrios, cuatro semanas de viaje… y chau colectivo.",
		"end_title": "¡La moto!",
		"end": "Te la compraste: roja, brillante, tuya. Primer día: arranca, hace dos cuadras, tose y se apaga para siempre. El mecánico dice que el arreglo sale más que la moto. Volvés a la parada y el chofer te saluda: \"Te extrañábamos\".",
	},
	{
		"title": "Mudarse cerca", "goal": "Mudarte cerca del laburo para no viajar más",
		"intro": "Plan B: si no podés esquivar el bondi, acercate al laburo. Hay que juntar para el depósito, el mes adelantado y la comisión de la inmobiliaria. Sí, todo eso.",
		"end_title": "¡Te mudaste!",
		"end": "Depto nuevo a diez cuadras del laburo. El primer lunes te llega un mail: \"Por reestructuración, te trasladamos a la sede de la otra punta de la ciudad\". Dos colectivos de ida y dos de vuelta. El bondi siempre gana.",
	},
]

## "night" cambia el cielo y las luces. "prize" es la camiseta que ganás al terminar el barrio.
const BARRIOS := [
	{"name": "Villa Parada", "line": "42", "color": "f2b705", "sky": "9fd3f0", "night": false, "prize": "p_parada",
		"intro": "Tu barrio de toda la vida. La 42 pasa cuando quiere, pero pasa. Arrancamos tranqui."},
	{"name": "Barrio Ramal", "line": "17", "color": "3fae5a", "sky": "a8dcc8", "night": false, "prize": "p_ramal",
		"intro": "Te cambiaron el turno y ahora tomás la 17. Viene un poco más llena y el chofer frena como si le debieran plata."},
	{"name": "El Centro", "line": "101", "color": "d64541", "sky": "c9d6e3", "night": false, "prize": "p_centro",
		"intro": "Hora pico en el Centro. La 101 viene tan llena que el chofer cobra por centímetro."},
	{"name": "La Costanera", "line": "5", "color": "4fb3e8", "sky": "1d2b4f", "night": true, "prize": "p_costa",
		"intro": "Última semana antes de la moto. La 5 de noche por la Costanera: lindo paisaje, viaje largo."},
	{"name": "Villa Trasbordo", "line": "33", "color": "f28c28", "sky": "f6d9a8", "night": false, "prize": "p_trasb",
		"intro": "Para ver departamentos tenés que combinar dos colectivos. Bienvenido a Villa Trasbordo."},
	{"name": "Barrio Terminal", "line": "88", "color": "9b2c4a", "sky": "b9c7d6", "night": false, "prize": "p_term",
		"intro": "Acá terminan todas las líneas. Y todos los pasajeros también, parece."},
	{"name": "Las Torres", "line": "214", "color": "7e57c2", "sky": "d6c9ef", "night": false, "prize": "p_torres",
		"intro": "El depto ideal queda en Las Torres, a diez cuadras del laburo. Ya casi."},
	{"name": "Barrio Nuevo", "line": "9", "color": "e0457b", "sky": "2a2440", "night": true, "prize": "p_nuevo",
		"intro": "Semana de mudanza. Viajás con una lámpara de pie en la mano. Nadie te mira raro. Bueno, todos."},
]
const BARRIOS_PER_CHAPTER := 4
const LIBRE_TEXT := "Terminaste la historia (por ahora). Seguís viajando por Barrio Nuevo con la dificultad al máximo. Se viene el capítulo 3…"

const ITEMS := [
	{"id": "cafe", "name": "Café", "price": 30, "lim": 2, "desc": "En el sueño te despierta al instante."},
	{"id": "perf", "name": "Perfume", "price": 40, "lim": 3, "desc": "3 segundos para respirar al lado del oloroso."},
	{"id": "lock", "name": "Candado", "price": 50, "lim": 2, "desc": "El choro se va con las manos vacías."},
	{"id": "bill", "name": "Billetera", "price": 35, "lim": 2, "desc": "Le comprás algo barato al vendedor y se va."},
]

const SKILLS := [
	{"id": "pulmones", "name": "Capacidad pulmonar"},
	{"id": "fuerza", "name": "Fuerza"},
	{"id": "verguenza", "name": "Resistencia a la vergüenza"},
]
const MAX_LEVEL := 5

## Camisetas de clubes de barrio inventados (sin clubes reales: sus marcas necesitan licencia)
const SKINS := [
	{"id": "buzo", "name": "Buzo azul", "price": 0, "sleeve": "2f6fd6", "pattern": "plain", "c1": "2f6fd6", "c2": "2861be"},
	{"id": "parada", "name": "Deportivo La Parada", "price": 300, "sleeve": "f28c28", "pattern": "band", "c1": "f28c28", "c2": "1b2430"},
	{"id": "linea42", "name": "Sportivo Línea 42", "price": 450, "sleeve": "6e3fb8", "pattern": "vstripes", "c1": "6e3fb8", "c2": "f2d33a"},
	{"id": "ramal", "name": "Atlético Ramal 5", "price": 600, "sleeve": "2bb3a3", "pattern": "sash", "c1": "2bb3a3", "c2": "7a2633"},
	{"id": "colect", "name": "Social Colectiveros", "price": 700, "sleeve": "c2362b", "pattern": "checks", "c1": "c2362b", "c2": "1b2430"},
	{"id": "pasaj", "name": "Unión Pasajeros", "price": 800, "sleeve": "f2b705", "pattern": "halves", "c1": "f2b705", "c2": "4a5568"},
	{"id": "boleto", "name": "Juventud Boleto", "price": 1000, "sleeve": "1f2f5a", "pattern": "hoops", "c1": "1f2f5a", "c2": "f28c28"},
	# Premios: no se compran, se ganan al terminar cada barrio ("prize" = índice del barrio)
	{"id": "p_parada", "name": "Villa Parada Juniors", "price": 0, "prize": 0, "sleeve": "f2b705", "pattern": "band", "c1": "f2b705", "c2": "1b2430"},
	{"id": "p_ramal", "name": "Ramal Fútbol Club", "price": 0, "prize": 1, "sleeve": "3fae5a", "pattern": "vstripes", "c1": "3fae5a", "c2": "f4f4f0"},
	{"id": "p_centro", "name": "Centro Hora Pico", "price": 0, "prize": 2, "sleeve": "d64541", "pattern": "halves", "c1": "d64541", "c2": "1b2430"},
	{"id": "p_costa", "name": "Costanera Nocturna", "price": 0, "prize": 3, "sleeve": "1f2f5a", "pattern": "hoops", "c1": "1f2f5a", "c2": "4fb3e8"},
	{"id": "p_trasb", "name": "Trasbordo Atlético", "price": 0, "prize": 4, "sleeve": "f28c28", "pattern": "sash", "c1": "f4f4f0", "c2": "f28c28"},
	{"id": "p_term", "name": "Terminal Sporting", "price": 0, "prize": 5, "sleeve": "9b2c4a", "pattern": "checks", "c1": "9b2c4a", "c2": "f2d33a"},
	{"id": "p_torres", "name": "Torres Unidas", "price": 0, "prize": 6, "sleeve": "7e57c2", "pattern": "vstripes", "c1": "7e57c2", "c2": "1b2430"},
	{"id": "p_nuevo", "name": "Barrio Nuevo Mudanzas", "price": 0, "prize": 7, "sleeve": "e0457b", "pattern": "band", "c1": "e0457b", "c2": "f4f4f0"},
]

var profile: Dictionary = {}
## En las pruebas automáticas (--autotest, --shot) se juega con una partida en memoria que no se guarda
var testing := false
## Letras del juego: Fredoka (licencia OFL, ver assets/fonts/OFL.txt)
var font: Font
var font_bold: Font


func _ready() -> void:
	_load_fonts()
	var args := OS.get_cmdline_user_args()
	testing = "--autotest" in args or Array(args).any(func(a): return a.begins_with("--shot"))
	if testing:
		profile = fresh_profile()
		if "--demo" in args:
			# Partida a mitad de semana, para revisar el diseño en las capturas
			profile.merge({"coins": 520, "barrio": 1, "day": 1, "trip": 2, "results": ["ok", "fail"], "tut_done": true,
				"owned": {"buzo": true, "p_parada": true}, "story_seen": {"cap0_intro": true, "barrio0": true, "barrio1": true}}, true)
		# --set=barrio:3,day:4,trip:3 pone esos números en la partida de prueba
		for a in args:
			if a.begins_with("--set="):
				for kv in a.substr(6).split(","):
					profile[kv.get_slice(":", 0)] = int(kv.get_slice(":", 1))
	else:
		load_profile()


func _load_fonts() -> void:
	var base: FontFile = load("res://assets/fonts/Fredoka.ttf")
	var system_fallback := ThemeDB.fallback_font  # para símbolos que Fredoka no tiene (✓, ✗)
	base.fallbacks = [system_fallback]
	font = _weight(base, 500)
	font_bold = _weight(base, 650)
	ThemeDB.fallback_font = font
	ThemeDB.get_default_theme().default_font = font


func _weight(base: Font, w: int) -> FontVariation:
	var f := FontVariation.new()
	f.base_font = base
	f.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): w}
	return f


func fresh_profile() -> Dictionary:
	return {
		"coins": 200,
		"owned": {"buzo": true},
		"eq": "buzo",
		"skills": {"pulmones": 0, "fuerza": 0, "verguenza": 0},
		"inv": {"cafe": 2, "lock": 1, "perf": 3, "bill": 1},
		"used": {"cafe": 0, "lock": 0, "perf": 0, "bill": 0},
		"barrio": 0,           # barrio actual del modo historia (llega a BARRIOS.size() al terminar todo)
		"day": 0,              # día de la semana dentro del barrio (0 = lunes)
		"trip": 0,
		"results": [],
		"tut_seen": {},
		"tut_done": false,
		"story_seen": {},      # carteles de historia ya mostrados
		"story_queue": [],     # carteles pendientes (finales de barrio y capítulo)
		"settings": DEFAULT_SETTINGS.duplicate(),
	}


# ---------- Configuración (pantalla del engranaje) ----------

const DEFAULT_SETTINGS := {
	"lang": "es",        # "es" o "en"
	"music": 0.8,        # volumen de la música (0 a 1)
	"sfx": 0.9,          # volumen de efectos y ambiente (0 a 1)
	"mute": false,
	"tilt": true,        # controlar el equilibrio inclinando el celular
	"tilt_sens": 1.0,    # sensibilidad de la inclinación (0,5 a 2)
	"vibra": true,       # vibrar al caerte, en frenadas y robos
}


func setting(key: String):
	return profile["settings"].get(key, DEFAULT_SETTINGS[key])


func set_setting(key: String, value) -> void:
	profile["settings"][key] = value
	save()


## Vibración corta del celular (si está prendida en configuración)
func vibrate(ms: int) -> void:
	if setting("vibra") and not testing:
		Input.vibrate_handheld(ms)


# ---------- Viaje de práctica (tutorial desde configuración) ----------
# Se juega con una copia de la partida: al volver al menú se restaura la de verdad y no se guarda nada.

var practice := false
var _saved_profile := {}


func start_practice() -> void:
	_saved_profile = profile.duplicate(true)
	practice = true
	profile["barrio"] = 0
	profile["day"] = 0
	profile["trip"] = 0
	profile["tut_seen"] = {}
	profile["tut_done"] = false
	# Para probar los ítems: de todos, hasta el límite del día
	for it in ITEMS:
		profile["inv"][it["id"]] = it["lim"]
		profile["used"][it["id"]] = 0


func end_practice() -> void:
	if not practice:
		return
	var st: Dictionary = profile["settings"]   # lo que se cambió en la pausa (sonido) se conserva
	profile = _saved_profile
	profile["settings"] = st
	_saved_profile = {}
	practice = false


func load_profile() -> void:
	profile = fresh_profile()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) == TYPE_DICTIONARY:
		for k in data.keys():
			profile[k] = data[k]
	# JSON guarda los números como float: los pasamos a int donde corresponde
	profile["coins"] = int(profile["coins"])
	profile["barrio"] = int(profile["barrio"])
	# Las partidas de antes del modo historia contaban los días sin tope: quedan en el barrio 1
	profile["day"] = int(profile["day"]) % 5
	profile["trip"] = int(profile["trip"])
	for group in ["skills", "inv", "used"]:
		for k in profile[group].keys():
			profile[group][k] = int(profile[group][k])
	# Configuración: completar lo que falte (partidas viejas guardaban "mute" suelto)
	var st: Dictionary = DEFAULT_SETTINGS.duplicate()
	if typeof(profile.get("settings")) == TYPE_DICTIONARY:
		st.merge(profile["settings"], true)
	if profile.has("mute"):
		st["mute"] = bool(profile["mute"])
		profile.erase("mute")
	profile["settings"] = st


func save() -> void:
	if testing or practice:
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(profile))


## Borra el progreso y empieza de cero (la configuración se mantiene)
func reset_progress() -> void:
	var st: Dictionary = profile["settings"].duplicate()
	profile = fresh_profile()
	profile["settings"] = st
	save()


# ---------- Reglas que dependen del progreso ----------

## Segundos que se aguanta la respiración (3 s base + 1,5 s por nivel de pulmones)
func lung_secs() -> float:
	return 3.0 + profile["skills"]["pulmones"] * 1.5


## Multiplicador de vergüenza (cada nivel de resistencia resta 8 %)
func shame_mult() -> float:
	return 1.0 - profile["skills"]["verguenza"] * 0.08


## Cuánto menos te mueven las frenadas (cada nivel de fuerza resta 10 %)
func strength_mult() -> float:
	return 1.0 - profile["skills"]["fuerza"] * 0.1


## Dificultad: sube medio punto por barrio y un cuarto por día de la semana (0 el primer lunes, 5 en el modo libre)
func diff() -> float:
	if story_done():
		return 5.0
	return minf(5.0, barrio_index() * 0.5 + int(profile["day"]) * 0.25)


func day_name() -> String:
	return DAYS[int(profile["day"]) % 5]


## El primer día de todos: el bamboleo y las frenadas arrancan más suaves
func first_day() -> bool:
	return barrio_index() == 0 and int(profile["day"]) == 0


# ---------- Modo historia ----------

## Terminaste los 8 barrios: se sigue jugando el último en modo libre
func story_done() -> bool:
	return int(profile["barrio"]) >= BARRIOS.size()


## Barrio que se está jugando (en el modo libre, el último)
func barrio_index() -> int:
	return mini(int(profile["barrio"]), BARRIOS.size() - 1)


func barrio() -> Dictionary:
	return BARRIOS[barrio_index()]


func chapter_index(b := -1) -> int:
	return (barrio_index() if b < 0 else b) / BARRIOS_PER_CHAPTER


## Barrios terminados dentro de un capítulo (0 a 4)
func chapter_progress(ch: int) -> int:
	return clampi(int(profile["barrio"]) - ch * BARRIOS_PER_CHAPTER, 0, BARRIOS_PER_CHAPTER)


## Se terminó la semana del barrio: premio, cartel de historia y al barrio siguiente.
## Devuelve las filas extra para el cartel de fin de viaje.
func complete_week() -> Array:
	var rows := []
	if story_done():
		return rows
	var b := int(profile["barrio"])
	var prize: String = BARRIOS[b]["prize"]
	profile["owned"][prize] = true
	profile["coins"] += BARRIO_COINS
	rows.append(["¡Terminaste %s!" % BARRIOS[b]["name"], "+%d" % BARRIO_COINS])
	rows.append(["Camiseta nueva", skin(prize)["name"]])
	profile["story_queue"].append("barrio_end:%d" % b)
	if (b + 1) % BARRIOS_PER_CHAPTER == 0:
		profile["coins"] += CHAPTER_COINS
		rows.append(["¡Capítulo terminado!", "+%d" % CHAPTER_COINS])
		profile["story_queue"].append("cap_end:%d" % (b / BARRIOS_PER_CHAPTER))
	profile["barrio"] = b + 1
	return rows


## Próximo cartel de historia para mostrar en el menú ("" si no hay ninguno)
func next_story() -> String:
	var q: Array = profile["story_queue"]
	if q.size() > 0:
		return q[0]
	if story_done():
		return "" if profile["story_seen"].get("libre", false) else "libre"
	var ch := chapter_index()
	if not profile["story_seen"].get("cap%d_intro" % ch, false):
		return "cap_intro:%d" % ch
	if not profile["story_seen"].get("barrio%d" % barrio_index(), false):
		return "barrio_intro:%d" % barrio_index()
	return ""


func mark_story(key: String) -> void:
	var q: Array = profile["story_queue"]
	if q.size() > 0 and q[0] == key:
		q.pop_front()
	match key.get_slice(":", 0):
		"cap_intro":
			profile["story_seen"]["cap%s_intro" % key.get_slice(":", 1)] = true
		"barrio_intro":
			profile["story_seen"]["barrio%s" % key.get_slice(":", 1)] = true
		"libre":
			profile["story_seen"]["libre"] = true
	save()


## Ítems disponibles para este viaje: lo que hay en la mochila, sin pasar el límite diario
func trip_items() -> Dictionary:
	var out := {}
	for it in ITEMS:
		var id: String = it["id"]
		var left_today: int = int(it["lim"]) - int(profile["used"].get(id, 0))
		out[id] = maxi(0, mini(int(profile["inv"].get(id, 0)), left_today))
	return out


func skill_level(id: String) -> int:
	return int(profile["skills"].get(id, 0))


## Precio del próximo nivel: 150 × el nivel al que subís
func skill_cost(id: String) -> int:
	return 150 * (skill_level(id) + 1)


func skill_effect(id: String) -> String:
	var l := skill_level(id)
	match id:
		"pulmones":
			return "Aguantás %s s la respiración" % str(3.0 + l * 1.5).replace(".", ",").trim_suffix(",0")
		"fuerza":
			return "Las frenadas te mueven %d%% menos" % (l * 10)
		_:
			return "Cada falla suma %d%% menos vergüenza" % (l * 8)


func upgrade_skill(id: String) -> bool:
	var c := skill_cost(id)
	if skill_level(id) >= MAX_LEVEL or profile["coins"] < c:
		return false
	profile["coins"] -= c
	profile["skills"][id] = skill_level(id) + 1
	save()
	return true


func buy_item(id: String) -> bool:
	for it in ITEMS:
		if it["id"] == id and profile["coins"] >= it["price"] and int(profile["inv"].get(id, 0)) < 9:
			profile["coins"] -= it["price"]
			profile["inv"][id] = int(profile["inv"].get(id, 0)) + 1
			save()
			return true
	return false


func skin(id: String) -> Dictionary:
	for s in SKINS:
		if s["id"] == id:
			return s
	return SKINS[0]


func buy_skin(id: String) -> bool:
	var s := skin(id)
	if s.has("prize") or profile["owned"].get(id, false) or profile["coins"] < s["price"]:
		return false
	profile["coins"] -= s["price"]
	profile["owned"][id] = true
	profile["eq"] = id
	save()
	return true


func use_item(id: String) -> void:
	profile["inv"][id] = maxi(0, int(profile["inv"].get(id, 0)) - 1)
	profile["used"][id] = int(profile["used"].get(id, 0)) + 1
	save()
