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


const LIP := 8.0   # alto del "canto" de abajo que le da relieve al botón


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var scale_p: float = 1.0 + (0.05 * sin(_t * 7.0) if pulse and not down else 0.0)
	if scale_p != 1.0:
		var grow := size * (scale_p - 1.0) * 0.5
		r = Rect2(-grow, size * scale_p)
	# Botón plano (shadow transparente) o con relieve: el cuerpo se apoya sobre un canto más oscuro
	var flat := shadow.a == 0.0
	var lip := 0.0 if flat else LIP
	var body := Rect2(r.position, Vector2(r.size.x, r.size.y - lip))
	if down:
		body.position.y += lip - 2.0 if not flat else 2.0
	var body_bg := bg if not disabled else Color("e6e9ee")
	var rad: int = int(minf(body.size.x, body.size.y) / 2.0) if shape == "circle" else radius
	rad = mini(rad, int(minf(body.size.x, body.size.y) / 2.0))
	if not flat:
		var lip_col := shadow if shadow.a >= 1.0 else body_bg.darkened(0.22)
		if disabled:
			lip_col = Color("cdd2da")
		var ls := StyleBoxFlat.new()
		ls.bg_color = lip_col
		ls.set_corner_radius_all(rad)
		if not disabled:
			ls.shadow_color = Color(0.06, 0.08, 0.12, 0.18)
			ls.shadow_size = 14
			ls.shadow_offset = Vector2(0, 6)
		ls.draw(get_canvas_item(), Rect2(r.position + Vector2(0, lip), body.size))
	var sb := StyleBoxFlat.new()
	sb.bg_color = body_bg
	sb.set_corner_radius_all(rad)
	if border.a > 0:
		sb.set_border_width_all(5)
		sb.border_color = border
	sb.draw(get_canvas_item(), body)
	# Brillo arriba, para que se vea "gordito"
	if not flat and not disabled and body_bg.get_luminance() < 0.92:
		var gl := StyleBoxFlat.new()
		gl.bg_color = Color(1, 1, 1, 0.2)
		var gh := minf(body.size.y * 0.22, 26.0)
		gl.set_corner_radius_all(int(gh / 2.0))
		var gx := body.size.x * (0.22 if shape == "circle" else 0.08)
		gl.draw(get_canvas_item(), Rect2(body.position + Vector2(gx, 6), Vector2(body.size.x - gx * 2.0, gh)))

	var c := body.get_center()
	if selected:
		var sel := StyleBoxFlat.new()
		sel.draw_center = false
		sel.set_border_width_all(6)
		sel.border_color = Color("f2b705")
		sel.set_corner_radius_all(rad)
		sel.draw(get_canvas_item(), body)
	var font: Font = Game.font_bold
	if tex != null:
		var ts := minf(body.size.x * 0.5, body.size.y * 0.42)
		draw_texture_rect(tex, Rect2(Vector2(c.x - ts / 2.0, body.position.y + 12), Vector2(ts, ts)), false)
		var tlines := text.split("\n")
		for i in tlines.size():
			var last := i == tlines.size() - 1 and tlines.size() > 1
			_line(font, body, body.position.y + 12 + ts + 8 + font_size + i * font_size * 1.15, tlines[i], sub_color if last else fg)
	elif icon != "":
		var isz: float = minf(body.size.x, body.size.y) * (0.42 if text == "" else 0.3)
		var ic: Vector2 = c if text == "" else c - Vector2(0, isz * 0.45)
		_draw_icon(icon, ic, isz)
	if text != "" and tex == null:
		var col := fg if not disabled else Color("8a93a1")
		var lines := text.split("\n")
		var lh := font_size * 1.1
		var y0 := c.y - lh * (lines.size() - 1) / 2.0 + font_size * 0.35
		if icon != "":
			y0 += minf(body.size.x, body.size.y) * 0.2
		for i in lines.size():
			_line(font, body, y0 + i * lh, lines[i], col)
	if overlay_text != "":
		var ob := StyleBoxFlat.new()
		ob.bg_color = overlay_color
		ob.set_corner_radius_all(rad)
		ob.draw(get_canvas_item(), body)
		draw_string(font, Vector2(body.position.x, c.y + 18), overlay_text, HORIZONTAL_ALIGNMENT_CENTER, body.size.x, 52, Color.WHITE)
	if badge >= 0:
		var bc := Vector2(r.end.x - 8, r.position.y + 8)
		draw_circle(bc, 22, Color.WHITE)
		draw_circle(bc, 19, Color("1b2430"))
		draw_string(font, Vector2(bc.x - 20, bc.y + 8), str(badge), HORIZONTAL_ALIGNMENT_CENTER, 40, 22, Color.WHITE)


