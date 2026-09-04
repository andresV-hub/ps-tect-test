---
name: rails-test-coverage
description: "Analiza criticidad del código y genera tests RSpec de alto valor con FactoryBot, y tests E2E de Playwright para funcionalidad de frontend. Usar cuando el usuario dice 'crea tests para', 'añade cobertura a', 'tests de', 'spec de' o 'necesito tests para'. No usar para ejecutar tests existentes (usar rails-test-runner), modificar tests existentes, o generar tests triviales de getters/setters."
compatibility: "Ruby 3.4+, Rails 8, requires RSpec, FactoryBot, Playwright (e2e/)"
metadata:
  version: 2.1.0
---

# Rails Test Coverage Generator (delega a bin/rails-generate)

A partir de v2, esta skill construye un manifest YAML y delega la generación al binario `bin/rails-generate`. No genera código directamente.

**La cobertura es una métrica de vanidad; la confianza es la métrica real.**

La cobertura tiene dos capas complementarias:
- **Backend (RSpec)**: valida lógica de negocio, validaciones, permisos y transiciones de estado
- **Frontend (Playwright E2E)**: valida que el flujo completo funciona en el navegador, incluyendo Turbo, modales de state machine y navegación de tablas

Ambas capas son obligatorias para módulos con interfaz de usuario. Ver `docs/playwright-e2e.md` para la referencia completa del setup E2E.

## Cuándo usar

Usar cuando el usuario dice "crea tests para", "añade cobertura a", "tests de", "spec de" o "necesito tests para". No usar para ejecutar tests existentes (usar `rails-test-runner`), modificar tests existentes, o generar tests triviales de getters/setters.

## Cómo elegir targets para el manifest

Antes de construir el manifest, evalúa el código usando esta matriz de criticidad:

**Nivel Crítico (target OBLIGATORIO):**
- Movimiento de dinero o recursos financieros
- Cambios de estado (AASM transitions)
- Autorización y permisos (Pundit policies)
- Cálculos de negocio complejos
- Servicios de orquestación (múltiples escrituras / transacciones)
- Callbacks de modelo que modifican datos

**Nivel Medio (target RECOMENDADO):**
- Validaciones estándar de modelo
- Servicios de búsqueda con filtros
- Requests de controladores
- Formateo de datos no trivial
- Métodos con lógica condicional

**Nivel Bajo (IGNORAR — no incluir en el manifest):**
- Getters/setters simples (`attr_reader`, `delegate`)
- Configuración visual pura (colores, clases CSS)
- Delegaciones directas sin lógica
- Métodos de presentación triviales
- TableDecorators con solo configuración
- ShowDecorators con solo delegaciones

Orden de prioridad por impacto de negocio:
1. Políticas de autorización sin tests — Riesgo: acceso no autorizado
2. Servicios de orquestación sin tests — Riesgo: inconsistencias en transacciones
3. State machine transitions sin tests — Riesgo: estados inválidos en workflow
4. Modelos con cálculos de negocio sin tests — Riesgo: errores en lógica crítica
5. Servicios Create/Update con validaciones complejas — Riesgo: datos inconsistentes
6. Request specs faltantes — Riesgo: solo integración HTTP, menor impacto
7. Decorators sin tests — Riesgo: solo presentación, no afecta lógica

## Procedimiento

### PASO 1: Construir el manifest

Crea `tmp/manifests/test-coverage-<scope>.yml` con el shape definido en `lib/generators/support/manifest_schema.rb` SCHEMAS[:"test-coverage"]. Para una referencia de campos válidos, mira `tmp/manifests/examples/test-coverage.yml`.

Campos clave (obligatorios y más usados):

- `targets` (requerido): array de targets. Cada target puede ser un string (ruta del archivo) o un hash con:
  - `kind`: `policy`, `service`, `model_state_machine`, `factory` (determina qué tipo de spec se genera)
  - `file`: ruta al archivo de producción, ej: `app/policies/article_policy.rb`
  - Para `kind: policy`: `roles` (array de roles a testear), `actions` (array de acciones Pundit)
  - Para `kind: service`: `error_strategy` (`bang` o `no_bang`), `transaction` (`true`/`false`), `rollback_stubs` (clases a stubear)
  - Para `kind: model_state_machine`: `states` (array), `transitions` (array de `{ event, from, to, valid }`)
  - Para `kind: factory`: `model`, `fields` (array), `traits` (array)
- `simplecov`: `false` (default) — poner `true` para añadir/actualizar configuración en `spec/spec_helper.rb`

### PASO 2: Invocar el binario

```bash
bin/rails-generate test-coverage --manifest=tmp/manifests/test-coverage-<scope>.yml [--force]
```

O en forma corta (targets individuales):

```bash
bin/rails-generate test-coverage app/policies/article_policy.rb app/services/articles/create.rb
```

### PASO 3: Reportar

El binario devuelve un envelope JSON con `--json` (campos: `subcommand`, `model`, `created`, `modified`, `skipped`, `warnings`, `errors`, `failed`, `exit_code`). Reporta al usuario:
- Archivos creados.
- Archivos omitidos porque ya existía un spec (warning: `spec_already_exists` — D4: los tests son sagrados).
- Si `failed: true`, qué falló y la sugerencia del binario.

Tras la generación, ejecutar los tests creados:
```bash
bundle exec rspec <spec_files_created> --format documentation
```

## Reglas que el binario ya enforce

