# Imagen Corporativa del Producto — Power Solutions

> **Este archivo es la fuente de verdad visual del producto.** La skill `rails-frontend-design` debe leerlo antes de cualquier propuesta de UI y atenerse a lo que aquí se documente.
>
> **Reglas de oro**: (1) este documento y el SCSS del proyecto deben permanecer alineados — si uno cambia, el otro también en el mismo commit; (2) el naming es parte de la marca: las clases propias llevan prefijo `ps-`, las de Bootstrap 5 se usan tal cual sin inventar variantes.

---

## 0. Versión actual de la imagen

- **Producto**: Power Solutions Technical Test — plataforma de exámenes y evaluación (roles `admin` / `student`).
- **Estilo de marca**: *instrumento de medida* (§1). Carcasa neutra de pizarra sobre superficies blancas, **azul eléctrico** para lo accionable y **ámbar** como única señal de "hay tiempo corriendo". La UI vende **claridad de estado** (¿el examen está abierto, cerrado, entregado?) y **fiabilidad del dato** (puntuaciones, analíticas), no espectáculo visual.
- **Stack real**: Rails 8.1 + **Slim** (con islas de ERB en Devise) + **Bootstrap 5.3.8** + **Bootstrap Icons 1.11.3** + simple_form 5.4 + will_paginate + filterrific + cocoon + flatpickr + Chartkick. Sin Node: Propshaft + importmap + dartsass-rails.
- **Estado**: ✅ **documento sincronizado con el código.** Los tokens viven en `app/assets/stylesheets/generics/_brand.scss` y los componentes `ps-*` con ellos; el esqueleto responsive está en `generics/layout.scss`. Las secciones marcadas **[VIGENTE]** describen lo que ya está implementado; quedan unas pocas **[OBJETIVO]** listadas en §12.

> **Aviso para la skill:** antes de crear una clase `ps-*` nueva, comprobar que no existe ya en `app/assets/stylesheets/generics/_brand.scss`. Si hay que añadirla, documentarla aquí en el mismo cambio.
>
> **Orden de carga (importante):** `_brand.scss` se carga **después** de `bootstrap`, no antes. Bootstrap 5.3 compila el color de cada componente a hex dentro de su propia regla (`.btn-primary` fija `--bs-btn-bg: #0d6efd`), así que redefinir `--bs-primary` no basta: la marca reescribe las variables CSS **por componente** (`--bs-btn-*`, `--bs-alert-*`, `--bs-table-*`…), que sí ganan por cascada.

---

## 1. Imagen de Marca

### 1.1 Qué hace realmente la aplicación

La marca no se diseña sobre el nombre, se diseña sobre el comportamiento del producto. Esto es lo que el código dice que hace:

| Hecho del dominio | Dónde vive | Qué exige a la marca |
|---|---|---|
| Un `admin` **compone** un examen con preguntas anidadas de tres tipos (`text`, `single_choice`, `multiple_choice`), cada una puntuable o no | `exam.rb`, `question.rb`, `_question_fields.slim` | Formularios densos, jerarquía clara entre pregunta y opciones, no decoración |
| Cada examen tiene **ventana temporal** `start_date` → `end_date`, y `available_now?` decide todo | `exam.rb`, `_list.slim` | El tiempo es el estado dominante. La marca necesita un color que grite "ahora" |
| El `student` **entrega una vez** y obtiene `score / total_score` | `user_exam.rb`, `user_exams/show.slim` | La cifra es el clímax de la pantalla. Necesita tipografía de datos |
| La corrección se muestra **respuesta a respuesta**, con lo elegido frente a lo correcto | `user_exams/show.slim` | Verde/rojo con icono; nunca sólo color, es información sensible para el usuario |
| El `admin` mide el sistema en **series temporales y distribuciones** | `analytics/index.slim` | Paleta de datos multi-serie, separada de la semántica |
| Autenticación por rol, dos vistas del mismo objeto | `user.rb` (`admin`/`student`) | Una sola marca, dos densidades: componer vs. responder |

**Síntesis en una frase:** esto no es una plataforma de aprendizaje, es un **instrumento de medida con ventana temporal**. Nadie viene a explorar; se viene a componer una prueba, a responderla dentro de un plazo, o a leer una cifra.

### 1.2 Direcciones exploradas

| # | Dirección | Idea | Por qué se descarta / elige |
|---|---|---|---|
| A | **Aula** | Papel, ámbar cálido, serif, tono docente | ❌ El producto no enseña, evalúa. El calor invita a explorar, y aquí no hay nada que explorar |
| B | **Certificación** | Navy institucional, sellos, verde de aprobado | ❌ Sobredimensiona el resultado: convierte cada examen en un veredicto y el 60 % de las pantallas son de composición, no de resultado |
| C | **Cuadro eléctrico** | La metáfora de "Power": circuito abierto/cerrado, señal, industrial | ⚠️ Buena raíz — la ventana temporal *es* un circuito que se abre y se cierra — pero llevada al literal (texturas, avisos de peligro) resulta agresiva para un examen |
| D | **Instrumento de medida** ✅ | Precisión: escala, aguja, lectura. Frío, neutro, un único acento de señal | ✅ **Elegida.** Cubre a la vez la composición (rigor), el plazo (señal) y la puntuación (lectura). Y hereda de C la energía sin caer en el disfraz industrial |

### 1.3 La dirección elegida: *instrumento de medida*

> **Un aparato de medición bien hecho: carcasa neutra, escala legible, y una sola luz que se enciende cuando hay corriente.**

Esa frase resuelve las tres decisiones fundacionales:

- **La carcasa** → neutros de pizarra y superficies blancas. Sin ruido, sin degradados, sin textura. Todo el peso visual disponible se reserva para el dato.
- **La escala** → azul eléctrico corporativo, heredado del `#3498db` que la aplicación ya usa en sus gráficos. Es el color de lo navegable y lo fiable: menú, enlaces, botón primario, series de datos.
- **La luz de corriente** → **ámbar**. Es el hallazgo de este brainstorming: el estado más importante de todo el producto es *"la ventana está abierta, actúa"*, y se venía pintando con el `bg-warning` de Bootstrap por descarte, no por diseño. Se eleva a **color de acento de la marca**. El ámbar significa siempre lo mismo en todo el producto: **hay tiempo corriendo**.

