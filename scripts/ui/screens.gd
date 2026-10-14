class_name Screens
extends Control
## Menú principal, tienda, habilidades y camisetas.
## Los paneles suben desde abajo y la flechita los vuelve a bajar, igual que en la demo.

const C_INK := Color("1b2430")
const C_MUTED := Color("5b6573")
const C_YELLOW := Color("f2b705")
const C_SOFT := Color("f6f8fa")

var trip: Trip            # el nodo del viaje (trip.gd): usamos sus ayudantes de interfaz
var current := "menu"
var preview := "buzo"    # camiseta que se está probando
var from_start := false  # si la tienda se abrió desde el cartel de ¡ARRANCAR!
var map_chapter := 0     # capítulo que se ve en el mapa
var map_barrio := 0      # barrio elegido en el mapa (se ve su recorrido)
var skins_tab := "clubes"  # "clubes" (se compran) o "premios" (se ganan en los barrios)
var wrap: Control
var msg: Label


func _init(p_trip) -> void:
	trip = p_trip
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func open(screen: String) -> void:
	current = screen
	if screen != "skins":
		preview = Game.profile["eq"]
	if screen != "menu":
		Audio.play("ui_open", -4.0)
	render(true)


func clear() -> void:
	trip._clear(self)


func render(animate := false) -> void:
	clear()
	if current == "menu":
		_logo()
	if current == "skins":
		var tip := trip._panel(Color(1, 1, 1, 0.9), 999)
		tip.add_child(trip._label("Arrastrá para girar al pibe", 22, C_INK, HORIZONTAL_ALIGNMENT_CENTER))
		var cc := CenterContainer.new()
		cc.set_anchors_preset(Control.PRESET_TOP_WIDE)
		cc.offset_top = 150
		cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cc.add_child(tip)
		add_child(cc)
	wrap = Control.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wrap)
	var sheet: PanelContainer = trip._panel(Color.WHITE, 46)
	var sb: StyleBoxFlat = sheet.get_theme_stylebox("panel")
	for side in ["left", "right", "top", "bottom"]:
		sb.set("content_margin_" + side, 28)
	sheet.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	sheet.grow_vertical = Control.GROW_DIRECTION_BEGIN
	sheet.offset_left = 20
	sheet.offset_right = -20
	sheet.offset_top = -20
	sheet.offset_bottom = -20
	wrap.add_child(sheet)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	sheet.add_child(v)
	match current:
		"menu":
			_menu(v)
		"tienda":
			_shop(v)
		"habilidades":
			_skills(v)
		"skins":
			_skins(v)
		"mapa":
			_map(v)
		"config":
			_config(v)
	if animate:
		wrap.position.y = 1400
		var tw := create_tween()
		tw.tween_property(wrap, "position:y", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func close() -> void:
	Audio.play("ui_close")
	var tw := create_tween()
	tw.tween_property(wrap, "position:y", 1400.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		if from_start:
			from_start = false
			trip.reset_trip()
		else:
			trip.go_menu("menu"))


func say(text: String) -> void:
	if is_instance_valid(msg):
		msg.text = text


# ---------------------------------------------------------------------

func _logo() -> void:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	var sign := trip._panel(C_YELLOW, 30)
	var ssb: StyleBoxFlat = sign.get_theme_stylebox("panel")
	ssb.shadow_color = Color("b58600")
	ssb.shadow_offset = Vector2(0, 10)
	ssb.content_margin_left = 36
	ssb.content_margin_right = 36
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", -14)
	sv.add_child(trip._label("VOY EN", 30, C_INK, HORIZONTAL_ALIGNMENT_CENTER))
	sv.add_child(trip._label("BONDI", 76, C_INK, HORIZONTAL_ALIGNMENT_CENTER))
	sign.add_child(sv)
	sign.rotation_degrees = -3
	var sign_c := CenterContainer.new()
	sign_c.add_child(sign)
	box.add_child(sign_c)
	var slogan := trip._panel(Color(1, 1, 1, 0.9), 999)
	slogan.add_child(trip._label("Llegá a destino, si podés", 24, C_INK, HORIZONTAL_ALIGNMENT_CENTER))
	var sl_c := CenterContainer.new()
	sl_c.add_child(slogan)
	box.add_child(sl_c)
	box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	box.offset_top = 112
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	sign.pivot_offset = sign.size / 2.0


func _handle(v: VBoxContainer) -> void:
	var c := CenterContainer.new()
	var h: TouchButton = trip._tb("close_sheet", "", Vector2(130, 64), Color("eef1f5"))
	h.icon = "down"
	h.radius = 999
	h.shadow = Color(0, 0, 0, 0)
	c.add_child(h)
	v.add_child(c)


func _msg(v: VBoxContainer, text := "") -> void:
	msg = trip._label(text, 21, C_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(msg)


func _menu(v: VBoxContainer) -> void:
	var p := Game.profile
	var br := Game.barrio()
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	top.add_child(_line_chip(br))
	var where := trip._label(("Modo libre" if Game.story_done() else br["name"]), 22, C_MUTED)
	where.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(where)
	v.add_child(top)
	var head := HBoxContainer.new()
	var day := trip._label(Game.day_name(), 34)
	day.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(day)
	head.add_child(trip._label("Viaje %d de 4" % (p["trip"] + 1), 22, C_MUTED))
	v.add_child(head)

	var trips := HBoxContainer.new()
	trips.add_theme_constant_override("separation", 10)
	var results: Array = p["results"]
	for i in Game.TRIPS.size():
		var r: String = results[i] if i < results.size() else ""
		var bg := Color("eef1f5")
		var fg := Color("4a5565")
		var mark := str(i + 1)
		if r == "ok":
			bg = Color("e3f2e5")
			fg = Color("2e7d32")
			mark = "✓"
		elif r == "fail":
			bg = Color("fbe3ea")
			fg = Color("b0264f")
			mark = "✗"
		elif i == p["trip"]:
			bg = Color("fff3c4")
			fg = C_INK
		var chip: PanelContainer = trip._panel(bg, 22)
		var csb: StyleBoxFlat = chip.get_theme_stylebox("panel")
		csb.content_margin_left = 6
		csb.content_margin_right = 6
		if i == p["trip"] and r == "":
			csb.set_border_width_all(4)
			csb.border_color = C_YELLOW
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 0)
		cv.add_child(trip._label(mark, 30, fg, HORIZONTAL_ALIGNMENT_CENTER))
		var tl := trip._label("%s →\n%s" % [Game.TRIPS[i]["from"], Game.TRIPS[i]["to"]], 18, fg, HORIZONTAL_ALIGNMENT_CENTER)
		cv.add_child(tl)
		chip.add_child(cv)
		trips.add_child(chip)
	v.add_child(trips)

	var play: TouchButton = trip._tb("play", "EMPEZAR EL DÍA" if p["trip"] == 0 else "SEGUIR EL DÍA", Vector2(300, 116), C_YELLOW)
	play.font_size = 40
	play.shadow = Color("b58600")
	play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(play)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	for it in [["go:mapa", "Mapa", "map"], ["go:tienda", "Tienda", "shop"], ["go:habilidades", "Habilidades", "bars"], ["go:skins", "Camisetas", "shirt"]]:
		var b: TouchButton = trip._tb(it[0], it[1], Vector2(130, 128), Color("eef1f5"))
		b.icon = it[2]
		b.font_size = 21
		b.shadow = Color(0, 0, 0, 0)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)
	v.add_child(row)
	_msg(v)


