class_name Trip
extends Node3D
## Un viaje en colectivo: arma el escenario, la interfaz y toda la lógica de los eventos.
## Es la misma lógica de la demo web, pasada a Godot.

const PIBE_Z := 0.8
const WALK_X := -0.3
const Z_MIN := -10.5
const Z_MAX := 1.5
const TRIG_Z := PIBE_Z - 0.6
# Asientos ocupados por pasajeros comunes (x, z)
const SEATS := [Vector2(-1.12, -.8), Vector2(-1.12, -3.8), Vector2(1.12, -5.3), Vector2(-1.12, -6.8), Vector2(1.12, -8.3), Vector2(-1.12, -9.8), Vector2(-1.12, .7)]

const C_INK := Color("1b2430")
const C_YELLOW := Color("f2b705")
const C_PINK := Color("e0457b")
const C_GREEN := Color("3fae5a")
const C_BLUE := Color("3e8fd6")
const C_RED := Color("c2362b")
const C_WHITE95 := Color(1, 1, 1, 0.95)

const TUT := {
	"tilt": ["¡Frenada!", "Mantené apretada la flecha de abajo del lado contrario a la caída (o inclina el celular) para que la bolita vuelva al centro. El colectivo se mueve todo el tiempo."],
	"olor": ["¡El oloroso!", "Mantené apretado AGUANTÁ hasta que su cara llegue al final. Soltá solo cuando la rayita esté en la zona verde: ahí respirás, pero la zona se achica. Al volver a apretar, la verde cambia de lugar. El perfume de al lado te deja respirar 3 segundos."],
	"vend": ["¡El vendedor ambulante!", "Te va a ofrecer cosas 3 veces seguidas. Tocá NO, GRACIAS cada vez antes de que se acabe el tiempo. O usá la billetera de al lado: le comprás algo barato y se va."],
	"choro": ["¡Te quiere robar!", "Tocá rápido para llevar la barra a tu lado antes de que el choro la lleve al suyo. O tocá el candado de al lado y se va con las manos vacías."],
	"eleccion": ["Subió una embarazada", "Elegí: cederle tu lugar (perdés la manija y te cuesta más el equilibrio) o hacerte el dormido cada vez que pase."],
	"fingir": ["¡Hacete el dormido!", "Mantené apretado y soltá cuando la rayita esté en la zona verde. Si tomaste café hace poco, va más lenta."],
	"sueno": ["¡Te estás durmiendo!", "Tocá rápido: cada toque sube la rayita y el sueño la baja. Cuando se acabe el tiempo tiene que estar en la zona verde. O tomate el café de al lado y te despertás al toque."],
}

const OFFERS := ["¿Alfajor? ¡Dos por mil!", "¿Pastillitas de menta?", "¿Medias? Tres pares, una ganga", "¿Un cargador para el celu?", "¿Curitas, pañuelitos?", "¿Una birome de tres colores?"]
const LAST_OFFER := "¡Última oferta, pibe!"

# ---------- Escena ----------
var cam: Camera3D
var outside: Array = []
var pibe: Dictionary
var walkers: Array = []
var seated_nodes: Array = []
var marker: Label3D
var stink_parts: Array = []
var fly_parts: Array = []
var shirt_mat := StandardMaterial3D.new()
var sleeve_mat := StandardMaterial3D.new()
# Cada barrio tiene su línea: el colectivo, el cartel y el cielo cambian (ver apply_line)
var bus_mat := StandardMaterial3D.new()
var bus_dark_mat := StandardMaterial3D.new()
var sign: Label3D
var env: Environment
var sun: DirectionalLight3D
var inside: OmniLight3D

# ---------- Interfaz ----------
var ui := {}
var targets: Array = []          # botones táctiles activos

# ---------- Estado del viaje ----------
var phase := "start"             # start, play, tut, pause, end
var t := 0.0
var shame := 0.0
var items := {}
var lock_t := 0.0
var perf_t := 0.0
var cafe_t := 0.0
var ceded := false
var emb_choice := ""
var ev = null                    # evento de botón activo (Dictionary) o null
var vend = null                  # vendedor activo (corre en paralelo)
var last_ev_end := 0.0
var tilt = null
var next_tilt := 3.0
var b := 0.0                     # equilibrio: -1 izquierda, 1 derecha
var ctrl_drag := 0.0
var ctrl_arrow := 0
var ctrl_key := 0
var fall_t := 0.0
var fall_dir := 1.0
var toast_t := 0.0
var sleep_at: Array = []
var ok_count := 0
var robbed := 0
var tutorial_mode := true
var seen := {}
var vend_seen := false
var after_tut := Callable()
var hold_index := -1
var arrow_index := -1
var drag_index := -1
var drag_x := 0.0
var autotest := false
var screens: Screens
var game_nodes: Array = []
var spin := 0.0
var spin_index := -1
var spin_x := 0.0
var spin_pause := 0.0
var auto_t := 0.0


func _ready() -> void:
	autotest = "--autotest" in OS.get_cmdline_user_args()
	shirt_mat.albedo_color = Color("2f6fd6")
	sleeve_mat.albedo_color = Color("2f6fd6")
	_build_world()
	_build_hud()
	if autotest:
		reset_trip()
	else:
		go_menu("menu")


# =====================================================================
#  ESCENARIO
# =====================================================================