Dos colores con significado, y nada más. Azul = puedes moverte. Ámbar = el reloj corre. El verde y el rojo quedan reservados a la corrección, donde son irrenunciables.

### 1.4 Personalidad

| Es | No es |
|---|---|
| Preciso | Frío o burocrático |
| Sobrio | Aburrido: el ámbar y la cifra grande dan pulso |
| Directo | Escueto: siempre dice *por qué* un examen no está disponible |
| Neutral ante el resultado | Punitivo: un suspenso se informa, no se castiga con rojo a pantalla completa |

### 1.5 Principios de diseño

- **El estado siempre visible.** Disponible, finalizado, aún no disponible, completado, en curso: nunca se deducen, se leen en una píldora con texto.
- **El tiempo es ámbar.** Ventana abierta, entrega sin enviar, plazo por vencer: siempre ámbar, nunca otra cosa. Y el ámbar no se usa para nada más.
- **La puntuación es el dato protagonista.** En resultados, `score / total` domina la pantalla: cifra grande, tabular, con su máximo al lado para que nunca se lea fuera de contexto.
- **El azul se gana.** Sólo lo accionable y lo de marca van en azul; el texto corrido es tinta pizarra.
- **Aire antes que bordes.** Separar con espacio; el borde de `1px` es el último recurso — y cuando aparece, es el único separador (nada de borde + sombra + fondo a la vez).
- **Una sola familia de iconos** (Bootstrap Icons) y un solo acento por pantalla.
- **Corrección visible, no punitiva.** Acierto en verde, fallo en rojo, siempre con icono y texto, nunca sólo color.
- **Densidad según el rol.** El `admin` compone: formularios compactos, tablas densas. El `student` responde: una pregunta respira, con espacio suficiente para leerla sin prisa.
- Radios: tarjetas y paneles `0.5rem`, controles `0.375rem`, píldoras `999px`.
- Sombras planas y bajas. Sin elevaciones dramáticas.

### 1.6 Logotipo **[VIGENTE]**

**Concepto: el conmutador.** Un anillo abierto por arriba con una barra vertical en el hueco — el símbolo universal de encendido (⏻), que además se lee como una **P**. Reúne las tres ideas: el círculo es el ciclo de evaluación, la barra es la corriente, y el conjunto es "Power".

- **Construcción**: lienzo `512×512`, centro en `256,256`, anillo de radio `176` y trazo `56` con hueco superior de `70°`, barra vertical centrada del mismo grosor de `y=96` a `y=216`. Extremos redondeados.
- **Variante sobre claro**: anillo en `--ps-blue-600`, barra en `--ps-amber-500`. Estructura azul, corriente ámbar: el logotipo explica el sistema de color entero.
- **Variante sobre oscuro** — `app/assets/images/logo.svg`, la que usa la navbar: anillo en **blanco**, barra en `--ps-amber-500`. Mantiene los dos colores del sistema legibles sobre el navy.
- **Variante monocroma** — `public/icon.svg`: todo en blanco sobre un cuadrado redondeado de `--ps-blue-900` (`rx: 112`). Obligatoria para el favicon, donde a 16px la barra ámbar se pierde.
- **Lockup horizontal**: símbolo a `28px` de alto + `Power Solutions` en weight 700, `letter-spacing: -0.01em`, `gap: 0.5rem`. Es lo que ocupa el `navbar-brand`.
- **Zona de respeto**: el radio del anillo por cada lado.
- **Prohibido**: rotarlo, rellenar el anillo, añadirle sombra, o usar el ámbar en el anillo y el azul en la barra (invierte el significado del sistema).
- **Variante rasterizada** — `public/icon.png`, 512×512 RGBA. Se genera con `script/render_icon.rb`, que dibuja la misma geometría con funciones de distancia y antialiasing 4×4 y escribe el PNG sobre Zlib. Se hizo así porque la máquina no tiene ImageMagick ni rsvg; **si se cambia el logotipo, hay que volver a ejecutarlo**:

```bash
ruby script/render_icon.rb public/icon.png
```

- **Reemplazó a**: el círculo rojo de `public/icon.svg` y `public/icon.png`, y los `theme_color` / `background_color` `"red"` de `app/views/pwa/manifest.json.erb`, restos del andamiaje de Rails.

### 1.7 Voz

Segunda persona, castellano neutro, sin exclamaciones ni gamificación. **Se nombra el estado y su causa**, nunca sólo el estado.

| ✅ | ❌ |
|---|---|
| "Este examen ha finalizado el 12/03/2026 a las 18:00" | "No disponible" |
| "Disponible hasta el 12/03/2026 a las 18:00" | "¡Date prisa!" |
| "Has obtenido 14 de 20" | "¡Buen trabajo! 🎉" |
| "Aún no has entregado este examen" | "Examen pendiente" |
| "Responder examen" | "¡Empezar ya!" |

Léxico fijo del dominio: **examen**, **convocatoria** (la ventana temporal), **pregunta**, **opción**, **entrega**, **puntuación**, **corrección**. No se alternan sinónimos entre pantallas.

Todo texto de interfaz pasa por I18n (`config/locales/`); **no se escribe copy en las vistas**.

---

## 2. Tokens de Color

### Azul de marca **[OBJETIVO]**

Escala derivada de `#3498db`, el azul que ya se usa hoy como color de serie en los gráficos de analíticas (`app/views/analytics/index.slim`). Contrastes calculados según WCAG 2.1 sobre blanco.

