---
name: rails-code-review
description: "Auditoría de código contra CLAUDE.md con detección de violaciones y reporte estructurado. Usar cuando el usuario dice 'revisa el código', 'code review de', 'audita', 'verifica que cumple las reglas' o 'full audit'. No usar para generar código nuevo, corregir bugs, o tomar decisiones arquitectónicas (usar rails-architecture-review)."
compatibility: "Ruby 3.4+, Rails 8, requires RSpec, FactoryBot, Draper, Discard, Pundit"
metadata:
  version: 1.2.0
---

# Rails Code Review

Realiza auditorías exhaustivas de código verificando cumplimiento de `CLAUDE.md`, patrones arquitectónicos y REGLAS CRÍTICAS del template. **Enfoque en prevención, no corrección.**

---

## REGLAS CRÍTICAS DE AUDITORÍA

Esta skill verifica cumplimiento de TODAS las reglas de `CLAUDE.md`. Las violaciones más comunes a detectar:

1. Métodos privados en Servicios/Decorators/Componentes
2. ActiveRecord directo en controladores
3. Scopes personalizados (solo `default_scope -> { kept }`)
4. Bang/no-bang incoherente entre servicio y controller
5. State Machines sin `available_frontend_events`
6. Métodos deprecated o anti-patterns Rails

---

## Proceso de Auditoría

### PASO 1: Identificar Archivos a Revisar

Según el contexto, analizar:

```ruby
# Modo FULL AUDIT (auditar todo el proyecto)
# Activar cuando el usuario pide: "audita todo", "review completo", "full audit"
- Modelos: app/models/**/*.rb
- Servicios: app/services/**/*.rb
- Controladores: app/controllers/**/*.rb
- Decorators: app/decorators/**/*.rb
- Componentes: app/components/**/*.rb
- Vistas: app/views/**/*.erb
- Tests: spec/**/*_spec.rb

# Modo IMPLEMENTACIÓN NUEVA (archivos recién creados)
- Mismos directorios, pero solo archivos nuevos del CRUD/feature

# Modo CAMBIO ESPECÍFICO (archivos modificados)
- Solo archivos modificados (usar git diff)
```

**Modo Full Audit**: Escanea TODO el directorio `app/` contra las reglas de CLAUDE.md. Útil para detectar violaciones acumuladas en código existente que no pasó por el orchestrator. Usar los comandos de verificación automatizada (PASO final) para un barrido rápido antes del análisis detallado.

---

### PASO 2: Checklist de Validación por Tipo de Archivo

#### 2.1 Modelos (`app/models/*.rb`)

**OBLIGATORIO verificar:**

Para ejemplos detallados de código correcto/incorrecto, consulta `references/violation_examples.md` (sección 2.1).

**Checklist:**
- [ ] `include Discard::Model` presente
- [ ] `default_scope -> { kept }` presente
- [ ] NO hay scopes personalizados
- [ ] NO hay métodos con parámetros externos
- [ ] NO hay métodos privados
- [ ] Validaciones correctas y completas
- [ ] Asociaciones correctamente definidas

---

#### 2.2 Servicios (`app/services/**/*.rb`)

**OBLIGATORIO verificar:**

Para ejemplos detallados de código correcto/incorrecto, consulta `references/violation_examples.md` (sección 2.2).

**Checklist:**
- [ ] Hereda de `BaseService` o `Base::Search`
- [ ] Implementa `service_execute`, NUNCA sobreescribe `execute` (solo Base services pueden sobreescribir `execute`)
- [ ] NO usa métodos privados (extraer a otro servicio si es complejo)
- [ ] Create/Update **de formularios** NO usan bang methods (`create`, `update`, no `create!`, `update!`)
- [ ] Servicios internos (Enable, Activate, etc.) SÍ usan bang methods (`update!`, `save!`)
- [ ] Search services usan `.includes()` para N+1 prevention
- [ ] Retorna el objeto después de operaciones
- [ ] Inicialización correcta con parámetros nombrados

---

#### 2.3 Controladores (`app/controllers/**/*.rb`)

**OBLIGATORIO verificar:**

Para ejemplos detallados de código correcto/incorrecto, consulta `references/violation_examples.md` (sección 2.3).

**Checklist:**
- [ ] NO usa ActiveRecord directo (`Model.find`, `Model.where`, `Model.all`)
- [ ] Usa servicios para todas las operaciones
- [ ] Usa `Base::Find` para búsquedas por ID
- [ ] Variables de instancia (`@`) son decorators, NO modelos
- [ ] Usa `authorize` para permisos (Pundit)
- [ ] NO contiene lógica de negocio
- [ ] Usa I18n para mensajes (no hardcoded)
- [ ] Usa `if obj.valid?` para verificar éxito de Create/Update sin bang (NUNCA `persisted?`, NUNCA `rescue RecordInvalid` con servicio sin bang)
- [ ] Usa `dom_id(object)` para turbo_stream IDs (NUNCA strings manuales como `"model_#{id}"`)