## Una línea de texto centrada; si tiene "●" dibuja una moneda en su lugar
func _line(font: Font, area: Rect2, y: float, line: String, col: Color) -> void:
	if not line.contains("●"):
		draw_string(font, Vector2(area.position.x, y), line, HORIZONTAL_ALIGNMENT_CENTER, area.size.x, font_size, col)
		return
	var parts := line.split("●", true, 1)
	var pre := parts[0].strip_edges()
	var post := parts[1].strip_edges()
	var gap := font_size * (1.3 if pre != "" else 1.1)
	var w_pre := font.get_string_size(pre, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var w_post := font.get_string_size(post, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var x := area.position.x + (area.size.x - w_pre - gap - w_post) / 2.0
	draw_string(font, Vector2(x, y), pre, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)
	var coin_x := x + w_pre + (gap / 2.0 if pre != "" else font_size * 0.4)
	Coin.paint(self, Vector2(coin_x, y - font_size * 0.36), font_size * 0.42)
	draw_string(font, Vector2(x + w_pre + gap, y), post, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)


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
		"map":
			var fold := PackedVector2Array([c + Vector2(-0.7, -0.45) * s, c + Vector2(-0.25, -0.6) * s, c + Vector2(0.25, -0.45) * s, c + Vector2(0.7, -0.6) * s,
				c + Vector2(0.7, 0.5) * s, c + Vector2(0.25, 0.65) * s, c + Vector2(-0.25, 0.5) * s, c + Vector2(-0.7, 0.65) * s])
			draw_colored_polygon(fold, Color("9fd3a8"))
			draw_polyline(fold + PackedVector2Array([fold[0]]), ink, 3, true)
			draw_line(c + Vector2(-0.25, -0.6) * s, c + Vector2(-0.25, 0.5) * s, ink, 2, true)
			draw_line(c + Vector2(0.25, -0.45) * s, c + Vector2(0.25, 0.65) * s, ink, 2, true)
			draw_circle(c + Vector2(0.05, -0.05) * s, 0.16 * s, Color("e0457b"))
		"check":
			draw_circle(c, 0.6 * s, Color("3fae5a"))
			draw_polyline(PackedVector2Array([c + Vector2(-0.3, 0) * s, c + Vector2(-0.08, 0.22) * s, c + Vector2(0.32, -0.2) * s]), Color.WHITE, s * 0.16, true)
		"bus":
			var body := Rect2(c + Vector2(-0.7, -0.45) * s, Vector2(1.4, 0.8) * s)
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color("f2b705")
			sb.set_corner_radius_all(int(0.18 * s))
			sb.border_color = ink
			sb.set_border_width_all(3)
			sb.draw(get_canvas_item(), body)
			for i in 3:
				draw_rect(Rect2(body.position + Vector2((0.14 + i * 0.4) * s, 0.12 * s), Vector2(0.3, 0.26) * s), Color("dff1fb"))
			for x in [-0.38, 0.38]:
				draw_circle(c + Vector2(x, 0.38) * s, 0.15 * s, ink)
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
