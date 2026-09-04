---
name: rails-orchestration
description: "Protocolo de delegación atómica con paralelización y field manifest para features complejas. Usar cuando el usuario dice 'implementa el módulo de', 'feature de X con Y', 'sistema de', o cuando el orchestrator necesita planificación multi-nivel. No usar para CRUDs simples (usar rails-crud directamente), cambios de un solo archivo, o bug fixes."
compatibility: "Ruby 3.4+, Rails 8, requires bin/ai-codex, RSpec"
metadata:
  version: 1.2.0
---

# Rails Orchestration Protocol

Orquesta equipos de developers para implementar features complejas mediante **delegación en cascada** y **paralelización inteligente**.

---

## PRINCIPIOS FUNDAMENTALES

### 1. Atomicidad de Tareas
- **Máximo 5 archivos por tarea**
- Una tarea = Un bloque lógico independiente
- Ejemplos de tareas atómicas:
  - "Crear modelo Category con migración" (2 archivos)
  - "Crear servicios Categories (Create, Update, Search)" (3 archivos)
  - "Crear decorators Categories" (3 archivos)
  - "Crear vistas index y show" (2 archivos)

### 2. Paralelización
- **Hasta 5 developers en paralelo**
- Solo paralelizar tareas **independientes** (sin dependencias entre archivos)
- Consulta `references/level_examples.md` para ejemplos detallados de paralelización

### 3. Validación Incremental
- **Validator entra después de cada bloque**
- No esperar al final para validar todo
- Correcciones tempranas evitan cascada de errores

### 4. Field Manifest (Contrato de Campos)
- Cada plan DEBE incluir un `field_manifest` JSON con TODOS los campos
- El manifest es el **contrato vinculante** entre niveles
- Todos los developers reciben el manifest VERBATIM en sus instrucciones
- Si un campo está en el manifest, DEBE aparecer en: migración, modelo, servicios, strong_params, vistas y tests
- Ejemplo de field_manifest:
  ```json
  {
    "entity": "Category",
    "fields": [
      {"name": "name", "type": "string", "required": true, "searchable": true, "in_form": true, "in_table": true, "in_show": true},
      {"name": "description", "type": "text", "required": false, "searchable": false, "in_form": true, "in_table": false, "in_show": true}
    ],
    "associations": [],
    "error_strategy": "no_bang"
  }
  ```

Consulta `references/plan_template.md` para el template JSON completo del plan.

### 5. Revisión AI Incremental y Especializada
- La revisión AI se ejecuta **incrementalmente** en niveles clave, NO solo al final
- Cada reviewer tiene enfoque **exclusivo** (sin solapamiento con el Validator):
  - **Codex** (vía `bin/ai-codex`): Lógica de negocio, bugs, edge cases, vulnerabilidades de seguridad
  - **Claude review pass** (interna del coordinador): I18n multiidioma, UX/accesibilidad, consistencia visual
- El Validator es el **único** responsable de reglas CLAUDE.md (Discard, bang, private, cross-layer)
- Review final consolidada solo verifica integración entre niveles
- Protocolo de corrección con severidades: CRÍTICO (bloquea), ALTO (corregir sin re-review), MEDIO/BAJO (sugerencia)

---

## PROTOCOLO DE EJECUCIÓN

### FASE 1: Análisis de Contexto

**Herramientas**: `Read`, `Glob`

**Acciones**:
1. Leer `db/schema.rb` para entender modelos existentes
2. Usar `Glob` para buscar patrones: `app/models/*.rb`, `app/services/**/*.rb`
3. Verificar rutas existentes: `config/routes.rb`
4. Identificar dependencias entre componentes

**Salida**: Mapa de dependencias y estado actual del proyecto

---

### FASE 2: Evaluación de Complejidad

**Criterios para escalar al Oracle**:
- Requerimiento viola patrones de CLAUDE.md
- Lógica de negocio extremadamente compleja (>200 líneas)
- Decisión arquitectónica que afecta múltiples módulos
- Integración con APIs externas sin documentación
- Performance crítica (optimizaciones complejas)

**Si NO escala al Oracle**: Proceder a FASE 3

---

### FASE 3: Atomización de Tareas

**Proceso**:
1. Dividir el requerimiento en bloques lógicos
2. Cada bloque debe tener **máximo 5 archivos**
3. Identificar dependencias entre bloques
4. Agrupar bloques en **niveles de dependencia**

**Aplicabilidad**: la atomización por niveles aplica a **lógica custom** que enriquece lo generado por el binario (transacciones complejas, side-effects, AASM con callbacks reales, integraciones externas). Para todo lo template-driven (CRUD, AASM básico, services Create/Update/Search, decorators, vistas estándar, locales placeholder, specs scaffolded) el binario lo genera en un solo paso y NO se atomiza.

**REGLA ABSOLUTA cuando aplique: Máximo 4 niveles.** Controllers, vistas, sidebar y locales van TODOS en NIVEL 3 ejecutando en paralelo. NO crear niveles separados para cada uno.

**Ventajas de esta estructura (legado del flujo pre-binario, sigue vigente para enriquecimiento custom):**
- Bug en servicio se detecta en Nivel 2 (no en Nivel 4)
- Controller y vistas ejecutan en paralelo (ahorra un nivel completo)
- Solo 3 pasos de validación antes de la verificación final
- Las vistas se construyen sobre controller ya testeado
- Nivel 4 es solo verificación, no creación

Consulta `references/level_examples.md` para ejemplos detallados de descomposición por niveles.

---

### FASE 4: Delegación con Plan Completo

**⚠️ IMPORTANTE**: El Orchestrator se llama UNA SOLA VEZ y retorna el plan COMPLETO de todos los niveles.

**Flujo real**:

