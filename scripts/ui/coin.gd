class_name Coin
extends Control
## Moneda dorada dibujada a mano. Como nodo sirve al lado de un número (HUD);
## Coin.paint() la dibuja dentro de otro control (botones de compra).


func _init(diameter := 30.0) -> void:
	custom_minimum_size = Vector2(diameter, diameter)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	paint(self, size / 2.0, minf(size.x, size.y) / 2.0)


static func paint(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_circle(c + Vector2(0, r * 0.14), r, Color("c98a00"))   # canto
	ci.draw_circle(c, r, Color("ffc928"))
	ci.draw_circle(c, r * 0.68, Color("f2b705"))
	ci.draw_arc(c, r * 0.68, 0, TAU, 24, Color("d99a00"), maxf(1.5, r * 0.12), true)
	ci.draw_circle(c + Vector2(-r * 0.32, -r * 0.36), r * 0.18, Color(1, 1, 1, 0.75))  # brillo
