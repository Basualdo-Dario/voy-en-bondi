class_name Characters
## Personajes armados con formas simples. Cada función devuelve un diccionario con
## "root" (el nodo para mover y girar) y otras partes que el juego necesita animar.

const INK := Color("1b2430")
const SKIN := Color("e8b48a")


static func _humanoid(o: Dictionary) -> Dictionary:
	var g := Node3D.new()
	Build.box(g, Vector3(.26, .7, .3), o["pants"], Vector3(-.17, .35, 0))
	Build.box(g, Vector3(.26, .7, .3), o["pants"], Vector3(.17, .35, 0))
	var shoes := [
		Build.box(g, Vector3(.3, .16, .44), o["shoes"], Vector3(-.17, .08, .05)),
		Build.box(g, Vector3(.3, .16, .44), o["shoes"], Vector3(.17, .08, .05)),
	]
	Build.box(g, Vector3(.82, .95, .52), o["shirt"], Vector3(0, 1.17, 0))
	var arm_l := Build.box(g, Vector3(.2, .78, .24), o["sleeve"], Vector3(-.53, 1.22, 0))
	var arm_r := Build.box(g, Vector3(.2, .78, .24), o["sleeve"], Vector3(.53, 1.22, 0))
	Build.sphere(g, .13, o["skin"], Vector3(-.53, .76, 0))
	var hand_r := Build.sphere(g, .13, o["skin"], Vector3(.53, .76, 0))
	Build.cyl(g, .14, .14, .14, o["skin"], Vector3(0, 1.7, 0))
	Build.sphere(g, .55, o["skin"], Vector3(0, 2.2, 0), 18)
	Build.sphere(g, .12, o["skin"], Vector3(-.55, 2.18, 0))
	Build.sphere(g, .12, o["skin"], Vector3(.55, 2.18, 0))
	Build.sphere(g, .065, INK, Vector3(-.18, 2.24, .51))
	Build.sphere(g, .065, INK, Vector3(.18, 2.24, .51))
	Build.box(g, Vector3(.16, .03, .03), INK, Vector3(0, 2.0, .53))
	return {"g": g, "shoes": shoes, "arm_l": arm_l, "arm_r": arm_r, "hand_r": hand_r}


## Envuelve al personaje a escala 0,7 dentro de un nodo raíz
static func _wrap(parent: Node3D, h: Dictionary) -> Dictionary:
	var root := Node3D.new()
	var inner: Node3D = h["g"]
	inner.scale = Vector3.ONE * 0.7
	root.add_child(inner)
	parent.add_child(root)
	h["root"] = root
	h["inner"] = inner
	return h


static func pibe(parent: Node3D, shirt_mat: Material, sleeve_mat: Material) -> Dictionary:
	var h := _humanoid({"skin": SKIN, "shirt": shirt_mat, "sleeve": sleeve_mat, "pants": Color("2d3a4a"), "shoes": Color.WHITE})
	var g: Node3D = h["g"]
	Build.cap(g, .58, Color("3b2a20"), Vector3(0, 2.22, -.02))
	Build.box(g, Vector3(.7, .8, .32), Color("1f3d6b"), Vector3(0, 1.2, -.42))      # mochila
	Build.box(g, Vector3(.12, .7, .06), Color("1f3d6b"), Vector3(-.25, 1.28, .27))   # tiras
	Build.box(g, Vector3(.12, .7, .06), Color("1f3d6b"), Vector3(.25, 1.28, .27))
	Build.box(g, Vector3(.62, .24, .22), sleeve_mat, Vector3(0, 1.74, -.22))          # capucha
	# Auriculares: vincha que pasa por arriba de la cabeza y dos parlantes a los costados
	Build.box(g, Vector3(.9, .09, .12), Color("e63946"), Vector3(0, 2.83, 0))
	for s in [-1, 1]:
		var side := Build.box(g, Vector3(.09, .5, .12), Color("e63946"), Vector3(s * .56, 2.55, 0))
		side.rotation.z = s * 0.35
	for s in [-1, 1]:
		var cup := Build.cyl(g, .17, .17, .14, Color("e63946"), Vector3(s * .62, 2.2, 0))
		cup.rotation.z = PI / 2
	return _wrap(parent, h)