---

#### 2.4 Decorators (`app/decorators/**/*.rb`)

**OBLIGATORIO verificar:**

Para ejemplos detallados de código correcto/incorrecto, consulta `references/violation_examples.md` (sección 2.4).

**Checklist:**
- [ ] NO usa métodos privados
- [ ] Tiene `delegate_all` y `delegate :to_key, :to_param, :persisted?, :model_name`
- [ ] TableDecorator tiene `collection_decorator_class` y `table_config`
- [ ] TableDecorator tiene método `table_cells` retornando hash
- [ ] NO contiene lógica de negocio
- [ ] NO llama a ActiveRecord directamente
- [ ] Solo lógica de presentación (formateo, HTML simple)
- [ ] Usa `h.` para helpers
- [ ] Usa I18n para strings

---

#### 2.5 Componentes (`app/components/**/*.rb`)

**OBLIGATORIO verificar:**

Para ejemplos detallados de código correcto/incorrecto, consulta `references/violation_examples.md` (sección 2.5).

**Checklist:**
- [ ] NO usa métodos privados
- [ ] NO infiere decorators (recibe objetos explícitos)
- [ ] NO llama a servicios
- [ ] NO contiene lógica de negocio
- [ ] Solo lógica de presentación mínima
- [ ] Usa componentes existentes (no genera HTML de formularios)

---

#### 2.6 State Machines (Modelos con AASM)

**OBLIGATORIO verificar:**

Para ejemplos detallados de código correcto/incorrecto, consulta `references/violation_examples.md` (sección 2.6).

**Checklist:**
- [ ] Tiene `include AASM`
- [ ] Tiene `has_many :state_changes, as: :state_changeable`
- [ ] Tiene método `available_frontend_events` obligatorio
- [ ] Tiene `include Discard::Model` y `default_scope -> { kept }`

---

#### 2.7 Vistas (`app/views/**/*.erb`)

**OBLIGATORIO verificar:**

Para ejemplos detallados de código correcto/incorrecto, consulta `references/violation_examples.md` (sección 2.7).

**Checklist:**
- [ ] Usa I18n para todos los strings (NO hardcoded)
- [ ] Usa componentes existentes para formularios (Form::Fields::*)
- [ ] Usa `Tables::IndexComponent` para tablas
- [ ] Usa `Show::Fields::FieldComponent` para campos de show
- [ ] NO genera HTML de formularios manualmente
- [ ] NO contiene lógica de negocio
- [ ] Variables `@` son decorators (tienen métodos de presentación)

---

### PASO 3: Detección de Code Smells Específicos

#### 3.1 Patrones Anti-Rails

Para ejemplos detallados de anti-patterns y violaciones de seguridad, consulta `references/violation_examples.md`.

---

#### 3.2 Violaciones de Seguridad

Para ejemplos detallados de anti-patterns y violaciones de seguridad, consulta `references/violation_examples.md`.

---

### PASO 3.5: Validación Cross-Layer (NUEVO)

**OBLIGATORIO para CRUDs y features multi-archivo.**

Esta validación verifica la **consistencia entre capas** - el error más común en implementaciones generadas por múltiples agentes.

#### 3.5.1 Completitud de Campos

Verificar que TODOS los campos fluyen correctamente por todas las capas:

```ruby
# Para cada campo del modelo, verificar presencia en:

# 1. Migración
t.string :name, null: false  # ✅ Campo existe

# 2. Servicio Create - initialize params
def initialize(name:, description:, another_description:)  # ✅ Todos los campos

# 3. Servicio Update - initialize params
def initialize(category:, name:, description:, another_description:)  # ✅ Todos los campos

# 4. Controller - strong_params
params.require(:category).permit(:name, :description, :another_description)  # ✅ Todos

# 5. Controller - llamada al servicio
::Categories::Create.execute(name: category_params[:name],
                             description: category_params[:description],
                             another_description: category_params[:another_description])  # ✅ Todos

# 6. Vista _form - campos del formulario
render Form::Fields::FieldComponent.new(form: f, attribute: :name, ...)
render Form::Fields::FieldComponent.new(form: f, attribute: :description, ...)
render Form::Fields::FieldComponent.new(form: f, attribute: :another_description, ...)  # ✅ Todos

# 7. Vista show - campos mostrados
render Show::Fields::FieldComponent.new(object: @category, attribute: :name, ...)
render Show::Fields::FieldComponent.new(object: @category, attribute: :description, ...)
render Show::Fields::FieldComponent.new(object: @category, attribute: :another_description, ...)  # ✅ Todos
```

