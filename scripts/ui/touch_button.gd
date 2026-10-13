class_name TouchButton
extends Control
## Botón dibujado a mano que responde a varios dedos a la vez.
## El juego (trip.gd) decide qué botón tocaste mirando get_global_rect(),
## porque los botones comunes de Godot solo aceptan un dedo por vez.

var id := ""
var group := "game"          # "game" o "modal": con un cartel abierto solo responden los del cartel
var text := ""
var font_size := 30
var shape := "rect"          # "rect" o "circle"
var bg := Color.WHITE
var fg := Color("1b2430")
var border := Color(0, 0, 0, 0)
var shadow := Color(0.106, 0.141, 0.188, 0.28)
var radius := 22
var icon := ""               # cafe, perf, lock, bill, left, right, pause, close, shop
var badge := -1              # numerito arriba a la derecha (-1 = no se muestra)
var overlay_text := ""       # texto grande encima (ej.: cuenta regresiva del perfume)
var overlay_color := Color(0.886, 0.427, 0.549, 0.92)
var down := false
var disabled := false
var pulse := false
var tex: Texture2D = null     # imagen arriba del texto (ej.: la camiseta)
var sub_color := Color("5b6573")  # color de la última línea cuando hay imagen
var selected := false

var _t := 0.0


func _init(p_id := "", p_text := "", p_size := Vector2(120, 120)) -> void:
	id = p_id
	text = p_text
	custom_minimum_size = p_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if pulse:
		_t += delta
		queue_redraw()


func set_down(v: bool) -> void:
	down = v
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var off := Vector2(0, 4) if down else Vector2.ZERO
	var scale_p: float = 1.0 + (0.05 * sin(_t * 7.0) if pulse and not down else 0.0)
	if scale_p != 1.0:
		var grow := size * (scale_p - 1.0) * 0.5
		r = Rect2(-grow, size * scale_p)
	var body_bg := bg if not disabled else Color("e3e7ed")
	var sb := StyleBoxFlat.new()
	sb.bg_color = body_bg
	var rad: int = int(min(r.size.x, r.size.y) / 2.0) if shape == "circle" else radius
	sb.set_corner_radius_all(rad)
	if border.a > 0:
		sb.set_border_width_all(5)
		sb.border_color = border
	if not down and not disabled:
		sb.shadow_color = shadow
		sb.shadow_size = 0
		sb.shadow_offset = Vector2(0, 7)
		var sh := sb.duplicate() as StyleBoxFlat
		sh.bg_color = shadow
		sh.border_color = Color(0, 0, 0, 0)
		sh.draw(get_canvas_item(), Rect2(r.position + Vector2(0, 7), r.size))
	sb.draw(get_canvas_item(), Rect2(r.position + off, r.size))

	var c := r.get_center() + off
	if selected:
		var sel := StyleBoxFlat.new()
		sel.draw_center = false
		sel.set_border_width_all(6)
		sel.border_color = Color("f2b705")
		sel.set_corner_radius_all(rad)
		sel.draw(get_canvas_item(), Rect2(r.position + off, r.size))
	if tex != null:
		var ts := minf(r.size.x * 0.5, r.size.y * 0.42)
		draw_texture_rect(tex, Rect2(Vector2(c.x - ts / 2.0, r.position.y + off.y + 12), Vector2(ts, ts)), false)
		var tlines := text.split("\n")
		for i in tlines.size():
			var last := i == tlines.size() - 1 and tlines.size() > 1
			draw_string(get_theme_default_font(), Vector2(r.position.x, r.position.y + off.y + 12 + ts + 8 + font_size + i * font_size * 1.15), tlines[i], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, font_size, sub_color if last else fg)
	elif icon != "":
		var isz: float = min(r.size.x, r.size.y) * (0.42 if text == "" else 0.3)
		var ic: Vector2 = c if text == "" else c - Vector2(0, isz * 0.45)
		_draw_icon(icon, ic, isz)
	if text != "" and tex == null:
		var font := get_theme_default_font()
		var col := fg if not disabled else Color("6b7685")
		var lines := text.split("\n")
		var lh := font_size * 1.1
		var y0 := c.y - lh * (lines.size() - 1) / 2.0 + font_size * 0.35
		if icon != "":
			y0 += min(r.size.x, r.size.y) * 0.2
		for i in lines.size():
			draw_string(font, Vector2(r.position.x, y0 + i * lh), lines[i], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, font_size, col)
	if overlay_text != "":
		var ob := StyleBoxFlat.new()
		ob.bg_color = overlay_color
		ob.set_corner_radius_all(rad)
		ob.draw(get_canvas_item(), Rect2(r.position + off, r.size))
		draw_string(get_theme_default_font(), Vector2(r.position.x, c.y + 18), overlay_text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 52, Color.WHITE)
	if badge >= 0:
		var bc := Vector2(r.end.x - 8, r.position.y + 8)
		draw_circle(bc, 20, Color("1b2430"))
		draw_string(get_theme_default_font(), Vector2(bc.x - 20, bc.y + 8), str(badge), HORIZONTAL_ALIGNMENT_CENTER, 40, 22, Color.WHITE)


