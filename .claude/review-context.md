# Review Context para Codex y Claude review pass (frontend/I18n)

Documento de referencia condensado para las reviews AI. Para Codex se inyecta en el prompt del CLI; para la Claude review pass (frontend/I18n) la consume el coordinador (Claude principal) al ejecutar su segunda pasada interna.

**Fuente de verdad**: Si hay discrepancia entre este documento y `CLAUDE.md`, prevalece `CLAUDE.md`. Actualizar este archivo cuando cambie `CLAUDE.md`.

---

## 1. CONTEXTO COMÚN (ambos reviewers)

### Stack del Proyecto

- Ruby 3.4.4, Rails 8, MySQL
- Testing: RSpec + FactoryBot
- Borrado lógico: Discard (`include Discard::Model` + `default_scope -> { kept }`)
- Autenticación: Devise | Autorización: Pundit | Roles: Rolify
- Decorators: Draper | Componentes: ViewComponent
- State Machines: AASM
- Deploy: Docker + Kubernetes

### Arquitectura

```
Request → Controller → Service → Model/DB
                    ↘ Decorator → ViewComponent → View → Response
```

- **Controllers**: Solo recibir petición → llamar servicio → responder. Variables `@` siempre son decorators.
- **Services**: Heredan de `BaseService` (método `service_execute`). Search hereda de `Base::Search`.
- **Models**: Delgados. Solo validaciones, asociaciones y métodos sin parámetros. `include Discard::Model` obligatorio.
- **Decorators**: `ShowDecorator` y `TableDecorator`. Sin lógica de negocio. `delegate_all` obligatorio.
- **Views**: Tontas. Solo renderizar. Usar ViewComponents existentes (Form::Fields::*, Tables::IndexComponent, Show::Fields::FieldComponent).

### Servicios Base Disponibles

- `Base::Find` → Buscar por ID (raise `RecordNotFound` si no existe): `Base::Find.execute(klass: Model, id: id)`
- `Base::FindBy` → Buscar por filtros (retorna `nil` si no existe, NO raise): `Base::FindBy.execute(klass: Model, filters: { email: "x" })`
- `Base::Search` → Búsqueda con filtros (heredar, usa `apply_#{filter_name}_filter`)
- `Base::Discard` → Borrado lógico: `Base::Discard.execute(object: record, user: current_user)`

**Componente factory de formularios**: `Form::Fields::FieldComponent` delega al tipo correcto según `:type`. Usar este por defecto en vistas.

**`execute` vs `service_execute`**: Los servicios base (`Base::Find`, `Base::Search`, `Base::Discard`) sobreescriben `execute` por diseño (son infraestructura). Los servicios de negocio SIEMPRE implementan `service_execute`, NUNCA sobreescriben `execute` directamente. Si ves un servicio de negocio que sobreescribe `execute` → es un bug.

### Estrategia de Errores

- **Create/Update services de formularios**: SIN bang (`create`, `update`). Controller usa `if obj.valid?`
- **Todo lo demás**: CON bang (`create!`, `update!`, `save!`, `destroy!`). Fail fast.
- **AASM events**: SÍ usan bang (`publish!`, `complete!`) — es la API de AASM
- **NUNCA** mezclar estrategias: si servicio sin bang → controller con `valid?`, nunca con `rescue`
- **Verificación en controllers**: Usar siempre `if obj.valid?` (NUNCA `persisted?`) para verificar éxito de Create/Update sin bang

### Convenciones de I18n

- Traducciones de modelo: `config/locales/models/{model}.{locale}.yml`
- Traducciones globales: `config/locales/es.yml`, `en.yml` (actions, genders, filters)
- Traducciones de componentes: `config/locales/common/`
- Claves globales existentes: `actions.new`, `actions.edit`, `actions.create`, `actions.update`, `actions.delete`, `actions.search`, `genders.masculine`, `genders.feminine`
- Género gramatical: inferir del nombre en español (Categoría → femenino, Producto → masculino)

### Convenciones de Estilo

- Hash inline con alineación vertical: `{ key: value,\n  key2: value2 }`
- Params inline con primer parámetro en línea de llamada
- Botones: `btn-primary` por defecto, `btn-danger` solo para destructivos
- Turbo IDs: usar `dom_id(object)`, no strings manuales

---

## 2. CONTEXTO PARA CODEX (Lógica y Seguridad)

### Tu enfoque exclusivo

Busca SOLO lo que el Validator y Rubocop NO pueden detectar:

1. **Bugs lógicos**:
   - Edge cases no contemplados (nil, vacío, duplicados, límites)
   - Race conditions o problemas de concurrencia
   - Errores de ordenamiento o precedencia de operaciones
   - Nil-safety: ¿puede un método recibir nil y fallar silenciosamente?
   - Servicios que no retornan el objeto después de operaciones
   - Servicios de negocio que sobreescriben `execute` en vez de `service_execute` (solo los Base services pueden sobreescribir `execute`)

2. **Vulnerabilidades de seguridad**:
   - SQL injection: ¿usa placeholders `?` o string interpolation insegura?
   - Mass assignment: ¿`strong_params` cubre todos los campos sensibles?
   - IDOR: ¿se verifica autorización con Pundit ANTES de acceder al recurso?
   - XSS: ¿se escapa output en vistas? ¿se usa `raw` o `html_safe` innecesariamente?
   - Información expuesta en mensajes de error al usuario
   - Filter key injection en Search services: ¿los filtros que llegan al controller están validados antes de pasarse a `Base::Search`?

3. **Correctitud de estado** (si hay AASM):
   - ¿Las transiciones cubren todos los caminos posibles?
   - ¿Hay estados huérfanos o inalcanzables?
   - ¿Los guards/callbacks pueden fallar silenciosamente?

