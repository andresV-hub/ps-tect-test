# Level Decomposition Examples

## Estructura de 4 niveles para un CRUD (obligatoria)

```
NIVEL 1 (Secuencial): Base de Datos
├─ Tarea 1.1: Migración + Modelos + Factories
│  ├─ db/migrate/XXXXXX_add_business_logic.rb (EDITAR, no crear)
│  ├─ app/models/category.rb
│  └─ spec/factories/categories.rb
│  (3 archivos)
│  → Ejecutar migración redo
│  → Validator verifica

NIVEL 2 (Paralelo interno): Lógica + Tests unitarios
├─ Tarea 2.1: Servicios
│  ├─ app/services/categories/create.rb
│  ├─ app/services/categories/update.rb
│  └─ app/services/categories/search.rb
│  (3 archivos)
│
├─ Tarea 2.2: Decorators
│  ├─ app/decorators/categories/category_show_decorator.rb
│  └─ app/decorators/categories/category_table_decorator.rb
│  (2 archivos)
│
├─ Tarea 2.3: Policy + Tests unitarios
│  ├─ app/policies/category_policy.rb
│  ├─ spec/models/category_spec.rb
│  ├─ spec/services/categories/create_spec.rb
│  └─ spec/services/categories/update_spec.rb
│  (4 archivos)
│
│  → Validator verifica
│  → Tester ejecuta: rspec spec/models/ spec/services/categories/
│  → Review bin/ai-codex OBLIGATORIA: servicios, edge cases, nil-safety

NIVEL 3 (PARALELO — TODAS las tareas ejecutan simultáneamente):
├─ Tarea 3a: Controller + Routes + Request Specs
│  ├─ app/controllers/admin/categories_controller.rb
│  ├─ config/routes.rb (EDITAR)
│  └─ spec/requests/admin/categories_spec.rb
│  (3 archivos)
│
├─ Tarea 3b: Sidebar
│  └─ app/views/layouts/application.html.erb (EDITAR)
│  (1 archivo)
│
├─ Tarea 3c: Vistas
│  ├─ app/views/admin/categories/index.html.erb
│  ├─ app/views/admin/categories/show.html.erb
│  ├─ app/views/admin/categories/_form.html.erb
│  ├─ app/views/admin/categories/new.html.erb
│  └─ app/views/admin/categories/edit.html.erb
│  (5 archivos)
│
├─ Tarea 3d: Locales
│  ├─ config/locales/models/category.es.yml
│  └─ config/locales/models/category.en.yml
│  (2 archivos)
│
│  → Validator verifica TODO
│  → Tester ejecuta: rspec spec/requests/ + suite completa
│  → Review Claude review pass OBLIGATORIA: I18n, UX, accesibilidad

NIVEL 4 (Verificación Final):
│  → Rubocop: bundle exec rubocop [archivos] -A
│  → Suite completa: bundle exec rspec --format documentation
│  → Verificar rutas: rails routes | grep categories
│  → Verificar sidebar: grep is_active? application.html.erb
│  → Review final consolidada: bin/ai-codex (backend) + Claude review pass (frontend) en PARALELO
│  → Reporte de cierre al usuario
│  (0 archivos nuevos - solo verificación)
```

**REGLA ABSOLUTA: Máximo 4 niveles.** Controllers, vistas, sidebar y locales van TODOS en NIVEL 3 ejecutando en paralelo. NO crear niveles separados para cada uno.

---

## Ejemplo de paralelización de developers

```
# EN UN SOLO MENSAJE, usar múltiples Task calls simultáneos:

Task 1 (developer):
  Tarea: "Crear servicios Categories"
  [contenido de plantilla]

Task 2 (developer):
  Tarea: "Crear decorators Categories"
  [contenido de plantilla]

Task 3 (developer):
  Tarea: "Crear CategoryPolicy"
  [contenido de plantilla]
```

---

## Ejecución paso a paso: CRUD Category completo

```
1. Coordinador → Task(orchestrator): "Planifica COMPLETO CRUD Category"

2. Orchestrator retorna plan COMPLETO con EXACTAMENTE 4 niveles, field_manifest,
   tests por nivel, y reviews AI OBLIGATORIAS (UNA SOLA LLAMADA)

┌─────────────────────────────────────────────────────────┐
│ NIVEL 1: Base de Datos (Secuencial)                    │
└─────────────────────────────────────────────────────────┘

3. Coordinador → Task(developer): "Editar migración + modelo + factory" (3 archivos)

4. Coordinador ejecuta migración redo (add_business_logic.rb ya estaba UP)

5. Coordinador → Task(validator): "Audita NIVEL 1"

6. Validator → ✅ APROBADO

┌─────────────────────────────────────────────────────────┐
│ NIVEL 2: Lógica + Tests unitarios (PARALELO interno)   │
└─────────────────────────────────────────────────────────┘

7. Coordinador → EN UN SOLO MENSAJE (3 developers paralelos):
   Task(dev-1): servicios Create + Update + Search (3 archivos)
   Task(dev-2): decorators Show + Table (2 archivos)
   Task(dev-3): policy + tests unitarios (4 archivos)

8. Coordinador → Task(validator) + Task(tester) en paralelo

9. Coordinador → Review bin/ai-codex OBLIGATORIA: servicios, edge cases, nil-safety
   bin/ai-codex → ✅ APROBADO

┌─────────────────────────────────────────────────────────┐
│ NIVEL 3: Interfaz + Presentación (TODO en PARALELO)    │
└─────────────────────────────────────────────────────────┘

10. Coordinador → EN UN SOLO MENSAJE (4 developers paralelos):
    Task(dev-1): controller + routes + request spec (3 archivos)
    Task(dev-2): sidebar application.html.erb (1 archivo)
    Task(dev-3): vistas index/show/_form/new/edit (5 archivos)
    Task(dev-4): locales es.yml + en.yml (2 archivos)

11. Coordinador → Task(validator) + Task(tester) en paralelo

12. Coordinador → Review Claude review pass OBLIGATORIA: I18n, UX, accesibilidad
    Claude review pass → ⚠️ 1 hallazgo ALTO → corregir → Validator confirma

┌─────────────────────────────────────────────────────────┐
│ NIVEL 4: Verificación Final                            │
└─────────────────────────────────────────────────────────┘

13. Rubocop + Suite completa + Routes check + Sidebar check

14. Review final consolidada: bin/ai-codex (backend) + Claude review pass (frontend) en PARALELO

15. Reporte de cierre al usuario con sugerencias no auto-aceptadas

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

## Ejemplo con Escalamiento al Oracle

```
┌─────────────────────────────────────────────────────────┐
│ CASO: Sistema de Notificaciones en Tiempo Real         │
└─────────────────────────────────────────────────────────┘

1. Coordinador → Task(orchestrator): "Planifica sistema notificaciones tiempo real"

2. Orchestrator analiza → Detecta complejidad extrema

3. Orchestrator retorna:
   {
     "escalar_a_oracle": true,
     "razon": "Arquitectura compleja con WebSockets, Redis, concurrencia",
     "consulta_para_oracle": "¿Arquitectura óptima para notificaciones en tiempo real?"
   }

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