**Tabla de verificación:**

| Campo | Migración | Svc Create | Svc Update | Strong Params | Controller Call | Form | Show |
|-------|-----------|-----------|-----------|---------------|----------------|------|------|
| name  | ✅/❌    | ✅/❌    | ✅/❌    | ✅/❌        | ✅/❌          | ✅/❌| ✅/❌|

Si algún campo tiene ❌ → **VIOLACIÓN CRÍTICA**.

#### 3.5.2 Consistencia de Estrategia de Errores

```ruby
# PATRÓN A: Sin bang (para formularios)
# Servicio:
@category.update(name: @name)  # Sin bang
@category  # Retorna objeto
# Controller:
if category.valid?
  redirect_to ...
else
  render :edit
end
# Test:
result = described_class.execute(**params)
expect(result.errors[:name]).to be_present  # Verifica errores en objeto

# PATRÓN B: Con bang (para operaciones internas)
# Servicio:
@user.update!(enabled: true)  # Con bang
# Controller:
begin
  ::Users::Update.execute(...)
  redirect_to ...
rescue ActiveRecord::RecordInvalid => e
  render :edit
end
# Test:
expect { described_class.execute(**params) }.to raise_error(ActiveRecord::RecordInvalid)
```

**NUNCA mezclar patrones**: Si el servicio usa `update` sin bang, el controller DEBE usar `valid?`, y el test DEBE verificar `errors`, NO `raise_error`.

#### 3.5.3 Consistencia de I18n

```ruby
# Verificar que TODAS las claves I18n referenciadas en código existen en los .yml

# Traducciones de modelo van en archivos SEPARADOS: config/locales/models/{model}.{locale}.yml
# Traducciones globales (actions.*, genders.*, filters.*) están en config/locales/es.yml y en.yml

# En código:
I18n.t('activerecord.messages.category.created_successfully')

# Debe existir en config/locales/models/category.es.yml:
# es:
#   activerecord:
#     models:
#       category: 'Categoría'
#     plural_name:
#       category: 'Categorías'
#     messages:
#       category:
#         created_successfully: 'Categoría creada exitosamente.'

# Y en config/locales/models/category.en.yml (mismo patrón en inglés)

# Claves globales del proyecto (NO crear, ya existen):
# actions.new, actions.edit, actions.create, actions.update, actions.delete
# genders.masculine, genders.feminine
```

**Estructura de locales del proyecto:**
- `config/locales/models/{model}.{locale}.yml` → Traducciones por modelo
- `config/locales/es.yml`, `en.yml` → Traducciones globales (actions, genders, pundit)
- `config/locales/common/` → Traducciones de componentes y layout

Si alguna clave referenciada NO existe → **VIOLACIÓN ALTA**.

---

### PASO 4: Generar Reporte de Auditoría

Para el template markdown completo del reporte con todas las secciones (Resumen Ejecutivo, Violaciones Críticas, Warnings, Code Smells, Aspectos Positivos, Cumplimiento por Categoría, Acciones Requeridas, Aprobación), consulta `references/report_template.md`.

---

## PASO 5 (Opcional): Revisión AI Complementaria

Cuando se ejecuta `/rails-code-review` de forma standalone (sin orchestrator), se puede complementar la auditoría con dos revisiones: Codex (CLI externo, lógica/seguridad) y la Claude review pass (interna del modelo, frontend/I18n/UX). Esto es especialmente útil para código con lógica compleja o vistas con I18n multiidioma.

### Cuándo activar

- **Activar Codex** si se detectan servicios con lógica de negocio compleja, AASM, o código que maneja datos sensibles
- **Activar Claude review pass** si se detectan vistas con I18n, formularios complejos, o locales multiidioma
- **No activar** si el código es simple (policies vacías, factories, rutas)

### Prompts (Referencia centralizada)

El contexto de cada review se construye leyendo **`.claude/review-context.md`**:

- **Para Codex**: Leer Sección 1 (Contexto Común) + Sección 2 (Contexto para Codex) + invocar `bin/ai-codex` con los archivos a revisar inline
- **Para la Claude review pass**: Leer Sección 1 (Contexto Común) + Sección 3 (Contexto para Claude review pass) y aplicar los checks inline sobre los archivos a revisar (vistas + locales) con `Read`. No se invoca ningún CLI externo

Ese archivo centralizado contiene las reglas del proyecto, el enfoque exclusivo de cada reviewer, lo que NO deben revisar, y el formato de respuesta esperado.

### Integración en el Reporte

Si se ejecutó revisión AI, añadir al reporte de auditoría:

```markdown
## Revisión AI Complementaria

| Reviewer | Veredicto | Hallazgos |
|----------|-----------|-----------|
| Codex    | ✅ APROBADO | 0 |
| Claude review pass   | ⚠️ 1 ALTO  | Falta traducción en en.yml |

**Protocolo de corrección:**
- CRÍTICO → Corregir + re-review al reviewer (máx 2)
- ALTO → Corregir, sin re-review
- MEDIO/BAJO → Sugerencia, no bloquea
```

---

## Comandos de Verificación Automatizada

Ejecutar `scripts/validate_rules.sh [directorio]` para verificación automatizada de todas las reglas. El script comprueba las seis categorías (ActiveRecord en controllers, métodos privados en servicios, scopes personalizados, Discard ausente, `available_frontend_events` ausente, strings hardcoded) y termina con código no-cero si encuentra violaciones.

---

## Niveles de Severidad

| Nivel | Descripción | Acción |
|-------|-------------|--------|
| 🔴 **CRÍTICA** | Viola REGLA CRÍTICA de CLAUDE.md | Bloquea aprobación |
| 🟡 **ALTA** | Genera bugs o problemas de performance | Requiere corrección |
| 🟡 **MEDIA** | Viola convención del template | Recomendación fuerte |
| 🟢 **BAJA** | Code smell o mejora de calidad | Sugerencia |

---

## Métricas de Éxito

| Métrica | Target |
|---------|--------|
| Violaciones críticas | 0 |
| Warnings de alta prioridad | < 3 |
| Cumplimiento general | ≥ 90% |
| Code smells | < 5 |
| Tiempo de auditoría | < 5 min |

---

## Casos Especiales

### Código Legacy o Migraciones

Si el código revisado es legacy o está en proceso de migración:

1. **Documentar estado actual** en reporte
2. **Proponer plan de migración** paso a paso
3. **NO bloquear** si hay plan de remediación claro
4. **Priorizar** fixes según impacto

### Dependencias Externas

Si el código usa gemas o APIs externas:

1. **Verificar** que sigue patrones del template (Adapter pattern)
2. **Documentar** dependencias en reporte
3. **Sugerir** abstracciones si hay acoplamiento fuerte

---

## Ejemplos

### Ejemplo 1: Code review de servicios

El usuario dice: "Revisa el código de app/services/orders/"

Acciones:
1. Leer todos los archivos en el directorio
2. Verificar herencia de BaseService, ausencia de private, bang coherente
3. Ejecutar `scripts/validate_rules.sh`
4. Generar reporte con severidad por violación

Resultado: Reporte con 0 CRÍTICO, 2 WARNING, 1 INFO

### Ejemplo 2: Full audit post-CRUD

El usuario dice: "Full audit del CRUD de categories"

Acciones:
1. Identificar todos los archivos: model, services, decorators, controller, views, specs
2. Revisar cada capa contra CLAUDE.md
3. Cross-check coherencia entre capas (PASO 3.5)

Resultado: Reporte completo con checklist de cumplimiento

---

## Resolución de Problemas

### Falso positivo: método privado en controller

Causa: Controllers SÍ permiten `private` para strong_params
Solución: Solo reportar private en services/decorators/components, no controllers

### Reporte demasiado extenso

Causa: Demasiados archivos analizados de golpe
Solución: Auditar por módulo (ej: solo services, luego decorators)

### Script de validación no encuentra archivos

Causa: Rutas relativas incorrectas
Solución: Ejecutar desde la raíz del proyecto

### El problema es arquitectónico, no de código
Causa: La review revela un problema de diseño fundamental, no una violación de reglas
Solución: Usar `/rails-architecture-review` para generar un blueprint técnico

---

## Validación automática

```bash
bin/rails-validate code-review path/to/files
bin/rails-validate code-review path/to/files --json  # Resultado parseable
```

Formato de salida esperado (`--json`):
```json
{
  "target": "app/services/module/",
  "passed": 5,
  "failed": 2,
  "checks": [
    {"name": "Directorio app existe", "status": "pass"},
    {"name": "Sin ActiveRecord directo en controllers", "status": "pass"},
    {"name": "Sin métodos privados en servicios", "status": "pass"},
    {"name": "Discard en todos los modelos", "status": "fail"},
    {"name": "Bang methods coherentes", "status": "pass"},
    {"name": "default_scope kept presente", "status": "fail"},
    {"name": "service_execute implementado", "status": "pass"}
  ]
}
```

---

## Notas de Rendimiento

- Tómate el tiempo necesario — lee CADA archivo completamente antes de reportar violaciones
- Calidad sobre velocidad — un CRÍTICO omitido es peor que una revisión lenta
- No saltes los pasos de validación — ejecuta siempre scripts/validate_rules.sh

---

## Referencias

- **CLAUDE.md**: Directrices principales del template
- **docs/components.md**: Guía de componentes ViewComponent
- **docs/state-machine.md**: Implementación de AASM
- **docs/testing.md**: Patrones de testing
