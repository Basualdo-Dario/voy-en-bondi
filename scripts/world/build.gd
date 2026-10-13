class_name Build
## Ayudantes para armar todo con formas simples (estilo low-poly de la demo).

static var _mats := {}


static func mat(c: Color) -> StandardMaterial3D:
	var key := c.to_html()
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 0.85
		if c.a < 1.0:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mats[key] = m
	return _mats[key]


static func _add(parent: Node3D, mesh: Mesh, c, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = c if c is Material else mat(c)
	mi.position = pos
	parent.add_child(mi)
	return mi


static func box(parent: Node3D, size: Vector3, c, pos: Vector3) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	return _add(parent, m, c, pos)


static func sphere(parent: Node3D, r: float, c, pos: Vector3, seg := 14) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = seg
	m.rings = maxi(4, seg / 2)
	return _add(parent, m, c, pos)


## Media esfera (pelo, gorras): la base queda en pos y la cúpula hacia arriba
static func cap(parent: Node3D, r: float, c, pos: Vector3) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r
	m.is_hemisphere = true
	m.radial_segments = 16
	m.rings = 8
	return _add(parent, m, c, pos)


static func cyl(parent: Node3D, r_top: float, r_bottom: float, h: float, c, pos: Vector3, seg := 14) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = r_top
	m.bottom_radius = r_bottom
	m.height = h
	m.radial_segments = seg
	return _add(parent, m, c, pos)


## Aro: queda acostado (en el plano XZ). Rotalo para pararlo.
static func ring(parent: Node3D, r: float, t: float, c, pos: Vector3) -> MeshInstance3D:
	var m := TorusMesh.new()
	m.inner_radius = r - t
	m.outer_radius = r + t
	m.rings = 20
	m.ring_segments = 8
	return _add(parent, m, c, pos)


static func label(parent: Node3D, text: String, size: int, c: Color, pos: Vector3) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.modulate = c
	l.outline_size = 12
	l.outline_modulate = Color("1b2430")
	l.pixel_size = 0.004
	l.position = pos
	parent.add_child(l)
	return l
