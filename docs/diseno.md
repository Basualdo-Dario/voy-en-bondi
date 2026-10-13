# Voy en Bondi — Documento de diseño

Oct 13, 2026 · @Dario

> Copia del documento de diseño (original en Claude Docs). Si algo de acá no coincide con el código, manda el código (`scripts/game.gd` tiene los números actuales). Cuando cambie una regla del juego, actualizar también este archivo.

## Concepto

**Nombre:** Voy en Bondi. **Slogan:** “Llegá a destino, si podés”.

Un chico tiene que sobrevivir a sus viajes en colectivo durante un día normal: ir al trabajo, a la facultad, a entrenar y volver a casa. Cada viaje es una serie de eventos a los que el jugador reacciona con distintos controles del celular.

- **Plataforma:** Android (Play Store).
- **Tono:** humor cotidiano; cualquiera que viaje en colectivo se siente identificado.
- **Objetivo principal:** terminar el día. Cada viaje suma puntos, que se juntan al final.

## Estructura de la partida

Una partida es un día con 4 viajes en orden. Entre viaje y viaje se vuelve al menú, donde se ve el plan del día y se puede pasar por la tienda.

| Viaje | Momento | Eventos principales |
| --- | --- | --- |
| 1. Casa → trabajo | Mañana | Colectivo lleno, equilibrio, abrirse paso al fondo |
| 2. Trabajo → facultad | Tarde | Cansancio, luchar contra el sueño |
| 3. Facultad → gimnasio | Tarde-noche | Robos, pasajeros con mal olor |
| 4. Gimnasio → casa | Noche | Piernas cansadas, ceder el lugar o fingir dormir ante la embarazada |

**Progresión:** cada día es un día de la semana, de lunes a viernes, con dificultad creciente. Cada semana es un barrio del modo historia (ver abajo).

## Modo historia

La partida se arma como una historia con dos capítulos, cada uno con un objetivo grande y un final con remate. Los textos y los datos de los barrios están en `scripts/game.gd` (`CHAPTERS` y `BARRIOS`).

- **Capítulo 1 · La moto:** el pibe junta para una moto y dejar el bondi. Final: se la compra y se le rompe el primer día.
- **Capítulo 2 · Mudarse cerca:** quiere mudarse cerca del laburo. Final: se muda y lo trasladan a la sede de la otra punta de la ciudad.
- **Después:** modo libre en el último barrio con la dificultad al máximo, hasta que llegue el capítulo 3.

**Mapa:** cada capítulo es una zona de la ciudad con 4 barrios que se desbloquean de a uno, unidos por el recorrido del colectivo. Adentro de cada barrio, la semana se ve como un recorrido de 5 paradas (lunes a viernes, 4 viajes por día).

| # | Capítulo | Barrio | Línea | Novedad (etapas siguientes) |
| --- | --- | --- | --- | --- |
| 1 | La moto | Villa Parada | 42 (amarilla) | Barrio inicial, eventos actuales |
| 2 | La moto | Barrio Ramal | 17 (verde) | El pibe con el parlante a todo volumen |
| 3 | La moto | El Centro | 101 (roja) | Hora pico: ir al fondo sin chocar a nadie |
| 4 | La moto | La Costanera | 5 (celeste, de noche) | El que se duerme encima tuyo |
| 5 | Mudarse cerca | Villa Trasbordo | 33 (naranja) | Tocar el timbre justo antes de la parada (propuesta) |
| 6 | Mudarse cerca | Barrio Terminal | 88 (bordó) | El músico que pasa la gorra (propuesta) |
| 7 | Mudarse cerca | Las Torres | 214 (violeta) | La señora del changuito: esquivarlo inclinándote (propuesta) |
| 8 | Mudarse cerca | Barrio Nuevo | 9 (rosa, de noche) | Viajar con la lámpara de la mudanza (propuesta) |

**Al terminar un barrio:** camiseta exclusiva del barrio (no se compra) y +200 monedas. Al terminar un capítulo: +500 más. Los carteles de historia salen en el menú: intro de cada capítulo y barrio, y los finales.

**Dificultad:** sube medio punto por barrio y un cuarto por día de la semana (de 0 el primer lunes hasta 4,5 el viernes del barrio 8; 5 en el modo libre).

## Eventos y controles

El jugador viaja parado todo el juego. Los personajes recorren el colectivo de punta a punta, dando vueltas, y cada vez que uno pasa cerca del jugador se dispara su evento. Si falla, se llena la barra de vergüenza.

