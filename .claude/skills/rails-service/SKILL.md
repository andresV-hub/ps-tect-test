---
name: rails-service
description: "Genera servicios Rails con BaseService, bang methods y transacciones. Usar cuando el usuario dice 'crea un servicio para', 'servicio que haga', 'service object para' o 'añade lógica de negocio para'. No usar para métodos de modelo simples sin parámetros, servicios Search (usar Base::Search directamente), u operaciones Discard (usar Base::Discard)."
compatibility: "Ruby 3.4+, Rails 8, requires RSpec, FactoryBot, Draper, Discard"
metadata:
  version: 2.0.0
---

# Rails Service Generator (delega a bin/rails-generate)

A partir de v2, esta skill construye un manifest YAML y delega la generación al binario `bin/rails-generate`. No genera código directamente.

## Cuándo usar

Usar cuando el usuario dice "crea un servicio para", "servicio que haga", "service object para" o "añade lógica de negocio para". No usar para métodos de modelo simples sin parámetros, servicios Search (usar `Base::Search` directamente), u operaciones Discard (usar `Base::Discard`).

## Procedimiento

### PASO 1: Construir el manifest

Crea `tmp/manifests/<ServiceName>.yml` con el shape definido en `lib/generators/support/manifest_schema.rb` SCHEMAS[:"service"]. Para una referencia de campos válidos, mira `tmp/manifests/examples/service.yml`.

Campos clave (obligatorios y más usados):

- `class_name` (requerido): nombre de la clase en CamelCase, ej: `Activate`
- `namespace`: módulo Ruby, ej: `Categories` → `Categories::Activate`
- `type` (enum): `create`, `update`, `search`, `action`, `orchestration`, `aasm_transition`, `batch`, `discard`. Default: `action`
- `error_strategy`: `bang` o `no_bang`. Si se omite, el binario infiere: `create`/`update` → `no_bang`; el resto → `bang`. Se emite warning con el valor inferido.
- `transaction`: `true` / `false` (default `false`). Activar para servicios que orquestan múltiples escrituras.
- `params`: array de `{ name, kw_default, doc }` — parámetros del `initialize`
- `target_model`: modelo sobre el que opera el servicio (para leer validaciones y asociaciones)
- `tests.generate`: `true` (default) — genera `spec/services/...`
- `tests.cases`: array de `{ name, kind }` (kind: `positive` o `negative`)

Regla de coherencia bang/no-bang (ya enforced por el binario):
- `create`/`update` → `no_bang` → controller usa `if obj.valid?`
- todo lo demás → `bang` → fail fast; dentro de `transaction` usar SIEMPRE bang

### PASO 2: Invocar el binario

```bash
bin/rails-generate service --manifest=tmp/manifests/<ServiceName>.yml [--force]
```

O en forma corta:

```bash
bin/rails-generate service Categories::Activate --type=action --target-model=Category
```

### PASO 3: Reportar

El binario devuelve un envelope JSON con `--json` (campos: `subcommand`, `model`, `created`, `modified`, `skipped`, `warnings`, `errors`, `failed`, `exit_code`). Reporta al usuario:
- Archivos creados/modificados.
- Warnings emitidas (strategy inferida: `error_strategy_inferred`).
- Si `failed: true`, qué falló y la sugerencia del binario.

## Reglas que el binario ya enforce

- Todas las reglas de CLAUDE.md aplicables (herencia de `BaseService`, implementar `service_execute` nunca `execute`, NO métodos privados, bang methods apropiados).
- Coherencia bang/no-bang entre servicio, controller y test: el binario infiere `error_strategy` y emite warning.
- Conflict detection: 2ª ejecución sin `--force` → exit 1.

## Pre-requisitos

Primera invocación del binario en un repo nuevo: ejecuta `bin/rails-generate bootstrap` para instalar los markers en `config/routes.rb` y `db/migrate/*_add_business_logic.rb`.

## Validación automática

```bash
bin/rails-validate service app/services/<namespace>/<name>.rb --json | jq '.failed'
```

## Plantillas

El binario renderiza ERB desde `lib/templates/service/`. Cualquier ajuste al output del generador se aplica allí.
