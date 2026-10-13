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
	if animate:
		wrap.position.y = 1400
		var tw := create_tween()
		tw.tween_property(wrap, "position:y", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func close() -> void:
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
	for it in [["go:tienda", "Tienda", "shop"], ["go:habilidades", "Habilidades", "bars"], ["go:skins", "Camisetas", "shirt"]]:
		var b: TouchButton = trip._tb(it[0], it[1], Vector2(180, 128), Color("eef1f5"))
		b.icon = it[2]
		b.font_size = 24
		b.shadow = Color(0, 0, 0, 0)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)
	v.add_child(row)
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
	else:
		action = trip._tb("buyskin", "Comprar ● %d" % sel["price"], Vector2(250, 80), C_YELLOW)
		action.shadow = Color("b58600")
		action.disabled = p["coins"] < sel["price"]
	action.radius = 999
	action.font_size = 26
	action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(action)
	v.add_child(head)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for s in Game.SKINS:
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
		trip.go_menu(current)
	elif id.begins_with("buy:"):
		var item := id.substr(4)
		if Game.buy_item(item):
			trip.update_coins()
			render()
			for it in Game.ITEMS:
				if it["id"] == item:
					say("Compraste %s." % String(it["name"]).to_lower())
	elif id.begins_with("up:"):
		var sk := id.substr(3)
		if Game.upgrade_skill(sk):
			trip.update_coins()
			render()
			say("¡Subiste a nivel %d! Se nota en el próximo viaje." % Game.skill_level(sk))
	elif id.begins_with("pick:"):
		preview = id.substr(5)
		trip.show_skin(preview)
		render()
	elif id == "buyskin":
		if Game.buy_skin(preview):
			trip.update_coins()
			render()
			say("¡Ya tenés puesta la de %s!" % Game.skin(preview)["name"])
	elif id == "equip":
		p["eq"] = preview
		Game.save()
		render()