| Token | Hex | Sobre blanco | Uso |
|---|---|---|---|
| `--ps-blue-50` | `#eef6fd` | 1.06:1 | Fondo de aviso informativo, fila activa de tabla |
| `--ps-blue-100` | `#d9ecfb` | 1.14:1 | Fondo de píldora informativa |
| `--ps-blue-200` | `#b3d9f6` | 1.35:1 | Bordes suaves, hover claro |
| `--ps-blue-300` | `#7dbeef` | 2.00:1 | Texto y enlaces **sobre azul oscuro** (5.87:1 sobre `--ps-blue-900`) |
| `--ps-blue-400` | `#3498db` | 3.15:1 | **Color de marca.** Superficies grandes, series de gráfico, iconos ≥24px |
| `--ps-blue-500` | `#2b7fb8` | 4.35:1 | Hover de botón primario, bordes de foco |
| `--ps-blue-600` | `#1f6b9c` | 5.77:1 | **Fondo de botón primario** (texto blanco) y **texto/enlaces sobre blanco** |
| `--ps-blue-700` | `#15537c` | 8.20:1 | Titulares de acento, estado activo del menú |
| `--ps-blue-900` | `#0e3b58` | 11.76:1 | Barra de navegación oscura, máximo contraste |

### Ámbar de corriente **[OBJETIVO]**

El acento de la marca (§1.3). **Significa una sola cosa en todo el producto: hay un plazo corriendo.** No se usa para ninguna otra idea.

| Token | Hex | Sobre blanco | Uso |
|---|---|---|---|
| `--ps-amber-100` | `#fef3c7` | 1.09:1 | Fondo de píldora "disponible" y de aviso de plazo |
| `--ps-amber-300` | `#fcd34d` | 1.55:1 | Texto y trazos **sobre azul oscuro** (8.16:1 sobre `--ps-blue-900`) |
| `--ps-amber-500` | `#f59e0b` | 2.15:1 | **Acento de marca.** Barra de la ventana abierta, barra del logotipo, indicador de convocatoria activa. **Nunca como texto sobre blanco** |
| `--ps-amber-700` | `#b45309` | 5.02:1 | Texto y borde de "disponible ahora" sobre blanco o sobre `--ps-amber-100` |

Regla de proporción: el ámbar ocupa como mucho el **5 %** de la superficie de una pantalla. Es una luz, no un fondo.

### Neutros

| Token | Hex | Contraste s/blanco | Uso | Estado |
|---|---|---|---|---|
| `--ps-ink` | `#1f2a37` | 14.53:1 — AAA | Titulares y texto principal | [OBJETIVO] |
| `--ps-ink-muted` | `#475569` | 7.58:1 — AAA | Texto secundario, descripciones | [OBJETIVO] |
| `--ps-ink-soft` | `#64748b` | 4.76:1 — AA | Metadatos, `small.text-muted`, deshabilitado | [OBJETIVO] |
| `--ps-border` | `#dee2e6` | — | Separadores, bordes de tarjeta, borde del menú lateral | **[VIGENTE]** en `layout.scss` |
| `--ps-canvas` | `#f8f9fa` | — | Fondo del menú lateral y de página | **[VIGENTE]** en `layout.scss` |
| `--ps-surface` | `#ffffff` | — | Tarjetas, paneles, tablas, área de contenido | **[VIGENTE]** |
| `--ps-on-dark` | `#ebedf0` | 9.14:1 sobre `--ps-blue-900` | Texto sobre fondo oscuro | [OBJETIVO] |

### Semánticos

Cada estado se declara como **par texto + fondo**, nunca como fondo suelto.

| Token | Texto | Fondo | Significado en el dominio |
|---|---|---|---|
| `--ps-success` | `#15803d` | `#ecfdf5` | Examen completado, respuesta correcta, opción correcta |
| `--ps-live` | `#b45309` (= `--ps-amber-700`) | `#fef3c7` (= `--ps-amber-100`) | **Convocatoria abierta ahora**, entrega en curso, plazo por vencer |
| `--ps-danger` | `#b91c1c` | `#fef2f2` | Error de validación, respuesta incorrecta, acción destructiva |
| `--ps-info` | `#1f6b9c` | `#eef6fd` | Aún no disponible, aviso neutro, listado vacío |
| `--ps-neutral` | `#475569` | `#f1f5f9` | Examen finalizado, estado inerte |

`--ps-live` **es** el ámbar de marca, no un "warning" genérico: no se usa para advertencias de formulario (para eso está `--ps-danger`) ni para nada que no tenga un reloj detrás.

`.error { color: #dc3545 }` en `layout.scss` es el rojo de Bootstrap **[VIGENTE]**; al implementar los tokens se sustituye por `--ps-danger`.

### Paleta de gráficos **[VIGENTE]**

Secuencia canónica para Chartkick, en este orden. Ya está en uso en `app/views/analytics/index.slim`.

| # | Hex | Se usa hoy en |
|---|---|---|
| 1 | `#3498db` | Exámenes creados por mes (línea) |
| 2 | `#2ecc71` | Entregas completadas por mes (línea) |
| 3 | `#9b59b6` | Puntuación media por examen (barras) |
| 4 | `#e67e22` | Alumnos por examen (tarta) |
| 5 | `#f1c40f` | — reserva |
| 6 | `#1abc9c` | — reserva |
| 7 | `#34495e` | — reserva |
| 8 | `#c0392b` | — reserva |

- Un gráfico de serie única usa siempre el color que le corresponde por su posición en el dashboard, no el primero de la lista.
- Los gráficos categóricos toman los colores en orden, sin saltos.
- **Nunca** se reutiliza un color de esta paleta para significado semántico (`#2ecc71` no es "correcto"; el verde de acierto es `--ps-success`).

### Reglas duras

