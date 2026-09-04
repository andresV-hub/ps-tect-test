---
name: rails-crud
description: "Genera CRUD completo con N+1 prevention, Discard, I18n y validación cross-layer. Usar cuando el usuario dice 'crea un CRUD de', 'genera el modelo X con campos', 'CRUD de X' o 'crea la gestión de'. No usar para bug fixes, añadir campos a modelos existentes, o cuando el orchestrator gestiona planificación multi-nivel."
compatibility: "Ruby 3.4+, Rails 8, requires RSpec, FactoryBot, Draper, Discard"
metadata:
  version: 2.0.0
---

# Rails CRUD Generator (delega a bin/rails-generate)

A partir de v2, esta skill construye un manifest YAML y delega la generación al binario `bin/rails-generate`. No genera código directamente.

## Cuándo usar

Usar cuando el usuario dice "crea un CRUD de", "genera el modelo X con campos", "CRUD de X" o "crea la gestión de". No usar para bug fixes, añadir campos a modelos existentes, o cuando el orchestrator gestiona planificación multi-nivel.

## Procedimiento

### PASO 1: Construir el manifest

Crea `tmp/manifests/<model>.yml` con el shape definido en `lib/generators/support/manifest_schema.rb` SCHEMAS[:"crud"]. Para una referencia de campos válidos, mira `tmp/manifests/examples/crud.yml`.

Campos clave (obligatorios y más usados):

- `model` (requerido): nombre del modelo en singular CamelCase, ej: `Category`
- `fields`: array de `{ name, type, required, in_form, in_table, in_search }`. Tipos válidos: `string text integer decimal boolean date datetime time belongs_to has_many references`
- `gender`: `masculine` o `feminine` (afecta mensajes flash en español; se emite warning si se usa el default)
- `error_strategy`: `no_bang` (formularios) o `bang`; default `no_bang`
- `associations`: hash con claves `has_many` y/o `has_many_through` (arrays). Si un `has_many_through` declara `join_model:`, el binario genera además la sincronización N-M completa (ver nota abajo).
- `search.includes`: asociaciones para `.includes()` en el Search service (prevención N+1)
- `locales.es` / `locales.en`: traducciones del modelo, atributos y mensajes flash
- `table_config.columns`: columnas de la tabla index con `key`, `sortable`, `sort_column`
- `sidebar.skip`: `false` (default) — **el sidebar se genera siempre**; el binario auto-instala los markers en `application.html.erb` si faltan (no requiere `bootstrap --sidebar` previo) y degrada a warning (sin fallar) si el layout no tiene la `<nav class="app-side__nav">` esperada. Pon `true` para omitir la entrada.
- `routes.skip`: `false` (default) — añade `resources :[plural]` dentro de `namespace :admin`

### PASO 2: Invocar el binario

```bash
bin/rails-generate crud --manifest=tmp/manifests/<model>.yml [--force]
```

O en forma corta (campos básicos):

```bash
bin/rails-generate crud ModelName name:string:required description:text --gender=feminine
```

### PASO 3: Reportar

El binario devuelve un envelope JSON con `--json` (campos: `subcommand`, `model`, `created`, `modified`, `skipped`, `warnings`, `errors`, `failed`, `exit_code`). Reporta al usuario:
- Archivos creados/modificados.
- Warnings emitidas (defaults aplicados: `gender_defaulted`, `error_strategy_defaulted`, `locale_missing`).
- Si `failed: true`, qué falló y la sugerencia del binario.

Tras la generación, ejecutar las reviews AI obligatorias:
1. **Codex** (lógica y seguridad): `bin/ai-codex -r security-reviewer -f app/services/<plural>/create.rb,app/controllers/admin/<plural>_controller.rb "Check edge cases, nil-safety, injection, mass assignment"`
2. **Claude review pass** (interna): leer Sección 1 + Sección 3 de `.claude/review-context.md` y aplicar checks sobre vistas y locales.

## Reglas que el binario ya enforce

- Todas las reglas de CLAUDE.md aplicables (Discard + `default_scope -> { kept }`, bang methods donde corresponde, NO métodos privados en servicios/decorators, NO scopes personalizados).
- N+1 prevention: `.includes()` en Search service según `search.includes` del manifest.
- Params explícitos en controllers: extrae campo a campo, nunca `**[singular]_params`.
- Conflict detection: 2ª ejecución sin `--force` → exit 1 con lista de archivos en conflicto.
- Migración centralizada: añade `create_table` a `db/migrate/*_add_business_logic.rb` (nunca crea migración nueva). Los `create_table`/`add_index` se emiten con `if_not_exists: true`, así que re-correr el `up` es idempotente.
- Search de `belongs_to` auto-generado: por cada campo `belongs_to`, si no existe `app/services/<target_table>/search.rb`, el binario genera un `<Namespace>::Search < Base::Search` mínimo para que el select del form funcione. Si ya existe, no lo pisa.
- Relación N-M auto-cableada: si un `has_many_through` declara `join_model:`, el binario genera el modelo intermedio + factory + tabla **y además**: param `<assoc>_ids` con `Model.transaction` en `Create`/`Update`, multi-select Select2 en `_form`, y `available_<assoc>` + `<assoc>_names` en el ShowDecorator. NO hay que enriquecerlo a mano.

## Aplicar la migración

`add_business_logic.rb` suele estar ya migrada, así que `db:migrate` es no-op y `db:migrate:redo` revienta (su `down` dropea tablas que aún no existían). Como los `create_table` usan `if_not_exists`, re-correr el `up` es seguro. Comando (lo imprime también el binario):

```bash
bin/rails runner "ActiveRecord::Base.connection.execute(%{DELETE FROM schema_migrations WHERE version='<VERSION>'})" && bin/rails db:migrate
```

El `DELETE` libera la versión (no-op si la BD es fresca); luego `db:migrate` re-ejecuta el `up` saltando lo existente y creando solo lo nuevo.

## Pre-requisitos

Primera invocación del binario en un repo nuevo: ejecuta `bin/rails-generate bootstrap` para instalar los markers en `config/routes.rb` y `db/migrate/*_add_business_logic.rb`.

## Validación automática

```bash
bin/rails-validate all ModelName --json | jq '.failed'
```

## Plantillas

El binario renderiza ERB desde `lib/templates/crud/`. Cualquier ajuste al output del generador se aplica allí.
