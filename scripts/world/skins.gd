class_name Skins
## Dibuja la textura de cada camiseta (128×128) a partir de su patrón.

static var _cache := {}


static func texture(id: String) -> ImageTexture:
	if _cache.has(id):
		return _cache[id]
	var s: Dictionary = Game.skin(id)
	var c1 := Color(s["c1"])
	var c2 := Color(s["c2"])
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	img.fill(c1)
	match s["pattern"]:
		"plain":
			img.fill_rect(Rect2i(30, 80, 68, 40), c2)
		"band":
			img.fill_rect(Rect2i(0, 52, 128, 26), c2)
		"vstripes":
			for i in 8:
				if i % 2 == 1:
					img.fill_rect(Rect2i(i * 16, 0, 16, 128), c2)
		"sash":
			for y in 128:
				for x in 128:
					if absi(x - y) < 21:
						img.set_pixel(x, y, c2)
		"checks":
			for i in 4:
				for j in 4:
					if (i + j) % 2 == 1:
						img.fill_rect(Rect2i(i * 32, j * 32, 32, 32), c2)
		"halves":
			img.fill_rect(Rect2i(64, 0, 64, 128), c2)
		"hoops":
			for i in 6:
				if i % 2 == 1:
					img.fill_rect(Rect2i(0, i * 22, 128, 22), c2)
	if s["pattern"] != "plain":
		# Cuello en V y escudito
		var collar := Color.WHITE if s["pattern"] in ["vstripes", "checks", "hoops"] else Color("1b2430")
		for y in 18:
			var half := int(20.0 * (1.0 - y / 18.0))
			for x in range(64 - half, 64 + half + 1):
				img.set_pixel(x, y, collar)
		for y in range(26, 55):
			for x in range(72, 101):
				var d := Vector2(x - 86, y - 40).length()
				if d <= 13.0:
					img.set_pixel(x, y, c2 if d > 10.5 else Color.WHITE)
	var tex := ImageTexture.create_from_image(img)
	_cache[id] = tex
	return tex


## Le pone la camiseta al pibe
static func apply(id: String, shirt_mat: StandardMaterial3D, sleeve_mat: StandardMaterial3D) -> void:
	var s: Dictionary = Game.skin(id)
	shirt_mat.albedo_texture = texture(id)
	shirt_mat.albedo_color = Color.WHITE
	# BoxMesh reparte la textura en una grilla de 3×2: así cada cara muestra la camiseta entera
	shirt_mat.uv1_scale = Vector3(3, 2, 1)
	sleeve_mat.albedo_color = Color(s["sleeve"])