- **`#3498db` NUNCA como color de texto sobre blanco** — 3.15:1, falla WCAG AA para texto normal. Para texto y enlaces sobre blanco: `--ps-blue-600` (`#1f6b9c`).
- **`.badge.bg-info` está prohibido.** Bootstrap pinta el badge con texto blanco sobre `#0dcaf0` → 1.96:1, ilegible. Usar `.badge.text-bg-info` (texto oscuro) o la píldora propia de §6.4.
- **`.badge.bg-warning` siempre con `.text-dark`** (ya se hace en `exams/_list.slim` y `user_exams/_list.slim` — mantener).
- **`#f59e0b` NUNCA como color de texto** — 2.15:1. Para texto ámbar: `--ps-amber-700` (`#b45309`).
- **El ámbar sólo significa tiempo.** Si un elemento en ámbar no tiene un plazo detrás, está mal pintado.
- **NUNCA** hex sueltos inline (`style="color: #..."`) ni en helpers de vista.
- **NUNCA** un color nuevo sin añadirlo antes a este documento.
- **Rojo prohibido como color de marca.** `public/icon.svg` (círculo rojo) y `theme_color: "red"` en `app/views/pwa/manifest.json.erb` son restos del andamiaje de Rails: deben sustituirse por el logotipo de §1.6 y `--ps-blue-600`.
- El color nunca es el único portador de significado: todo estado lleva texto o icono.

---

## 3. Tipografía

Una sola familia, toda la jerarquía por **peso y tamaño**. Un instrumento de medida no cambia de tipografía entre la carcasa y la escala.

- **Familia [VIGENTE]**: la pila del sistema por defecto de Bootstrap 5. La aplicación no carga fuentes propias.
- **Familia [OBJETIVO]**: **Inter variable, auto-alojada** en `app/assets/fonts/` y servida por Propshaft con `font-display: swap`. Es una grotesca neutra, con cifras excelentes, y no necesita Node ni CDN (§10.10). Se elige por dos motivos concretos del producto: la altura de x alta sostiene las tablas densas del `admin`, y sus `tabular-nums` alinean las puntuaciones en columna.
- **Cifras tabulares — obligatorio [VIGENTE]**: `font-variant-numeric: tabular-nums` en `.ps-num`, `.ps-score`, `.ps-pill--points` y todas las celdas de `table.table`. Sin esto, la columna de `score / total` baila entre filas y el dato deja de ser legible de un vistazo.
- **Título de página** (`h1`, `h2` de cabecera de sección): `clamp(1.5rem, 2.5vw, 1.9rem)`, weight 700, `letter-spacing: -0.02em`, color `--ps-ink`.
- **Título de sección / cabecera de tarjeta** (`h3`, `.card-header h5`): `1.15rem`, weight 600.
- **Título de pregunta** (`.card-title` en `exams/show`, `user_exams/show`): `1.05rem`, weight 600.
- **Cuerpo**: `1rem`, line-height `1.6`, color `--ps-ink`.
- **Secundario / metadatos** (`small`, `.text-muted`, fechas): `0.875rem`, color `--ps-ink-soft`.
- **Píldora / etiqueta de estado**: `0.75rem`, weight 600, mayúsculas, `letter-spacing: 0.06em`.
- **Puntuación destacada** (`user_exams/show`): `1.25rem`, weight 700 — es el dato protagonista de la pantalla.

Máximo 75 caracteres por línea en texto largo (enunciado de pregunta, respuesta libre).

**Fechas y horas**: todas se presentan como `dd/mm/aaaa HH:MM`. Hoy se consigue con `strftime("%d/%m/%Y %H:%M")` repetido en seis vistas **[VIGENTE]**; el objetivo es centralizarlo en `config/locales/generics/formats.es.yml` y usar `l(fecha, format: :short)`.

---

## 4. Espaciado, Bordes y Sombras

| Propiedad | Valor canónico | Aplicación | Estado |
|---|---|---|---|
| Ancho del menú lateral | `250px` | `.left-menu` | **[VIGENTE]** |
| Padding del área de contenido | `20px` | `.content-area` | **[VIGENTE]** |
| Padding del menú lateral | `1rem` (`.p-3`) | `nav` dentro de `.left-menu` | **[VIGENTE]** |
| Radio tarjeta / panel | `0.5rem` | `.card` | **[VIGENTE]** |
| Radio control | `0.375rem` | inputs, botones, selects | **[VIGENTE]** (Bootstrap) |
| Radio píldora | `999px` | `.ps-pill` | **[VIGENTE]** |
| Padding tarjeta | `1rem` | `.card-body` | **[VIGENTE]** |
| Padding celda de tabla | `0.75rem` | `tbody td` | **[VIGENTE]** |
| Separación entre tarjetas apiladas | `0.5rem` (`.mb-2`) preguntas · `1rem` (`.mb-3`) bloques | `exams/show`, `_question_fields` | **[VIGENTE]** |
| Padding píldora | `0.25rem 0.7rem` | `.ps-pill` | **[VIGENTE]** |
| Borde | `1px solid var(--ps-border)` | tarjetas, tablas, menú lateral | **[VIGENTE]** |
| Sombra tarjeta | `0 1px 2px rgba(31, 42, 55, 0.06)` | reposo | **[VIGENTE]** |
| Sombra tarjeta hover | `0 6px 16px rgba(31, 42, 55, 0.10)` | sólo tarjetas clicables | **[VIGENTE]** |
| Foco | `0 0 0 3px rgba(52, 152, 219, 0.35)` | inputs y botones | **[VIGENTE]** |
| Transición | `160ms ease` | hover/focus | **[VIGENTE]** |
| Logotipo | `height: 32px` (`28px` en la navbar) | `.ps-logo` | **[VIGENTE]** en `generic.scss` y `_brand.scss` |

Toda separación vertical se expresa con las utilidades de Bootstrap (`mt-*`, `mb-*`, `p-*`). No se escriben márgenes sueltos en SCSS salvo dentro de un componente `ps-*`.

---

## 5. Layout **[VIGENTE]**

Esqueleto definido en `app/assets/stylesheets/generics/layout.scss` y `app/views/layouts/application.slim`.