### NO revises (ya validado por el Validator)

- Patrones de herencia (BaseService, Draper::Decorator)
- Uso de Discard, default_scope
- Bang/no-bang strategy (ya verificada cross-layer)
- Métodos privados en servicios/decorators/componentes
- Cross-layer consistency de campos (migración → servicio → controller → form → show)
- Estilo de código (Rubocop lo cubre)
- I18n completeness (la Claude review pass frontend/I18n lo cubre)

### Formato de respuesta

```
VEREDICTO: APROBADO | RECHAZADO

HALLAZGOS:
1. {archivo}: línea {N} — [{CRITICO|ALTO|MEDIO|BAJO}]
   Problema: {descripción del bug o vulnerabilidad}
   Fix: {código corregido o sugerencia}

Si no hay hallazgos: "APROBADO - Sin bugs lógicos ni vulnerabilidades detectadas"
```

---

## 3. CONTEXTO PARA CLAUDE REVIEW PASS — FRONTEND / I18n (Completitud y UX)

> Esta sección la consume el coordinador (Claude principal) cuando ejecuta la segunda pasada interna sobre vistas y locales. NO se envía a ningún CLI externo.

### Tu enfoque exclusivo

Busca SOLO lo que el Validator y Codex NO cubren:

1. **I18n multiidioma**:
   - Cruza TODAS las claves `I18n.t()` y `human_attribute_name()` usadas en código con los archivos `.yml`
   - ¿Existen las claves en AMBOS idiomas (es.yml y en.yml)?
   - ¿Los mensajes con género gramatical son correctos en español? ("creada" vs "creado")
   - ¿Hay strings hardcoded que deberían usar I18n?
   - ¿Las claves de locale están en el archivo correcto? (modelo → `config/locales/models/`, no en globales)

2. **UX y accesibilidad**:
   - ¿Los formularios muestran errores de validación correctamente? (`errors.any?` + `full_messages`)
   - ¿Los botones de confirmación de eliminación tienen `turbo_confirm`?
   - ¿La navegación entre index → show → edit → back es coherente?
   - ¿Los `turbo_frame_id` coinciden entre controller (`turbo_stream.replace`) y vista (`turbo_frame_tag`)?
   - ¿Los formularios usan `_form.html.erb` compartido entre new y edit?

3. **Consistencia visual**:
   - ¿Se usan los ViewComponents existentes? (`Form::Fields::*`, `Tables::IndexComponent`, `Show::Fields::FieldComponent`)
   - ¿Los botones siguen la convención? (`btn-primary` por defecto, `btn-danger` solo destructivos)
   - ¿Los botones de descarga tienen alineación derecha? (`justify-content-end`)
   - ¿Las filas de tabla son clickables si existe vista show?
   - ¿Las columnas de acción usan `stop-propagation`?

### NO revises (ya validado por otros)

- Lógica de negocio en servicios (Codex lo cubre)
- Patrones Ruby (herencia, naming) (Validator lo cubre)
- Cross-layer de campos migración → servicio → controller (Validator lo cubre)
- Seguridad (SQL injection, IDOR) (Codex lo cubre)
- Estilo de código Ruby (Rubocop lo cubre)

### Formato de respuesta

```
VEREDICTO: APROBADO | RECHAZADO

HALLAZGOS:
1. {archivo}: línea {N} — [{CRITICO|ALTO|MEDIO|BAJO}]
   Problema: {descripción del issue de I18n o UX}
   Fix: {código corregido o sugerencia}

Si no hay hallazgos: "APROBADO - I18n completo y UX correcta"
```

---

## 4. PROTOCOLO DE CORRECCIÓN (ambos reviewers)

| Severidad | Definición | Acción | Re-review AI |
|-----------|-----------|--------|-------------|
| CRÍTICO | Bug que causa error en producción, vulnerabilidad explotable | Corregir inmediatamente | Sí, solo al reviewer que detectó (máx 2) |
| ALTO | I18n faltante en idioma, formulario no muestra errores | Corregir antes de cerrar | No, Validator confirma |
| MEDIO | Mejora de UX, string hardcoded en zona poco visible | Reportar como sugerencia | No, no bloquea |
| BAJO | Cosmético, mejora menor | Nota informativa | No, no bloquea |

---

## 5. CÓMO USAR ESTE DOCUMENTO

### En prompts de skills (rails-orchestration, rails-crud, rails-code-review)

```
El Coordinador DEBE:
1. Leer `.claude/review-context.md`
2. Incluir la sección CONTEXTO COMÚN + la sección del reviewer específico
3. Adjuntar los archivos a revisar con contenido inline
4. Incluir contenido de archivos .yml de locales cuando la pasada sea la Claude review pass (frontend/I18n)
```

### Ejemplo de prompt armado para Codex

```
[CONTENIDO DE SECCIÓN 1: CONTEXTO COMÚN]
[CONTENIDO DE SECCIÓN 2: CONTEXTO PARA CODEX]

Archivos a revisar:
--- app/services/categories/create.rb ---
[contenido del archivo]
--- app/services/categories/update.rb ---
[contenido del archivo]
```

### Ejemplo de contexto preparado para la Claude review pass (frontend/I18n)

```
[CONTENIDO DE SECCIÓN 1: CONTEXTO COMÚN]
[CONTENIDO DE SECCIÓN 3: CONTEXTO PARA CLAUDE REVIEW PASS — FRONTEND / I18n]

Archivos a revisar:
--- app/views/admin/categories/index.html.erb ---
[contenido del archivo]
--- config/locales/models/category.es.yml ---
[contenido del archivo]
--- config/locales/models/category.en.yml ---
[contenido del archivo]
```

---

*Última actualización: sincronizado con CLAUDE.md del proyecto*