# ---------- Configuración ----------

# Rango y paso de los valores que se ajustan con − y +
const STEPS := {"music": [0.0, 1.0, 0.1], "sfx": [0.0, 1.0, 0.1], "tilt_sens": [0.5, 2.0, 0.25]}
const CREDITS := "Idea y diseño: Dario.\nProgramación: Dario con Claude.\n\nLetra: Fredoka (licencia OFL).\nEfectos de sonido: Kenney, GGBotNet y Joseph Sardin (BigSoundBank), todos CC0.\nMúsica: hecha para el juego.\n\nClubes, barrios y líneas son inventados."


func _config(v: VBoxContainer) -> void:
	_handle(v)
	v.add_child(trip._label("Configuración", 44))
	var lang: String = Game.setting("lang")
	_set_row(v, "Idioma", [_choice("lang:es", "Español", lang == "es"), _choice("lang:en", "English", lang == "en")])
	_set_row(v, "Música", _stepper("music"))
	_set_row(v, "Efectos", _stepper("sfx"))
	_set_row(v, "Sonido", [_toggle("tog:mute", not Audio.muted)])
	_set_row(v, "Inclinar el celular", [_toggle("tog:tilt", Game.setting("tilt"))])
	if Game.setting("tilt"):
		_set_row(v, "Sensibilidad", _stepper("tilt_sens"))
	_set_row(v, "Vibración", [_toggle("tog:vibra", Game.setting("vibra"))])
	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", 12)
	for a in [["practice", "Viaje de\npráctica", C_YELLOW], ["credits", "Créditos", Color("eef1f5")], ["reset", "Reiniciar\npartida", Color("fbe3ea")]]:
		var b: TouchButton = trip._tb(a[0], a[1], Vector2(150, 100), a[2])
		b.font_size = 22
		b.shadow = Color("b58600") if a[2] == C_YELLOW else Color(0, 0, 0, 0)
		if a[0] == "reset":
			b.fg = Color("b0264f")
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		acts.add_child(b)
	v.add_child(acts)
	_msg(v)