```
html, body                        ← flex column, height 100%, fondo --ps-canvas
├── body > header                 ← _header.html.slim, flex-shrink: 0
└── .main-content-wrapper         ← flex row (columna por debajo de lg)
    ├── aside#appSideMenu         ← .left-menu.offcanvas-lg.offcanvas-start
    │                               250px fijos en lg+, cajón deslizante debajo.
    │                               Sólo si existe "#{controller_path}/menu"
    └── .content-area             ← flex-grow: 1, overflow-y: auto, padding 20px,
        │                           `.ps-auth` añadido en pantallas de Devise
        ├── _flash                ← mensajes flash (§6.10)
        └── yield
```

**Reglas del esqueleto:**

- El scroll **nunca** es de la página: el `body` no desborda. Cada columna (`.left-menu`, `.content-area`) gestiona su propio `overflow-y`.
- La cabecera es fija en altura y no participa del scroll.
- El menú lateral es **contextual por controlador**: se renderiza automáticamente si existe `app/views/<controller>/_menu.slim`. Hoy lo tienen `exams` y `user_exams` (este último reutiliza el de exams). Un recurso nuevo con menú propio sólo tiene que añadir ese partial — no se toca el layout.
- Las páginas de Devise no tienen menú lateral. En lugar de estirarse al ancho completo, el `.content-area` recibe `.ps-auth`, que centra cada bloque hijo en una columna de `420px`.
- **Nada de `.container` dentro de `.content-area`**: el área de contenido ya define su padding y su scroll.

**Jerarquía canónica de una vista de contenido:**

```
.mt-4
├── .ps-page-header         ← h1 + acción primaria (flex, space-between)
├── hr
├── .ps-filters             ← sólo en index: superficie propia sobre --ps-canvas
└── contenido               ← tabla, tarjetas o formulario
```

Un solo `h1` por pantalla, dentro de `.ps-page-header`; las secciones dentro de la página usan `h2` seguido de `hr`.

---

## 6. Componentes de UI

### 6.1 Barra de navegación **[VIGENTE]**

`app/views/layouts/_header.html.slim` — `nav.navbar.navbar-expand-lg.navbar-light.bg-light` con `.container-fluid`.

- Izquierda: `navbar-brand` → inicio; después los enlaces de sección (`Exámenes`, y `Analíticas` sólo para `admin`).
- Derecha (`ms-auto`): dropdown con el email del usuario y `Cerrar sesión`.
- Sin sesión: sólo `Iniciar sesión` y `Registrarse`, alineados a la derecha.
- **[OBJETIVO]**: pasar a `navbar-dark` sobre `--ps-blue-900` con el logotipo corporativo en el `navbar-brand`, y marcar el enlace de la sección activa con `--ps-blue-300`.
- **JS hook**: `#userDropdown` y los atributos `data-bs-toggle="dropdown"` los consume el JS de Bootstrap. No renombrar.

### 6.2 Menú lateral **[VIGENTE]**

`exams/_menu.slim` — `nav.p-3` con `h4` de título y `ul.nav.flex-column` de `nav-link`.

- Muestra siempre las acciones globales del recurso; añade las acciones sobre el registro actual (`Ver X`, `Editar X`, `Eliminar X`) sólo cuando `@exam` está persistido.
- La acción destructiva va con `.text-danger` y `turbo_confirm`.
- Las opciones se filtran por rol: `admin` ve creación y edición, `student` ve sus entregas.
- **[OBJETIVO]**: estado activo del enlace con fondo `--ps-blue-50` y texto `--ps-blue-700`.

### 6.3 Tablas de listado **[VIGENTE]**

Patrón único, idéntico en `exams/_list.slim` y `user_exams/_list.slim`:

```slim
.table-responsive
  table.table.table-hover.table-striped
    thead / tbody
= will_paginate coleccion
```

- La primera columna es siempre el enlace al recurso.
- La última columna es siempre `Acciones`, con botones `btn-sm` separados por `me-2`.
- La penúltima (para `student`) es el estado, en píldora.
- Los encabezados salen de `Model.human_attribute_name` o de I18n; nunca texto literal.
- Estado vacío: `.alert.alert-info` con el mensaje traducido, **nunca** una tabla vacía.
- Paginación: `will_paginate` con `WillPaginate.per_page = 10` (`config/initializers/will_paginate.rb`), tema Bootstrap vía `will_paginate-bootstrap`.

### 6.4 Píldoras de estado

Léxico de estados del dominio. Hoy son badges de Bootstrap **[VIGENTE]**; el objetivo es una clase propia `ps-pill ps-pill--<estado>` con el par texto+fondo de §2.

Los badges genéricos de Bootstrap quedaron retirados: dos de ellos (`bg-info`) daban 1.96:1 de contraste.

| Estado | Clase | Token | Texto | Significado |
|---|---|---|---|---|
| Entregado | `.ps-pill--done` | `--ps-success` | "Entregado" | El alumno entregó el examen |
| **Disponible** | `.ps-pill--live` | `--ps-live` | "Disponible" | Convocatoria abierta, requiere acción |
| Finalizado | `.ps-pill--closed` | `--ps-neutral` | "Finalizado" | `end_date` en el pasado |
| Programado | `.ps-pill--scheduled` | `--ps-info` | "Programado" | `start_date` en el futuro |
| En curso | `.ps-pill--live` | `--ps-live` | "En curso" | Entrega iniciada sin enviar |
| Sin entregar | `.ps-pill--live` | `--ps-live` | "Sin entregar" | Entrega sin completar |
| Puntos de pregunta | `.ps-pill--points` | `--ps-blue-100` sobre `--ps-blue-700` | "N puntos" | Valor de la pregunta |
| Puntuación | `.ps-score` | `--ps-blue-700` | `14,00 / 20,00` | El dato protagonista |

Los textos viven en `activerecord.user_exam.attributes.status_badge.*`. Esas claves **no existían**: las vistas llevaban tiempo pintando `translation missing` en la columna de estado.

- Toda píldora lleva **texto**; el color acompaña, no sustituye.
- `.ps-pill--live` es la **única** píldora ámbar del sistema, y lleva siempre la fecha límite a su lado (§1.7: se nombra el estado *y su causa*).
- `.ps-score` no es una píldora: es el dato protagonista. Cifra a `1.25rem` weight 700 con `tabular-nums`, y el máximo (`/ total`) en `--ps-ink-soft` a tamaño de cuerpo, para que la nota nunca se lea sin su escala.

