# Voy en Bondi

*Llegá a destino, si podés.*

Proyecto de Godot 4.7 con el juego completo, igual que la demo: menú con el día de 4 viajes, tienda, habilidades, camisetas, y los viajes con el equilibrio (flechas o inclinando el celular) y los eventos del oloroso, el choro, la embarazada, el sueño y el vendedor ambulante, con sus ítems al lado del botón.

El progreso (monedas, día, compras y mejoras) se guarda solo en el celular.

## 1. Instalar Godot

1. Entrá a https://godotengine.org/download y bajá **Godot 4.7.2** para Windows, versión **Standard** (no la .NET).
2. Es un `.zip`: descomprimilo en una carpeta, por ejemplo `C:\Godot`. No hace falta instalar nada, se abre directo.

## 2. Abrir el proyecto

1. Descomprimí `voy-en-bondi.zip` en una carpeta, por ejemplo `Documentos\voy-en-bondi`.
2. Abrí Godot. En el administrador de proyectos tocá **Importar** y elegí el archivo `project.godot` de esa carpeta.
3. La primera vez tarda unos segundos en importar.

## 3. Probarlo en la compu

Apretá **F5** (o el botón ▶ de arriba a la derecha).

- **Equilibrio:** flechas ← → del teclado, o mantené apretadas las flechas de la pantalla con el mouse.
- **Botón grande (AGUANTÁ, TOCÁ, MANTENÉ):** clic, o la barra espaciadora.
- Con el mouse se usa un solo "dedo" a la vez; en el celular podés usar las flechas y el botón con dos pulgares.

## 4. Pasarlo al celular (Android)

Esto se hace una sola vez:

1. **Java 17:** bajá e instalá *Temurin 17 (JDK)* desde https://adoptium.net/temurin/releases/?version=17
2. **Android SDK:** instalá Android Studio desde https://developer.android.com/studio. Abrilo, andá a **More Actions → SDK Manager** y fijate de tener instalado:
   - en *SDK Platforms*: Android 16 (API 36);
   - en *SDK Tools*: Android SDK Build-Tools, Android SDK Platform-Tools y Android SDK Command-line Tools.
3. **Configurar Godot:** en Godot, **Editor → Editor Settings → Export → Android** y completá:
   - *Java SDK Path*: la carpeta donde se instaló el JDK (algo como `C:\Program Files\Eclipse Adoptium\jdk-17...`);
   - *Android SDK Path*: normalmente `C:\Users\TU_USUARIO\AppData\Local\Android\Sdk`.
4. **Plantillas de exportación:** **Editor → Manage Export Templates → Download and Install**.
5. **Preset de Android:** **Project → Export → Add... → Android**. Dejá todo como viene, salvo en **Permissions**: marcá **Vibrate** (si no, la vibración de configuración no funciona en el celular).

Para instalarlo en el celular:

- **Opción rápida (cable USB):** en el celular activá las *Opciones de desarrollador* (tocá 7 veces "Número de compilación" en *Ajustes → Acerca del teléfono*) y prendé la *Depuración por USB*. Conectalo a la compu y en Godot tocá el ícono de Android que aparece arriba a la derecha. Se instala y se abre solo.
- **Opción APK:** en **Project → Export**, elegí el preset de Android y tocá **Export Project**. Te genera un `.apk` que podés pasar al celular e instalar.

## Cómo está organizado

```
project.godot            configuración (vertical, pantalla, renderer liviano)
scenes/trip.tscn         la escena del viaje
scripts/game.gd          progreso, guardado y reglas de economía (autoload "Game")
scripts/trip.gd          el viaje: escenario, interfaz y lógica de todos los eventos
scripts/ui/screens.gd    menú, tienda, habilidades y camisetas
scripts/world/skins.gd   texturas de las camisetas
scripts/world/build.gd   ayudantes para armar todo con formas simples
scripts/world/characters.gd  los personajes
scripts/ui/touch_button.gd   botones que aceptan varios dedos a la vez
scripts/ui/meter.gd          las barras (vergüenza, aire, forcejeo, equilibrio...)
scripts/ui/coin.gd           la moneda dibujada
scripts/ui/city_map.gd       el mapa de la ciudad (modo historia)
scripts/ui/route_stops.gd    las paradas de la semana de cada barrio
assets/fonts/            la letra Fredoka (licencia libre OFL)
assets/audio/            efectos de sonido (CC0, ver CREDITOS.md) y la música
scripts/audio.gd         el sonido: efectos, música y motor (autoload "Audio")
tools/make_music.gd      genera la música de cumbia
docs/diseno.md           el documento de diseño completo
CLAUDE.md                contexto para seguir trabajando con Claude Code
```

Los números del juego (vergüenza por falla, duración del viaje, precios) están arriba de todo en `scripts/game.gd`, así se ajustan fácil.
