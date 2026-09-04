# Plan Template Reference

## Estructura completa del plan JSON retornado por el Orchestrator

El Orchestrator retorna un plan JSON completo con todos los niveles en una sola llamada. Estructura obligatoria:

```json
{
  "feature": "CRUD Category",
  "field_manifest": {
    "entity": "Category",
    "fields": [
      {"name": "name", "type": "string", "required": true, "searchable": true, "in_form": true, "in_table": true, "in_show": true},
      {"name": "description", "type": "text", "required": false, "searchable": false, "in_form": true, "in_table": false, "in_show": true}
    ],
    "associations": [],
    "error_strategy": "no_bang"
  },
  "escalar_a_oracle": false,
  "niveles": [
    {
      "numero": 1,
      "nombre": "Base de Datos",
      "tipo": "secuencial",
      "tareas": [
        {
          "id": "1.1",
          "descripcion": "Migración + Modelo + Factory",
          "agente": "developer",
          "model": "sonnet",
          "archivos": [
            "db/migrate/XXXXXX_add_business_logic.rb (EDITAR)",
            "app/models/category.rb",
            "spec/factories/categories.rb"
          ],
          "skill": "rails-crud",
          "validaciones": [
            "include Discard::Model presente",
            "default_scope -> { kept } presente",
            "Sin scopes personalizados"
          ]
        }
      ],
      "post_nivel": {
        "comando_migracion": "bin/rails runner \"ActiveRecord::Base.connection.execute(%{DELETE FROM schema_migrations WHERE version='XXXXXX'})\" && bin/rails db:migrate",
        "validator": { "agente": "validator", "model": "sonnet", "skill": "rails-code-review" },
        "review_ai": null
      },
      "rollback": []
    },
    {
      "numero": 2,
      "nombre": "Lógica + Tests unitarios",
      "tipo": "paralelo",
      "tareas": [
        {
          "id": "2.1",
          "descripcion": "Servicios Categories (Create, Update, Search)",
          "agente": "developer",
          "model": "sonnet",
          "archivos": [
            "app/services/categories/create.rb",
            "app/services/categories/update.rb",
            "app/services/categories/search.rb"
          ],
          "skill": "rails-service",
          "validaciones": [
            "Create sin bang (formulario de usuario)",
            "Update sin bang (formulario de usuario)",
            "Search hereda Base::Search"
          ]
        },
        {
          "id": "2.2",
          "descripcion": "Decorators Categories",
          "agente": "developer",
          "model": "sonnet",
          "archivos": [
            "app/decorators/categories/category_show_decorator.rb",
            "app/decorators/categories/category_table_decorator.rb"
          ],
          "skill": "rails-table-decorator",
          "validaciones": [
            "Sin métodos privados",
            "collection_decorator_class definido en TableDecorator",
            "table_config con columnas correctas"
          ]
        },
        {
          "id": "2.3",
          "descripcion": "Policy + Tests unitarios",
          "agente": "developer",
          "model": "sonnet",
          "archivos": [
            "app/policies/category_policy.rb",
            "spec/models/category_spec.rb",
            "spec/services/categories/create_spec.rb",
            "spec/services/categories/update_spec.rb"
          ],
          "skill": "rails-crud",
          "validaciones": [
            "Policy hereda ApplicationPolicy",
            "Tests con subject { build(:category) } para uniqueness"
          ]
        }
      ],
      "post_nivel": {
        "validator": { "agente": "validator", "model": "sonnet", "skill": "rails-code-review" },
        "testing": {
          "agente": "tester",
          "model": "sonnet",
          "skill": "rails-test-runner",
          "fase": "post-servicios",
          "comando": "bundle exec rspec spec/models/category_spec.rb spec/services/categories/",
          "criterio_exito": "0 failures, 0 pending",
          "si_falla": {
            "accion": "Analizar con rails-test-runner",
            "estrategia": "Corregir código de producción",
            "limite_iteraciones": 3
          },
          "timeout": "5 minutos"
        },
        "review_ai": {
          "provider": "codex",
          "command": "bin/ai-codex -r code-reviewer -f app/services/categories/create.rb,app/services/categories/update.rb,app/services/categories/search.rb 'Review for: bang/no-bang coherence, nil-safety, edge cases, CLAUDE.md compliance'",
          "enfoque": "lógica de servicios, edge cases, nil-safety, vulnerabilidades",
          "obligatoria": true
        }
      },
      "rollback": ["app/models/category.rb"]
    },
    {
      "numero": 3,
      "nombre": "Interfaz + Presentación",
      "tipo": "paralelo",
      "tareas": [
        {
          "id": "3a",
          "descripcion": "Controller + Routes + Request Specs",
          "agente": "developer",
          "model": "sonnet",
          "archivos": [
            "app/controllers/admin/categories_controller.rb",
            "config/routes.rb (EDITAR)",
            "spec/requests/admin/categories_spec.rb"
          ],
          "skill": "rails-crud",
          "validaciones": [
            "Sin ActiveRecord directo",
            "Usa Base::Find y servicios",
            "authorize presente en cada acción"
          ]
        },
        {
          "id": "3b",
          "descripcion": "Sidebar",
          "agente": "developer",
          "model": "sonnet",
          "archivos": [
            "app/views/layouts/application.html.erb (EDITAR)"
          ],
          "skill": null,
          "validaciones": ["Entrada de menú añadida con is_active? correcto"]
        },
        {
          "id": "3c",
          "descripcion": "Vistas CRUD",
          "agente": "developer",
          "model": "sonnet",
          "archivos": [
            "app/views/admin/categories/index.html.erb",
            "app/views/admin/categories/show.html.erb",
            "app/views/admin/categories/_form.html.erb",
            "app/views/admin/categories/new.html.erb",
            "app/views/admin/categories/edit.html.erb"
          ],
          "skill": "rails-crud",
          "validaciones": [
            "Usa ViewComponents (no HTML manual)",
            "Tables::IndexComponent en index",
            "Form::Fields::FieldComponent en _form"
          ]
        },
        {
          "id": "3d",
          "descripcion": "Locales I18n",
          "agente": "developer",
          "model": "sonnet",
          "archivos": [
            "config/locales/models/category.es.yml",
            "config/locales/models/category.en.yml"
          ],
          "skill": null,
          "validaciones": ["Todos los campos en ambos idiomas", "Claves de error traducidas"]
        }
      ],
      "post_nivel": {
        "validator": { "agente": "validator", "model": "sonnet", "skill": "rails-code-review" },
        "testing": {
          "agente": "tester",
          "model": "sonnet",
          "skill": "rails-test-runner",
          "fase": "post-controller",
          "comando": "bundle exec rspec spec/requests/admin/categories_spec.rb",
          "criterio_exito": "0 failures",
          "si_falla": {
            "accion": "Analizar con rails-test-runner",
            "estrategia": "Corregir código de producción",
            "limite_iteraciones": 3
          },
          "timeout": "5 minutos"
        },
        "review_ai": {
          "provider": "claude_pass",
          "command": "internal — el Coordinador lee Sección 1 + Sección 3 de `.claude/review-context.md` y aplica los checks sobre app/views/admin/categories/index.html.erb, app/views/admin/categories/_form.html.erb, config/locales/models/category.es.yml, config/locales/models/category.en.yml",
          "enfoque": "I18n multiidioma, UX de formularios y vistas, accesibilidad",
          "obligatoria": true
        }
      },
      "rollback": [
        "app/services/categories/create.rb",
        "app/services/categories/update.rb",
        "app/decorators/categories/category_show_decorator.rb"
      ]
    },
    {
      "numero": 4,
      "nombre": "Verificación Final",
      "tipo": "verificacion",
      "tareas": [],
      "post_nivel": {
        "comandos": [
          "bundle exec rubocop app/models/category.rb app/services/categories/ app/decorators/categories/ app/controllers/admin/categories_controller.rb app/policies/category_policy.rb -A",
          "bundle exec rspec --format documentation",
          "rails routes | grep categories",
          "grep -n 'categories' app/views/layouts/application.html.erb"
        ],
        "review_ai_final": {
          "paralelo": true,
          "codex": {
            "provider": "codex",
            "command": "bin/ai-codex -r code-reviewer -f {archivos_backend_no_revisados} 'Final review: integración entre servicios, controller y policy; cross-layer coherence'",
            "enfoque": "backend: integración entre servicios, controller y policy; archivos no revisados previamente",
            "obligatoria": true
          },
          "claude_pass": {
            "provider": "claude_pass",
            "command": "internal — el Coordinador lee Sección 1 + Sección 3 de `.claude/review-context.md` y aplica los checks sobre {archivos_frontend_no_revisados}",
            "enfoque": "frontend: consistencia visual, I18n completo, accesibilidad global",
            "obligatoria": true
          }
        },
        "reporte_cierre": true
      }
    }
  ]
}
```