- **Eventos al mismo tiempo:** como máximo dos, uno de botón y uno de inclinar el celular. Por ejemplo, una frenada justo cuando pasa la embarazada. Nunca se juntan dos eventos de botón.
- **Vendedor ambulante:** cuenta como evento de botón. Mientras te ofrece cosas no arranca ningún otro (oloroso, choro, embarazada ni sueño), pero las frenadas siguen igual. Si llega cuando hay otro evento, espera a que termine.
- **Tres controles en total:** inclinar el celular, tocar rápido y mantener apretado.

**Ritmo:** el jugador siempre tiene que estar haciendo algo.

- El colectivo se mueve todo el tiempo, así que siempre hay que corregir un poco el equilibrio. Las frenadas y curvas son picos más fuertes, cada 5 a 8 segundos.
- Nunca pasan más de 2 segundos sin evento: si no viene nadie, el próximo personaje se apura a pasar.
- Un "!" sobre el personaje avisa un segundo antes de que llegue.
- En el primer viaje los eventos no se juntan hasta que el jugador vio cada uno solo. Cuando se juntan con un evento de botón, la frenada es más suave.

**Equilibrio en pantalla:** la barra de equilibrio va abajo, entre dos flechas que se mantienen apretadas para inclinarse. Así se ve junto con el evento de botón. En el primer viaje el bamboleo arranca suave y va subiendo.

| Evento | Cuándo aparece | Control | Ganás si | Perdés si |
| --- | --- | --- | --- | --- |
| Equilibrio | El colectivo frena o dobla | Inclinar el celular al lado contrario de la caída | Te mantuviste parado hasta que pasó | Te caés |
| Oloroso | Pasa cerca el sucio del gym | Pasa caminando despacio al lado tuyo. Aparecen dos barras: una con su cara, que avanza hasta que se aleja, y la de aire. Mantener apretado para aguantar: la barra de aire se llena de izquierda a derecha. Tiene una zona verde de aire limpio: solo se puede soltar ahí. Mientras respirás, la zona se achica; hay que volver a apretar antes de que desaparezca. La barra no vuelve a cero, y cada vez que apretás la zona verde cambia de lugar. El perfume da 3 segundos para respirar sin tragar el olor | Aguantaste hasta que su cara llegó al final de la barra | Si soltás fuera de la zona verde (sin perfume) o la zona se termina mientras respirás, vomitás. Si la barra se vacía, te desmayás |
| Sueño | Cansancio durante el viaje (más frecuente a la tarde y a la noche) | Tocar rápido: cada toque sube la línea y el sueño la baja sola. La zona verde está al final de la barra | Cuando se acaba el tiempo, la línea está en la zona verde | Te dormís y te caés |
| Choro | Pasa cerca el choro | Si el candado está activo, pasa de largo. Si no, forcejeo: tocar rápido para llevar la barra a tu lado mientras el choro tira al suyo | La barra llega a tu lado | La barra llega al lado del choro: te roba |
| Embarazada | La primera vez que aparece, elegís: ceder el lugar o fingir dormir | Ceder: perdés tu lugar en la manija y el equilibrio es más difícil el resto del viaje. Fingir: cada vez que pasa, mantener apretado para mover la línea y soltar en la zona verde | Fingir: soltaste dentro de la zona verde | Si te pasás, te dormís de verdad y te caés. Si no llegás, te ve despierto |
| Ir al fondo | Al subir con el colectivo lleno | Arrastrar el dedo entre agarraderas sin golpear a nadie | Llegaste al fondo | Golpeás a alguien o te caés |
| Vendedor ambulante | Pasa cerca el vendedor | Te ofrece 3 veces seguidas. Tocar NO, GRACIAS antes de que se acabe el tiempo de cada oferta; el botón cambia de lugar y cada oferta es más rápida. Con la billetera le comprás algo barato y se va enseguida | Le dijiste que no las 3 veces, o usaste la billetera | No respondiste a tiempo: te enchufa algo y perdés 20 monedas |

**Tutorial:** el cartel que explica cada evento aparece solo la primera vez que sale ese evento en el primer nivel. Después solo aparecen la barra y el botón.

## Puntaje, vergüenza y guardado

- **Barra de vergüenza:** reemplaza a las vidas. Si se llena, el viaje sale mal.
- **Fallar un viaje** no termina el día: se sigue con menos puntos.
- **Puntaje:** cada viaje da puntos; al final del día se suman.
- **Guardado:** se guarda entre viajes. Se puede salir a mitad del día y continuar después.
- **Salir a mitad de un viaje:** al volver, ese viaje empieza de cero.