```
COORDINADOR (Claude Principal):
  1. Pide plan COMPLETO al Orchestrator: Task(orchestrator) → "Planifica TODO el feature"

  2. Orchestrator retorna plan COMPLETO con TODOS los niveles:
     - field_manifest (contrato único)
     - Array de niveles con tareas atomizadas
     - Instrucciones estructuradas (JSON, no prosa)
     - Tests integrados por nivel
     - Reviews AI asignadas por nivel
     - Rollback por nivel

  3. Coordinador ejecuta nivel por nivel según el plan:

     POR CADA NIVEL:
       a. Lanza Task(developer) según tareas del nivel
          Si paralelizable → múltiples developers en UN SOLO mensaje
          Si secuencial → un developer

       b. Lanza Task(validator) para auditar el bloque
          Validator usa Bash para verificaciones automatizadas

       c. Si Validator rechaza:
          → Lanza Task(developer) con correcciones (máx 3 iteraciones)
          → Si 3 iteraciones fallan → ESCALAR (oracle o opus)

       d. Si Validator aprueba Y el nivel tiene testing:
          → Lanza Task(tester) para ejecutar tests del nivel
          → Si tests fallan → Tester corrige y re-ejecuta

       e. Si el nivel tiene review AI asignada:
          → Ejecuta la review (Codex vía `bin/ai-codex` o Claude review pass interna según plan)
          → Verifica hallazgos CRÍTICOS antes de actuar (filtro falsos positivos)

       f. Continúa al siguiente nivel

  4. Nivel final: verificación global (rubocop, suite completa, rutas)
```

**Estructura de comunicación** (flujo binario):

```
Usuario
  ↓
Coordinador (Claude Principal)
  ├→ Task(orchestrator) → Retorna plan COMPLETO (UNA sola vez)
  │
  ├→ FASE Generación: bin/rails-generate <sub> --manifest=... --json
  │     (1 comando produce 21 archivos para CRUD básico, +2 si has_many_through con join_model)
  │     → Task(validator) sobre lo generado
  │
  ├→ FASE Enriquecimiento (sólo si el feature necesita lógica no expresable en templates):
  │     Task(developer) por cada pieza custom — transacciones complejas, side-effects,
  │     AASM con callbacks reales, integraciones externas, modificaciones cruzadas
  │     → Task(validator) sobre lo enriquecido
  │     → Task(tester) si el bloque toca services/models
  │     → Review Codex sobre los services enriquecidos (bin/ai-codex)
  │
  └→ FASE Verificación Final:
        bin/rails runner "...DELETE FROM schema_migrations WHERE version='<VER>'..." && bin/rails db:migrate
        Rubocop + rspec + routes check
        Claude review pass final sobre vistas/locales modificados
```

**Delegación template-driven (binario):**

Para CRUDs, servicios, state machines, table decorators y specs, el orchestrator construye el manifest YAML correspondiente y ejecuta `bin/rails-generate <subcommand> --manifest=tmp/manifests/<x>.yml`. El developer Sonnet ya NO se invoca para tareas template-driven; solo se delega al developer para lógica de negocio custom no expresable en plantillas (transacciones N-M complejas, side-effects, integraciones externas).

Pre-requisito: si es la primera ejecución en el repo, ejecutar `bin/rails-generate bootstrap` antes de cualquier otro subcomando.

```bash
# Ejemplos de delegación al binario desde el orchestrator:
bin/rails-generate crud   --manifest=tmp/manifests/Category.yml   --json
bin/rails-generate service --manifest=tmp/manifests/Activate.yml  --json
bin/rails-generate state-machine --manifest=tmp/manifests/Article.yml --json
bin/rails-generate table-decorator --manifest=tmp/manifests/ArticleTable.yml --json
bin/rails-generate test-coverage --manifest=tmp/manifests/coverage-articles.yml --json
```

El envelope JSON (`created`, `modified`, `skipped`, `warnings`, `failed`) se pasa al Validator para verificación cruzada.

**Plantilla de Task para Developer (lógica custom no template-driven):**

```markdown
Tarea: [Descripción breve - ej: "Implementar lógica N-M de Categories::Sync"]

**Contexto:**
- Modelo: [Nombre del modelo]
- Dependencias: [Archivos que deben existir antes]

**Archivos a crear (MAX 5):**
1. [ruta/archivo1.rb]
2. [ruta/archivo2.rb]
...

**Instrucciones:**
1. Esta tarea NO está cubierta por bin/rails-generate (lógica custom)
2. Sigue EXACTAMENTE los patrones de CLAUDE.md
3. [Regla específica crítica si aplica]

**Validaciones:**
- [Criterio 1 de validación]
- [Criterio 2 de validación]

**Al finalizar:**
- Reporta qué archivos creaste
- Ejecuta comando de verificación: [comando bash si aplica]
- Reporta cualquier error o bloqueo
```

**Ejemplo de delegación paralela** (3 developers para lógica custom NO cubierta por el binario):

```python
# EN UN SOLO MENSAJE, usar 3 Task calls.
# Pre-condición: el binario ya generó los scaffolds vía
#   bin/rails-generate crud --manifest=tmp/manifests/order.yml
# Estos developers ENRIQUECEN lo generado con lógica que el binario no infiere.

Task 1 (developer):
  Tarea: "Implementar Orders::ExecuteTransfer con transacción atómica
          (decrementar StockItem origen, incrementar StockItem destino, registrar StateChange)"
  Archivos: app/services/orders/execute_transfer.rb + spec
  [contenido de plantilla]

Task 2 (developer):
  Tarea: "Añadir validate :origin_and_destination_must_differ y método
          apply_stock_movements (callback after del AASM) en StockTransfer"
  Archivos: app/models/stock_transfer.rb (modificar)
  [contenido de plantilla]

Task 3 (developer):
  Tarea: "Implementar StockItems::AdjustQuantity (action service, levanta
          si quantity resultante < 0) + spec con rollback case"
  Archivos: app/services/stock_items/adjust_quantity.rb + spec
  [contenido de plantilla]
```

---

### FASE 5: Integración y Verificación Final

**Después del último NIVEL**:

1. Aplicar la migración. `bin/rails-generate crud` modifica `add_business_logic.rb`, que ya está `up`. **NUNCA uses `db:migrate:redo`** (su `down` revienta al dropear tablas que aún no existían). Como los `create_table`/`add_index` se emiten con `if_not_exists: true`, re-correr el `up` es seguro. Usa el comando que imprime el binario como NEXT STEP:
   ```
   bin/rails runner "ActiveRecord::Base.connection.execute(%{DELETE FROM schema_migrations WHERE version='<VERSION>'})" && bin/rails db:migrate
   ```
   El `DELETE` libera la versión (no-op en BD fresca); `db:migrate` re-ejecuta el `up` saltando tablas existentes. Ver `lib/templates/_markers/business_logic_marker.md`.