func _draw_icon(kind: String, c: Vector2, s: float) -> void:
	var ink := Color("1b2430")
	match kind:
		"left", "right":
			var d := -1.0 if kind == "left" else 1.0
			var pts := PackedVector2Array([c + Vector2(-0.35 * s * d, -0.6 * s), c + Vector2(0.35 * s * d, 0), c + Vector2(-0.35 * s * d, 0.6 * s)])
			draw_polyline(pts, ink, s * 0.2, true)
		"pause":
			draw_rect(Rect2(c + Vector2(-0.45 * s, -0.5 * s), Vector2(0.3 * s, s)), ink)
			draw_rect(Rect2(c + Vector2(0.15 * s, -0.5 * s), Vector2(0.3 * s, s)), ink)
		"down":
			var pts2 := PackedVector2Array([c + Vector2(-0.5, -0.2) * s, c + Vector2(0, 0.3) * s, c + Vector2(0.5, -0.2) * s])
			draw_polyline(pts2, ink, s * 0.18, true)
		"bars":
			draw_line(c + Vector2(-0.45, 0.5) * s, c + Vector2(-0.45, 0.1) * s, Color("2e7d32"), s * 0.25, true)
			draw_line(c + Vector2(0, 0.5) * s, c + Vector2(0, -0.2) * s, Color("2e7d32"), s * 0.25, true)
			draw_line(c + Vector2(0.45, 0.5) * s, c + Vector2(0.45, -0.5) * s, Color("2e7d32"), s * 0.25, true)
		"shirt":
			var sh_pts := PackedVector2Array([c + Vector2(-0.3, -0.6) * s, c + Vector2(-0.75, -0.25) * s, c + Vector2(-0.5, 0.05) * s, c + Vector2(-0.35, -0.05) * s, c + Vector2(-0.35, 0.65) * s, c + Vector2(0.35, 0.65) * s, c + Vector2(0.35, -0.05) * s, c + Vector2(0.5, 0.05) * s, c + Vector2(0.75, -0.25) * s, c + Vector2(0.3, -0.6) * s, c + Vector2(0, -0.45) * s])
			draw_colored_polygon(sh_pts, Color("f28c28"))
			draw_polyline(sh_pts + PackedVector2Array([sh_pts[0]]), ink, 3, true)
		"lungs":
			draw_circle(c + Vector2(-0.25, 0.1) * s, 0.3 * s, Color("9cc7ee"))
			draw_circle(c + Vector2(0.25, 0.1) * s, 0.3 * s, Color("9cc7ee"))
			draw_line(c + Vector2(0, -0.6) * s, c + Vector2(0, 0) * s, ink, 4, true)
		"dumbbell":
			draw_rect(Rect2(c + Vector2(-0.6, -0.1) * s, Vector2(1.2, 0.2) * s), Color("8c939e"))
			draw_rect(Rect2(c + Vector2(-0.75, -0.35) * s, Vector2(0.25, 0.7) * s), Color("2b2f36"))
			draw_rect(Rect2(c + Vector2(0.5, -0.35) * s, Vector2(0.25, 0.7) * s), Color("2b2f36"))
		"blush":
			draw_circle(c, 0.6 * s, Color("f6c1d0"))
			draw_circle(c + Vector2(-0.22, -0.1) * s, 0.08 * s, ink)
			draw_circle(c + Vector2(0.22, -0.1) * s, 0.08 * s, ink)
			draw_arc(c + Vector2(0, 0.35) * s, 0.25 * s, -PI * 0.85, -PI * 0.15, 8, ink, 3)
		"close":
			draw_line(c + Vector2(-0.4, -0.4) * s, c + Vector2(0.4, 0.4) * s, ink, s * 0.16, true)
			draw_line(c + Vector2(0.4, -0.4) * s, c + Vector2(-0.4, 0.4) * s, ink, s * 0.16, true)
		"shop":
			var bag := PackedVector2Array([c + Vector2(-0.6, -0.1) * s, c + Vector2(0.6, -0.1) * s, c + Vector2(0.5, 0.7) * s, c + Vector2(-0.5, 0.7) * s])
			draw_colored_polygon(bag, Color("f2b705"))
			draw_polyline(bag + PackedVector2Array([bag[0]]), ink, 4, true)
			draw_arc(c + Vector2(0, -0.1) * s, 0.3 * s, PI, TAU, 16, ink, 4, true)
		"cafe":
			draw_rect(Rect2(c + Vector2(-0.45, -0.3) * s, Vector2(0.8, 0.8) * s), Color("8a5a33"))
			draw_rect(Rect2(c + Vector2(-0.45, -0.3) * s, Vector2(0.8, 0.8) * s), ink, false, 4)
			draw_arc(c + Vector2(0.4, 0.1) * s, 0.2 * s, -PI / 2, PI / 2, 12, ink, 4, true)
			draw_line(c + Vector2(-0.2, -0.75) * s, c + Vector2(-0.1, -0.45) * s, Color("8c939e"), 4, true)
			draw_line(c + Vector2(0.1, -0.75) * s, c + Vector2(0.2, -0.45) * s, Color("8c939e"), 4, true)
		"perf":
			draw_rect(Rect2(c + Vector2(-0.4, -0.2) * s, Vector2(0.8, 0.9) * s), Color("e26d8c"))
			draw_rect(Rect2(c + Vector2(-0.4, -0.2) * s, Vector2(0.8, 0.9) * s), ink, false, 4)
			draw_rect(Rect2(c + Vector2(-0.2, -0.55) * s, Vector2(0.4, 0.35) * s), Color("c9ced6"))
			draw_line(c + Vector2(0.35, -0.5) * s, c + Vector2(0.65, -0.65) * s, ink, 4, true)
		"lock":
			draw_arc(c + Vector2(0, -0.2) * s, 0.32 * s, PI, TAU, 16, ink, 6, true)
			draw_rect(Rect2(c + Vector2(-0.5, -0.2) * s, Vector2(1.0, 0.8) * s), Color("f2b705"))
			draw_rect(Rect2(c + Vector2(-0.5, -0.2) * s, Vector2(1.0, 0.8) * s), ink, false, 4)
			draw_circle(c + Vector2(0, 0.2) * s, 0.1 * s, ink)
		"bill":
			draw_rect(Rect2(c + Vector2(-0.6, -0.4) * s, Vector2(1.2, 0.9) * s), Color("8a5a33"))
			draw_rect(Rect2(c + Vector2(-0.6, -0.4) * s, Vector2(1.2, 0.9) * s), ink, false, 4)
			draw_rect(Rect2(c + Vector2(0.1, -0.15) * s, Vector2(0.5, 0.4) * s), Color("a8732f"))
			draw_circle(c + Vector2(0.25, 0.05) * s, 0.08 * s, Color("f2b705"))