static func set_grab(p: Dictionary, on: bool) -> void:
	var arm: MeshInstance3D = p["arm_r"]
	var hand: MeshInstance3D = p["hand_r"]
	if on:
		arm.position = Vector3(.53, 2.2, 0)
		arm.scale = Vector3(1, 1.5, 1)
		hand.position = Vector3(.53, 2.82, 0)
	else:
		arm.position = Vector3(.53, 1.22, 0)
		arm.scale = Vector3.ONE
		hand.position = Vector3(.53, .76, 0)


static func choro(parent: Node3D) -> Dictionary:
	var c := Color("c68e66")
	var green := Color("1e8c4e")
	var h := _humanoid({"skin": c, "shirt": green, "sleeve": c, "pants": Color("8c939e"), "shoes": Color.WHITE})
	var g: Node3D = h["g"]
	Build.box(g, Vector3(.25, .3, .27), green, Vector3(-.53, 1.47, 0))
	Build.box(g, Vector3(.25, .3, .27), green, Vector3(.53, 1.47, 0))
	Build.box(g, Vector3(.05, .95, .54), Color.WHITE, Vector3(-.39, 1.17, 0))
	Build.box(g, Vector3(.05, .95, .54), Color.WHITE, Vector3(.39, 1.17, 0))
	Build.label(g, "10", 96, Color.WHITE, Vector3(-.08, 1.12, .27))
	var back := Build.label(g, "10", 96, Color.WHITE, Vector3(0, 1.15, -.27))
	back.rotation.y = PI
	var strap := Build.box(g, Vector3(.07, 1.15, .03), INK, Vector3(0, 1.2, .27))      # riñonera cruzada
	strap.rotation.z = .7
	Build.box(g, Vector3(.36, .2, .14), Color("2b2f36"), Vector3(.16, .98, .31))
	Build.cap(g, .59, Color("111111"), Vector3(0, 2.22, 0))                            # gorra
	var visor := Build.box(g, Vector3(.5, .04, .42), Color("111111"), Vector3(0, 2.44, .52))
	visor.rotation.x = -.12
	Build.sphere(g, .05, Color("c9ced6"), Vector3(.28, 2.38, .5))                      # piercing
	Build.sphere(g, .3, Color("c9a66b"), Vector3(.66, .58, .08))                       # bolsa
	return _wrap(parent, h)


static func embarazada(parent: Node3D) -> Dictionary:
	var pink := Color("e26d8c")
	var h := _humanoid({"skin": SKIN, "shirt": pink, "sleeve": SKIN, "pants": Color("2b2f36"), "shoes": Color.WHITE})
	var g: Node3D = h["g"]
	Build.box(g, Vector3(.25, .3, .27), pink, Vector3(-.53, 1.47, 0))
	Build.box(g, Vector3(.25, .3, .27), pink, Vector3(.53, 1.47, 0))
	var belly := Build.sphere(g, .44, Color("ec8da6"), Vector3(0, 1.0, .24), 16)
	belly.scale = Vector3(1, 1, .85)
	Build.cap(g, .58, Color("6b3e26"), Vector3(0, 2.22, -.02))
	Build.sphere(g, .24, Color("6b3e26"), Vector3(0, 2.78, -.12))                      # rodete
	Build.box(g, Vector3(.34, .08, .08), Color("f2b705"), Vector3(0, 2.6, -.18))
	Build.sphere(g, .08, Color("e0b23b"), Vector3(-.6, 1.96, 0))                        # aros
	Build.sphere(g, .08, Color("e0b23b"), Vector3(.6, 1.96, 0))
	Build.box(g, Vector3(.42, .48, .26), Color("f4e9d0"), Vector3(-.66, .42, .06))     # bolsa
	var bread := Build.cyl(g, .065, .065, .75, Color("d9a35a"), Vector3(-.74, .86, .02), 10)
	bread.rotation.z = .22
	return _wrap(parent, h)