2. Ejecutar Rubocop sobre TODOS los archivos generados: `bundle exec rubocop [archivos] -A`
3. Ejecutar todos los tests: `bundle exec rspec`
4. Verificar rutas: `rails routes | grep [recurso]`
5. Validación final con Validator

**Reporte final**:
```markdown
## Resumen de Implementación

**Archivos creados**: X
**Archivos modificados**: Y
**Tests**: TODOS PASANDO / Z FALLANDO
**Rutas agregadas**: [listar rutas]
**Migraciones ejecutadas**: [timestamp_migration_name]

**Validaciones cumplidas**:
- Sin ActiveRecord directo en controladores
- Discard implementado en modelo
- Servicios con bang methods apropiados
- ViewComponents usados correctamente
- I18n completo

**Próximos pasos** (si aplica):
[Tareas pendientes o mejoras sugeridas]
```

---

### FASE 6: Reviews AI (CLI Codex + Claude review pass interna)

**OBLIGATORIO**: La revisión AI se ejecuta **incrementalmente** en niveles clave, no como una única revisión masiva al final. La review de backend se ejecuta vía `bin/ai-codex`. La review de frontend/I18n la ejecuta el Coordinador como una **Claude review pass interna** leyendo los archivos y aplicando los checks de la Sección 3 de `.claude/review-context.md` (sin CLI externo).

#### Principio: Separación de Responsabilidades

| Verificación | Responsable | Justificación |
|---|---|---|
| Reglas CLAUDE.md (Discard, private, bang, scopes) | **Solo Validator** | Determinista, no necesita IA externa |
| Cross-layer consistency (campos, error strategy) | **Solo Validator** | Mecánico: leer archivos y comparar |
| Bugs lógicos, edge cases, nil-safety | **bin/ai-codex** | Razonamiento sobre correctitud |
| Seguridad (OWASP, injection, mass assignment) | **bin/ai-codex** | Análisis de vulnerabilidades reales |
| I18n completeness multiidioma | **Claude review pass** | El Coordinador cruza .yml vs código aplicando Sección 3 de `review-context.md` |
| UX/accesibilidad de vistas | **Claude review pass** | Análisis de templates contra los checks de UX/consistencia visual |
| Estilo y naming conventions | **Rubocop** | Ya automatizado |

#### Comandos de Review

**Codex (backend, lógica de servicios):**
```bash
bin/ai-codex -r code-reviewer \
  -f app/services/categories/create.rb,app/services/categories/update.rb,app/services/categories/search.rb \
  "Review these services for: bang/no-bang coherence, nil-safety, edge cases, CLAUDE.md compliance"
```

**Claude review pass (frontend, I18n, UX):**

No es un comando CLI. El Coordinador la ejecuta inline:

1. Lee Sección 1 (Contexto Común) + Sección 3 (Claude review pass frontend/I18n) de `.claude/review-context.md`.
2. Lee con `Read` los archivos del nivel (vistas `.erb`, locales `.yml`, decorators).
3. Aplica los checks de I18n multiidioma, UX, accesibilidad y consistencia visual sobre el contenido.
4. Emite un veredicto con el mismo formato (APROBADO/RECHAZADO + hallazgos por severidad) que las reviews de Codex.

**Revisión cruzada Codex → análisis interno:**
```bash
bin/ai-codex -r architect -f app/services/categories/ "Analyze architecture" --json > /tmp/codex_analysis.json
```
El Coordinador relee `/tmp/codex_analysis.json` y aplica una pasada crítica interna sobre el análisis (sin enviarlo a otro CLI).

#### Plan de Reviews por Fase

```
FASE Generación (bin/rails-generate produce todos los scaffolds):
  → Validator (envelope JSON del binario + bin/rails-validate crud <Model>)
  → Review AI: NO sobre lo generado puro (templates ya están validados por Fase 8 specs)
    Excepción: si el manifest declara `validates:` extendidos o `join_model:` con campos
    extra, sí se justifica una review Codex sobre el modelo intermedio enriquecido.

FASE Enriquecimiento (sólo si hay lógica custom no template-driven):
  → Validator sobre los archivos enriquecidos/nuevos
  → Tester si la lógica enriquecida toca services/models con criticidad
  → Review Codex OBLIGATORIA (bin/ai-codex): lógica de negocio custom, edge cases,
    transacciones, rollback, nil-safety, side-effects, integraciones externas

FASE Verificación Final:
  → aplicar migración (DELETE schema_migrations + db:migrate, idempotente con if_not_exists) + Rubocop + suite completa + routes check
  → Claude review pass OBLIGATORIA (interna, Sección 3 de `.claude/review-context.md`)
    sobre vistas/locales MODIFICADOS manualmente respecto a lo generado por el binario
    (cuando el feature requiere ajustes visuales o I18n más allá de lo template-driven)
  → Review Codex final consolidada sobre el feature completo si NIVEL Enriquecimiento
    aplicó muchos cambios (>5 archivos custom)
```

**Criterio para activar review AI en un nivel:**
- Si el Validator sugiere `"review_ai_sugerida": "codex"` o `"claude_pass"` → Activar
- Si el nivel contiene lógica de negocio (servicios con cálculos, AASM) → `bin/ai-codex`
- Si el nivel contiene vistas con I18n o formularios complejos → Claude review pass interna
- **NUNCA saltar reviews por "simplicidad"** — los errores más costosos ocurren en código que parece simple

#### Prompt Templates (Referencia centralizada)

**IMPORTANTE**: El contexto de las reviews se construye leyendo `.claude/review-context.md`, que contiene:
- Sección 1 (CONTEXTO COMÚN): stack, arquitectura, servicios base, estrategia de errores, I18n, estilo
- Sección 2 (CONTEXTO PARA CODEX): enfoque en bugs lógicos y seguridad + formato de respuesta
- Sección 3 (CONTEXTO PARA CLAUDE REVIEW PASS — FRONTEND/I18n): enfoque en I18n multiidioma y UX + formato de respuesta