func _build_world() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("9fd3f0")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.88, 0.95)
	env.ambient_light_energy = 0.75
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.light_energy = 0.9
	add_child(sun)
	inside = OmniLight3D.new()
	inside.position = Vector3(0, 2.4, -3)
	inside.omni_range = 14
	inside.light_energy = 0.6
	inside.light_color = Color("fff4dd")
	add_child(inside)

	cam = Camera3D.new()
	cam.fov = 58
	cam.current = true
	add_child(cam)

	# --- Colectivo ---
	var bus := Node3D.new()
	add_child(bus)
	var w := 3.4
	var h := 2.7
	var z0 := -12.0
	var z1 := 4.0
	var length := z1 - z0
	var zc := (z0 + z1) / 2.0
	Build.box(bus, Vector3(w, .12, length), Color("5f6b7a"), Vector3(0, -.06, zc))
	var z := z0 + .3
	while z < z1:
		Build.box(bus, Vector3(1.2, .02, .06), Color("4f5966"), Vector3(0, .01, z))
		z += .45
	Build.box(bus, Vector3(w, .1, length), Color("e9edf1"), Vector3(0, h, zc))
	var glass := Color(0.81, 0.92, 0.97, 0.18)
	for s in [-1, 1]:
		Build.box(bus, Vector3(.1, 1.05, length), bus_mat, Vector3(s * w / 2, .52, zc))
		Build.box(bus, Vector3(.1, .5, length), bus_mat, Vector3(s * w / 2, 2.45, zc))
		Build.box(bus, Vector3(.04, 1.15, length), glass, Vector3(s * w / 2, 1.62, zc))
		var zp := z0
		while zp <= z1:
			Build.box(bus, Vector3(.12, 1.2, .1), bus_dark_mat, Vector3(s * w / 2, 1.62, zp))
			zp += 1.6
		var rail := Build.cyl(bus, .035, .035, length, bus_mat, Vector3(s * .55, 2.38, zc), 8)
		rail.rotation.x = PI / 2
		var zh := z0 + 1.2
		while zh < z1:
			Build.box(bus, Vector3(.04, .34, .06), Color("2b313b"), Vector3(s * .55, 2.2, zh))
			var handle := Build.ring(bus, .08, .02, Color("2b313b"), Vector3(s * .55, 1.97, zh))
			handle.rotation.z = PI / 2
			zh += .8
	var zl := z0 + 1
	while zl < z1:
		var lamp_mat := StandardMaterial3D.new()
		lamp_mat.albedo_color = Color("fffbe8")
		lamp_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		Build.box(bus, Vector3(.5, .04, .25), lamp_mat, Vector3(0, h - .07, zl))
		zl += 1.6
	Build.box(bus, Vector3(w, 1.3, .05), Color(0.81, 0.92, 0.97, 0.25), Vector3(0, 1.6, z0))
	Build.box(bus, Vector3(w, .9, .1), Color("2b313b"), Vector3(0, .45, z0))
	Build.box(bus, Vector3(w, .45, .1), Color("2b313b"), Vector3(0, 2.45, z0))
	sign = Build.label(bus, "LÍNEA 42", 64, Color("ffb020"), Vector3(0, 2.45, z0 + .07))
	sign.outline_size = 0
	# Chofer
	var drv := Node3D.new()
	bus.add_child(drv)
	Build.box(drv, Vector3(.8, .9, .5), Color("5c7fa8"), Vector3(0, 1.0, 0))
	Build.sphere(drv, .4, Color("d8a27c"), Vector3(0, 1.75, 0))
	Build.cap(drv, .42, Color("3a2a20"), Vector3(0, 1.77, 0))
	drv.position = Vector3(-1.05, 0, z0 + 1.0)
	drv.scale = Vector3.ONE * .8
	for zz in [-9.5, -6.5, -3.5]:
		Build.cyl(bus, .035, .035, h, bus_mat, Vector3(.62, h / 2, zz), 8)
	for zz in [-9.8, -8.3, -6.8, -5.3, -3.8, -2.3, -.8, .7]:
		_seat(bus, -1.12, zz)
	for zz in [-9.8, -8.3, -6.8, -5.3]:
		_seat(bus, 1.12, zz)

	# --- Afuera: la ciudad pasa por la ventana ---
	var cols := ["e76f51", "f4a261", "e9c46a", "8ab17d", "6d9dc5", "b5838d", "cfd8dc"]
	for i in 26:
		var s := 1 if i % 2 else -1
		var bh := 2.0 + float((i * 37) % 50) / 10.0
		var g := Node3D.new()
		if i % 5 == 0:
			Build.cyl(g, .12, .15, 1.4, Color("6b4f3a"), Vector3(0, .7, 0), 6)
			Build.sphere(g, .8, Color("5e9c3a"), Vector3(0, 1.8, 0), 8)
		else:
			Build.box(g, Vector3(2.2, bh, 2.4), Color(cols[i % cols.size()]), Vector3(0, bh / 2, 0))
			Build.box(g, Vector3(1.6, .6, .05), Color("cfeaf8"), Vector3(0, bh * .6, 1.21))
		g.position = Vector3(s * (5.2 + float((i * 13) % 16) / 10.0), 0, -40 + i * 2)
		add_child(g)
		outside.append(g)
	Build.box(self, Vector3(30, .05, 80), Color("6e7682"), Vector3(0, -.2, -10))
	for s in [-1, 1]:
		Build.box(self, Vector3(2.4, .25, 80), Color("bfc5cc"), Vector3(s * 4.6, -.1, -10))

	# --- Personajes ---
	pibe = Characters.pibe(self, shirt_mat, sleeve_mat)
	var sucio := Characters.sucio(self)
	stink_parts = sucio["stink"]
	fly_parts = sucio["flies"]
	walkers = [
		{"d": sucio, "type": "olor", "speed": 1.05},
		{"d": Characters.choro(self), "type": "choro", "speed": 1.5},
		{"d": Characters.embarazada(self), "type": "emb", "speed": .8},
		{"d": Characters.vendedor(self), "type": "vend", "speed": 1.2},
	]
	# Pasajeros comunes sentados: en cada viaje se mezclan los asientos (ver reset_trip)
	for k in [["abuela", 0], ["oficinista", 0], ["estudiante", 0], ["obrero", 0], ["comun", 0], ["abuela", 1], ["estudiante", 1]]:
		var c := _passenger(k[0], k[1])
		c["root"].rotation.y = PI
		seated_nodes.append(c["root"])
	_shuffle_seats()
	# Y algunos parados del lado derecho, agarrados de la manija, lejos del pasillo
	var standing := [["oficinista", 1, -2.0], ["obrero", 1, -3.4], ["estudiante", 0, -4.6]]
	for k in standing:
		var c := _passenger(k[0], k[1])
		c["root"].position = Vector3(.92, 0, k[2])
		c["root"].rotation.y = PI
		Characters.set_grab(c, true)

	marker = Label3D.new()
	marker.text = "!"
	marker.font_size = 140
	marker.modulate = Color.WHITE
	marker.outline_size = 40
	marker.outline_modulate = C_RED
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.no_depth_test = true
	marker.pixel_size = 0.004
	marker.visible = false
	add_child(marker)


## Pinta el colectivo con el color de la línea del barrio y pone el cielo (de día o de noche)
func apply_line() -> void:
	var br := Game.barrio()
	var c := Color(br["color"])
	bus_mat.albedo_color = c
	bus_mat.roughness = 0.85
	bus_dark_mat.albedo_color = c.darkened(0.15)
	bus_dark_mat.roughness = 0.85
	sign.text = "LÍNEA %s" % br["line"]
	var night: bool = br["night"]
	env.background_color = Color(br["sky"])
	env.ambient_light_energy = 0.5 if night else 0.75
	sun.light_energy = 0.25 if night else 0.9
	inside.light_energy = 1.1 if night else 0.6


func _passenger(kind: String, v: int) -> Dictionary:
	match kind:
		"abuela":
			return Characters.abuela(self, v)
		"oficinista":
			return Characters.oficinista(self, v)
		"estudiante":
			return Characters.estudiante(self, v)
		"obrero":
			return Characters.obrero(self, v)
	return Characters.comun(self, [Color("b4bcc7"), Color("9aa3af")][v % 2])


## Reparte a los pasajeros sentados en asientos al azar
func _shuffle_seats() -> void:
	var spots := SEATS.duplicate()
	spots.shuffle()
	for i in seated_nodes.size():
		var s: Vector2 = spots[i]
		seated_nodes[i].position = Vector3(s.x, .085, s.y)


func _seat(parent: Node3D, x: float, z: float) -> void:
	var g := Node3D.new()
	Build.box(g, Vector3(1.0, .14, .55), Color("2f5da8"), Vector3(0, .52, 0))
	Build.box(g, Vector3(1.0, .8, .12), Color("2f5da8"), Vector3(0, .95, .3))
	Build.box(g, Vector3(1.04, .06, .16), Color("8c939e"), Vector3(0, 1.37, .3))
	Build.box(g, Vector3(.9, .45, .06), Color("8c939e"), Vector3(0, .25, -.2))
	g.position = Vector3(x, 0, z)
	parent.add_child(g)


# =====================================================================
#  INTERFAZ
# =====================================================================

func _style(c: Color, radius := 24) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	# Sombra suave y difuminada (solo en tarjetas blancas, no en los chips de color)
	if c.a > 0.8 and c.get_luminance() > 0.985:
		sb.shadow_color = Color(0.06, 0.08, 0.12, 0.14)
		sb.shadow_size = 18
		sb.shadow_offset = Vector2(0, 6)
	return sb


