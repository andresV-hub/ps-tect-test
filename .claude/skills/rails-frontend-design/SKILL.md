---
name: rails-frontend-design
description: "Diseña y refina vistas, componentes y estilos del producto Rails siguiendo la imagen corporativa definida en styles.md. Usar cuando el usuario dice 'diseña la vista de', 'mejora la UI de', 'rediseña X', 'estilo de Y', 'maqueta', 'estilo de marca', 'aplica la imagen corporativa', 'unifica el look de' o 'mira si esto encaja con el diseño'. No usar para generar lógica de negocio (controllers/services), CRUD completo (usar /rails-crud), ni decoradores de tabla aislados (usar /rails-table-decorator)."
compatibility: "Ruby 3.4+, Rails 8, Bootstrap 5, ViewComponent + Draper. La imagen corporativa concreta vive en references/styles.md y es sustituible por proyecto."
metadata:
  version: 1.0.0
---

# Rails Frontend Design

Skill de diseño UI para proyectos Rails generados desde este template. **No asume ninguna paleta, tipografía ni naming concreto**: toda decisión visual se delega a `references/styles.md`, que es la imagen corporativa del producto actual y se reemplaza al clonar el template a un nuevo proyecto.

---

## Contrato con `styles.md`

`references/styles.md` es la **fuente de verdad visual del producto**. Su estructura es estable (secciones documentadas) pero su contenido cambia por proyecto:

- **Al clonar el template** → `styles.md` viene con la imagen del template Rails base (azul/naranja "Osen").
- **Al adaptar a un producto nuevo** → el usuario sustituye `styles.md` (paleta, tipografía, nombres de tokens, ejemplos) por la imagen corporativa del producto.
- **Esta skill nunca hardcodea colores ni tokens**: siempre cita `styles.md §X` como referencia.

Si `styles.md` describe `app-pill--brand` con un magenta, esta skill propondrá `app-pill--brand` con magenta. Si lo describe como `c-tag--primary` con cian, propondrá eso. La skill se adapta al lenguaje del producto.

---

## REGLAS CRÍTICAS

Aplican TODAS las reglas de `CLAUDE.md`. Adicionalmente:

1. **Leer `references/styles.md` primero**: Antes de proponer cualquier estilo, abrir el archivo completo. NUNCA improvisar tokens, paletas o convenciones sin consultarlo.
2. **Citar la sección al proponer**: Cada decisión visual referencia explícitamente la sección de `styles.md` que la justifica (`§Paleta`, `§Pills`, `§Layout`, etc.). Si no encuentras justificación, no propongas el cambio.
3. **Respetar el lenguaje del producto**: Si `styles.md` usa naming `app-*`, no introduzcas `c-*`. Si usa `c-*`, no introduzcas `app-*`. El naming es parte de la marca.
4. **No inventar tokens**: Si una situación requiere un color/estilo no documentado, **proponer su adición a `styles.md` al usuario primero**. No introducir CSS suelto.
5. **ViewComponents siempre**: Usa los componentes existentes (`Form::Fields::FieldComponent`, `Tables::IndexComponent`, `Show::Fields::FieldComponent`, `StateMachine::StateChangesCardComponent`). Si `styles.md` documenta nuevos componentes del producto, usarlos preferentemente.
6. **Coherencia cruzada**: Vistas que comparten patrón (index ↔ show ↔ subtable, hermanas de un mismo recurso) deben mostrar el mismo lenguaje visual. Detectar y alinear desviaciones.
7. **No tocar el design system sin aviso**: SCSS de tokens (típicamente en `app/assets/stylesheets/components/`) sólo se modifica con permiso explícito del usuario, y siempre actualizando `styles.md` en el mismo cambio.
8. **No romper JS hooks**: Antes de renombrar o eliminar cualquier selector (`#id`, `.clase`, atributo `data-*`), grep el repositorio (`app/javascript/`, partials de layout, controllers de Stimulus, comentarios "JS hooks preserved") para verificar que no se consulta desde JS. Si se consulta, mantén el selector original aunque cambie el contenido visual. Documenta los hooks preservados al inicio del archivo SCSS modificado.

---

## Proceso de Ejecución

### PASO 1: Cargar la imagen corporativa actual

Lectura obligatoria antes de cualquier propuesta:

1. `references/styles.md` completo
2. Las vistas, decorators y componentes implicados en el cambio
3. Las vistas hermanas/relacionadas (para detectar inconsistencias entre ellas)
4. **Inventario de JS hooks afectados**: si el cambio toca SCSS/HTML del layout, navbar, sidebar, modales o cualquier elemento con `id="..."` o `data-*`, ejecutar `grep` en `app/javascript/` (y en SCSS por cabeceras "JS hooks preserved: ...") para listar los selectores que NO se pueden renombrar. Documentar ese inventario antes de tocar nada.

Si `styles.md` referencia archivos SCSS concretos del proyecto, abrir esos archivos para verificar que lo documentado existe en código.

### PASO 2: Detectar deriva visual

Comparar el código actual contra `styles.md`. Marcar como "deriva":

- Uso de clases Bootstrap genéricas cuando el sistema documenta un equivalente propio (p.ej. `badge bg-*` cuando hay pills propios)
- Botones/iconos sin la clase del sistema definida en `styles.md`
- HTML manual de formularios cuando existen ViewComponents
- Layouts/grids que no siguen la jerarquía documentada (page header → surface → grid)
- Colores hex inline sin mapeo a tokens
- Padding/radius/sombras fuera de la tabla canónica de `styles.md`
- Naming mezclado (parte `app-*`, parte `c-*`) en un mismo archivo

### PASO 3: Diagnóstico y propuesta

Estructura toda propuesta en 3 bloques:

```markdown
## Diagnóstico
- [Inconsistencia 1] en `path/to/file.rb:LL` — desvía de `styles.md §X`
- [Inconsistencia 2] en `path/to/view.html.erb:LL` — usa Bootstrap genérico en lugar del token del producto

## Propuesta
- Reemplazar `<clase actual>` por `<token de styles.md>` en archivo:línea
- Mover el bloque de filtros a la estructura documentada en `styles.md §Filtros`

## Tokens del sistema aplicados
- `<token>` → `styles.md §<sección>`
- `<componente>` → `styles.md §<sección>`
```

### PASO 4: Implementar respetando el sistema

- Cambios en decoradores → editar `*_decorator.rb` con los tokens documentados
- Cambios en vistas → respetar la jerarquía documentada en `styles.md §Layout`
- Cambios SCSS → solo con permiso explícito; actualizar también `styles.md` en el mismo commit
- Nuevos ViewComponents → en `app/components/` con SCSS modular, documentándolos en `styles.md`

### PASO 5: Verificar coherencia

Antes de cerrar la tarea, revisar:

- [ ] ¿Hay otra vista con el mismo patrón que quedó con estilo antiguo? Alinearla.
- [ ] ¿El cambio mantiene responsive según breakpoints de `styles.md`?
- [ ] ¿Los iconos siguen la librería única declarada en `styles.md`?
- [ ] ¿La paleta usa únicamente tokens documentados?
- [ ] ¿`styles.md` sigue siendo fiel al código (no quedó desactualizado)?
- [ ] ¿Todos los JS hooks listados en el PASO 1 siguen presentes (IDs, clases consultadas, `data-*`)? Si alguno se renombró, ¿se actualizó también la referencia JS en el mismo commit?

---

## Flujo recomendado al clonar el template a un nuevo producto

Cuando el usuario inicia un proyecto nuevo a partir del template y quiere aplicar su imagen corporativa:

1. **Recopilar la nueva imagen** (logo, paleta, tipografía, ejemplos de UI, brandbook si existe).
2. **Reemplazar `references/styles.md`** con el documento del producto nuevo, manteniendo la estructura por secciones (`§Imagen de marca`, `§Paleta`, `§Tipografía`, `§Layout`, `§Componentes`, etc.). Si el usuario solo aporta paleta y tipografía, ayudarle a rellenar el resto a partir del documento previo (estructura) sustituyendo los valores.
3. **Sincronizar el SCSS**: Editar los tokens en `app/assets/stylesheets/components/_app_components.scss` (o donde estén definidos) para que reflejen `styles.md`. Renombrar clases si el producto exige un naming distinto (`app-*` → `acme-*`, por ejemplo) y actualizar las vistas/decoradores correspondientes en una pasada de barrido.
4. **Auditar vistas existentes** del template (login, dashboard, CRUDs base, errores) y aplicar la nueva imagen.
5. **Actualizar la documentación cruzada** (`CLAUDE.md`, `docs/components.md`) si alguna referencia visual quedó obsoleta.

Para esta migración inicial, considera invocar `/oh-my-claudecode:frontend-design` si necesitas explorar direcciones estéticas alternativas antes de comprometerte con la del brandbook.

---

## Recetas rápidas para casos comunes

### "Las badges/estados se ven distintas entre dos vistas"

1. Localizar ambos decoradores/vistas
2. Identificar qué clase usa cada uno
3. Consultar `styles.md §Pills` (o equivalente) para ver el token correcto del producto
4. Alinear ambos al mismo token, respetando la semántica (estado leído/resuelto/pendiente, etc.) documentada en `styles.md`

### "Rediseña la cabecera de una vista"

1. Consultar `styles.md §Page Header` (o equivalente del producto)
2. Aplicar la estructura documentada (header + lead + actions + cta)
3. Usar las variantes de CTA documentadas (primary/ghost/etc.) según jerarquía

### "Diseña el index de X"

1. Consultar `styles.md §Layout` (jerarquía de página) y `§Tablas`
2. Wrapper → header con CTA "Nuevo" → filtros en surface → tabla en surface con turbo frame
3. Modal de creación si aplica

### "Diseña el show de X con state machine"

1. Consultar `styles.md §Show grid` y `§State Machine`
2. Grid con columna principal (show fields) y lateral (state changes card)
3. Subtablas embebidas deben usar los mismos tokens visuales que las tablas principales

### "Aplica la nueva imagen corporativa a toda la app"

1. Reemplazar `references/styles.md` con el documento del producto
2. Diff visual: comparar antiguos tokens con nuevos, generar mapa de migración
3. Aplicar en orden: tokens SCSS → componentes ViewComponent → decoradores → vistas
4. Auditar vista a vista que ninguna referencia al estilo anterior quedó suelta

---

## Cuándo escalar a `/oh-my-claudecode:frontend-design` (skill oficial)

La skill oficial está pensada para exploración creativa libre. Úsala cuando:

- El usuario pida explorar direcciones estéticas alternativas antes de decidir la imagen corporativa
- Se rediseñe el design system desde cero (no hay `styles.md` válido aún)
- El cambio requiere romper deliberadamente con la marca actual

En cualquier otro caso, `rails-frontend-design` es la correcta porque respeta la marca documentada del producto.

---

## Recursos

- **`references/styles.md`**: Imagen corporativa del producto actual. **Sustituible por proyecto.** Lectura obligatoria antes de cada propuesta.
- **`docs/components.md`** (raíz del proyecto): Catálogo de ViewComponents del template Rails. Estable entre productos.
- **`app/assets/stylesheets/components/`**: Implementación SCSS de los tokens documentados en `styles.md`.
- **`CLAUDE.md`**: Reglas técnicas del proyecto (estables entre productos).