**Flujo para armar el contexto:**

```
1. Coordinador lee: .claude/review-context.md
2. Para bin/ai-codex: usar Sección 1 + Sección 2 como prompt base, pasar archivos con -f
3. Para la Claude review pass: el Coordinador lee Sección 1 + Sección 3 como guía y aplica los checks inline sobre los archivos .rb/.erb/.yml con `Read`
```

**¿Por qué centralizado?**
- Si CLAUDE.md cambia, se actualiza UN solo archivo (review-context.md)
- Codex y la Claude review pass siempre operan con el contexto completo y actualizado del proyecto

#### Protocolo de Corrección por Severidad

```
┌─────────────────────────────────────────────────────────────────┐
│ SEVERIDAD   │ ACCIÓN                    │ RE-REVIEW AI          │
├─────────────┼───────────────────────────┼───────────────────────┤
│ CRÍTICO     │ Corregir inmediatamente   │ SÍ - Solo al reviewer │
│ (bug,       │ antes de continuar        │ que lo detectó        │
│ vulnerab.)  │                           │ Máximo 2 re-reviews   │
├─────────────┼───────────────────────────┼───────────────────────┤
│ ALTO        │ Corregir antes de cerrar  │ NO - Validator        │
│ (I18n       │                           │ confirma corrección   │
│ faltante)   │                           │                       │
├─────────────┼───────────────────────────┼───────────────────────┤
│ MEDIO       │ Reportar como sugerencia  │ NO                    │
│ (mejora UX) │ al usuario                │ No bloquea            │
├─────────────┼───────────────────────────┼───────────────────────┤
│ BAJO        │ Reportar como nota        │ NO                    │
│ (cosmético) │ informativa               │ No bloquea            │
└─────────────┴───────────────────────────┴───────────────────────┘
```

#### Reporte Final Consolidado

```
┌─────────────────────────────────────────────────────────────────┐
│ REPORTE FINAL DE REVISIÓN AI                                    │
├─────────────────────────────────────────────────────────────────┤
│ Reviews ejecutadas:                                             │
│   Nivel 2 → Codex: ✅ APROBADO                                 │
│   Nivel 4 → Claude review pass: ⚠️ 1 hallazgo ALTO (corregido)            │
│   Nivel 4 → Codex: ✅ APROBADO | Claude review pass: ✅ APROBADO          │
├─────────────────────────────────────────────────────────────────┤
│ Hallazgos totales: 1 ALTO (corregido), 1 MEDIO (sugerencia)   │
│ Re-reviews: 0                                                   │
├─────────────────────────────────────────────────────────────────┤
│ VEREDICTO: ✅ COMPLETADO                                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## INTEGRACIÓN DEL ORACLE

### ¿Cuándo escalar al Oracle?

El Orchestrator debe retornar `"escalar_a_oracle": true` cuando detecta:

1. **Violaciones de patrones**: Requerimiento contradice CLAUDE.md
2. **Complejidad arquitectónica**:
   - Modelos con >10 asociaciones
   - Transacciones distribuidas
   - Concurrencia compleja
3. **Performance crítica**:
   - Queries complejos con múltiples joins
   - Optimizaciones de índices no triviales
   - Procesamiento de grandes volúmenes
4. **Integraciones complejas**:
   - APIs externas sin documentación
   - WebSockets/tiempo real
   - Message queues y workers
5. **Decisiones que afectan múltiples módulos**

### Proceso de escalamiento

```
1. Orchestrator detecta complejidad → Retorna plan con "escalar_a_oracle": true

2. Coordinador lanza Task(oracle) con la consulta específica

3. Oracle analiza y retorna Blueprint con:
   - Diagnóstico de causa raíz
   - Patrón arquitectónico propuesto (pseudocódigo)
   - Constraints para implementación
   - Criterios de aprobación
   - Consideraciones de seguridad

4. Coordinador relanza Task(orchestrator) con el Blueprint del Oracle

5. Orchestrator atomiza el Blueprint en tareas para developers
```

Consulta `references/plan_template.md` para el template JSON completo del plan.

---

## INTEGRACIÓN DEL TESTER

### Tests Integrados por Nivel (No al Final)

**Principio**: Cada nivel que crea código testeable incluye sus propios tests como tareas del developer. El Tester solo ejecuta y corrige.

| Nivel | Tests incluidos | Tester ejecuta |
|---|---|---|
| 1 (modelo) | Factory only | No (sin lógica que testear) |
| 2 (servicios) | model_spec + service_specs + policy_spec | `rspec spec/models/ spec/services/ spec/policies/` |
| 3 (controller+vistas+locales) | request_spec + Page Object E2E + spec E2E + seeds E2E | `rspec spec/requests/` |
| 4 (verificación) | Ninguno nuevo | `rspec` (suite completa) + `cd e2e && npm test` (si el módulo tiene vistas) |

**Nivel 3 — generación de tests E2E:** cuando el developer crea controller + vistas, también debe crear:
- `e2e/pages/admin/<Modelo>Page.ts` (Page Object)
- `e2e/tests/admin/<modelo>.spec.ts` (spec con tests de navegación + state machine si aplica)
- Entradas en `db/seeds/98_e2e_data.rb` con registros `E2E*` en estados relevantes

**Nivel 4 — ejecución E2E:** el Tester corre `cd e2e && npm test` después de `bundle exec rspec`. Si fallan tests E2E, diagnosticar por selector/seed/vista antes de reportar el fallo.

**Ventaja**: Un bug en un servicio se detecta en Nivel 2, antes de construir el controller encima. No espera a Nivel 4.

### Proceso de testing

```
1. Developer crea código + tests specs

2. Validator audita el código (sintaxis, patrones)

3. Coordinador lanza Task(tester) con:
   - Comando de tests a ejecutar
   - Criterio de éxito

4. Tester ejecuta: bundle exec rspec [archivos]

5. Si tests PASAN → Continuar

6. Si tests FALLAN:
   a. Tester analiza con rails-test-runner
   b. Tester identifica causa raíz
   c. Tester corrige CÓDIGO DE PRODUCCIÓN (NO tests)
   d. Tester re-ejecuta tests
   e. Ciclo hasta que pasen

