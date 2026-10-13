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
]

var profile: Dictionary = {}


func _ready() -> void:
	load_profile()


func fresh_profile() -> Dictionary:
	return {
		"coins": 200,
		"owned": {"buzo": true},
		"eq": "buzo",
		"skills": {"pulmones": 0, "fuerza": 0, "verguenza": 0},
		"inv": {"cafe": 2, "lock": 1, "perf": 3, "bill": 1},
		"used": {"cafe": 0, "lock": 0, "perf": 0, "bill": 0},
		"day": 0,
		"trip": 0,
		"results": [],
		"tut_seen": {},
		"tut_done": false,
	}


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
	profile["day"] = int(profile["day"])
	profile["trip"] = int(profile["trip"])
	for group in ["skills", "inv", "used"]:
		for k in profile[group].keys():
			profile[group][k] = int(profile[group][k])


func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(profile))


func reset_progress() -> void:
	profile = fresh_profile()
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


## Dificultad del día: 0 el lunes, sube hasta 4
func diff() -> int:
	return mini(int(profile["day"]), 4)


func day_name() -> String:
	return DAYS[int(profile["day"]) % 5]


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
	if profile["owned"].get(id, false) or profile["coins"] < s["price"]:
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