## Ítems y tienda

En esta versión la tienda está abierta siempre: se puede comprar en el menú entre viaje y viaje. Lo comprado queda en la mochila y en cada viaje se usa hasta el límite diario de cada ítem.

- **Uso:** cada ítem aparece al lado del botón del evento donde sirve. Perfume junto a AGUANTÁ (se puede deslizar el dedo del botón al perfume), candado junto al forcejeo con el choro, café junto al botón del sueño (te despierta al instante) y billetera junto al NO, GRACIAS del vendedor.
- **Se guardan** entre días, pero hay un límite por día para cada ítem.
- **Efectos secundarios:** algunos ítems tienen un costo además del precio.

| Ítem | Efecto | Límite por día | Efecto secundario |
| --- | --- | --- | --- |
| Café | En el evento de sueño, sube la línea de golpe | 2 | — |
| Perfume | Durante 3 segundos se puede respirar sin inhalar el olor, para salvarse cuando está por perder | 3 usos | — |
| Candado | Durante 6 segundos el choro pasa de largo y no hay forcejeo | 2 | — |
| Skins | Camisetas de fútbol de clubes de barrio inventados: Deportivo La Parada, Sportivo Línea 42, Atlético Ramal 5, Social Colectiveros, Unión Pasajeros y Juventud Boleto. Sin clubes reales, porque sus marcas y camisetas necesitan licencia y Google Play rechaza apps que las usan sin permiso | — | — |
| Billetera | Le comprás algo barato al vendedor ambulante (5 monedas) y se va enseguida | 2 | Gastás 5 monedas |

**Ansiedad:** queda fuera de esta versión. Se puede evaluar más adelante como efecto secundario del café.

## Habilidades del jugador

El jugador mejora tres habilidades para aguantar viajes más difíciles.

La barra de capacidad pulmonar solo aparece cuando hay un oloroso cerca.

| Habilidad | Qué mejora |
| --- | --- |
| Capacidad pulmonar | Aguantar más tiempo la respiración y resistir varios olorosos |
| Fuerza | Mantener el equilibrio y no caerse en frenadas y curvas |
| Resistencia a la vergüenza | La barra de vergüenza se llena más lento, así no pierde rápido |

Se mejoran con monedas y todas arrancan en nivel 0. Cada una tiene 5 niveles; los precios están en Reglas de economía.

## Reglas de economía (propuesta)

Números iniciales para programar; se ajustan después de probar el juego.

**Puntaje y monedas**

- **Puntaje del viaje:** 100 menos la vergüenza con la que terminás el viaje.
- **Monedas por viaje:** 20 fijas más la mitad del puntaje (entre 20 y 70).
- **Viaje fallado** (la vergüenza llegó a 100): ganas solo las 20 fijas y seguís el día.
- **Terminar el día:** +50 monedas. Si no fallaste ningún viaje: +100 más.
- **Robo:** el choro se lleva 30 monedas. El vendedor ambulante, si no le decís que no a tiempo, te cobra 20 (sin vergüenza).
- **Monedas al empezar el juego:** 200.

**Vergüenza por cada falla** (sin mejoras)

| Falla | Vergüenza |
| --- | --- |
| Caerte | +32 |
| Te roban | +32 |
| Vomitar | +36 |
| Te ven despierto | +36 |
| Dormirte y caerte | +36 |
| Desmayarte | +40 |

Con 3 o 4 fallas se pierde el viaje.

**Precios**

| Qué | Precio | Límite |
| --- | --- | --- |
| Café | 30 | 2 por día |
| Perfume | 40 | 3 usos por día |
| Candado | 50 | 2 por día |
| Nivel de habilidad | 150 × el nivel al que subís (150, 300, 450, 600, 750) | 5 niveles |
| Skins | Entre 300 y 1000 | — |
| Billetera | 35 | 2 por día |

**Efecto de las habilidades por nivel**

| Habilidad | Nivel 0 | Cada nivel suma | Nivel 5 |
| --- | --- | --- | --- |
| Capacidad pulmonar | Aguantás 3 s | +1,5 s | 10,5 s |
| Fuerza | Aguantás frenadas suaves | +10% de inclinación tolerada | +50% |
| Resistencia a la vergüenza | Vergüenza normal | −8% de vergüenza por falla | −40% |

