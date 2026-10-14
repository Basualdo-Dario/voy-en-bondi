# Voy en Bondi

Juego para celular (Android) hecho en Godot 4.7.2, GDScript, renderer GL Compatibility, pantalla vertical (720×1520).
Un pibe tiene que sobrevivir a sus viajes en colectivo. Slogan: "Llegá a destino, si podés".
Todo el texto del juego está en español rioplatense (voseo).

## Reglas del juego (resumen)

- Un día tiene 4 viajes (Casa→Trabajo→Facu→Gym→Casa), de 75 s cada uno. Entre viaje y viaje se vuelve al menú.
- El jugador va parado. El equilibrio está siempre activo: flechas en pantalla, flechas del teclado o inclinando el celular.
- Los personajes recorren el pasillo y cuando pasan cerca disparan su evento: oloroso (aguantar la respiración con zona verde que cambia de lugar), choro (forcejeo tocando rápido), embarazada (ceder el lugar o fingir dormir), vendedor ambulante (3 ofertas, NO GRACIAS; mientras está no arranca ningún otro evento de botón, pero las frenadas siguen) y sueño (tocar rápido hasta la zona verde).
- Como máximo se juntan un evento de botón y una frenada. En el primer viaje no se juntan hasta que el jugador vio cada uno solo, y el tutorial aparece solo esa primera vez.
- Los ítems (café, perfume, candado, billetera) aparecen al lado del botón del evento donde sirven.
- Con 3 o 4 fallas se pierde el viaje (barra de vergüenza). La tienda está siempre abierta.
- Habilidades: pulmones, fuerza y resistencia a la vergüenza (5 niveles, 150 × nivel).
- Camisetas: clubes de barrio inventados. Nunca usar clubes, marcas ni escudos reales.

Los números de economía están en `scripts/game.gd`. **Antes de cambiar reglas, eventos o economía, leé `docs/diseno.md`**: es el documento de diseño completo (todos los eventos, controles, ítems, habilidades, precios, personajes y pendientes).

## Estructura

- `scenes/trip.tscn` + `scripts/trip.gd` (class_name Trip): escena única. Arma el escenario 3D, la interfaz y toda la lógica del viaje.
- `scripts/ui/screens.gd`: menú, tienda, habilidades y camisetas (paneles que suben desde abajo).
- `scripts/game.gd` (autoload `Game`): perfil, guardado en `user://save.json`, reglas y precios.
- `scripts/world/`: `build.gd` (formas simples), `characters.gd` (personajes), `skins.gd` (texturas de camisetas).
- `scripts/ui/touch_button.gd` y `meter.gd`: botones y barras dibujados a mano.
- `scripts/audio.gd` (autoload `Audio`): efectos (`Audio.play("coins")`), música y motor del colectivo. Los sonidos están en `assets/audio/` con sus créditos en `CREDITOS.md`; usar solo sonidos CC0. La música se genera con `tools/make_music.gd` (`godot --headless --path . -s res://tools/make_music.gd`).
- `scripts/ui/city_map.gd` y `route_stops.gd`: el mapa del modo historia (barrios del capítulo y paradas de la semana).
- Modo historia: los datos (`CHAPTERS`, `BARRIOS`) y la lógica (`complete_week`, `next_story`) están en `game.gd`. El perfil guarda `barrio` (0 a 8; 8 = modo libre) y `day` (día dentro del barrio).

## Convenciones importantes

- Los toques los maneja `trip.gd` a mano (`_input` con `InputEventScreenTouch`/`ScreenDrag`) para soportar varios dedos a la vez. Por eso todos los botones son `TouchButton` registrados con `_tb(...)` y no `Button` de Godot. `emulate_mouse_from_touch` está apagado y `emulate_touch_from_mouse` prendido.
- Los botones tienen grupo: "game", "menu" o "modal". Con un cartel abierto solo responden los del grupo "modal".
- En GDScript, cuando un valor viene de un Dictionary, declarar el tipo explícito (`var x: float = d["k"]`) en vez de `:=`, porque si no falla el parseo.
- La interfaz se arma por código (no hay escenas .tscn de UI).
- Estilo visual "juego móvil vivo": letra Fredoka (`Game.font` y `Game.font_bold`; `_label` pone negrita desde 30 px), botones con relieve (el color `shadow` del `TouchButton` es el canto; transparente = botón plano) y tarjetas blancas con sombra suave (`_style`). En el texto de un botón, "●" se dibuja como moneda (`Coin`).
- Configuración: `Game.setting("clave")` y `Game.set_setting(...)` (valores por defecto en `DEFAULT_SETTINGS`). El viaje de práctica usa `Game.start_practice()`/`end_practice()`: juega con una copia de la partida y `go_menu` restaura la real.
- Con `--autotest` o `--shot`, `Game.testing` está prendido: se juega con una partida en memoria que no se guarda. `--demo` arranca esa partida a mitad de semana (para capturas).

## Cómo probar sin abrir el editor

```bash
# Revisar que todo compile
godot --headless --editor --quit --path .

# Jugar un viaje completo con piloto automático (imprime los eventos y el resultado)
godot --headless --path . --fixed-fps 60 --quit-after 6000 -- --autotest

# Captura de una pantalla del menú (necesita pantalla virtual, por ejemplo xvfb-run)
godot --path . --rendering-driver opengl3 --resolution 405x855 -- --demo --tap=go:skins,pick:ramal --shot=captura.png

# Probar un momento de la historia: --set pone números en la partida de prueba (ej.: fin del capítulo 1)
godot --headless --path . --fixed-fps 60 --quit-after 6000 -- --autotest --set=barrio:3,day:4,trip:3

# Captura en medio de un viaje (a los 10 segundos)
godot --path . --rendering-driver opengl3 --resolution 405x855 -- --autotest --shot=captura.png --shot-time=10
```

## Historial de cambios (Git)

El proyecto usa Git (rama `main`). Después de cada cambio que funcione:

1. Anotarlo arriba de todo en `docs/cambios.md`, con la fecha y en lenguaje de jugador (qué cambia en el juego, no en el código).
2. Hacer un commit con un mensaje en castellano que explique qué cambió y por qué.

Así cualquier cambio se puede deshacer volviendo a un commit anterior.