## Fila de configuración: nombre a la izquierda y los controles a la derecha
func _set_row(v: VBoxContainer, title: String, controls: Array) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var l: Label = trip._label(title, 24)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	for c in controls:
		row.add_child(c)
	v.add_child(row)


func _choice(id: String, text: String, on: bool) -> TouchButton:
	var b: TouchButton = trip._tb(id, text, Vector2(140, 64), C_YELLOW if on else Color("eef1f5"))
	b.font_size = 22
	b.radius = 999
	b.shadow = Color("b58600") if on else Color(0, 0, 0, 0)
	return b


## Interruptor Sí/No
func _toggle(id: String, on: bool) -> TouchButton:
	var b: TouchButton = trip._tb(id, "Sí" if on else "No", Vector2(120, 64), Color("3fae5a") if on else Color("e3e7ed"))
	b.fg = Color.WHITE if on else Color("5b6573")
	b.font_size = 24
	b.radius = 999
	b.shadow = Color("2e7d32") if on else Color(0, 0, 0, 0)
	return b


## − barra +
func _stepper(key: String) -> Array:
	var r: Array = STEPS[key]
	var val: float = Game.setting(key)
	var minus: TouchButton = trip._tb("dec:" + key, "−", Vector2(64, 64), Color("eef1f5"))
	var plus: TouchButton = trip._tb("inc:" + key, "+", Vector2(64, 64), Color("eef1f5"))
	for b in [minus, plus]:
		b.font_size = 34
		b.radius = 999
		b.shadow = Color(0, 0, 0, 0)
	var m := Meter.new(18)
	m.custom_minimum_size = Vector2(150, 18)
	m.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	m.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	m.fill_color = C_YELLOW
	m.fill = (val - r[0]) / (r[1] - r[0])
	return [minus, m, plus]


func _config_tap(id: String) -> void:
	if id.begins_with("lang:"):
		Game.set_setting("lang", id.substr(5))
		render()
		if id == "lang:en":
			say("La traducción al inglés llega en la próxima actualización. Por ahora el juego sigue en español.")
	elif id.begins_with("dec:") or id.begins_with("inc:"):
		var key := id.substr(4)
		var r: Array = STEPS[key]
		var val: float = Game.setting(key)
		val += r[2] if id.begins_with("inc:") else -r[2]
		Game.set_setting(key, snappedf(clampf(val, r[0], r[1]), 0.01))
		Audio.apply_settings()
		render()
		Audio.play("tap")
	elif id == "tog:mute":
		Audio.set_muted(not Audio.muted)
		Game.save()
		render()
	elif id == "tog:tilt" or id == "tog:vibra":
		var key := id.substr(4)
		Game.set_setting(key, not Game.setting(key))
		render()
		if key == "vibra" and Game.setting("vibra"):
			Game.vibrate(120)
	elif id == "practice":
		Game.start_practice()
		trip.reset_trip()
	elif id == "credits":
		trip.show_modal("Créditos", "Voy en Bondi", CREDITS, [], [["modal_back", "VOLVER", 420, C_YELLOW]])
	elif id == "reset":
		trip.show_modal("Reiniciar partida", "¿Seguro?", "Se borran tus monedas, compras, mejoras y el avance de la historia. La configuración se mantiene.", [],
			[["reset_ok", "SÍ, BORRAR", 260, Color("c2362b")], ["modal_back", "CANCELAR", 260, Color("eef1f5")]])
	elif id == "reset_ok":
		Game.reset_progress()
		Audio.apply_settings()
		trip.go_menu("menu")