**Dificultad:** sube con cada día y cada barrio (ver Modo historia): el choro tira más fuerte, las frenadas vienen más seguido y el vendedor da menos tiempo.

## Monetización

Sin publicidad. Todo se maneja con monedas que se ganan jugando: el jugador elige si las gasta en ítems, en mejorar habilidades o en skins. La compra de monedas con dinero real queda para la segunda versión.

- Comprar monedas requiere Google Play Billing y una cuenta de comerciante.
- Recomendación: la primera versión sale solo con monedas ganadas; las compras se agregan después.
- Los ítems ayudan pero no reemplazan la habilidad, para que no sea un juego de pagar para ganar.

## Estilo visual y cámara

El juego es 3D low-poly: personajes armados con formas simples, colores fuertes y onda argentina.

- **Personajes:** cada uno se reconoce por un rasgo exagerado. Las amenazas usan colores fuertes; los pasajeros comunes van en gris.
- **Cámara:** fija dentro del colectivo, en vertical, desde atrás y un poco arriba del jugador.
- **Animaciones:** simples y graciosas (tambalearse, caerse, cabecear de sueño).
- **Pantalla (HUD):** barra de vergüenza arriba, progreso del viaje, monedas, el evento con su botón y el ítem que sirve al lado, y abajo el equilibrio entre dos flechas.

| Personaje | Rol | Rasgos |
| --- | --- | --- |
| El pibe | Jugador | Auriculares rojos, mochila, buzo azul, SUBE en la mano |
| El choro | Amenaza: robo | Camiseta de fútbol con el 10, gorra, riñonera cruzada, piercings, bolsa del botín |
| La embarazada | Fingir dormir | Rodete con broche, aros grandes, remera rosa, calza, bolsa de los mandados |
| El sucio del gym | Amenaza: olor | Musculosa, short, vincha, ojotas con medias, mancuerna, olor verde y moscas |
| Pasajero común | Relleno | Todo en gris, mochila adelante, termo bajo el brazo |
| La abuela | Relleno | Pelo canoso con rodete, anteojos, chal tejido, bolsa de compras |
| El oficinista | Relleno | Camisa, corbata, maletín y celular en la mano |
| El estudiante | Relleno | Guardapolvo blanco, mochila, auriculares chiquitos |
| El obrero | Relleno | Casco, chaleco con bandas reflectivas, bolso con la vianda |

Los pasajeros de relleno van con colores apagados (cada uno tiene dos variantes) para que las amenazas resalten. Siete van sentados, mezclados al azar en cada viaje, y tres parados del lado derecho, agarrados de la manija y lejos del pasillo.
| El vendedor ambulante | Molestia: te ofrece cosas | Remera naranja, gorra roja y bandeja de golosinas colgada del cuello |

## Sonido

- **Efectos:** de bancos con licencia CC0 (Kenney y OpenGameArt), listados en `assets/audio/CREDITOS.md`. Cada acción importante tiene su sonido: botones, compras, frenadas (a veces con bocinazo), caídas, el aviso "!", ganar o perder un evento y el fin del viaje.
- **Ambiente:** el motor del colectivo suena durante el viaje y baja de tono en las frenadas.
- **Música:** cumbia chiptune en loop, generada por código. Más fuerte en el menú y más bajita en el viaje.
- **Silenciar:** botón en el menú y en la pausa; se guarda en la partida.
- **Pendiente:** no hay sonidos CC0 buenos de vómito, bostezo ni frenada con chirrido; por ahora se usan otros parecidos.

## Primera versión (alcance)

Un día completo con lo justo para probar si el juego es divertido.

- [x] Un día con los 4 viajes
- [x] Personajes que recorren el colectivo y eventos de equilibrio, oloroso, choro, embarazada, vendedor ambulante y sueño
- [x] Barra de vergüenza y puntaje por viaje
- [x] Guardado entre viajes
- [x] Tienda abierta siempre, con monedas ganadas
- [x] 2 o 3 ítems: café, candado, perfume

**Motor sugerido:** Godot en 3D (gratis, liviano, buen soporte para Android y acelerómetro).

## Pendientes por definir

- [ ] Probar los números de Reglas de economía en el prototipo y ajustarlos
- [ ] Cada cuánto pasa cada personaje según el día de la semana
- [ ] Cuánto más difícil es el equilibrio después de ceder el lugar
- [x] Diseño de la pantalla de tienda
- [ ] Diseño del interior del colectivo y animaciones de cada personaje
- [ ] Logo definitivo de Voy en Bondi
