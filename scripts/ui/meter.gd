class_name Meter
extends Control
## Barra dibujada a mano: sirve para la vergüenza, el aire, el forcejeo, el sueño y el equilibrio.
## Todos los valores van de 0 a 1.

var bg := Color("e3e7ed")
var fill := 0.0
var fill_color := Color("e0457b")
var zones: Array = []       # [{ "a": desde, "w": ancho, "c": Color }]
var needle := -1.0          # rayita negra (-1 = no se muestra)
var face := -1.0            # carita del oloroso (-1 = no se muestra)
var dot := -1.0             # bolita amarilla del equilibrio (-1 = no se muestra)
var radius := 999


func _init(height := 24.0) -> void:
	custom_minimum_size = Vector2(60, height)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_values(values: Dictionary) -> void:
	for k in values.keys():
		set(k, values[k])
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var rad: int = int(min(radius, size.y / 2.0))
	_rounded(r, bg, rad)
	for z in zones:
		var zr := Rect2(r.position.x + r.size.x * float(z["a"]), 0, r.size.x * float(z["w"]), r.size.y)
		if zr.size.x > 0.5:
			draw_rect(zr, z["c"])
	if fill > 0.0:
		_rounded(Rect2(0, 0, r.size.x * clampf(fill, 0, 1), r.size.y), fill_color, rad)
	if needle >= 0.0:
		var x := r.size.x * clampf(needle, 0, 1)
		draw_rect(Rect2(x - 4, -5, 8, r.size.y + 10), Color("1b2430"))
	if dot >= 0.0:
		var x2 := r.size.x * clampf(dot, 0, 1)
		var cy := r.size.y / 2.0
		draw_circle(Vector2(x2, cy), r.size.y * 0.75 + 4, Color("1b2430"))
		draw_circle(Vector2(x2, cy), r.size.y * 0.75, Color("f2b705"))
	if face >= 0.0:
		var x3 := r.size.x * clampf(face, 0, 1)
		var c := Vector2(x3, r.size.y / 2.0)
		var fr := r.size.y * 0.85
		draw_circle(c, fr + 4, Color("3e9b47"))
		draw_circle(c, fr, Color("d9a27a"))
		draw_circle(c + Vector2(-fr * 0.35, -fr * 0.15), fr * 0.14, Color("1b2430"))
		draw_circle(c + Vector2(fr * 0.35, -fr * 0.15), fr * 0.14, Color("1b2430"))
		draw_arc(c + Vector2(0, fr * 0.55), fr * 0.4, -PI * 0.85, -PI * 0.15, 8, Color("1b2430"), 3)


func _rounded(r: Rect2, c: Color, rad: int) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(rad)
	sb.draw(get_canvas_item(), r)