7. Tester reporta resultado final
```

Consulta `references/level_examples.md` para ejemplos detallados de descomposición por niveles.

**IMPORTANTE**: El Tester NO modifica tests existentes. Si un test falla:
- ✅ Analiza el código de producción
- ✅ Corrige el código de producción
- ❌ NO modifica el test (a menos que sea explícitamente solicitado)

### Reglas Obligatorias para Generación de Tests

Los prompts a developers que crean tests DEBEN incluir estas reglas para evitar errores recurrentes:

1. **shoulda-matchers uniqueness**: SIEMPRE añadir `subject { build(:model) }` antes de tests que usen `validate_uniqueness_of`. Sin un subject válido, el matcher falla con NOT NULL constraint
2. **Pundit authorization tests**: ApplicationController tiene `rescue_from Pundit::NotAuthorizedError` que redirige. Los tests de autorización DEBEN usar `expect(response).to be_redirect`, NUNCA `expect { ... }.to raise_error(Pundit::NotAuthorizedError)`
3. **Devise en request specs**: Los usuarios non-admin DEBEN llamar `user.confirm` antes de `sign_in` para que Devise los autentique correctamente
4. **Update service con params opcionales**: Si el servicio Update usa `param: nil` como default para preservar valores actuales, el test de "name nil" debe verificar que preserva el valor actual, NO que genera error
5. **Rubocop sobre YAML**: NUNCA pasar archivos .yml a Rubocop (los parsea como Ruby y reporta falsos errores de sintaxis). Solo pasar archivos .rb

---

## MANEJO DE ERRORES

### Developer reporta "Tarea demasiado grande"

**Respuesta del Coordinador**:
1. Relanza Task(orchestrator): "Subdivide la tarea X en subtareas más pequeñas"
2. Orchestrator retorna plan con tareas de máximo 3 archivos
3. Coordinador ejecuta nuevas tareas

### Validator rechaza código

**Respuesta del Coordinador**:
1. Lee feedback del Validator
2. Lanza Task(developer) con instrucciones de corrección específicas
3. Developer corrige
4. Relanza Task(validator) para re-auditar

### Tester reporta tests fallidos

**Respuesta del Coordinador**:
1. Tester analiza automáticamente con rails-test-runner
2. Tester corrige código de producción
3. Tester re-ejecuta tests
4. **REVALIDACIÓN OBLIGATORIA**: Después de que el Tester corrija código, relanzar Validator sobre los archivos modificados por el Tester
5. Si persisten fallos después de 3 iteraciones → Ver "Escalación por agotamiento de iteraciones"

### Escalación por agotamiento de iteraciones (NUEVO)

Si cualquier agente (developer, tester, validator) no resuelve un problema en 3 iteraciones:

**NUNCA seguir iterando** — 3 fallos consecutivos indican que el enfoque es incorrecto.

| Tipo de error | Escalar a | Acción |
|---|---|---|
| Error de lógica/diseño | **Oracle** | Pedir blueprint alternativo |
| Error de implementación | **Developer model=opus** | Más capacidad de razonamiento |
| Error de patrón del template | **Coordinador** | Revisar si la skill o CLAUDE.md tienen inconsistencias |
| Error de dependencia/entorno | **Usuario** | Reportar bloqueo y pedir asistencia |

**Formato de escalación:**
```json
{
  "escalacion_requerida": true,
  "iteraciones_fallidas": 3,
  "agente_original": "developer",
  "tipo_error": "lógica|implementación|patrón|dependencia",
  "destino": "oracle|opus|coordinador|usuario",
  "razon": "Descripción del problema persistente",
  "intentos_previos": ["intento 1...", "intento 2...", "intento 3..."]
}
```

### Rollback entre niveles

Si un nivel superior revela un error en un nivel inferior:

1. **Identificar** qué archivo del nivel inferior necesita cambios
2. **Lanzar** Task(developer) con instrucción de corrección específica + referencia al error del nivel superior
3. **Re-validar** solo el archivo corregido (no todo el nivel inferior)
4. **Re-ejecutar** tests afectados de ambos niveles
5. **Continuar** con el nivel superior

**El plan del Orchestrator debe incluir `"rollback"` por nivel** indicando qué archivos de niveles anteriores podrían verse afectados.

### Developer bloqueado por dependencia

**Respuesta del Coordinador**:
1. Identifica qué dependencia falta
2. Relanza Task(orchestrator): "Planifica resolución de dependencia X"
3. Ejecuta plan de dependencia primero
4. Retoma tarea original

### Oracle retorna Blueprint complejo

**Respuesta del Coordinador**:
1. Lanza Task(orchestrator) con Blueprint del Oracle
2. Orchestrator atomiza Blueprint en niveles
3. Coordinador ejecuta niveles normalmente

---

## CRITERIOS DE ÉXITO

✅ **Todas las tareas completadas**
✅ **Validator aprueba todos los bloques**
✅ **Rubocop pasa sin errores** (`bundle exec rubocop [archivos] -A`)
✅ **Tests RSpec en verde** (`bundle exec rspec`)
✅ **Tests E2E en verde** (`cd e2e && npm test`) — solo si el módulo tiene vistas
✅ **Migraciones ejecutadas correctamente**
✅ **Sin violaciones de REGLAS CRÍTICAS**

---

## EJEMPLO COMPLETO: CRUD Category con Flujo Híbrido

### Ejecución paso a paso (Coordinador ejecuta — flujo binario)

```
1. Coordinador → Task(orchestrator): "Planifica COMPLETO CRUD Category"

2. Orchestrator retorna plan COMPLETO: manifest YAML del binario + lista de
   piezas custom (si las hay) + reviews AI asignadas (UNA SOLA LLAMADA)

┌─────────────────────────────────────────────────────────┐
│ FASE GENERACIÓN: bin/rails-generate (Atómica)          │
└─────────────────────────────────────────────────────────┘

3. Coordinador escribe el manifest YAML en tmp/manifests/category.yml
   con todos los locales es/en, table_columns, search.includes, sidebar.