### 6.5 Botones **[VIGENTE]**

Mapeo de intención fijo. No se improvisan variantes.

| Intención | Clase | Ejemplo |
|---|---|---|
| Acción principal | `.btn.btn-primary` | Realizar examen, Enviar respuestas, Aplicar filtros |
| Acción secundaria / volver | `.btn.btn-secondary` | Volver, Restablecer filtros |
| Crear | `.btn.btn-success.float-end` | Crear nuevo examen (en cabecera de index) |
| Editar | `.btn.btn-warning` | Editar examen |
| Eliminar | `.btn.btn-danger` | Eliminar examen (siempre con `turbo_confirm`) |
| Consultar resultado | `.btn.btn-info` | Ver mis resultados, Ver respuestas |
| Añadir fila anidada | `.btn.btn-outline-primary.btn-sm` | Añadir pregunta |
| Añadir sub-fila / quitar | `.btn.btn-outline-secondary.btn-sm` / `.btn.btn-outline-danger.btn-sm` | Añadir opción / Quitar pregunta |

- Dentro de tablas, siempre `btn-sm`.
- Una sola acción primaria por pantalla.
- Toda acción destructiva pasa por `data: { turbo_confirm: t(...) }`.

### 6.6 Tarjetas **[VIGENTE]**

- **Tarjeta de detalle** (`exams/show`, `user_exams/show`): `.card.mb-3` con `.card-body` y pares `strong` etiqueta + valor.
- **Tarjeta de pregunta** (`exams/show`, `user_exams/show`): `.card.mb-2`, `h5.card-title` con el número y el enunciado, píldora de puntos flotando a la derecha, tipo de pregunta en `em`, y las opciones en `ul.list-group.list-group-flush`.
- **Tarjeta de gráfico** (`analytics/index`): `.card` con `.card-header > h5` y `.card-body` con el gráfico a `height: "300px"`.
- **Tarjeta de campos anidados** (`_question_fields.slim`): `.nested-fields.card.card-body.mb-3`.

### 6.7 Lista de opciones y corrección **[VIGENTE]**

`ul.list-group.list-group-flush` con un `li.list-group-item` por opción, precedido siempre de icono:

| Contexto | Icono | Color |
|---|---|---|
| Opción correcta (vista de admin) | `bi-check-lg` | `.text-success` |
| Opción incorrecta (vista de admin) | `bi-x-lg` | `.text-danger` |
| Opción elegida por el alumno | `bi-check-circle-fill` + `strong` | `.text-primary` |
| Opción no elegida | `bi-circle` | `.text-muted` |

La solución correcta se muestra siempre en una lista aparte, bajo el epígrafe traducido correspondiente. Icono **y** texto: nunca sólo color.

### 6.8 Formularios **[VIGENTE]**

- Se usa **simple_form** (`config.button_class = "btn"`, wrapper `:default`) con la rejilla de Bootstrap (`.row`, `.col-md-*`).
- `f.error_notification class: 'alert alert-danger'` encabeza todo formulario.
- Los errores de asociaciones anidadas se pintan como `.alert.alert-danger` dentro del contenedor de la asociación.
- Acciones al pie, en `.form-actions.mt-4`: primaria (`btn-primary.me-2`) y volver (`btn-secondary`).
- **Fechas**: input `as: :string` con clase `.flatpickr-input` y `data-date-format="Y-m-d H:i"`. Flatpickr se inicializa en `turbo:load` con locale `es` (`app/javascript/src/flatpickr_init.js`). **No usar `date_field` nativo.**
- **Formularios anidados**: cocoon con `link_to_add_association` / `link_to_remove_association`.
- **Inconsistencia detectada**: `user_exams/_form.html.slim` usa `form_with` + helpers crudos (`radio_button_tag`, `check_box_tag`) y texto en castellano incrustado, en lugar de simple_form + I18n como el resto. Debe alinearse.

**JS hooks — NO renombrar** (`app/javascript/src/question_form_logic.js`):

| Selector | Función |
|---|---|
| `.nested-fields` | Contenedor de pregunta que cocoon inserta/elimina |
| `data-question-type` | Atributo leído para decidir si se muestran las opciones |
| `.question-type-select` | Select cuyo `change` dispara el refresco |
| `.scorable-checkbox` | Casilla que activa/desactiva el campo de puntuación |
| `.score-input` / `.score-input-group` | Campo de puntuación y su envoltorio |
| `.options-fields` / `#options-container` | Bloque de opciones que se oculta en preguntas de texto |
| `.flatpickr-input` | Selector de fecha |
| `#filterrific_results` | Destino del refresco parcial de filtros |
| `#appSideMenu` / `#mainNav` / `#userDropdown` | Offcanvas, collapse y dropdown de Bootstrap |

> `.score-fields` se consultaba desde el JS pero no existía en ninguna vista, y además se mostraba en las dos ramas del condicional: no hacía nada. Se retiró del JS; el envoltorio real es `.score-input-group`, gobernado por `updateScorableFields()`.

**Controles por tipo de pregunta** — idénticos en `user_exams/new.html.slim` y en `user_exams/_form.html.slim` (que usa `edit`), aunque sigan siendo dos formularios distintos:

| Tipo | Control | Nombre del parámetro |
|---|---|---|
| `text` | `text_area` | `…[text_answer]` |
| `single_choice` | **radio** (`radio_button_tag`) | `…[question_option_ids][]` |
| `multiple_choice` | casilla | `…[question_option_ids][]` |

El `single_choice` usaba casillas en `new`: el control mentía sobre la restricción y dejaba marcar varias opciones donde sólo cabe una. El sufijo `[]` se conserva en los radios porque el controlador permite `question_option_ids: []`; el agrupado del radio lo hace el propio `name`, así que sigue llegando un array de un elemento.