- Todas las reglas de CLAUDE.md aplicables (NO modificar tests existentes — D4 sacred-tests).
- **D4 — `--force` NO sobreescribe specs existentes**: esta es la única excepción al comportamiento de `--force`. Si un spec ya existe, siempre se omite y se emite warning `spec_already_exists`.
- Cada spec generado sigue las reglas de test documentadas en CLAUDE.md: `subject { build(:model) }` para `validate_uniqueness_of`, `expect(response).to be_redirect` (no `raise_error`) para Pundit, `user.confirm` antes de `sign_in` en request specs.
- Componentes agnósticos (`Tables::*`, `StateMachine::*`) se testean con doubles, nunca con modelos de negocio.
- Conflict detection para archivos no-spec: 2ª ejecución sin `--force` → exit 1.

## Pre-requisitos

Primera invocación del binario en un repo nuevo: ejecuta `bin/rails-generate bootstrap` para instalar los markers en `config/routes.rb` y `db/migrate/*_add_business_logic.rb`.

## Plantillas

El binario renderiza ERB desde `lib/templates/test_coverage/`. Cualquier ajuste al output del generador se aplica allí.

---

## Tests E2E con Playwright (capa frontend)

Para módulos con interfaz de usuario, además de los specs RSpec se deben generar tests E2E. Estos validan el flujo completo en el navegador: navegación, formularios, Turbo Streams y modales de state machine.

**Pre-requisito**: el entorno E2E debe estar configurado (`e2e/` existe, `bin/e2e-setup` ejecutado). Ver `docs/playwright-e2e.md`.

### Cuándo generar tests E2E

| Funcionalidad | Tests E2E requeridos |
|---|---|
| CRUD con vistas (index, show, new, edit) | Sí |
| State machine con modal de transición | Sí — flujo de transición en navegador |
| Módulo solo de servicios/backend sin vistas | No |
| Componentes internos (decorators, policies) | No |

### Qué crear para cada módulo nuevo

**1. Page Object** — `e2e/pages/admin/<Modelo>Page.ts`:

```typescript
import { type Page, expect } from '@playwright/test';

export class <Modelo>Page {
  constructor(private page: Page) {}

  async goto(): Promise<void> {
    await this.page.goto('/admin/<modelos>');
    await this.page.waitForLoadState('networkidle');
  }

  async expectInTable(name: string): Promise<void> {
    await expect(this.page.locator('turbo-frame#<modelos>_list')).toContainText(name);
  }

  async clickRow(name: string): Promise<void> {
    await this.page.locator('table tbody tr').filter({ hasText: name }).click();
  }

  // Solo si tiene state machine:
  async triggerStateEvent(eventLabel: string): Promise<void> {
    await this.page.locator('button[data-bs-toggle="modal"]')
      .filter({ hasText: eventLabel }).click();
    const modal = this.page.locator('.modal.show');
    await expect(modal).toBeVisible();
    await modal.locator('#state_change_observations').fill('E2E test');
    await modal.locator('input[type="submit"][value="Confirmar"]').click();
    await this.page.waitForLoadState('networkidle');
  }

  async expectState(state: string): Promise<void> {
    await expect(this.page.locator('.badge.fs-6')).toContainText(state, { ignoreCase: true });
  }
}
```

**2. Spec** — `e2e/tests/admin/<modelo>.spec.ts`:

```typescript
import { test, expect } from '@playwright/test';
import { <Modelo>Page } from '../../pages/admin/<Modelo>Page';

test.describe('Admin > <Modelos>', () => {
  test('lista es accesible', async ({ page }) => {
    const modelPage = new <Modelo>Page(page);
    await modelPage.goto();
    await expect(page).toHaveURL(/\/admin\/<modelos>/);
    await expect(page.locator('turbo-frame#<modelos>_list')).toBeVisible();
  });

  test('navega al formulario de creación', async ({ page }) => {
    await page.goto('/admin/<modelos>/new');
    await expect(page.locator('form[action*="/admin/<modelos>"]')).toBeVisible();
  });

  // Solo si tiene state machine — datos prefijados E2E* en db/seeds/98_e2e_data.rb:
  test.describe('State machine', () => {
    test('puede transicionar desde estado inicial', async ({ page }) => {
      const modelPage = new <Modelo>Page(page);
      await modelPage.goto();
      await modelPage.clickRow('E2E <Modelo> Initial');
      await modelPage.expectState('<estado_inicial>');
      await modelPage.triggerStateEvent('<Evento>');
      await modelPage.expectState('<estado_destino>');
    });
  });
});
```

**3. Seeds E2E** — añadir en `db/seeds/98_e2e_data.rb` un registro por estado que los tests necesiten:

```ruby
# Limpiar
<Modelo>.with_discarded.where("name LIKE ?", "E2E%").each(&:really_destroy!)

# Crear datos con estado conocido
registro_initial = <Modelo>::Create.execute(name: "E2E <Modelo> Initial", user: admin_user, ...)

# Si tiene state machine — un registro por estado a testear:
registro_published = <Modelo>::Create.execute(name: "E2E <Modelo> Published", user: admin_user, ...)
<Modelo>::Publish.execute(record: registro_published, user: admin_user)
```

### Ejecutar los tests E2E

```bash
# Setup inicial (solo una vez o cuando cambien seeds)
bin/e2e-setup

# Correr la suite
cd e2e && npm test

# Solo los tests del módulo nuevo
cd e2e && npm test -- tests/admin/<modelo>.spec.ts

# Con UI interactiva (útil para depurar)
cd e2e && npm run test:ui
```