static func sucio(parent: Node3D) -> Dictionary:
	var s := Color("d9a27a")
	var h := _humanoid({"skin": s, "shirt": Color("ece6d3"), "sleeve": s, "pants": s, "shoes": Color("2b2f36")})
	var g: Node3D = h["g"]
	h["arm_l"].scale = Vector3(1.35, 1, 1.25)
	h["arm_r"].scale = Vector3(1.35, 1, 1.25)
	for sh in h["shoes"]:
		sh.scale.y = .35
		sh.position.y = .03
	Build.box(g, Vector3(.28, .14, .32), Color.WHITE, Vector3(-.17, .13, 0))           # medias
	Build.box(g, Vector3(.28, .14, .32), Color.WHITE, Vector3(.17, .13, 0))
	Build.box(g, Vector3(.86, .34, .55), Color("2f6fd6"), Vector3(0, .62, 0))          # short
	for p in [Vector2(-.15, 1.3), Vector2(.2, 1.0), Vector2(-.05, .85)]:
		Build.box(g, Vector3(.16, .1, .02), Color("c9b47a"), Vector3(p.x, p.y, .262))  # manchas
	var bar := Build.cyl(g, .04, .04, .7, Color("8c939e"), Vector3(.53, .76, 0), 8)   # mancuerna
	bar.rotation.x = PI / 2
	for side in [-1, 1]:
		var plate := Build.cyl(g, .16, .16, .08, Color("2b2f36"), Vector3(.53, .76, side * .3))
		plate.rotation.x = PI / 2
	Build.cap(g, .57, Color("4a3524"), Vector3(0, 2.22, 0))
	var band := Build.ring(g, .565, .05, Color("e63946"), Vector3(0, 2.46, 0))         # vincha
	band.rotation.x = 0
	var stink := []
	for i in 12:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.243, 0.608, 0.278, 0.8)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var sp := Build.sphere(g, .07, m, Vector3.ZERO, 8)
		sp.set_meta("a", i / 12.0 * TAU)
		sp.set_meta("t", i / 12.0)
		stink.append(sp)
	var flies := []
	for i in 3:
		var f := Build.sphere(g, .045, INK, Vector3.ZERO, 6)
		f.set_meta("a", i * 2.1)
		f.set_meta("r", .9 + i * .12)
		f.set_meta("y", 2.0 + i * .25)
		flies.append(f)
	h["stink"] = stink
	h["flies"] = flies
	return _wrap(parent, h)


static func vendedor(parent: Node3D) -> Dictionary:
	var h := _humanoid({"skin": Color("d9a27a"), "shirt": Color("f28c28"), "sleeve": Color("f28c28"), "pants": Color("3a4250"), "shoes": Color("2b2f36")})
	var g: Node3D = h["g"]
	Build.cap(g, .59, Color("d63b3b"), Vector3(0, 2.22, 0))
	var visor := Build.box(g, Vector3(.5, .04, .42), Color("d63b3b"), Vector3(0, 2.44, .52))
	visor.rotation.x = -.12
	Build.box(g, Vector3(1.0, .12, .55), Color("8a5a33"), Vector3(0, 1.1, .52))       # bandeja
	var candies := [[-.35, "e63946"], [-.12, "2f6fd6"], [.1, "f2b705"], [.32, "3e9b47"]]
	for cd in candies:
		Build.box(g, Vector3(.18, .16, .3), Color(cd[1]), Vector3(cd[0], 1.24, .5))
	for s in [-1, 1]:
		var st := Build.box(g, Vector3(.05, .75, .05), Color("6b4f3a"), Vector3(s * .3, 1.5, .32))
		st.rotation.x = .5
	return _wrap(parent, h)


static func comun(parent: Node3D, shirt: Color) -> Dictionary:
	var h := _humanoid({"skin": Color("d8c2b0"), "shirt": shirt, "sleeve": shirt, "pants": Color("4f5866"), "shoes": Color("2b313b")})
	var g: Node3D = h["g"]
	Build.sphere(g, .2, Color("5e5a57"), Vector3(-.47, 2.3, -.12))
	Build.sphere(g, .2, Color("5e5a57"), Vector3(.47, 2.3, -.12))
	Build.sphere(g, .24, Color("5e5a57"), Vector3(0, 2.25, -.42), 10)
	return _wrap(parent, h)
