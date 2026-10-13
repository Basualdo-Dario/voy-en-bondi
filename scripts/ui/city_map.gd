class_name CityMap
extends Control
## Plano de la ciudad de un capítulo: calles de fondo, los 4 barrios como manzanas
## (botones que agrega screens.gd en `grid`) y el recorrido del colectivo que los une.

var grid := GridContainer.new()
var line_color := Color("f2b705")


func _init() -> void:
	custom_minimum_size = Vector2(0, 430)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.columns = 2
	grid.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		grid.set("offset_" + side, 26 if side in ["left", "top"] else -26)
	grid.add_theme_constant_override("h_separation", 44)
	grid.add_theme_constant_override("v_separation", 44)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.sort_children.connect(queue_redraw)
	add_child(grid)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("e4ead9")          # pasto / veredas
	sb.set_corner_radius_all(30)
	sb.draw(get_canvas_item(), r)
	# Calles: una cruz por el medio y un anillo alrededor de las manzanas
	var road := Color("c9cfd6")
	var mid := r.get_center()
	draw_rect(Rect2(0, mid.y - 16, r.size.x, 32), road)
	draw_rect(Rect2(mid.x - 16, 0, 32, r.size.y), road)
	for i in range(1, 12):
		draw_rect(Rect2(i * r.size.x / 12.0 - 8, mid.y - 2, 16, 4), Color.WHITE)   # líneas de la calle
	# Recorrido del colectivo: une los barrios en orden (arriba izq → arriba der → abajo der → abajo izq)
	var tiles := grid.get_children()
	if tiles.size() < 4:
		return
	var pts := PackedVector2Array()
	for i in [0, 1, 3, 2]:
		var t: Control = tiles[i]
		pts.append(grid.position + t.position + t.size / 2.0)
	draw_polyline(pts, Color(1, 1, 1, 0.9), 22, true)
	draw_polyline(pts, line_color, 12, true)
	for p in pts:
		draw_circle(p, 16, Color.WHITE)
		draw_circle(p, 10, line_color)