## Chapita con el número de la línea, en su color
func _line_chip(br: Dictionary) -> PanelContainer:
	var c := Color(br["color"])
	var chip: PanelContainer = trip._panel(c, 999)
	var fg := C_INK if c.get_luminance() > 0.55 else Color.WHITE
	var l: Label = trip._label("LÍNEA %s" % br["line"], 20, fg, HORIZONTAL_ALIGNMENT_CENTER)
	l.add_theme_font_override("font", Game.font_bold)
	chip.add_child(l)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return chip


## Estado de un barrio en el mapa: "done", "current" o "locked"
func _barrio_state(i: int) -> String:
	var reached := int(Game.profile["barrio"])
	if i < reached:
		return "done"
	return "current" if i == reached else "locked"


func _map(v: VBoxContainer) -> void:
	_handle(v)
	# Pestañas de capítulos (los que todavía no llegaste quedan bloqueados)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	for c in Game.CHAPTERS.size():
		var sel := c == map_chapter
		var t: TouchButton = trip._tb("chap:%d" % c, "Cap. %d · %s" % [c + 1, Game.CHAPTERS[c]["title"]], Vector2(120, 66), C_YELLOW if sel else Color("eef1f5"))
		t.font_size = 21
		t.radius = 999
		t.shadow = Color("b58600") if sel else Color(0, 0, 0, 0)
		t.disabled = c > Game.chapter_index(int(Game.profile["barrio"]) if not Game.story_done() else Game.BARRIOS.size() - 1)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(t)
	v.add_child(tabs)

	# Meta del capítulo y cuánto falta
	var ch: Dictionary = Game.CHAPTERS[map_chapter]
	var done := Game.chapter_progress(map_chapter)
	var meta := HBoxContainer.new()
	var ml: Label = trip._label("Meta: %s" % ch["goal"].to_lower(), 22)
	ml.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ml.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.add_child(ml)
	meta.add_child(trip._label("%d de %d" % [done, Game.BARRIOS_PER_CHAPTER], 22, Color("2e7d32")))
	v.add_child(meta)
	var pm := Meter.new(16)
	pm.fill_color = Color("3fae5a")
	pm.fill = float(done) / Game.BARRIOS_PER_CHAPTER
	v.add_child(pm)

	# La ciudad: los 4 barrios del capítulo
	var city := CityMap.new()
	var first := map_chapter * Game.BARRIOS_PER_CHAPTER
	city.line_color = Color(Game.BARRIOS[clampi(map_barrio, first, first + 3)]["color"])
	for i in range(first, first + Game.BARRIOS_PER_CHAPTER):
		var br: Dictionary = Game.BARRIOS[i]
		var st := _barrio_state(i)
		var label: String = {"done": "Terminado", "current": "Estás acá", "locked": "Bloqueado"}[st]
		var tile: TouchButton = trip._tb("barrio:%d" % i, "%s\nLínea %s · %s" % [br["name"], br["line"], label], Vector2(200, 150), Color("eef1f5") if st == "locked" else Color(br["color"]).lightened(0.55))
		tile.icon = {"done": "check", "current": "bus", "locked": "lock"}[st]
		tile.font_size = 19
		tile.shadow = Color(0, 0, 0, 0) if st == "locked" else Color(br["color"]).darkened(0.1)
		tile.selected = i == map_barrio
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.size_flags_vertical = Control.SIZE_EXPAND_FILL
		city.grid.add_child(tile)
	v.add_child(city)

	# Recorrido de la semana del barrio elegido
	var sb: Dictionary = Game.BARRIOS[map_barrio]
	var rh := HBoxContainer.new()
	rh.add_theme_constant_override("separation", 10)
	rh.add_child(_line_chip(sb))
	var rl: Label = trip._label("Recorrido de %s" % sb["name"], 22)
	rh.add_child(rl)
	v.add_child(rh)
	var stops := RouteStops.new()
	stops.color = Color(sb["color"])
	match _barrio_state(map_barrio):
		"done":
			stops.done = 5
		"current":
			stops.done = int(Game.profile["day"])
			stops.current = int(Game.profile["day"])
	v.add_child(stops)
	_msg(v)


