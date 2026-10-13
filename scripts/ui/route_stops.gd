class_name RouteStops
extends Control
## Recorrido de un barrio: 5 paradas (lunes a viernes) unidas por la línea del colectivo.
## done = paradas ya hechas; current = parada de hoy (-1 si no hay).

const DAY_SHORT := ["Lun", "Mar", "Mié", "Jue", "Vie"]

var color := Color("f2b705")
var done := 0
var current := -1


func _init() -> void:
	custom_minimum_size = Vector2(0, 132)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var n := DAY_SHORT.size()
	var pad := 44.0
	var y := 68.0
	var step := (size.x - pad * 2.0) / float(n - 1)
	var font: Font = Game.font_bold
	# Tramo hecho en color, lo que falta en gris
	draw_line(Vector2(pad, y), Vector2(size.x - pad, y), Color("dfe4ea"), 12, true)
	var reach := minf(float(maxi(done, current)), float(n - 1))
	if reach > 0:
		draw_line(Vector2(pad, y), Vector2(pad + step * reach, y), color, 12, true)
	for i in n:
		var c := Vector2(pad + step * i, y)
		if i < done:
			draw_circle(c, 20, color)
			draw_polyline(PackedVector2Array([c + Vector2(-8, 0), c + Vector2(-2, 7), c + Vector2(9, -7)]), Color.WHITE, 5, true)
		elif i == current:
			draw_circle(c + Vector2(0, 3), 27, Color(0, 0, 0, 0.15))
			draw_circle(c, 27, Color.WHITE)
			draw_circle(c, 21, color)
			_bus(c + Vector2(0, -48))
		else:
			draw_circle(c, 16, Color("dfe4ea"))
			draw_circle(c, 8, Color.WHITE)
		var col := Color("1b2430") if i == current else Color("5b6573")
		draw_string(font, Vector2(c.x - 40, y + 54), DAY_SHORT[i], HORIZONTAL_ALIGNMENT_CENTER, 80, 22, col)


## Colectivito sobre la parada de hoy
func _bus(c: Vector2) -> void:
	var body := Rect2(c - Vector2(26, 14), Vector2(52, 28))
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(8)
	sb.border_color = Color("1b2430")
	sb.set_border_width_all(3)
	sb.draw(get_canvas_item(), body)
	for i in 3:
		draw_rect(Rect2(body.position + Vector2(7 + i * 14, 6), Vector2(10, 9)), Color("dff1fb"))
	for x in [-14, 14]:
		draw_circle(c + Vector2(x, 15), 6, Color("1b2430"))
