---
name: rails-state-machine
description: "Implementa AASM state machines con available_frontend_events, componentes UI y transiciones validadas. Usar cuando el usuario dice 'añade estados a', 'máquina de estados', 'state machine para', 'estados de' o 'workflow de'. No usar para flags booleanos simples, enums sin transiciones, o campos de estado sin lógica de negocio."
compatibility: "Ruby 3.4+, Rails 8, requires RSpec, FactoryBot, Draper, Discard, AASM"
metadata:
  version: 2.0.0
---

# Rails State Machine Generator (delega a bin/rails-generate)

A partir de v2, esta skill construye un manifest YAML y delega la generación al binario `bin/rails-generate`. No genera código directamente.

## Cuándo usar

Usar cuando el usuario dice "añade estados a", "máquina de estados", "state machine para", "estados de" o "workflow de". No usar para flags booleanos simples, enums sin transiciones, o campos de estado sin lógica de negocio.

## Procedimiento

### PASO 1: Construir el manifest

Crea `tmp/manifests/<Model>.yml` con el shape definido en `lib/generators/support/manifest_schema.rb` SCHEMAS[:"state-machine"]. Para una referencia de campos válidos, mira `tmp/manifests/examples/state-machine.yml`.

Campos clave (obligatorios y más usados):

- `model` (requerido): nombre del modelo en singular CamelCase, ej: `Article`
- `events` (requerido): array de objetos `{ name, from (array), to, button_class, badge_after_class, requires_inputs }`. Cada evento genera su servicio de transición.
- `mode`: `new` (AASM no existe en el modelo) o `extend` (añadir eventos a AASM existente). Default: `new`
- `states`: array de nombres de estado, ej: `[draft, pending_review, published]`
- `initial_state`: estado inicial para AASM
- `column`: columna de BD donde se persiste el estado. Default: `state`
- `frontend_events`: subset de eventos visibles en UI (los que `available_frontend_events` retorna)
- `policy`: hash `{ event_name: [roles] }` para permisos de transición en Pundit
- `locales.es` / `locales.en`: deben incluir los 3 bloques obligatorios: `states.*`, `events.*`, `event_changes.*`
- `migration.generate_column`: `true` si la columna `state` no existe todavía en la BD

Los tres bloques I18n son obligatorios (el binario los valida y emite warning si faltan):
- `states.*` → Nombre del estado (badges): "Borrador", "Aprobado"
- `events.*` → Verbo infinitivo (botones): "Aprobar", "Rechazar"
- `event_changes.*` → Participio pasado (timeline): "Aprobado", "Rechazado"

### PASO 2: Invocar el binario

```bash
bin/rails-generate state-machine --manifest=tmp/manifests/<Model>.yml [--force]
```

O en forma corta:

```bash
bin/rails-generate state-machine Article --states=draft,pending_review,published --events=submit,publish --initial-state=draft
```

### PASO 3: Reportar

El binario devuelve un envelope JSON con `--json` (campos: `subcommand`, `model`, `created`, `modified`, `skipped`, `warnings`, `errors`, `failed`, `exit_code`). Reporta al usuario:
- Archivos creados/modificados.
- Warnings emitidas (`locale_missing`, `locale_bucket_missing` si falta algún bloque I18n).
- Si `failed: true`, qué falló y la sugerencia del binario.

## Reglas que el binario ya enforce

- Todas las reglas de CLAUDE.md aplicables (Discard + `default_scope`, `available_frontend_events` obligatorio, `has_many :state_changes, as: :state_changeable`).
- Modo `extend`: solo agrega nuevos estados/eventos, nunca reescribe el bloque `aasm` existente.
- Cada evento genera un servicio de transición con `Model.transaction` y bang methods.
- El ShowDecorator implementa `state_changes_decorator` que retorna subclase de `StateMachine::StateChangesDecorator`.
- Vista show usa `StateMachine::StateChangesCardComponent`, nunca HTML manual.
- **No pisa lo del crud (mode `new`)**: si ya existen el ShowDecorator y la vista show (generados por `rails-crud`), el binario los **parchea** en vez de recrearlos — inyecta `state_changes_decorator` + la subclase en el decorator (preservando métodos como `available_<assoc>`) e inserta la `<section>` del `StateChangesCardComponent` en la show (preservando los campos). Por eso, **tras un crud no hace falta `--force`** (no hay conflicto; solo se crean los servicios de transición). Si SM corre standalone (sin crud), genera decorator y show desde plantilla.
- CLI corto de eventos: `--events=name` infiere la transición secuencial desde `--states`; usa `--events=name:from:to` (con `+` para varios orígenes, ej. `reopen:archived+active:draft`) para transiciones explícitas.
- Conflict detection: una re-ejecución que intente recrear ficheros ya existentes sin `--force` → exit 1.

## Pre-requisitos

Primera invocación del binario en un repo nuevo: ejecuta `bin/rails-generate bootstrap` para instalar los markers en `config/routes.rb` y `db/migrate/*_add_business_logic.rb`.

## Validación automática

```bash
bin/rails-validate state-machine app/models/<model>.rb --json | jq '.failed'
```

## Plantillas

El binario renderiza ERB desde `lib/templates/state_machine/`. Cualquier ajuste al output del generador se aplica allí.