## Nivel de una habilidad: 5 segmentos, verdes los que ya tenés
func _level_bar(level: int) -> Meter:
	var m := Meter.new(14)
	m.bg = Color(0, 0, 0, 0)
	m.custom_minimum_size = Vector2(220, 14)
	m.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	for i in Game.MAX_LEVEL:
		m.zones.append({"a": i * 0.2 + 0.015, "w": 0.17, "round": true, "c": Color("3fae5a") if i < level else Color("dfe4ea")})
	return m


func _row(icon: String, title: String, sub: String, extra, btn: TouchButton) -> PanelContainer:
	var card: PanelContainer = trip._panel(C_SOFT, 26)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	var ic := TouchButton.new("", "", Vector2(88, 88))
	ic.icon = icon
	ic.shadow = Color(0, 0, 0, 0)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 2)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(trip._label(title, 26))
	var sl := trip._label(sub, 19, C_MUTED)
	sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tv.add_child(sl)
	if extra is Control:
		tv.add_child(extra)
	elif extra != "":
		tv.add_child(trip._label(extra, 22, Color("2e7d32")))
	h.add_child(tv)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(btn)
	card.add_child(h)
	return card


func _buy_button(id: String, label: String, price: int, can: bool) -> TouchButton:
	var b: TouchButton = trip._tb(id, "%s\n● %d" % [label, price] if price >= 0 else label, Vector2(160, 104), C_YELLOW)
	b.font_size = 24
	b.shadow = Color("b58600")
	b.disabled = not can
	return b


func _shop(v: VBoxContainer) -> void:
	_handle(v)
	v.add_child(trip._label("Tienda", 44))
	var p := Game.profile
	for it in Game.ITEMS:
		var id: String = it["id"]
		var have := int(p["inv"].get(id, 0))
		var can: bool = p["coins"] >= it["price"] and have < 9
		v.add_child(_row(id, "%s · tenés %d" % [it["name"], have], "%s Máximo %d por día." % [it["desc"], it["lim"]], "", _buy_button("buy:" + id, "Comprar", it["price"], can)))
	_msg(v, "Lo que compres queda en tu mochila para todo el día.")


func _skills(v: VBoxContainer) -> void:
	_handle(v)
	v.add_child(trip._label("Habilidades", 44))
	var icons := {"pulmones": "lungs", "fuerza": "dumbbell", "verguenza": "blush"}
	for s in Game.SKILLS:
		var id: String = s["id"]
		var l := Game.skill_level(id)
		var maxed := l >= Game.MAX_LEVEL
		var b: TouchButton
		if maxed:
			b = _buy_button("up:" + id, "Al máximo", -1, false)
		else:
			b = _buy_button("up:" + id, "Mejorar", Game.skill_cost(id), Game.profile["coins"] >= Game.skill_cost(id))
		v.add_child(_row(icons[id], s["name"], Game.skill_effect(id), _level_bar(l), b))
	_msg(v)