## Texto. Desde 30 px va en negrita (títulos)
func _label(text: String, size := 26, color := C_INK, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	if size >= 30:
		l.add_theme_font_override("font", Game.font_bold)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


func _panel(c := C_WHITE95, radius := 22) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _style(c, radius))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func _tb(id: String, text: String, size: Vector2, bg := Color.WHITE, group := "game") -> TouchButton:
	var b_ := TouchButton.new(id, text, size)
	b_.bg = bg
	b_.group = group
	targets.append(b_)
	return b_


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	ui["root"] = root

	var flash := ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1, 1, 1, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(flash)
	ui["flash"] = flash

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 34)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(col)

	# Fila de arriba: pausa, viaje, monedas
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	col.add_child(top)
	var pause := _tb("pause", "", Vector2(76, 76))
	pause.icon = "pause"
	top.add_child(pause)
	game_nodes.append(pause)
	var trip_p := _panel()
	trip_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var trip_v := VBoxContainer.new()
	trip_v.add_theme_constant_override("separation", -6)
	var trip_k := _label("", 17, Color("5b6573"), HORIZONTAL_ALIGNMENT_CENTER)
	trip_v.add_child(trip_k)
	var trip_l := _label("", 30, C_INK, HORIZONTAL_ALIGNMENT_CENTER)
	trip_v.add_child(trip_l)
	trip_p.add_child(trip_v)
	top.add_child(trip_p)
	game_nodes.append(trip_p)
	var spacer_top := Control.new()
	spacer_top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer_top)
	ui["spacer_top"] = spacer_top
	ui["trip_k"] = trip_k
	ui["trip"] = trip_l
	var coins_p := _panel(C_WHITE95, 999)
	var coins_row := HBoxContainer.new()
	coins_row.add_theme_constant_override("separation", 8)
	coins_row.add_child(Coin.new(30))
	var coins_l := _label("", 30)
	coins_row.add_child(coins_l)
	coins_p.add_child(coins_row)
	coins_p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(coins_p)
	ui["coins"] = coins_l

	# Recorrido
	var route := Meter.new(14)
	route.fill_color = C_YELLOW
	route.bg = Color(1, 1, 1, 0.75)
	col.add_child(route)
	game_nodes.append(route)
	ui["route"] = route

	# Vergüenza
	var shame_p := _panel()
	var shame_row := HBoxContainer.new()
	shame_row.add_theme_constant_override("separation", 10)
	var blush := TouchButton.new("", "", Vector2(44, 44))
	blush.icon = "blush"
	blush.bg = Color(0, 0, 0, 0)
	blush.shadow = Color(0, 0, 0, 0)
	shame_row.add_child(blush)
	shame_row.add_child(_label("Vergüenza", 22))
	var shame_m := Meter.new(18)
	shame_m.fill_color = C_PINK
	shame_row.add_child(shame_m)
	shame_p.add_child(shame_row)
	col.add_child(shame_p)
	game_nodes.append(shame_p)
	ui["shame"] = shame_m

	# Aviso
	var toast_p := _panel(Color(0.106, 0.141, 0.188, 0.92), 999)
	toast_p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var toast_l := _label("", 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	toast_p.add_child(toast_l)
	toast_p.modulate.a = 0
	col.add_child(toast_p)
	ui["toast"] = toast_p
	ui["toast_l"] = toast_l

	var sp1 := Control.new()
	sp1.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(sp1)

	# Vendedor (en el medio)
	var vend_box := HBoxContainer.new()
	vend_box.add_theme_constant_override("separation", 12)
	vend_box.alignment = BoxContainer.ALIGNMENT_CENTER
	vend_box.visible = false
	col.add_child(vend_box)
	ui["vend"] = vend_box

	var sp2 := Control.new()
	sp2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(sp2)

	# Evento de botón
	var evt := VBoxContainer.new()
	evt.add_theme_constant_override("separation", 16)
	evt.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	evt.custom_minimum_size = Vector2(600, 0)
	col.add_child(evt)
	game_nodes.append(evt)
	ui["evt"] = evt

	# Equilibrio con flechas
	var ctrl := HBoxContainer.new()
	ctrl.add_theme_constant_override("separation", 14)
	col.add_child(ctrl)
	game_nodes.append(ctrl)
	var left := _tb("arrowL", "", Vector2(124, 124))
	left.icon = "left"
	ctrl.add_child(left)
	var bal_p := _panel()
	bal_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bal_col := VBoxContainer.new()
	bal_col.add_child(_label("Equilibrio", 22, C_INK, HORIZONTAL_ALIGNMENT_CENTER))
	var bal := Meter.new(30)
	bal.bg = Color("ddf1e1")
	bal.zones = [
		{"a": 0.0, "w": 0.12, "c": C_PINK}, {"a": 0.12, "w": 0.18, "c": Color("f6d2de")},
		{"a": 0.70, "w": 0.18, "c": Color("f6d2de")}, {"a": 0.88, "w": 0.12, "c": C_PINK},
	]
	bal.dot = 0.5
	bal_col.add_child(bal)
	bal_p.add_child(bal_col)
	ctrl.add_child(bal_p)
	var right := _tb("arrowR", "", Vector2(124, 124))
	right.icon = "right"
	ctrl.add_child(right)
	ui["balance"] = bal
	ui["left"] = left
	ui["right"] = right

	# Capa para carteles
	var modal := Control.new()
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screens = Screens.new(self)
	root.add_child(screens)
	root.add_child(modal)
	ui["modal"] = modal


func _set_mode(mode: String) -> void:
	for n in game_nodes:
		n.visible = mode == "game"
	ui["spacer_top"].visible = mode != "game"
	if mode == "game":
		screens.clear()


## Vuelve al menú (o abre tienda, habilidades o camisetas)
func go_menu(screen := "menu") -> void:
	phase = "screen"
	hide_modal()
	ev = null
	vend = null
	tilt = null
	_clear(ui["evt"])
	_clear(ui["vend"])
	ui["vend"].visible = false
	marker.visible = false
	_set_mode("screen")
	for i in walkers.size():
		var w: Dictionary = walkers[i]
		w["d"]["root"].position = Vector3(WALK_X, 0, -10.5 + i * 0.9)
		w["d"]["root"].rotation.y = 0.0
	Characters.set_grab(pibe, false)
	ceded = false
	b = 0.0
	fall_t = 0.0
	spin = 0.0
	update_coins()
	apply_line()
	screens.open(screen)
	show_skin(screens.preview)
	if screen == "menu":
		_show_next_story()


# ---------- Carteles de historia ----------

var story_key := ""


## Muestra el próximo cartel de historia pendiente (intro de capítulo o barrio, finales), si hay
func _show_next_story() -> void:
	story_key = Game.next_story()
	if story_key == "":
		hide_modal()
		return
	var n := int(story_key.get_slice(":", 1))
	var ok := [["story_ok", "¡VAMOS!", 420, C_YELLOW]]
	match story_key.get_slice(":", 0):
		"cap_intro":
			var ch: Dictionary = Game.CHAPTERS[n]
			show_modal("Capítulo %d" % (n + 1), ch["title"], "%s\n\nMeta: %s." % [ch["intro"], ch["goal"].to_lower()], [], ok)
		"barrio_intro":
			var br: Dictionary = Game.BARRIOS[n]
			show_modal("Semana nueva · Línea %s" % br["line"], br["name"], br["intro"], [], ok)
		"barrio_end":
			var br2: Dictionary = Game.BARRIOS[n]
			var ch2 := Game.chapter_index(n)
			var done := Game.chapter_progress(ch2)
			show_modal("Barrio terminado", "¡Chau, %s!" % br2["name"], "Te ganaste la camiseta %s. Ya la tenés en Camisetas." % Game.skin(br2["prize"])["name"],
				[["Meta: %s" % Game.CHAPTERS[ch2]["title"].to_lower(), "%d de %d barrios" % [done, Game.BARRIOS_PER_CHAPTER]]], [["story_ok", "SEGUIR", 420, C_YELLOW]])
		"cap_end":
			var ch3: Dictionary = Game.CHAPTERS[n]
			show_modal("Fin del capítulo %d" % (n + 1), ch3["end_title"], ch3["end"], [], [["story_ok", "JAJA, SEGUIR", 420, C_YELLOW]])
		"libre":
			show_modal("Modo libre", "¿Y ahora?", Game.LIBRE_TEXT, [], [["story_ok", "SEGUIR VIAJANDO", 460, C_YELLOW]])


func show_skin(id: String) -> void:
	Skins.apply(id, shirt_mat, sleeve_mat)


func update_coins() -> void:
	ui["coins"].text = str(Game.profile["coins"])


func _clear(node: Node) -> void:
	for c in node.get_children():
		_forget_targets(c)
		c.queue_free()


func _forget_targets(node: Node) -> void:
	if node is TouchButton:
		targets.erase(node)
	for c in node.get_children():
		_forget_targets(c)


## Cartel centrado. rows: [[texto, valor], ...]; buttons: [[id, texto, ancho, color], ...]
func show_modal(kicker: String, title: String, body: String, rows: Array, buttons: Array, closable := false) -> void:
	hide_modal()
	var m: Control = ui["modal"]
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.08, 0.12, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(center)
	var card := _panel(Color.WHITE, 40)
	card.custom_minimum_size = Vector2(620, 0)
	var sb: StyleBoxFlat = card.get_theme_stylebox("panel")
	sb.content_margin_left = 34
	sb.content_margin_right = 34
	sb.content_margin_top = 30
	sb.content_margin_bottom = 34
	center.add_child(card)
	# Entrada con "pop": el cartel crece un poquito desde el centro y aparece
	card.resized.connect(func(): card.pivot_offset = card.size / 2.0)
	card.scale = Vector2.ONE * 0.88
	center.modulate.a = 0.0
	var tw := card.create_tween().set_parallel()
	tw.tween_property(card, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(center, "modulate:a", 1.0, 0.16)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	card.add_child(v)
	if closable:
		var close_row := HBoxContainer.new()
		close_row.alignment = BoxContainer.ALIGNMENT_END
		var x := _tb("close", "", Vector2(70, 70), Color("eef1f5"), "modal")
		x.icon = "close"
		x.shape = "circle"
		close_row.add_child(x)
		v.add_child(close_row)
	v.add_child(_label(kicker.to_upper(), 20, Color("5b6573"), HORIZONTAL_ALIGNMENT_CENTER))
	var tl := _label(title, 52, C_INK, HORIZONTAL_ALIGNMENT_CENTER)
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tl.custom_minimum_size = Vector2(540, 0)
	v.add_child(tl)
	if body != "":
		var bl := _label(body, 26, C_INK, HORIZONTAL_ALIGNMENT_CENTER)
		bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bl.custom_minimum_size = Vector2(540, 0)
		v.add_child(bl)
	for r in rows:
		var row := HBoxContainer.new()
		var a := _label(r[0], 25)
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(a)
		row.add_child(_label(r[1], 25))
		v.add_child(row)
	var brow := HBoxContainer.new()
	brow.add_theme_constant_override("separation", 14)
	brow.alignment = BoxContainer.ALIGNMENT_CENTER
	for bt in buttons:
		var btn := _tb(bt[0], bt[1], Vector2(bt[2], 104), bt[3], "modal")
		btn.font_size = 36 if bt[2] > 300 else 24
		if bt.size() > 4:
			btn.icon = bt[4]
		if bt[3] == C_YELLOW:
			btn.shadow = Color("b58600")
		if bt[2] > 300:
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		brow.add_child(btn)
	v.add_child(brow)


func hide_modal() -> void:
	_clear(ui["modal"])


func modal_open() -> bool:
	return ui["modal"].get_child_count() > 0


# =====================================================================
#  VIAJE
# =====================================================================

func reset_trip() -> void:
	var p := Game.profile
	var tr: Dictionary = Game.TRIPS[p["trip"]]
	ui["trip_k"].text = ("Línea %s · %s · Viaje %d de 4" % [Game.barrio()["line"], Game.day_name(), p["trip"] + 1]).to_upper()
	ui["trip"].text = "%s → %s" % [tr["from"], tr["to"]]
	phase = "start"
	t = 0.0
	shame = 0.0
	items = Game.trip_items()
	lock_t = 0.0
	perf_t = 0.0
	cafe_t = 0.0
	ceded = false
	emb_choice = ""
	ev = null
	vend = null
	last_ev_end = 0.0
	tilt = null
	next_tilt = 3.0
	b = 0.0
	ctrl_drag = 0.0
	ctrl_arrow = 0
	fall_t = 0.0
	toast_t = 0.0
	sleep_at = [24.0, 44.0, 62.0]
	ok_count = 0
	robbed = 0
	tutorial_mode = not p["tut_done"]
	seen = {}
	vend_seen = false
	_clear(ui["evt"])
	_clear(ui["vend"])
	ui["vend"].visible = false
	marker.visible = false
	_shuffle_seats()
	apply_line()
	# Orden de llegada de los personajes al azar
	var order := walkers.duplicate()
	order.shuffle()
	var waits := [1.0, 8.0, 12.0, 18.0]
	for i in order.size():
		var w: Dictionary = order[i]
		w["z"] = -6.0 if i == 0 else -10.5
		w["dir"] = 1
		w["cool"] = 0.0
		w["wait"] = waits[i]
		w["state"] = "walk"
		w["parked"] = false
		w["boost"] = 1.0
		w["d"]["root"].position = Vector3(WALK_X, 0, w["z"])
	pibe["root"].position = Vector3(.75, 0, PIBE_Z)
	pibe["root"].rotation = Vector3(0, PI, 0)
	Characters.set_grab(pibe, true)
	_set_mode("game")
	Skins.apply(p["eq"], shirt_mat, sleeve_mat)
	_upd_bars()
	update_coins()
	var body := "Llegá sin pasar vergüenza. Los personajes van y vienen por el pasillo: cuando pasan cerca tuyo, arranca su evento." if (p["trip"] == 0 and Game.first_day()) else ""
	show_modal("%s · Viaje %d de 4" % [Game.day_name(), p["trip"] + 1], "%s → %s" % [tr["from"], tr["to"]], body, [], [["start", "¡ARRANCAR!", 420, C_YELLOW], ["shopfirst", "Tienda", 130, Color("eef1f5"), "shop"]], true)
	if autotest:
		hide_modal()
		phase = "play"


func toast(msg: String) -> void:
	ui["toast_l"].text = msg
	ui["toast"].modulate.a = 1.0
	toast_t = 2.2
	if autotest:
		print("[%.1f] %s" % [t, msg])


func flash(c: Color) -> void:
	var f: ColorRect = ui["flash"]
	f.color = Color(c.r, c.g, c.b, 0.55)
	var tw := create_tween()
	tw.tween_property(f, "color:a", 0.0, 0.35)


func _upd_bars() -> void:
	ui["shame"].set_values({"fill": minf(1.0, shame / 100.0)})


func add_shame(kind: String, msg: String) -> void:
	var v := roundi(Game.SHAME[kind] * Game.shame_mult())
	shame += v
	_upd_bars()
	toast("%s +%d vergüenza" % [msg, v])
	if shame >= 100:
		end_trip()


func tutorial(key: String, then: Callable) -> void:
	if Game.profile["tut_seen"].get(key, false) or autotest:
		then.call()
		return
	Game.profile["tut_seen"][key] = true
	phase = "tut"
	after_tut = then
	show_modal("Tutorial", TUT[key][0], TUT[key][1], [], [["tutok", "¡DALE!", 420, C_YELLOW]])


func combos_ok() -> bool:
	if not tutorial_mode:
		return true
	for k in ["tilt", "olor", "choro", "emb", "sueno", "vend"]:
		if not seen.get(k, false):
			return false
	return true


# ---------- Ítems al lado del botón ----------

func _ctx(id: String) -> TouchButton:
	if items.get(id, 0) <= 0:
		return null
	var c := _tb("item:" + id, "", Vector2(124, 124))
	c.icon = id
	c.badge = items[id]
	c.border = C_YELLOW
	c.pulse = id == "perf"
	return c


func _use_item(id: String) -> void:
	items[id] -= 1
	Game.use_item(id)


func use_perfume() -> bool:
	if items.get("perf", 0) <= 0 or perf_t > 0 or ev == null or ev["type"] != "olor":
		return false
	_use_item("perf")
	perf_t = 3.0
	if ev.has("ctx") and is_instance_valid(ev["ctx"]):
		ev["ctx"].badge = items["perf"]
		ev["ctx"].pulse = false
		ev["ctx"].overlay_text = "3"
		ev["ctx"].queue_redraw()
	return true


# ---------- Eventos de botón ----------

func start_ev(type: String, w) -> void:
	tutorial(type, func(): _start_ev_now(type, w))


func _start_ev_now(type: String, w) -> void:
	marker.visible = false
	ev = {"type": type, "w": w, "t": 0.0, "holding": false, "started": false}
	if w != null:
		w["state"] = "slow" if type == "olor" else "hold"
	var box: VBoxContainer = ui["evt"]
	_clear(box)
	var card := _panel()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	card.add_child(v)
	box.add_child(card)
	var act_row := HBoxContainer.new()
	act_row.alignment = BoxContainer.ALIGNMENT_CENTER
	act_row.add_theme_constant_override("separation", 26)
	var act: TouchButton = null
	var ctx_id := ""
	match type:
		"olor":
			ev["lungs"] = 100.0
			ev["stay"] = 6.0
			ev["breath_t"] = 0.0
			ev["zone"] = {"a": 0.35 + randf() * 0.2, "w": 0.2}
			ev["breathing"] = false
			v.add_child(_row2("Está pasando", "Se fue"))
			var fm := Meter.new(30)
			fm.bg = Color("cfe8be")
			fm.face = 0.0
			v.add_child(fm)
			v.add_child(_row2("Aguantando", "Sin aire"))
			var lm := Meter.new(28)
			lm.fill_color = Color(0.243, 0.561, 0.839, 0.9)
			lm.needle = 0.0
			v.add_child(lm)
			ev["face_m"] = fm
			ev["lung_m"] = lm
			act = _tb("act", "AGUANTÁ", Vector2(200, 200), C_YELLOW)
			ev["hold"] = true
			ctx_id = "perf"
		"choro":
			ev["p"] = 0.5
			marker.visible = true
			v.add_child(_row3("Vos", "Forcejeo", "Choro"))
			var tm := Meter.new(30)
			tm.bg = Color("f1ece6")
			tm.zones = [{"a": 0.0, "w": 0.08, "c": C_GREEN}, {"a": 0.92, "w": 0.08, "c": C_PINK}]
			tm.needle = 0.5
			v.add_child(tm)
			ev["tug_m"] = tm
			act = _tb("act", "TOCÁ", Vector2(200, 200), C_YELLOW)
			ctx_id = "lock"
		"eleccion":
			ev["limit"] = 5.0
			var rl := _row2("Subió una embarazada", "")
			v.add_child(rl)
			ev["time_l"] = rl.get_child(1)
			var cr := HBoxContainer.new()
			cr.add_theme_constant_override("separation", 14)
			var c1 := _tb("ceder", "Ceder\nel lugar", Vector2(280, 120), Color("ddf1e1"))
			c1.font_size = 28
			var c2 := _tb("fingir", "Hacerme\nel dormido", Vector2(280, 120))
			c2.font_size = 28
			cr.add_child(c1)
			cr.add_child(c2)
			box.add_child(cr)
		"fingir":
			ev["pos"] = 0.0
			v.add_child(_row2("Despierto", "Dormido"))
			var fmm := Meter.new(30)
			fmm.zones = [{"a": 0.58, "w": 0.16, "c": C_GREEN}, {"a": 0.74, "w": 0.26, "c": Color(0.557, 0.357, 0.851, 0.35)}]
			fmm.needle = 0.0
			v.add_child(fmm)
			ev["f_m"] = fmm
			act = _tb("act", "MANTENÉ", Vector2(200, 200), C_YELLOW)
			ev["hold"] = true
		"sueno":
			ev["v"] = 0.4
			ev["dur"] = 5.0
			var r3 := _row3("Dormido", "", "Despierto")
			v.add_child(r3)
			ev["time_l"] = r3.get_child(1)
			var sm := Meter.new(30)
			sm.zones = [{"a": 0.8, "w": 0.2, "c": C_GREEN}]
			sm.needle = 0.4
			v.add_child(sm)
			ev["s_m"] = sm
			act = _tb("act", "TOCÁ", Vector2(200, 200), C_YELLOW)
			ctx_id = "cafe"
	if act != null:
		act.shape = "circle"
		act.font_size = 34
		act.shadow = Color("b58600")
		act_row.add_child(act)
		ev["act"] = act
		if ctx_id != "":
			var c := _ctx(ctx_id)
			if c != null:
				act_row.add_child(c)
				ev["ctx"] = c
		box.add_child(act_row)


func _row2(a: String, b_: String) -> HBoxContainer:
	var r := HBoxContainer.new()
	var l1 := _label(a, 21)
	l1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(l1)
	r.add_child(_label(b_, 21))
	return r


func _row3(a: String, mid: String, c: String) -> HBoxContainer:
	var r := HBoxContainer.new()
	var l1 := _label(a, 21)
	l1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(l1)
	var l2 := _label(mid, 21, C_INK, HORIZONTAL_ALIGNMENT_CENTER)
	l2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(l2)
	var l3 := _label(c, 21, C_INK, HORIZONTAL_ALIGNMENT_RIGHT)
	l3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(l3)
	return r


func end_ev(win: bool) -> void:
	if ev != null and ev["w"] != null:
		var w: Dictionary = ev["w"]
		w["state"] = "walk"
		w["cool"] = 6.0
		w["boost"] = 1.0
	if win:
		ok_count += 1
	ev = null
	last_ev_end = t
	marker.visible = false
	_clear(ui["evt"])


func press() -> void:
	if ev == null or phase != "play" or not ev.has("act"):
		return
	if ev.get("hold", false):
		if ev["type"] == "olor" and ev["breathing"]:
			var used: float = 1.0 - ev["lungs"] / 100.0
			var wz := 0.2
			var lo := minf(used + 0.08, 1.0 - wz - 0.02)
			var hi := 1.0 - wz - 0.02
			ev["zone"] = {"a": lo + randf() * maxf(0.0, hi - lo), "w": wz}
		ev["breathing"] = false
		ev["holding"] = true
		ev["started"] = true
		ev["act"].set_down(true)
	elif ev["type"] == "choro":
		ev["p"] = maxf(0.0, ev["p"] - 0.07)
	elif ev["type"] == "sueno":
		ev["v"] = minf(1.0, ev["v"] + 0.08)


func release() -> void:
	if ev == null or not ev.get("holding", false):
		return
	ev["holding"] = false
	if ev.has("act") and is_instance_valid(ev["act"]):
		ev["act"].set_down(false)
	if phase != "play":
		return
	if ev["type"] == "olor" and perf_t <= 0:
		var used: float = 1.0 - ev["lungs"] / 100.0
		var z: Dictionary = ev["zone"]
		if used >= z["a"] and used <= z["a"] + z["w"]:
			ev["breathing"] = true
			toast("Respirando en la zona verde…")
		else:
			end_ev(false)
			flash(Color("3e9b47"))
			add_shame("vomito", "¡Soltaste fuera de la verde y vomitaste!")
			return
	if ev != null and ev["type"] == "fingir":
		var p: float = ev["pos"]
		if p >= 0.58 and p <= 0.74:
			toast("¡Zafaste! Pensó que dormías")
			end_ev(true)
		elif p > 0.74:
			end_ev(false)
			fall(1.0 if randf() < 0.5 else -1.0)
			add_shame("dormir", "Te dormiste de verdad y te caíste.")
		else:
			end_ev(false)
			add_shame("visto", "Te vio con los ojos abiertos.")


# ---------- Vendedor (en paralelo) ----------

func start_vend(w: Dictionary) -> void:
	tutorial("vend", func():
		vend = {"w": w, "n": 0, "win": 1.8 - Game.diff() * 0.1, "ot": 0.0}
		vend_seen = true
		w["state"] = "hold"
		_vend_offer())


func _vend_offer() -> void:
	var box: HBoxContainer = ui["vend"]
	_clear(box)
	box.visible = true
	vend["ot"] = 0.0
	var txt: String = LAST_OFFER if vend["n"] == 2 else OFFERS[(vend["n"] + int(t)) % OFFERS.size()]
	var card := _panel(Color.WHITE)
	card.custom_minimum_size = Vector2(330, 0)
	var v := VBoxContainer.new()
	v.add_child(_label("Vendedor · %d de 3" % (vend["n"] + 1), 18, Color("5b6573")))
	var tl := _label(txt, 24)
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tl.custom_minimum_size = Vector2(290, 0)
	v.add_child(tl)
	var tm := Meter.new(14)
	tm.fill_color = C_RED
	tm.fill = 1.0
	v.add_child(tm)
	card.add_child(v)
	vend["m"] = tm
	var nog := _tb("nogracias", "NO,\nGRACIAS", Vector2(170, 130), Color.WHITE)
	nog.fg = C_RED
	nog.border = C_RED
	nog.font_size = 26
	var pieces: Array = [card, nog]
	var c := _ctx("bill")
	if c != null:
		pieces.append(c)
	if vend["n"] % 2 == 1:
		pieces.reverse()
	for p in pieces:
		box.add_child(p)


func end_vend(win: bool) -> void:
	if vend != null:
		var w: Dictionary = vend["w"]
		w["state"] = "walk"
		w["cool"] = 8.0
		w["boost"] = 1.0
	if win:
		ok_count += 1
	vend = null
	last_ev_end = t
	_clear(ui["vend"])
	ui["vend"].visible = false


# ---------- Equilibrio ----------

func start_tilt() -> void:
	tutorial("tilt", func():
		var dir := -1.0 if randf() < 0.5 else 1.0
		var p := Game.profile
		var first_day_soft := (0.7 if p["trip"] == 0 else 0.85) if Game.first_day() else 1.0
		var amp := 1.35 * Game.strength_mult() * (1.45 if ceded else 1.0) * (0.65 if ev != null else 1.0) * first_day_soft
		tilt = {"t": 0.0, "dur": 3.2, "dir": dir, "amp": amp}
		seen["tilt"] = true
		toast("¡Curva! Te vas a la derecha" if dir > 0 else "¡Frenada! Te vas a la izquierda"))


func fall(dir: float) -> void:
	fall_t = 1.4
	fall_dir = dir
	tilt = null
	b = 0.0
	flash(C_PINK)


# ---------- Fin del viaje ----------

func end_trip() -> void:
	if phase == "end":
		return
	phase = "end"
	ev = null
	_clear(ui["evt"])
	end_vend(false)
	tilt = null
	marker.visible = false
	var p := Game.profile
	var failed := shame >= 100
	var score := maxi(0, 100 - roundi(shame))
	var coins := 20 + (0 if failed else score / 2)
	p["coins"] += coins
	var tr: Dictionary = Game.TRIPS[p["trip"]]
	var results: Array = p["results"]
	while results.size() <= p["trip"]:
		results.append("")
	results[p["trip"]] = "fail" if failed else "ok"
	p["tut_done"] = true
	var rows := [
		["Puntaje del viaje", str(score)],
		["Eventos superados", str(ok_count)],
		["Vergüenza", "%d%%" % mini(100, roundi(shame))],
		["Monedas ganadas", "+%d" % coins],
	]
	if robbed > 0:
		rows.append(["Monedas perdidas (choro y vendedor)", "−%d" % robbed])
	var body := ""
	if p["trip"] == 3:
		var clean := true
		for r in results:
			if r != "ok":
				clean = false
		var bonus := 50 + (100 if clean else 0)
		p["coins"] += bonus
		rows.append(["¡Terminaste el %s!" % Game.day_name().to_lower(), "+50"])
		if clean:
			rows.append(["Día sin fallar", "+100"])
		p["day"] += 1
		p["trip"] = 0
		p["results"] = []
		p["used"] = {"cafe": 0, "lock": 0, "perf": 0, "bill": 0}
		if p["day"] >= 5:
			# Se terminó la semana: premio del barrio y al siguiente (los carteles de historia salen en el menú)
			p["day"] = 0
			rows.append_array(Game.complete_week())
			body = "¡Semana terminada!" if Game.story_done() else "La semana que viene: %s, Línea %s." % [Game.barrio()["name"], Game.barrio()["line"]]
		else:
			body = "Mañana es %s: todo se pone un poco más difícil." % Game.day_name().to_lower()
	else:
		p["trip"] += 1
	Game.save()
	update_coins()
	if autotest:
		print("FIN DEL VIAJE: fallado=%s puntaje=%d eventos=%d" % [failed, score, ok_count])
		print("  barrio=%d día=%d viaje=%d monedas=%d historia=%s" % [p["barrio"], p["day"], p["trip"], p["coins"], p["story_queue"]])
		for r in rows:
			print("  %s: %s" % r)
		get_tree().quit()
		return
	show_modal("Viaje fallado" if failed else "¡Llegaste!", "Qué vergüenza" if failed else "%s → %s" % [tr["from"], tr["to"]], body, rows, [["tomenu", "VOLVER AL MENÚ", 460, C_YELLOW]])


# =====================================================================
#  ENTRADA (dedos, mouse y teclado)
# =====================================================================

func _hit(pos: Vector2) -> TouchButton:
	var group := "modal" if modal_open() else "game"
	for i in range(targets.size() - 1, -1, -1):
		var tb: TouchButton = targets[i]
		if not is_instance_valid(tb) or tb.group != group or not tb.is_visible_in_tree() or tb.disabled:
			continue
		if tb.get_global_rect().has_point(pos):
			return tb
	return null


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_down(event.index, event.position)
		else:
			_touch_up(event.index)
	elif event is InputEventScreenDrag:
		if event.index == spin_index:
			spin += (event.position.x - spin_x) * 0.012
			spin_x = event.position.x
			spin_pause = 2.0
		if event.index == drag_index:
			ctrl_drag = clampf((event.position.x - drag_x) / 90.0, -1.0, 1.0)
		# Deslizar el dedo desde AGUANTÁ hasta el perfume
		if event.index == hold_index and ev != null and ev["type"] == "olor" and ev["holding"] and ev.has("ctx") and is_instance_valid(ev["ctx"]):
			if ev["ctx"].get_global_rect().has_point(event.position) and use_perfume():
				ev["holding"] = false
				ev["act"].set_down(false)
				hold_index = -1
				toast("¡Perfume! Respirá tranquilo 3 segundos")
	elif event is InputEventKey and not event.echo:
		if event.keycode == KEY_LEFT or event.keycode == KEY_A:
			ctrl_key = -1 if event.pressed else (0 if ctrl_key < 0 else ctrl_key)
		elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
			ctrl_key = 1 if event.pressed else (0 if ctrl_key > 0 else ctrl_key)
		elif event.keycode == KEY_SPACE:
			if event.pressed:
				press()
			else:
				release()


func _touch_down(index: int, pos: Vector2) -> void:
	var tb := _hit(pos)
	if tb == null:
		if phase == "play":
			drag_index = index
			drag_x = pos.x
		elif phase == "screen":
			spin_index = index
			spin_x = pos.x
		return
	match tb.id:
		"arrowL", "arrowR":
			if phase == "play":
				ctrl_arrow = -1 if tb.id == "arrowL" else 1
				arrow_index = index
				tb.set_down(true)
		"act":
			hold_index = index
			press()
		_:
			_tap(tb.id)


func _touch_up(index: int) -> void:
	if index == arrow_index:
		arrow_index = -1
		ctrl_arrow = 0
		ui["left"].set_down(false)
		ui["right"].set_down(false)
	if index == hold_index:
		hold_index = -1
		release()
	if index == drag_index:
		drag_index = -1
		ctrl_drag = 0.0
	if index == spin_index:
		spin_index = -1


func _tap(id: String) -> void:
	match id:
		"start":
			hide_modal()
			phase = "play"
		"tutok":
			hide_modal()
			phase = "play"
			var f := after_tut
			after_tut = Callable()
			if f.is_valid():
				f.call()
		"pause":
			if phase == "play":
				phase = "pause"
				show_modal("Pausa", "Viaje en pausa", "", [], [["resume", "SEGUIR", 420, C_YELLOW]])
		"resume":
			hide_modal()
			phase = "play"
		"close", "tomenu":
			go_menu("menu")
		"story_ok":
			Game.mark_story(story_key)
			_show_next_story()
			return
		"shopfirst":
			screens.from_start = true
			go_menu("tienda")
	if phase == "screen":
		screens.tap(id)
		return
	if phase != "play":
		return
	match id:
		"ceder":
			if ev != null and ev["type"] == "eleccion":
				ceded = true
				emb_choice = "ceder"
				end_ev(true)
				Characters.set_grab(pibe, false)
				var w: Dictionary = walkers[2]
				w["parked"] = true
				w["state"] = "park"
				toast("Le cediste el lugar. Ojo: ahora no tenés manija")
		"fingir":
			if ev != null and ev["type"] == "eleccion":
				emb_choice = "fingir"
				var w = ev["w"]
				ev = null
				_clear(ui["evt"])
				start_ev("fingir", w)
		"item:cafe":
			if items.get("cafe", 0) > 0 and ev != null and ev["type"] == "sueno":
				_use_item("cafe")
				cafe_t = 20.0
				toast("¡Con el café te despertaste al toque!")
				end_ev(true)
		"item:lock":
			if items.get("lock", 0) > 0 and ev != null and ev["type"] == "choro":
				_use_item("lock")
				lock_t = 6.0
				toast("Candado puesto: el choro se fue con las manos vacías")
				end_ev(true)
		"item:perf":
			use_perfume()
		"item:bill":
			if items.get("bill", 0) > 0 and vend != null:
				_use_item("bill")
				Game.profile["coins"] = maxi(0, Game.profile["coins"] - 5)
				update_coins()
				toast("Le compraste un caramelo y se fue")
				end_vend(true)
		"nogracias":
			if vend != null:
				vend["n"] += 1
				if vend["n"] >= 3:
					toast("¡Se rindió! Siguió con otro")
					end_vend(true)
				else:
					vend["win"] = maxf(1.0, vend["win"] - 0.18)
					_vend_offer()


# =====================================================================
#  LÓGICA POR CUADRO
# =====================================================================

func _step(dt: float) -> void:
	t += dt
	if toast_t > 0:
		toast_t -= dt
		if toast_t <= 0:
			create_tween().tween_property(ui["toast"], "modulate:a", 0.0, 0.25)
	if lock_t > 0:
		lock_t -= dt
	if perf_t > 0:
		perf_t -= dt
		if ev != null and ev.has("ctx") and is_instance_valid(ev["ctx"]):
			ev["ctx"].overlay_text = str(maxi(1, ceili(perf_t))) if perf_t > 0 else ""
			ev["ctx"].queue_redraw()
	if cafe_t > 0:
		cafe_t -= dt
	ui["route"].set_values({"fill": minf(1.0, t / Game.TRIP_SECONDS)})
	if t >= Game.TRIP_SECONDS:
		end_trip()
		return
	if fall_t > 0:
		fall_t -= dt

	_step_walkers(dt)

	# El director: nunca más de 2 segundos sin evento
	if ev == null and vend == null and t - last_ev_end > 2.0:
		var cand := walkers.filter(func(w): return not w["parked"] and w["state"] == "walk" and w["wait"] <= 0 and w["cool"] <= 0 and not (w["type"] == "choro" and lock_t > 0))
		var boosting := cand.any(func(w): return w["boost"] > 1.0)
		if cand.size() > 0 and not boosting:
			for w in cand:
				if w["dir"] < 0 and w["z"] < TRIG_Z - 1:
					w["dir"] = 1
			var toward := cand.filter(func(w): return w["dir"] > 0 and w["z"] < TRIG_Z)
			toward.sort_custom(func(a, c): return a["z"] > c["z"])
			if toward.size() > 0:
				toward[0]["boost"] = 2.6
	# Aviso "!" sobre el que está por llegar
	if ev == null:
		var nexts := walkers.filter(func(w): return vend == null and not w["parked"] and w["state"] == "walk" and w["dir"] > 0 and w["cool"] <= 0 and w["z"] < TRIG_Z and TRIG_Z - w["z"] < 2.2)
		nexts.sort_custom(func(a, c): return a["z"] > c["z"])
		marker.visible = nexts.size() > 0
		if nexts.size() > 0:
			var r: Node3D = nexts[0]["d"]["root"]
			marker.position = r.position + Vector3(0, 2.3 + sin(t * 8) * .06, 0)

	# Sueño programado
	if ev == null and vend == null and sleep_at.size() > 0 and t >= sleep_at[0]:
		if t - last_ev_end > 1.2 and (tilt == null or combos_ok()):
			sleep_at.pop_front()
			seen["sueno"] = true
			start_ev("sueno", null)

	# Vendedor
	if vend != null:
		vend["ot"] += dt
		vend["m"].set_values({"fill": maxf(0.0, 1.0 - vend["ot"] / vend["win"])})
		if vend["ot"] >= vend["win"]:
			var lost := mini(20, Game.profile["coins"])
			Game.profile["coins"] -= lost
			robbed += lost
			update_coins()
			end_vend(false)
			toast("Te enchufó unas medias: −20 monedas")

	if ev != null:
		_step_event(dt)
		if phase != "play":
			return

	_step_balance(dt)


func _step_walkers(dt: float) -> void:
	for w in walkers:
		var root: Node3D = w["d"]["root"]
		var inner: Node3D = w["d"]["inner"]
		if w["parked"]:
			root.position = Vector3(.85, 0, PIBE_Z - .15)
			root.rotation.y = PI
			continue
		if w["cool"] > 0:
			w["cool"] -= dt
		if w["wait"] > 0:
			w["wait"] -= dt
		elif w["state"] == "walk":
			w["z"] += w["dir"] * w["speed"] * w["boost"] * dt
			if w["z"] > Z_MAX:
				w["z"] = Z_MAX
				w["dir"] = -1
				w["boost"] = 1.0
			if w["z"] < Z_MIN:
				w["z"] = Z_MIN
				w["dir"] = 1
			var near: bool = w["dir"] > 0 and absf(w["z"] - TRIG_Z) < 0.18
			if near and w["cool"] <= 0:
				w["boost"] = 1.0
				if w["type"] == "vend":
					# El vendedor nunca se junta con otro evento de botón: si hay uno, espera a que termine
					if vend == null and ev == null and t - last_ev_end > 1.2 and not (tutorial_mode and not vend_seen and tilt != null):
						seen["vend"] = true
						start_vend(w)
					else:
						w["z"] = TRIG_Z - 0.19
				else:
					# Mientras está el vendedor no arranca ningún otro evento de botón
					var free: bool = ev == null and vend == null and t - last_ev_end > 1.2 and (tilt == null or combos_ok())
					if w["type"] == "choro" and lock_t > 0:
						toast("Candado puesto: el choro pasó de largo")
						w["cool"] = 6.0
						ok_count += 1
						last_ev_end = t
					elif free:
						seen[w["type"]] = true
						match w["type"]:
							"olor":
								start_ev("olor", w)
							"choro":
								start_ev("choro", w)
							"emb":
								start_ev("fingir" if emb_choice == "fingir" else "eleccion", w)
					elif ev == null:
						w["z"] = TRIG_Z - 0.19
					else:
						w["cool"] = 2.0
		if w["state"] == "slow":
			w["z"] = minf(Z_MAX, w["z"] + dt * (Z_MAX - TRIG_Z) / 6.0)
			w["dir"] = 1
			inner.position.y = absf(sin(t * 4)) * .04
		var x := 0.05 if (w["type"] == "vend" and w["state"] == "hold") else WALK_X
		root.position = Vector3(x, 0, w["z"])
		root.rotation.y = PI * 0.8 if w["state"] == "hold" else (0.0 if w["dir"] > 0 else PI)
		if w["state"] == "walk" and w["wait"] <= 0:
			inner.position.y = absf(sin(t * 8 + w["speed"] * 3)) * .05


func _step_event(dt: float) -> void:
	ev["t"] += dt
	match ev["type"]:
		"olor":
			var left: float = ev["stay"] - ev["t"]
			ev["face_m"].set_values({"face": minf(1.0, ev["t"] / ev["stay"])})
			if ev["holding"]:
				ev["lungs"] -= dt * 100.0 / Game.lung_secs()
				ev["breath_t"] = 0.0
			elif perf_t > 0:
				ev["lungs"] = minf(100.0, ev["lungs"] + dt * 70.0)
			elif ev["breathing"]:
				ev["zone"]["w"] -= dt * 0.13
				ev["zone"]["a"] += dt * 0.065
				if ev["zone"]["w"] <= 0:
					end_ev(false)
					flash(Color("3e9b47"))
					add_shame("vomito", "Se te acabó el aire limpio y vomitaste.")
					return
			elif ev["started"] or ev["t"] > 1.6:
				ev["breath_t"] += dt
				if ev["breath_t"] > 0.15:
					end_ev(false)
					flash(Color("3e9b47"))
					add_shame("vomito", "¡Vomitaste en el colectivo!")
					return
			var used: float = minf(1.0, 1.0 - maxf(0.0, ev["lungs"]) / 100.0)
			var z: Dictionary = ev["zone"]
			ev["lung_m"].set_values({"fill": used, "needle": used, "zones": [{"a": z["a"], "w": maxf(0.0, z["w"]), "c": C_GREEN}]})
			if ev["lungs"] <= 0:
				end_ev(false)
				fall(1.0)
				add_shame("desmayo", "Te desmayaste por aguantar de más.")
				return
			if left <= 0:
				toast("¡Zafaste! El oloroso siguió de largo")
				end_ev(true)
		"choro":
			ev["p"] = minf(1.0, ev["p"] + dt * (0.22 + Game.diff() * 0.04))
			ev["tug_m"].set_values({"needle": ev["p"]})
			var r: Node3D = ev["w"]["d"]["root"]
			marker.position = r.position + Vector3(0, 2.3 + sin(t * 6) * .05, 0)
			if ev["p"] <= 0.04:
				toast("¡Te lo sacaste de encima!")
				end_ev(true)
			elif ev["p"] >= 0.96:
				var lost := mini(30, Game.profile["coins"])
				Game.profile["coins"] -= lost
				robbed += lost
				update_coins()
				end_ev(false)
				add_shame("robo", "Te robaron 30 monedas.")
		"eleccion":
			var left2: float = ev["limit"] - ev["t"]
			ev["time_l"].text = "%d s" % ceili(maxf(0, left2))
			if left2 <= 0:
				end_ev(false)
				add_shame("visto", "No hiciste nada y te miró feo.")
		"fingir":
			if ev["holding"]:
				ev["pos"] = minf(1.0, ev["pos"] + dt * (0.26 if cafe_t > 0 else 0.42))
			ev["f_m"].set_values({"needle": ev["pos"]})
			if not ev["started"] and ev["t"] > 2.5:
				end_ev(false)
				add_shame("visto", "Te vio despierto.")
			elif ev["pos"] >= 1.0:
				ev["holding"] = false
				end_ev(false)
				fall(-1.0)
				add_shame("dormir", "Te dormiste de verdad y te caíste.")
		"sueno":
			ev["v"] = maxf(0.0, ev["v"] - dt * 0.14)
			ev["s_m"].set_values({"needle": ev["v"]})
			var left3: float = ev["dur"] - ev["t"]
			ev["time_l"].text = "%d s" % ceili(maxf(0, left3))
			if left3 <= 0:
				if ev["v"] >= 0.8:
					toast("¡Despierto! Bien ahí")
					end_ev(true)
				else:
					end_ev(false)
					fall(1.0)
					add_shame("dormir", "Te dormiste y te caíste.")


func _shot_time() -> float:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot-time="):
			return float(a.substr(12))
	return 10.0


func _sensor_ctrl() -> float:
	# Inclinar el celular: el acelerómetro marca la gravedad sobre el eje X de la pantalla
	var acc := Input.get_accelerometer()
	if acc.length() < 1.0:
		return 0.0
	var v := -acc.x / 3.5
	if absf(v) < 0.12:
		return 0.0
	return clampf(v, -1.0, 1.0)


func _step_balance(dt: float) -> void:
	if tilt == null and fall_t <= 0:
		next_tilt -= dt
		if next_tilt <= 0:
			if ev != null and not combos_ok():
				next_tilt = 1.5
			else:
				next_tilt = maxf(3.5, 5.0 - Game.diff() * 0.4) + randf() * 3.0
				start_tilt()
				if phase != "play":
					return
	# El colectivo se mueve todo el tiempo: siempre hay que corregir un poco
	var ramp := minf(1.0, 0.35 + t / 45.0) if Game.first_day() else 1.0
	var sway := (sin(t * 0.9) * 0.55 + sin(t * 2.3 + 1.0) * 0.3) * (0.5 if ev != null else 1.0) * (1.3 if ceded else 1.0) * ramp
	var ctrl := float(ctrl_key) if ctrl_key != 0 else (float(ctrl_arrow) if ctrl_arrow != 0 else (ctrl_drag if absf(ctrl_drag) > 0.01 else _sensor_ctrl()))
	if autotest:
		ctrl = clampf(-b * 2.0, -1.0, 1.0)
	var force := sway
	if tilt != null:
		tilt["t"] += dt
		force += tilt["dir"] * tilt["amp"] * sin(PI * minf(1.0, tilt["t"] / tilt["dur"]))
	if fall_t <= 0:
		b += (force + ctrl * 1.8 - b * 0.5) * dt
		if absf(b) >= 1.0:
			fall(signf(b))
			add_shame("caer", "¡Te caíste!")
			return
	ui["balance"].set_values({"dot": 0.5 + clampf(b, -1, 1) * 0.5})
	if tilt != null and tilt["t"] >= tilt["dur"]:
		tilt = null
		ok_count += 1


# =====================================================================
#  CADA CUADRO: animaciones, cámara y piloto automático de prueba
# =====================================================================

var _dbg_frames := 0


## Solo para revisar el diseño: -- --tap=go:skins,pick:ramal --shot=archivo.png
func _debug_shots() -> void:
	_dbg_frames += 1
	var args := OS.get_cmdline_user_args()
	if _dbg_frames == 20:
		for a in args:
			if a.begins_with("--tap="):
				for id in a.substr(6).split(","):
					if id == "spin":
						spin = 2.6
					else:
						_tap(id)
	if _dbg_frames == 70:
		for a in args:
			if a.begins_with("--shot="):
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(a.substr(7))
				get_tree().quit()


func _process(delta: float) -> void:
	var dt := minf(0.05, delta)
	if not autotest:
		_debug_shots()
	if autotest and phase == "play":
		_autopilot(dt)
	if phase == "play":
		_step(dt)
	var now := Time.get_ticks_msec() / 1000.0
	var root: Node3D = pibe["root"]
	var px := 0.35 if ceded else 0.75
	root.position.x += (px - root.position.x) * minf(1.0, dt * 4.0)
	var lean := b * 0.35
	if fall_t > 0:
		lean = fall_dir * 1.25 * sin(PI * minf(1.0, (1.4 - fall_t) / 1.4))
	root.rotation.z = lean + (0.0 if (tilt != null or fall_t > 0) else sin(now * 1.1) * 0.03)
	var sleepy: bool = ev != null and ((ev["type"] == "fingir" and (ev["holding"] or ev["pos"] > 0)) or (ev["type"] == "sueno" and ev["v"] < 0.5))
	root.rotation.x = 0.28 if sleepy else 0.0
	pibe["inner"].scale = Vector3.ONE * (0.73 if (ev != null and ev["type"] == "olor" and ev["holding"]) else 0.7)
	if ceded:
		Characters.set_grab(pibe, false)

	if phase == "screen":
		# Menú: el pibe de frente, girando para lucir la camiseta
		if spin_pause > 0:
			spin_pause -= dt
		elif screens.current == "skins" and spin_index < 0:
			spin += dt * 0.7
		root.position = Vector3(0, 0, PIBE_Z)
		root.rotation = Vector3(0, spin + (0.0 if screens.current == "skins" else sin(now * 0.6) * 0.35), 0)
		if screens.current == "skins":
			cam.position = Vector3(0, 1.1, PIBE_Z + 5.6)
			cam.look_at(Vector3(0, -0.15, PIBE_Z))
		else:
			cam.position = Vector3(0, 1.45, PIBE_Z + 5.4)
			cam.look_at(Vector3(0, 0.45, PIBE_Z))
		_animate_ambient(dt, now)
		return
	# Cámara alta, detrás del pibe
	cam.position = Vector3(root.position.x - .25, 2.52, PIBE_Z + 4.4)
	cam.look_at(Vector3(root.position.x * .3, .95, PIBE_Z - 6))
	var roll := 0.0
	if tilt != null:
		roll = tilt["dir"] * sin(PI * minf(1.0, tilt["t"] / tilt["dur"])) * 0.05
	else:
		roll = sin(now * 0.9) * 0.006
	cam.rotate_object_local(Vector3(0, 0, 1), roll)
	_animate_ambient(dt, now)


func _animate_ambient(dt: float, now: float) -> void:

	# Olor y moscas
	var near: bool = ev != null and ev["type"] == "olor"
	for s in stink_parts:
		var u := fmod(float(s.get_meta("t")) + now * 0.25, 1.0)
		var sc := 1.6 if near else 1.0
		var a: float = s.get_meta("a")
		var r := (0.75 + sin(u * 9 + a) * 0.08) * sc
		s.position = Vector3(cos(a) * r, 0.9 + u * 2.2, sin(a) * r)
		s.material_override.albedo_color.a = 0.85 * (1.0 - u)
		s.scale = Vector3.ONE * (0.6 + u) * sc
	for f in fly_parts:
		var fa: float = f.get_meta("a") + now * 3.2
		var fr: float = f.get_meta("r")
		f.position = Vector3(cos(fa) * fr, float(f.get_meta("y")) + sin(now * 7 + float(f.get_meta("a"))) * .08, sin(fa) * fr)

	# La ciudad pasa por la ventana
	var speed := 3.0 if phase != "play" else (2.0 if tilt != null else 7.0)
	for g in outside:
		g.position.z += speed * dt
		if g.position.z > 12:
			g.position.z -= 52


## Piloto automático solo para pruebas (godot --headless -- --autotest)
func _autopilot(dt: float) -> void:
	auto_t += dt
	# Captura de pantalla para revisar el diseño: -- --autotest --shot=archivo.png --shot-time=28
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot=") and t >= _shot_time() and not has_meta("shot_done"):
			set_meta("shot_done", true)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(a.substr(7))
			get_tree().quit()
	if vend != null and vend["ot"] > 0.4:
		_tap("nogracias")
	if ev == null:
		return
	match ev["type"]:
		"olor":
			var used: float = 1.0 - ev["lungs"] / 100.0
			var z: Dictionary = ev["zone"]
			if not ev["holding"] and not ev["breathing"] and ev["t"] > 0.2:
				press()
			elif ev["holding"] and used >= z["a"] + z["w"] * 0.5:
				release()
			elif ev["breathing"] and z["w"] < 0.12:
				press()
		"choro", "sueno":
			if fmod(auto_t, 0.12) < dt:
				press()
		"eleccion":
			if ev["t"] > 0.5:
				_tap("fingir")
		"fingir":
			if not ev["holding"] and ev["pos"] < 0.5 and ev["t"] > 0.3:
				press()
			elif ev["holding"] and ev["pos"] >= 0.65:
				release()
