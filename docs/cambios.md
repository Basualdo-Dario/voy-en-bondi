# Registro de cambios

Cada cambio del juego, del más nuevo al más viejo. El detalle completo y la forma de volver atrás están en el historial de Git (`git log`).

## 2026-10-13

- **Configuración (engranaje arriba a la izquierda del menú):** idioma (español; el inglés llega en la próxima actualización), volumen de música y de efectos por separado, sonido prendido/apagado, control inclinando el celular (prender/apagar y sensibilidad), vibración (al caerte, en frenadas y robos), viaje de práctica con todos los tutoriales que no cuenta para tu partida, créditos y reiniciar partida (con cartel de confirmación). El botón de sonido del menú pasó adentro de configuración; en la pausa sigue estando.
- **Choro con tiempo:** el forcejeo dura como máximo 5 segundos (con cuenta regresiva). Si no llevás la barra a tu zona verde a tiempo, te roba.
- **Música cumbia villera:** nueva canción de 38 segundos con teclado berreta con vibrato, guacharaca al frente, timbales con redobles, cencerro y bajo. Dos partes para que no sea tan repetitiva.
- **Murmullo de gente:** se sacó el balbuceo de los personajes (sonaba robótico) y en su lugar suena de fondo, durante el viaje, una grabación real de gente hablando bajito.
- **Sonido:** efectos para botones, compras, monedas, frenadas (con bocinazo del chofer), caídas, el "!" de aviso, el forcejeo con el choro, el sueño, aguantar la respiración, el vendedor, los ítems y el fin del viaje. Motor del colectivo de fondo que baja de tono en las frenadas. Música de cumbia chiptune en el menú (más bajita en el viaje). Botón para silenciar en el menú y en la pausa (se guarda).
- **Modo historia (etapa 1):** dos capítulos ("La moto" y "Mudarse cerca") con 8 barrios. Cada barrio es una semana con su línea de colectivo (otro color, otro cartel, algunos de noche). Pantalla de Mapa con la ciudad, los barrios y el recorrido de la semana. Carteles de historia al empezar capítulos y barrios, y finales con remate. Al terminar un barrio: camiseta exclusiva y +200 monedas; al terminar un capítulo, +500. La dificultad sube por barrio. Las partidas guardadas siguen en el barrio 1.
- **Pasajeros nuevos:** la abuela, el oficinista, el estudiante y el obrero, con colores apagados y dos variantes cada uno. Siete van sentados (cambian de asiento en cada viaje) y tres parados agarrados de la manija.
- **Interfaz más moderna:** letra nueva (Fredoka), botones con relieve, brillo y sombra suave, tarjetas con sombras difuminadas, barras más prolijas, moneda dibujada en lugar del "●", nivel de habilidades como barrita de 5 segmentos, cartel de arriba del viaje más compacto, ícono en la barra de vergüenza y carteles que aparecen con una animación.
- **Pruebas automáticas:** el piloto automático y las capturas juegan con una partida de prueba y ya no tocan la partida guardada.
- **Vendedor ambulante:** mientras te ofrece cosas no arranca ningún otro evento de botón (oloroso, choro, embarazada ni sueño). Las frenadas siguen igual. Si llega cuando hay otro evento, espera a que termine. Después de que se va hay 1,2 s de respiro antes del próximo evento.
- **Primera versión** guardada en Git: el día de 4 viajes con todos los eventos, tienda, habilidades y camisetas.