func _skins(v: VBoxContainer) -> void:
	_handle(v)
	var p := Game.profile
	var sel := Game.skin(preview)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 0)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.add_child(trip._label("Camisetas", 20, C_MUTED))
	hv.add_child(trip._label(sel["name"], 32))
	head.add_child(hv)
	var action: TouchButton
	if p["eq"] == preview:
		action = trip._tb("noop", "Puesta", Vector2(200, 80), Color("ddf1e1"))
		action.fg = Color("2e7d32")
		action.shadow = Color(0, 0, 0, 0)
	elif p["owned"].get(preview, false):
		action = trip._tb("equip", "Ponérmela", Vector2(220, 80), C_YELLOW)
		action.shadow = Color("b58600")
	elif sel.has("prize"):
		# Las de premio no se compran: se ganan terminando su barrio
		action = trip._tb("noop", "Premio del barrio %d" % (int(sel["prize"]) + 1), Vector2(250, 80), C_YELLOW)
		action.disabled = true
	else:
		action = trip._tb("buyskin", "Comprar ● %d" % sel["price"], Vector2(250, 80), C_YELLOW)
		action.shadow = Color("b58600")
		action.disabled = p["coins"] < sel["price"]
	action.radius = 999
	action.font_size = 22 if sel.has("prize") and not p["owned"].get(preview, false) else 26
	action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(action)
	v.add_child(head)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	for t in [["clubes", "Clubes"], ["premios", "Premios de barrio"]]:
		var on: bool = skins_tab == t[0]
		var tb: TouchButton = trip._tb("tab:" + t[0], t[1], Vector2(120, 60), C_YELLOW if on else Color("eef1f5"))
		tb.font_size = 22
		tb.radius = 999
		tb.shadow = Color("b58600") if on else Color(0, 0, 0, 0)
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(tb)
	v.add_child(tabs)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for s in Game.SKINS:
		if s.has("prize") != (skins_tab == "premios"):
			continue
		var id: String = s["id"]
		var name_lines: String = s["name"]
		var parts: PackedStringArray = name_lines.split(" ")
		if parts.size() >= 3:
			name_lines = parts[0] + "\n" + " ".join(parts.slice(1))
		elif parts.size() == 2:
			name_lines = parts[0] + "\n" + parts[1]
		var tag := ""
		if p["owned"].get(id, false):
			tag = "Puesta" if p["eq"] == id else "Tuya"
		elif s.has("prize"):
			tag = "Barrio %d" % (int(s["prize"]) + 1)
		else:
			tag = "● %d" % s["price"]
		var b: TouchButton = trip._tb("pick:" + id, name_lines + "\n" + tag, Vector2(196, 168), C_SOFT)
		b.tex = Skins.texture(id)
		b.font_size = 20
		b.shadow = Color(0, 0, 0, 0)
		b.selected = id == preview
		b.sub_color = Color("2e7d32") if p["owned"].get(id, false) else C_MUTED
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(b)
	v.add_child(grid)
	_msg(v)


# ---------------------------------------------------------------------

func tap(id: String) -> void:
	var p := Game.profile
	if id == "close_sheet":
		close()
	elif id == "play":
		trip.reset_trip()
	elif id.begins_with("go:"):
		current = id.substr(3)
		if current != "skins":
			preview = p["eq"]
		if current == "skins":
			skins_tab = "premios" if Game.skin(p["eq"]).has("prize") else "clubes"
		if current == "mapa":
			map_chapter = Game.chapter_index()
			map_barrio = Game.barrio_index()
		trip.go_menu(current)
	elif id.begins_with("chap:"):
		map_chapter = int(id.substr(5))
		map_barrio = Game.barrio_index() if Game.chapter_index() == map_chapter else map_chapter * Game.BARRIOS_PER_CHAPTER
		render()
	elif id.begins_with("barrio:"):
		var i := int(id.substr(7))
		if _barrio_state(i) == "locked":
			say("Se desbloquea cuando termines %s." % Game.BARRIOS[i - 1]["name"])
		else:
			map_barrio = i
			render()
			say(Game.BARRIOS[i]["intro"])
	elif id.begins_with("tab:"):
		skins_tab = id.substr(4)
		render()
	elif current == "config" or id == "reset_ok":
		_config_tap(id)
	elif id.begins_with("buy:"):
		var item := id.substr(4)
		if Game.buy_item(item):
			Audio.play("buy")
			trip.update_coins()
			render()
			for it in Game.ITEMS:
				if it["id"] == item:
					say("Compraste %s." % String(it["name"]).to_lower())
	elif id.begins_with("up:"):
		var sk := id.substr(3)
		if Game.upgrade_skill(sk):
			Audio.play("buy")
			trip.update_coins()
			render()
			say("¡Subiste a nivel %d! Se nota en el próximo viaje." % Game.skill_level(sk))
	elif id.begins_with("pick:"):
		preview = id.substr(5)
		trip.show_skin(preview)
		render()
	elif id == "buyskin":
		if Game.buy_skin(preview):
			Audio.play("buy")
			trip.update_coins()
			render()
			say("¡Ya tenés puesta la de %s!" % Game.skin(preview)["name"])
	elif id == "equip":
		p["eq"] = preview
		Game.save()
		render()