**`text_answer_correct` es sólo del admin.** Es la marca de corrección de las respuestas libres: `UserExam#calculate_score!` suma los puntos de la pregunta cuando está a `true`. La casilla se pinta únicamente si `current_user.admin?`, **y además** `user_exam_params` sólo la permite para el admin — ocultarla en la vista no basta, porque se puede añadir a mano al formulario.

### 6.9 Barra de filtros **[VIGENTE]**

`exams/index.html.slim` — `form_for_filterrific` dentro de `.ps-filters`, una superficie propia sobre `--ps-canvas` con borde y radio de §4: select de ordenación en `.col-md-8` (`.form-select`) y acciones en `.col-md-4` (`Aplicar filtros` primario + `Restablecer filtros` secundario), con `.row.g-3.align-items-end`. Los resultados se refrescan dentro de `#filterrific_results` vía `index.js.erb`. Va entre la cabecera de página y el listado.

### 6.10 Alertas y mensajes flash **[VIGENTE]**

| Variante | Uso |
|---|---|
| `.alert.alert-info` | Estado vacío ("no hay exámenes", "sin preguntas", "sin respuestas") |
| `.alert.alert-warning` | Plazo: examen abierto, finalizado o aún no disponible. Es ámbar (`--ps-live`) |
| `.alert.alert-danger` | Errores de validación de formulario |
| `.alert.alert-success` | Confirmación de una acción completada |

**Flash** — `app/views/layouts/_flash.html.slim`, renderizado al principio del `.content-area`. Los controladores llevaban tiempo emitiendo `notice` y `alert` que el layout nunca pintaba. El mapeo es fijo:

| Clave de flash | Variante | Icono |
|---|---|---|
| `notice`, `success` | `alert-success` | `bi-check-circle-fill` |
| `alert`, `error` | `alert-danger` | `bi-exclamation-triangle-fill` |
| cualquier otra | `alert-info` | `bi-info-circle-fill` |

Cada mensaje lleva icono **y** texto (§9) y es descartable (`.alert-dismissible` + `.btn-close`).

### 6.11 Gráficos **[VIGENTE]**

Chartkick sobre Chart.js. `height: "300px"`, título por I18n, colores según la paleta de §2, dos por fila (`.col-md-6`). Todo gráfico va dentro de una tarjeta con `.card-header`.

---

## 7. Iconografía

- **Librería única: Bootstrap Icons, servida por la gema.** Se insertan como **SVG en línea** con el helper `bi_icon` de `ApplicationHelper`; no hay hoja de fuente ni CDN. Ninguna otra familia, ningún SVG suelto, ningún emoji en la interfaz.

```slim
= bi_icon("check-lg", class: "text-success me-2")
= bi_icon("list", "aria-label": t("navigation.toggle_side_menu"))
```

- El SVG sale con `fill="currentColor"`, así que hereda el color: `.text-success`, `.text-danger`, `.text-muted` siguen funcionando igual que con la fuente.
- Sin `aria-label`, la gema marca el icono como `aria-hidden="true"` — que es lo correcto cuando acompaña a un texto. Si el icono va solo en un control, la etiqueta accesible va en el botón.
- `.bi { vertical-align: -0.125em }` en `_brand.scss` reproduce la corrección de línea base que aplicaba la hoja de Bootstrap Icons.
- La gema (`bootstrap-icons` 1.0.15) trae 2050 símbolos. Necesita `require: "bootstrap_icons"` en el `Gemfile`: el archivo de entrada no se llama como la gema y Bundler no la carga sola.
- Iconos en uso hoy: `bi-check-lg`, `bi-x-lg`, `bi-check-circle-fill`, `bi-circle`.
- Tamaño: hereda del texto. Separación del texto con `.me-2`.
- El icono nunca va solo en un elemento accionable sin `aria-label`.
- Iconos en uso: `check-lg`, `x-lg`, `check-circle-fill`, `circle` (corrección); `list` (abrir menú lateral), `person-circle` (usuario), `plus-lg`; `journal-text`, `check2-square`, `plus-square`, `graph-up` (portada); `check-circle-fill`, `exclamation-triangle-fill`, `info-circle-fill` (flash).

---

## 8. Responsive

Breakpoints de Bootstrap 5, sin puntos propios. `sm 576` · `md 768` · `lg 992` · `xl 1200` · `xxl 1400`.

- **Rejilla de formularios**: `col-md-*`. Por debajo de `md`, los campos apilan a ancho completo.
- **Analíticas**: `col-md-6` → una tarjeta por fila en móvil.
- **Tablas**: siempre dentro de `.table-responsive` (scroll horizontal en móvil, nunca truncado).
- **Navbar**: `navbar-expand-lg` con `#mainNav.collapse.navbar-collapse` → hamburguesa por debajo de `lg`. Antes la navbar declaraba `navbar-expand-lg` sin ningún `.collapse`, así que el atributo no hacía nada.
- **Menú lateral [VIGENTE]**: `aside#appSideMenu.left-menu.offcanvas-lg.offcanvas-start`. En `lg+` es un panel estático de `250px`; por debajo es un cajón de `280px` que abre el botón `#appSideMenuToggle` de la navbar, y `.main-content-wrapper` pasa a `flex-direction: column`. Antes el menú tenía `250px` fijos en todos los tamaños y se comía el ancho útil en móvil.

---

## 9. Accesibilidad

Objetivo: **WCAG 2.1 nivel AA**.

- Texto normal ≥ **4.5:1**, texto grande (≥24px, o ≥19px en negrita) y componentes de UI ≥ **3:1**.
- El color nunca es el único portador de significado: acierto/fallo llevan icono, los estados llevan texto.
- Todo control tiene etiqueta asociada (`label for`), ya sea vía simple_form o `label_tag`.
- El foco es siempre visible; no se elimina el `outline` sin sustituirlo por el anillo de §4.
- Jerarquía de encabezados sin saltos: un solo `h1`/`h2` de página, `h3`+ para las secciones.
- Los diálogos destructivos usan `turbo_confirm`, que es accesible por teclado.
- **Deudas conocidas**: los badges `bg-info` de §2 (1.96:1) y la ausencia de `aria-label` en los enlaces del menú lateral que sólo se distinguen por el nombre del recurso.