4. Coordinador → ejecuta:
   bin/rails-generate crud --manifest=tmp/manifests/category.yml --json > /tmp/gen.json

5. Coordinador lee /tmp/gen.json:
   - 21 archivos creados (modelo, factory, services, decorators, controller,
     policy, vistas, locales, specs) + 2 más si has_many_through con join_model.
   - 2 archivos modificados: config/routes.rb, db/migrate/*_add_business_logic.rb.
   - "failed": false.

6. Coordinador → aplica la migración: `bin/rails runner "...DELETE FROM schema_migrations WHERE version='<VER>'..." && bin/rails db:migrate`
   (el sidebar lo auto-instala el propio crud; no hace falta `bootstrap --sidebar`)

7. Coordinador → Task(validator): "Audita lo generado por el binario"
   El validator corre bin/rails-validate crud Category y bin/rails-validate all Category.

8. Validator → ✅ APROBADO

┌─────────────────────────────────────────────────────────┐
│ FASE ENRIQUECIMIENTO (sólo si hay lógica no template)  │
└─────────────────────────────────────────────────────────┘

9. Coordinador → EN UN SOLO MENSAJE (N developers paralelos para lógica custom):
   Task(dev-1): "Implementar transacción atómica en Categories::Sync (N-M)"
   Task(dev-2): "Añadir validate :sku_format_check y callback after_create"
   Task(dev-3): "Crear Categories::Archive (action service con side-effect a Audit)"

   Si la feature es un CRUD puro sin extras, este nivel se omite por completo.

10. Coordinador → Task(validator) + Task(tester) sobre los archivos enriquecidos

11. Coordinador → Review Codex OBLIGATORIA si N >= 1 (bin/ai-codex -r code-reviewer)
    sobre los services custom: edge cases, transacciones, rollback, nil-safety
    bin/ai-codex → ✅ APROBADO

┌─────────────────────────────────────────────────────────┐
│ FASE VERIFICACIÓN FINAL                                │
└─────────────────────────────────────────────────────────┘

12. Rubocop sobre archivos enriquecidos (no sobre los generados — ya cumplen
    reglas vía templates) + suite completa + routes check + sidebar check

13. Claude review pass OBLIGATORIA sólo sobre vistas/locales MODIFICADAS
    manualmente respecto al output del binario (I18n, UX, accesibilidad)

14. Reporte de cierre al usuario con sugerencias no auto-aceptadas y los
    warnings emitidos por el envelope JSON del binario

    ┌─────────────────────────────────────────────────────┐
    │ REPORTE FINAL                                       │
    │                                                     │
    │ Agent calls totales: ~14                            │
    │   1 orchestrator + 7 developers + 3 validators      │
    │   + 2 testers + 4 reviews AI                        │
    │                                                     │
    │ Reviews AI (TODAS ejecutadas):                      │
    │   Nivel 2 → bin/ai-codex: ✅ APROBADO              │
    │   Nivel 3 → Claude review pass: ⚠️ 1 ALTO (corregido) │
    │   Nivel 4 → bin/ai-codex + Claude review pass: ✅       │
    │                                                     │
    │ Tests: ✅ 19 examples, 0 failures                   │
    │ Rubocop: ✅ 0 offenses                              │
    │ Sidebar: ✅ Entrada añadida                         │
    │                                                     │
    │ VEREDICTO: ✅ CRUD COMPLETADO                       │
    └─────────────────────────────────────────────────────┘
```

---

### Ejemplo con Escalamiento al Oracle

```
┌─────────────────────────────────────────────────────────┐
│ CASO: Sistema de Notificaciones en Tiempo Real         │
└─────────────────────────────────────────────────────────┘

1. Coordinador → Task(orchestrator): "Planifica sistema notificaciones tiempo real"

2. Orchestrator analiza → Detecta complejidad extrema

3. Orchestrator retorna escalar_a_oracle: true con razón y consulta para Oracle

4. Coordinador → Task(oracle, model=opus): [consulta detallada]

5. Oracle analiza profundamente y retorna Blueprint:
   - Stack: ActionCable + Redis
   - Arquitectura de canales
   - Esquema BD para notificaciones
   - Workers para procesamiento
   - Tests de integración
   - Consideraciones de seguridad

6. Coordinador → Task(orchestrator): "Atomiza Blueprint del Oracle"

7. Orchestrator retorna plan atomizado en 8 niveles

8. Coordinador ejecuta niveles normalmente con developers/validator/tester
```

---

### Métricas de Performance

**Métricas (CRUD Category)**:

**Archivos generados**: ~23 archivos
**Niveles ejecutados**: 4 (3 de creación + 1 de verificación)
**Agent calls totales**: ~16 (vs ~28 flujo anterior = ~43% reducción)
**Orchestrator calls**: 1 (vs 5 anterior)
**Testing**: Integrado por nivel (bugs detectados en su nivel, no al final)
**Reviews AI**: 2 (Codex en Nivel 2, Claude review pass en Nivel 3)

**Ventajas del flujo optimizado**:
- ✅ Orchestrator llamado UNA vez (plan completo, sin inconsistencias entre niveles)
- ✅ Developer usa Sonnet (menos alucinaciones que Haiku)
- ✅ Tests integrados por nivel (bugs detectados temprano)
- ✅ Reviews AI en el momento óptimo (no al final cuando es tarde)
- ✅ Validator con Bash (verificación automatizada, no solo lectura)
- ✅ Escalación clara después de 3 iteraciones (no loops infinitos)
- ✅ Rollback entre niveles (no hay que rehacer todo)
- ✅ ~43% menos agent calls (menos contexto consumido)

---

## MODO DIRECTO (Tareas simples)

Para tareas bien definidas que una skill ya cubre completamente, el flujo completo orchestrator→developer→validator es **innecesario**. En estos casos, usar el modo directo:

**Cuando usar modo directo:**
- CRUD completo de un modelo simple → developer con skill `rails-crud`
- Un servicio individual → developer con skill `rails-service`
- Un TableDecorator → developer con skill `rails-table-decorator`
- Una state machine → developer con skill `rails-state-machine`

**Cuando usar flujo completo:**
- Feature de 10+ archivos con dependencias entre capas
- Lógica de negocio compleja que requiere decisiones arquitectónicas
- Múltiples modelos interrelacionados
- Integración con sistemas externos

El modo directo permite que un developer (Sonnet) ejecute la skill directamente sin pasar por orchestrator/validator, reduciendo el overhead del 80% de las tareas cotidianas.

---

## NOTAS IMPORTANTES

1. **NUNCA lanzar más de 5 developers en paralelo** (saturación del sistema)
2. **SIEMPRE validar después de cada bloque**, no al final
3. **Si un developer falla**, no continuar al siguiente nivel hasta resolver
4. **Priorizar corrección sobre velocidad**: Mejor 3 bloques bien hechos que 10 con errores
5. **REVALIDAR después del Tester**: Si el Tester modifica código de producción, el Validator DEBE re-auditar los archivos modificados antes de continuar

### Reglas de UI que TODO developer DEBE recibir en sus instrucciones

**Filtros de index (OBLIGATORIO):**
- PROHIBIDO usar Bootstrap grid (`row g-3` + `col-md-*`) para filtros
- SIEMPRE usar `.filters-row` dentro de `.index-filters-simple` o `.index-filters-advanced`
- `index-filters-simple`: `.filters-row` con query + botón
- `index-filters-advanced`: `.card > .card-body > .filters-row` con todos los inputs inline
- Ver CLAUDE.md sección "Filtros de Index" para templates exactos

**State Machine en show views (OBLIGATORIO):**
- NUNCA crear HTML manual para historial de estados ni botones de transición
- SIEMPRE usar `StateMachine::StateChangesCardComponent` con `state_changes_decorator`
- El ShowDecorator DEBE tener método `state_changes_decorator` que retorne subclase de `StateMachine::StateChangesDecorator`
- La subclase personaliza `state_badge_class`, `event_button_class`, y opcionalmente `event_path`
- Ver CLAUDE.md sección "State Machines (AASM)" y `docs/state-machine.md` para templates

**I18n con State Machine (OBLIGATORIO — 3 bloques):**
- `states.*` → Nombre del estado (badges): "Borrador", "Aprobado"
- `events.*` → Verbo infinitivo (botones): "Aprobar", "Rechazar"
- `event_changes.*` → Participio pasado (timeline): "Aprobado", "Rechazado"
- Los 3 bloques son OBLIGATORIOS. Olvidar `event_changes` rompe el historial del componente

---

## Ejemplos

### Ejemplo 1: CRUD simple orquestado

El usuario dice: "Implementa el módulo de categorías con name y description"

Acciones:
1. Generar plan completo con 4 niveles y field_manifest
2. Nivel 1: Migración + Modelo + Factory (secuencial)
3. Nivel 2: Servicios + Decorators + Policy + Tests unitarios (paralelo interno)
4. Nivel 3: Controller + Vistas + Sidebar + I18n (todo en paralelo)
5. Nivel 4: Rubocop + Suite completa + Reviews finales bin/ai-codex + Claude review pass

Resultado: CRUD completo en ~14-16 agent calls

### Ejemplo 2: Feature compleja con state machine

El usuario dice: "Sistema de pedidos con estados pending/confirmed/shipped/delivered"

Acciones:
1. Plan con 4 niveles (BD+SM model, Servicios+SM events, Controller+Vistas+SM components, Verificación)
2. Oracle consultado para decidir guards en transiciones
3. Reviews bin/ai-codex para lógica de estados en Nivel 2, Claude review pass para UI de componentes en Nivel 3

Resultado: Módulo completo con state machine integrada

---

## Resolución de Problemas

### Developer no sigue el field_manifest

Causa: Instrucciones al developer no incluyen el manifest verbatim.
Solución: SIEMPRE pasar field_manifest COMPLETO en las instrucciones del Task, no solo el nombre de los campos.

### Tests fallan después de Nivel 2

Causa: Servicios y modelo no están coherentes.
Solución: El tester analiza y el coordinator corrige ANTES de avanzar al Nivel 3. NUNCA continuar con tests en rojo.

### Review AI no disponible (bin/ai-codex falla)

Causa: CLI wrapper no instalado o API key missing.
Solución: Ejecutar `bin/ai-codex --selftest` (hace un ping real al backend, no como `--help` que siempre sale 0). Si falla, imprime la causa real (modelo no soportado, sin auth, `codex` ausente…); escalar al usuario con ese mensaje antes de continuar. La Claude review pass no tiene dependencia externa; siempre debe ejecutarse.

### Orchestrator genera demasiados niveles

Causa: Feature es más simple de lo estimado.
Solución: Para CRUDs simples sin lógica especial, usar rails-crud directamente. La regla absoluta es máximo 4 niveles.

### Developer reporta tarea con más de 5 archivos

Causa: Atomización insuficiente en el plan del Orchestrator.
Solución: Relanzar Task(orchestrator) pidiendo subdivisión de esa tarea específica en subtareas de máximo 3 archivos.

### La tarea es un CRUD simple sin lógica especial
Causa: El orchestrator es excesivo para un CRUD de un modelo con campos básicos
Solución: Usar `/rails-crud` directamente — es más rápido y produce el mismo resultado para CRUDs simples

---

## Validación automática por nivel

```bash
bin/rails-validate level archivo1.rb archivo2.rb  # Post-cada-nivel
bin/rails-validate crud ModelName --json           # Post-final
```

Formato de salida esperado de `rails-validate crud --json`:
```json
{
  "model": "ModelName",
  "passed": 18,
  "failed": 0,
  "checks": [
    {"name": "Modelo", "status": "pass"},
    {"name": "Service: create", "status": "pass"},
    {"name": "Service: update", "status": "pass"},
    {"name": "Service: search", "status": "pass"},
    {"name": "ShowDecorator", "status": "pass"},
    {"name": "TableDecorator", "status": "pass"},
    {"name": "Controller", "status": "pass"},
    {"name": "Policy", "status": "pass"},
    {"name": "Vista: index", "status": "pass"},
    {"name": "Vista: show", "status": "pass"},
    {"name": "Vista: new", "status": "pass"},
    {"name": "Vista: edit", "status": "pass"},
    {"name": "Vista: _form", "status": "pass"},
    {"name": "Factory", "status": "pass"},
    {"name": "I18n ES", "status": "pass"},
    {"name": "I18n EN", "status": "pass"},
    {"name": "Model spec", "status": "pass"},
    {"name": "Request spec", "status": "pass"}
  ]
}
```

Formato de salida esperado de `bin/ai-codex --json`:
```json
{
  "role": "code-reviewer",
  "model": "gpt-5.3-codex",
  "response": "Review summary text...",
  "timestamp": "2026-03-24T10:30:00Z"
}
```

---

## Notas de Rendimiento

- Tómate el tiempo necesario — genera el plan COMPLETO en una sola llamada al Orchestrator, sin iterar sobre el plan.
- Calidad sobre velocidad — valida cada nivel ANTES de continuar al siguiente.
- No saltes los pasos de validación — las Reviews AI son OBLIGATORIAS, nunca se omiten.
- Field manifest es la fuente de verdad — si un campo falta en cualquier capa, la implementación está incompleta.
- El script `scripts/validate_level.sh` puede usarse para verificar rápidamente que todos los archivos de un nivel existen antes de lanzar el Validator.

---

## Ejemplos

### Ejemplo 1: CRUD simple orquestado

El usuario dice: "Implementa el módulo de categorías con name y description"

Acciones:
1. Generar plan completo con 4 niveles y field_manifest
2. Nivel 1: Migración + Modelo + Factory (secuencial)
3. Nivel 2: Servicios + Decorators + Policy + Tests unitarios (paralelo interno)
4. Nivel 3: Controller + Vistas + Sidebar + I18n (todo en paralelo)
5. Nivel 4: Rubocop + Suite completa + Reviews finales bin/ai-codex + Claude review pass

Resultado: CRUD completo en ~14-16 agent calls

### Ejemplo 2: Feature compleja con state machine

El usuario dice: "Sistema de pedidos con estados pending/confirmed/shipped/delivered"

Acciones:
1. Plan con 4 niveles (BD+SM model, Servicios+SM events, Controller+Vistas+SM components, Verificación)
2. Oracle consultado para decidir guards en transiciones
3. Reviews bin/ai-codex para lógica de estados en Nivel 2, Claude review pass para UI de componentes en Nivel 3

Resultado: Módulo completo con state machine integrada

---

## Resolución de Problemas

### Developer no sigue el field_manifest

Causa: Instrucciones al developer no incluyen el manifest verbatim.
Solución: SIEMPRE pasar field_manifest COMPLETO en las instrucciones del Task, no solo el nombre de los campos.

### Tests fallan después de Nivel 2

Causa: Servicios y modelo no están coherentes.
Solución: El tester analiza y el coordinator corrige ANTES de avanzar al Nivel 3. NUNCA continuar con tests en rojo.

### Review AI no disponible (bin/ai-codex falla)

Causa: CLI wrapper no instalado o API key missing.
Solución: Ejecutar `bin/ai-codex --selftest` (hace un ping real al backend, no como `--help` que siempre sale 0). Si falla, imprime la causa real (modelo no soportado, sin auth, `codex` ausente…); escalar al usuario con ese mensaje antes de continuar. La Claude review pass no tiene dependencia externa; siempre debe ejecutarse.

### Orchestrator genera demasiados niveles

Causa: Feature es más simple de lo estimado.
Solución: Para CRUDs simples sin lógica especial, usar rails-crud directamente. La regla absoluta es máximo 4 niveles.

### Developer reporta tarea con más de 5 archivos

Causa: Atomización insuficiente en el plan del Orchestrator.
Solución: Relanzar Task(orchestrator) pidiendo subdivisión de esa tarea específica en subtareas de máximo 3 archivos.

### La tarea es un CRUD simple sin lógica especial
Causa: El orchestrator es excesivo para un CRUD de un modelo con campos básicos
Solución: Usar `/rails-crud` directamente — es más rápido y produce el mismo resultado para CRUDs simples

---

## Validación automática por nivel

```bash
bin/rails-validate level archivo1.rb archivo2.rb  # Post-cada-nivel
bin/rails-validate crud ModelName --json           # Post-final
```

Formato de salida esperado de `rails-validate crud --json`:
```json
{
  "model": "ModelName",
  "passed": 18,
  "failed": 0,
  "checks": [
    {"name": "Modelo", "status": "pass"},
    {"name": "Service: create", "status": "pass"},
    {"name": "Service: update", "status": "pass"},
    {"name": "Service: search", "status": "pass"},
    {"name": "ShowDecorator", "status": "pass"},
    {"name": "TableDecorator", "status": "pass"},
    {"name": "Controller", "status": "pass"},
    {"name": "Policy", "status": "pass"},
    {"name": "Vista: index", "status": "pass"},
    {"name": "Vista: show", "status": "pass"},
    {"name": "Vista: new", "status": "pass"},
    {"name": "Vista: edit", "status": "pass"},
    {"name": "Vista: _form", "status": "pass"},
    {"name": "Factory", "status": "pass"},
    {"name": "I18n ES", "status": "pass"},
    {"name": "I18n EN", "status": "pass"},
    {"name": "Model spec", "status": "pass"},
    {"name": "Request spec", "status": "pass"}
  ]
}
```

Formato de salida esperado de `bin/ai-codex --json`:
```json
{
  "role": "code-reviewer",
  "model": "gpt-5.3-codex",
  "response": "Review summary text...",
  "timestamp": "2026-03-24T10:30:00Z"
}
```

---

## Notas de Rendimiento

- Tómate el tiempo necesario — genera el plan COMPLETO en una sola llamada al Orchestrator, sin iterar sobre el plan.
- Calidad sobre velocidad — valida cada nivel ANTES de continuar al siguiente.
- No saltes los pasos de validación — las Reviews AI son OBLIGATORIAS, nunca se omiten.
- Field manifest es la fuente de verdad — si un campo falta en cualquier capa, la implementación está incompleta.
- El script `scripts/validate_level.sh` puede usarse para verificar rápidamente que todos los archivos de un nivel existen antes de lanzar el Validator.

---

*Generado para el template ts-rails-template*
