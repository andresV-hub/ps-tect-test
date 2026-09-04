---
name: rails-table-decorator
description: "Genera TableDecorator con table_config, N+1 prevention e I18n. Usar cuando el usuario dice 'tabla de', 'listado de', 'index de', 'table decorator para' o 'añade columnas a la tabla de'. No usar para ShowDecorators, form helpers o vistas no tabulares."
compatibility: "Ruby 3.4+, Rails 8, requires Draper, Common::PaginatingIndexCollectionDecorator"
metadata:
  version: 2.0.0
---

# Rails Table Decorator Generator (delega a bin/rails-generate)

A partir de v2, esta skill construye un manifest YAML y delega la generación al binario `bin/rails-generate`. No genera código directamente.

## Cuándo usar

Usar cuando el usuario dice "tabla de", "listado de", "index de", "table decorator para" o "añade columnas a la tabla de". No usar para ShowDecorators, form helpers o vistas no tabulares.

## Procedimiento

### PASO 1: Construir el manifest

Crea `tmp/manifests/<Model>TableDecorator.yml` con el shape definido en `lib/generators/support/manifest_schema.rb` SCHEMAS[:"table-decorator"]. Para una referencia de campos válidos, mira `tmp/manifests/examples/table-decorator.yml`.

Campos clave (obligatorios y más usados):

- `model` (requerido): nombre del modelo en singular CamelCase, ej: `Article`
- `columns` (requerido): array de objetos de columna. Cada columna requiere `key`. Campos opcionales por columna:
  - `sortable`: `true` / `false`
  - `sort_column`: nombre calificado para ORDER BY, ej: `"users.name"` (necesario para columnas de asociación)
  - `label_key`: clave I18n del label; por defecto usa `Model.human_attribute_name(:key)`
  - `source`: expresión Ruby para el valor, ej: `"object.user&.name"` (con safe navigation para asociaciones)
  - `fallback_key`: clave I18n para nil, ej: `"common.not_available"`
  - `render`: `badge` (para estados) o `actions_buttons`
  - La columna `:actions` siempre debe tener `cell_class: stop-propagation` (el binario lo inyecta automáticamente)
- `search_includes`: array de asociaciones para añadir `.includes()` al Search service (prevención N+1), ej: `[user, company]`
- `row_clickable`: `true` (default) — hace las filas clickables hacia la ruta show
- `turbo_frame_id`: id del turbo_frame que envuelve la tabla, ej: `articles_list`
- `actions`: `{ show: true, edit: true, destroy: true }` — botones de acción con guards de policy
- `i18n.generate_locale_skeleton`: `false` (default) — poner `true` para crear/actualizar `config/locales/models/<model>.es.yml`

### PASO 2: Invocar el binario

```bash
bin/rails-generate table-decorator --manifest=tmp/manifests/<Model>TableDecorator.yml [--force]
```

O en forma corta (usa columnas inferidas del schema):

```bash
bin/rails-generate table-decorator Article
```

### PASO 3: Reportar

El binario devuelve un envelope JSON con `--json` (campos: `subcommand`, `model`, `created`, `modified`, `skipped`, `warnings`, `errors`, `failed`, `exit_code`). Reporta al usuario:
- Archivos creados/modificados.
- Si se modificó el Search service para añadir `.includes()` (warning: `search_includes_patched`).
- Warnings emitidas (columnas sin `sort_column` cuando `sortable: true`).
- Si `failed: true`, qué falló y la sugerencia del binario.

## Reglas que el binario ya enforce

- Todas las reglas de CLAUDE.md aplicables (NO métodos privados, `collection_decorator_class` obligatorio, `table_config` + `table_cells` obligatorios, policy guards en cada botón de acción).
- N+1 prevention: si `search_includes` no está vacío, el binario parchea el Search service añadiendo `.includes()`.
- Stop propagation: la columna `:actions` siempre recibe `cell_class: "stop-propagation"`.
- Conflict detection: 2ª ejecución sin `--force` → exit 1.

## Pre-requisitos

Primera invocación del binario en un repo nuevo: ejecuta `bin/rails-generate bootstrap` para instalar los markers en `config/routes.rb` y `db/migrate/*_add_business_logic.rb`.

## Validación automática

```bash
bin/rails-validate crud ModelName --json | jq '.checks[] | select(.name == "TableDecorator")'
```

## Plantillas

El binario renderiza ERB desde `lib/templates/table_decorator/`. Cualquier ajuste al output del generador se aplica allí.