---

## 10. Antipatrones (NO HACER)

1. **Hex inline** en vistas o helpers. Todo color por token o por clase de Bootstrap documentada aquí.
2. **Copy incrustado en la vista o en el controlador.** Todo texto de interfaz va a `config/locales/`. Se puede verificar de una pasada: un script que extraiga las claves `t('…')` de `app/views`, `app/controllers` y `app/helpers` y compruebe `I18n.exists?(clave, :es)` debe salir limpio.
3. **Mezclar idiomas en la interfaz.** El producto habla castellano.
4. **`.badge.bg-info` con texto blanco.** Ver §2. En su lugar, las píldoras `ps-pill--*`.
5. **`strftime` en las vistas.** El formato de fecha está centralizado: `l(fecha, format: :short)`.
6. **`.container` dentro de `.content-area`.** El área de contenido ya define su padding y su scroll.
7. **`date_field` nativo** en lugar de flatpickr: rompe la coherencia del selector de fechas.
8. **HTML de formulario a mano** cuando simple_form cubre el caso.
9. **Renombrar selectores sin comprobar el JS.** Antes de tocar cualquier `id`, clase o `data-*` de §6.8, hacer `grep` en `app/javascript/`.
10. **Añadir dependencias de CSS/JS por CDN.** El proyecto no tiene Node por decisión de diseño: todo llega por gema + importmap.
11. **Sombras dramáticas, degradados, animaciones de entrada.** No son de esta marca.
12. **Más de un acento por pantalla.** Si ya hay un botón primario, el resto son secundarios u outline.

---

## 11. Checklist de revisión de UI

Antes de dar por cerrado un cambio visual:

- [ ] ¿Todos los colores salen de §2? ¿Ningún hex inline?
- [ ] ¿Todos los textos pasan por I18n, en castellano?
- [ ] ¿Los estados se leen (texto + icono), no sólo se ven?
- [ ] ¿Los contrastes cumplen AA (§9)?
- [ ] ¿La vista sigue la jerarquía canónica de §5 (`h2` → `hr` → contenido)?
- [ ] ¿Los botones respetan el mapeo de intención de §6.5?
- [ ] ¿Las tablas van en `.table-responsive`, con `will_paginate` y estado vacío?
- [ ] ¿Los iconos son Bootstrap Icons y sólo Bootstrap Icons?
- [ ] ¿Los JS hooks de §6.8 siguen intactos? (`grep` en `app/javascript/`)
- [ ] ¿Las vistas hermanas del mismo recurso quedaron con el mismo lenguaje visual?
- [ ] ¿Este documento sigue siendo fiel al código?

---

## 12. Estado de la migración

| Área | Estado | Siguiente paso |
|---|---|---|
| Dirección de marca | ✅ Definida (§1) | — |
| Tokens de color `ps-*` | ✅ `generics/_brand.scss` | — |
| Ámbar de corriente | ✅ `--ps-amber-*` + `--ps-live` | — |
| Píldoras `ps-pill` y `.ps-score` | ✅ Implementadas | — |
| Logotipo (SVG) | ✅ `app/assets/images/logo.svg`, `public/icon.svg` | — |
| Navbar de marca | ✅ Navy + lockup + sección activa | — |
| Menú lateral responsive | ✅ `offcanvas-lg` | — |
| Mensajes flash | ✅ `layouts/_flash.html.slim` | — |
| Esqueleto de layout | ✅ Tokenizado | — |
| Paleta de gráficos | ✅ Implementada | — |
| Cifras tabulares | ✅ Aplicadas | — |
| I18n completo de la UI | ✅ 143 claves, ninguna ausente en `:es` | — |
| Formato de fecha centralizado | ✅ `time.formats.short` | — |
| Pantallas de Devise | ✅ Centradas con `.ps-auth` | Rediseñar el formulario en tarjeta si se quiere ir más allá |
| `public/icon.png` | ✅ Generado por `script/render_icon.rb` | — |
| Iconos servidos por gema | ✅ SVG en línea vía `bi_icon`, sin CDN | — |
| Controles de `single_choice` | ✅ Radios en las dos vistas | — |
| `text_answer_correct` sólo admin | ✅ Vista + strong params | — |
| Autorización de `edit`/`update` | ✅ El alumno sólo toca sus entregas | Revisar el resto de controladores con el mismo criterio |
| Tipografía Inter auto-alojada | ❌ Pila del sistema | Añadir la variable a `app/assets/fonts/` + `@font-face` en `_brand.scss` |

---

## 13. Referencias cruzadas

| Qué | Dónde |
|---|---|
| Entrada de estilos | `app/assets/stylesheets/application.scss` |
| **Tokens y componentes de marca** | `app/assets/stylesheets/generics/_brand.scss` |
| Esqueleto de layout | `app/assets/stylesheets/generics/layout.scss` |
| Reglas previas a Bootstrap | `app/assets/stylesheets/generics/generic.scss` |
| Logotipo | `app/assets/images/logo.svg` (sobre oscuro), `public/icon.svg` (favicon/PWA) |
| Generador del PNG del icono | `script/render_icon.rb` |
| Helper de iconos | `app/helpers/application_helper.rb` (`bi_icon`) |
| Layout HTML | `app/views/layouts/application.slim`, `_header.html.slim`, `_flash.html.slim` |
| Menús laterales | `app/views/<recurso>/_menu.slim` |
| JavaScript de formularios | `app/javascript/src/question_form_logic.js` |
| Inicialización de fechas | `app/javascript/src/flatpickr_init.js` |
| Mapa de importaciones | `config/importmap.rb` |
| Configuración de formularios | `config/initializers/simple_form.rb` |
| Paginación | `config/initializers/will_paginate.rb` |
| Textos de interfaz | `config/locales/` |
| Skill que consume este documento | `.claude/skills/rails-frontend-design/` |