## Formato de escalación al Oracle

Cuando el Orchestrator detecta complejidad extrema, retorna:

```json
{
  "escalar_a_oracle": true,
  "razon": "Arquitectura compleja con WebSockets, Redis, concurrencia",
  "consulta_para_oracle": "
    Tenemos 5 modelos relacionados (User, Order, Product, Category, Payment)
    que deben agregarse para generar reportes de ventas con:
    - Filtros dinámicos por fecha, categoría, usuario
    - Agrupaciones por día/semana/mes
    - Cálculos de totales, promedios, percentiles
    - Exportación a CSV/PDF
    - Performance objetivo: <2s para 1M de registros

    ¿Cuál es la arquitectura óptima?
    - ¿Materializar vistas vs queries complejas?
    - ¿Índices específicos necesarios?
    - ¿Usar ActiveRecord o SQL directo?
    - ¿Cachear resultados?
  "
}
```

## Formato de escalación por agotamiento de iteraciones

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

---

## Estructura de comunicación (diagrama)

```
Usuario
  ↓
Coordinador (Claude Principal)
  ├→ Task(orchestrator) → Retorna plan COMPLETO (UNA sola vez)
  │
  ├→ NIVEL 1: Task(developer) → Task(validator)
  ├→ NIVEL 2: Task(dev-1, dev-2, dev-3) → Task(validator) → Task(tester) → bin/ai-codex
  ├→ NIVEL 3: Task(dev-1, dev-2, dev-3, dev-4) → Task(validator) → Task(tester) → Claude review pass (frontend/I18n)
  └→ NIVEL 4: Verificación final (rubocop + rspec + routes + bin/ai-codex + Claude review pass final)
```

~15-18 calls para un CRUD (vs ~28 anterior = ~43% reducción)

---

## Plantilla de Task para Developer

```markdown
Tarea: [Descripción breve - ej: "Crear servicios Categories"]

**Contexto:**
- Modelo: [Nombre del modelo]
- Dependencias: [Archivos que deben existir antes]

**Archivos a crear (MAX 5):**
1. [ruta/archivo1.rb]
2. [ruta/archivo2.rb]
...

**Instrucciones:**
1. Consulta la skill [rails-crud | rails-service | rails-table-decorator] según el tipo de tarea
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

---

## Reporte final de implementación

```markdown
## Resumen de Implementación

**Archivos creados**: X
**Archivos modificados**: Y
**Tests**: TODOS PASANDO ✅ / Z FALLANDO ❌
**Rutas agregadas**: [listar rutas]
**Migraciones ejecutadas**: [timestamp_migration_name]

**Validaciones cumplidas**:
- ✅ Sin ActiveRecord directo en controladores
- ✅ Discard implementado en modelo
- ✅ Servicios con bang methods apropiados
- ✅ ViewComponents usados correctamente
- ✅ I18n completo

**Próximos pasos** (si aplica):
[Tareas pendientes o mejoras sugeridas]
```
