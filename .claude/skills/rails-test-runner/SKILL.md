---
name: rails-test-runner
description: "Ejecuta RSpec tests, diagnostica fallos y propone correcciones en código de producción. Usar cuando el usuario dice 'corre los tests', 'ejecuta rspec', 'los tests fallan', 'fix de tests' o 'por qué falla este test'. No usar para generar tests nuevos (usar rails-test-coverage), modificar archivos de test, o frameworks de test distintos de RSpec."
compatibility: "Ruby 3.4+, Rails 8, requires RSpec, FactoryBot, Devise, Pundit"
metadata:
  version: 1.2.0
---

# Rails Test Runner

Ejecuta tests de RSpec, analiza fallos con juicio de valor, y propone soluciones que corrijan el código de producción. **NUNCA sugiere eliminar tests. Prefiere corregir el código de producción, no el test.**

**Para patrones de diagnóstico detallados y tabla de errores completa, consulta `references/diagnosis_patterns.md`.**
**Para ejecutar y resumir rápidamente, usar: `scripts/run_and_summarize.sh spec/path`.**

---

## REGLAS CRÍTICAS

Según `CLAUDE.md`: los tests son sagrados y NUNCA se modifican ni eliminan. Adicionalmente, esta skill requiere:

1. **Evaluación de valor antes de arreglar**: preguntarse si el test aporta confianza o es frágil antes de proponer cualquier solución
2. **Proponer refactorización si el test es frágil**: sugerir la mejora al usuario, no aplicarla silenciosamente
3. **El problema siempre está en el código de producción**: si un test de alto valor falla, el código de producción está roto

---

## DEFINICIÓN DE CALIDAD

**Un buen test es aquel que falla solo cuando la regla de negocio se rompe, no cuando se refactoriza el código.**

Tests robustos:
- Prueba comportamiento observable, no detalles de implementación
- Falla por razones claras (violación de regla de negocio)
- No depende del orden de claves en hashes o arrays
- Usa factories en lugar de mockear todo

Tests frágiles (identificar y reportar al usuario):
- Mockea el Modelo + Servicio + Base de datos simultáneamente
- Verifica el orden exacto de elementos en un JSON
- Depende de nombres de variables internas
- Verifica cuántas veces se llama a un método en lugar de el resultado

---

## Proceso de Ejecución

### PASO 1: Ejecutar Tests

```bash
bundle exec rspec [path]

# O usar el script incluido:
.claude/skills/rails-test-runner/scripts/run_and_summarize.sh spec/path
```

Capturar: total ejecutados, exitosos/fallidos, mensajes de error completos, stack traces.

---

### PASO 2: Clasificar Fallos

Consultar la tabla completa de errores en `references/diagnosis_patterns.md`.

Diagnóstico rápido por síntoma:

| Sintoma | Causa probable | Accion |
|---------|----------------|--------|
| `undefined method 'X'` | Metodo no existe | Implementar en codigo de produccion |
| `Validation failed: X can't be blank` | Factory desactualizada | Actualizar factory |
| `NameError: uninitialized constant` | Clase no existe o namespace incorrecto | Crear clase o corregir namespace |
| `Pundit::NotAuthorizedError` en request spec | Test espera raise pero ApplicationController redirige | Evaluar — el test puede ser fragil |
| `ActiveRecord::RecordNotFound` | Factory no crea el registro antes de consultar | Ajustar setup del test |
| `ActionController::UrlGenerationError` | Ruta no existe en routes.rb | Agregar ruta faltante |
| `I18n::MissingTranslationData` | Clave I18n no existe | Agregar traduccion en config/locales/ |
| `NoMethodError: undefined method 'confirm'` | Falta user.confirm antes de sign_in | Llamar user.confirm en setup |

---

### PASO 3: Análisis de Contexto + Evaluación de Valor

Para cada test fallido:

1. Leer el test completo (spec file)
2. Leer el código de producción referenciado (modelo/servicio/controlador)
3. Leer la factory asociada (si aplica)
4. Identificar la discrepancia entre expectativa del test y realidad del código

**Antes de proponer solución, responder: ¿este test aporta confianza o es frágil?**

Señales de test de ALTO valor:
- Falla porque una regla de negocio se violó
- Prueba comportamiento observable (output dado un input)
- Es independiente de la implementación interna

Señales de test FRÁGIL:
- Falla porque cambió el orden de claves en un JSON
- Mockea todo: modelo + servicio + base de datos
- Verifica detalles de implementación (variables internas, cantidad de llamadas a métodos)

Consultar `references/diagnosis_patterns.md` para ejemplos concretos de ambos tipos.

---

### PASO 4: Proponer Solución con Juicio de Valor

#### Caso A: Test de alto valor que falla legítimamente

Acción: corregir el código de producción para cumplir el contrato.

```ruby
# Test (correcto, no se toca):
it 'calcula descuento del 20% para clientes VIP' do
  vip_user = create(:user, :vip)
  order = create(:order, user: vip_user, subtotal: 100)
  expect(order.discounted_total).to eq(80.0)
end

# Solución: implementar el método faltante en app/models/order.rb
def discounted_total
  return subtotal unless user.vip?
  subtotal * 0.8
end
```

#### Caso B: Test frágil que falla por detalle de implementación

Acción: NO modificar el test. Reportar al usuario con diagnóstico y sugerencia de refactorización.

```
Test Fragil Detectado

Test: spec/services/users/create_spec.rb:42
Fallo: expected hash keys to match [:id, :name, :email], got [:email, :name, :id]

Diagnostico:
Este test verifica el ORDEN de claves en un hash — detalle de implementacion
irrelevante. El orden de insercion en Ruby es determinista pero no es parte
del contrato publico del servicio.

Recomendacion (no aplicada automaticamente):
# Test fragil actual:
expect(result.keys).to eq([:id, :name, :email])

# Test robusto sugerido:
expect(result).to include(id: be_a(Integer), name: 'John Doe', email: 'john@example.com')
```

#### Caso C: Over-mocking detectado

Acción: NO modificar el test. Reportar con propuesta de test de integración ligero.

```
Over-Mocking Detectado

Test: spec/services/orders/process_spec.rb:15
Problema: Mockea simultaneamente Modelo + Servicio + Base de datos

Recomendacion (no aplicada automaticamente):
# Test con over-mocking actual → verifica llamadas, no resultados
# Test de integracion ligero sugerido:
it 'procesa el pedido y crea el pago' do
  order = create(:order, state: :pending, total: 100)
  result = described_class.execute(order_id: order.id, payment_method: 'card')
  expect(order.reload.state).to eq('completed')
  expect(order.payments.last.amount).to eq(100)
end
```

---

### PASO 5: Implementar Solución

Solo en código de producción. Nunca en archivos `spec/`.

**Solución A: Implementar método faltante**

```ruby
# Si el test espera user.full_name pero el método no existe en app/models/user.rb
def full_name
  "#{name} #{surname}".strip
end
```

**Solución B: Actualizar factory**

```ruby
# Si el modelo ahora requiere email pero la factory no lo provee
FactoryBot.define do
  factory :user do
    name { Faker::Name.first_name }
    email { Faker::Internet.unique.email }  # Agregar
  end
end
```

**Solución C: Corregir namespace**

```ruby
# Si el test espera Users::Create pero el archivo define User::Create
module Users   # Corregir de User a Users
  class Create < BaseService
```

**Solución D: Ajustar policy**

```ruby
# Si el test espera que admin pueda destroy pero policy no lo permite
def destroy?
  user.has_role?(:admin)
end
```

**Solución E: Corregir setup de estado inicial**

```ruby
# Si la transición AASM falla porque el estado inicial es incorrecto
# En la factory o en el let del test de producción:
let(:order) { create(:order, state: :pending) }  # Asegurar estado correcto
```

---

### PASO 6: Re-ejecutar Tests

```bash
# Ejecutar SOLO el test que falló para verificar fix
bundle exec rspec spec/path/to/file_spec.rb:42

# Si pasa, ejecutar toda la suite para detectar regresiones
bundle exec rspec
```

---

### PASO 7: Reportar Resultado con Evaluación de Calidad

```
Tests Fixed: 3/3

Fixes Applied (Alto Valor):
1. spec/models/user_spec.rb:42
   - Error: undefined method 'full_name'
   - Fix: Implementado User#full_name en app/models/user.rb:15
   - Valor: Alto (prueba comportamiento publico)

2. spec/services/users/create_spec.rb:12
   - Error: Validation failed: email can't be blank
   - Fix: Agregado email a factory en spec/factories/users.rb:5
   - Valor: Alto (prueba validacion de negocio)

Tests con Advertencias (no modificados, requieren revision del usuario):
1. spec/services/orders/process_spec.rb:45
   - Advertencia: Over-mocking detectado (mockea 5+ dependencias)
   - Recomendacion: Reemplazar por test de integracion ligero (ver sugerencia adjunta)
   - Valor: Bajo (test de caja blanca)

Suite Status: All 127 tests passing
Nivel de Confianza: Alto (todos los tests de alto valor pasan)
```

---

## Casos Especiales

### Fallo por Cambio de Arquitectura

Si el test falla porque el patrón arquitectónico cambió (ej: antes usaba `User.create` directo, ahora debe pasar por `Users::Create.execute`): verificar primero si el código de producción sigue el patrón correcto del template. NUNCA modificar el test sin verificar que el código de producción es el correcto.

### Múltiples Tests Fallan por la Misma Causa

Si 10 tests fallan con `undefined method 'X'`:
1. Implementar el método UNA sola vez en el código de producción
2. Re-ejecutar TODOS los tests afectados
3. Reportar fix único con impacto múltiple

---

## Comandos Útiles

```bash
# Ejecutar tests en orden aleatorio (detectar dependencias entre tests)
bundle exec rspec --order random

# Ejecutar solo tests que fallaron la última vez
bundle exec rspec --only-failures

# Ejecutar con cobertura
COVERAGE=true bundle exec rspec

# Ver detalles completos de fallo
bundle exec rspec --format documentation

# Ejecutar con perfil de lentitud (detectar tests lentos)
bundle exec rspec --profile 10

# Script incluido (ejecuta y resume)
.claude/skills/rails-test-runner/scripts/run_and_summarize.sh spec/services/
```

---

## Archivos Típicamente Afectados (Código de Producción)

- `app/models/*.rb` — implementación de métodos faltantes
- `spec/factories/*.rb` — datos de factories desactualizados
- `app/services/**/*.rb` — lógica de negocio
- `app/policies/*.rb` — autorización
- `config/locales/*.yml` — traducciones
- `app/controllers/**/*.rb` — acciones de controlador

Los archivos `spec/**/*_spec.rb` solo se tocan si se está proponiendo una refactorización sugerida al usuario y este la aprueba.

---

## Métricas de Éxito

| Metrica | Target |
|---------|--------|
| Tests ejecutados | 100% |
| Tests pasando | 100% |
| Tests robustos | >= 90% |
| Tests fragiles identificados | Reportar todos |
| Tests con over-mocking | < 5% |
| Tests modificados/eliminados | 0 |

---

## Ejemplos

### Ejemplo 1: Test falla por método no implementado

El usuario dice: "Los tests de user_spec.rb fallan"

Acciones:
1. Ejecutar `bundle exec rspec spec/models/user_spec.rb`
2. Diagnosticar: `undefined method 'full_name' for #<User>`
3. Leer el test: espera `user.full_name` retorne "John Doe"
4. Evaluar valor: alto — prueba comportamiento público observable
5. Implementar `full_name` en `app/models/user.rb`
6. Re-ejecutar y verificar verde

Resultado: Test pasa. El método faltante fue implementado en el código de producción, no se tocó el test.

---

### Ejemplo 2: Test falla por Pundit en request spec

El usuario dice: "Los tests de categories_spec.rb fallan"

Acciones:
1. Ejecutar `bundle exec rspec spec/requests/admin/categories_spec.rb`
2. Diagnosticar: test espera `raise_error(Pundit::NotAuthorizedError)` pero no se lanza
3. Causa: `ApplicationController` tiene `rescue_from Pundit::NotAuthorizedError` que redirige antes de que el error llegue al test
4. Evaluar valor del test: el test está probando el comportamiento incorrecto — debería verificar `be_redirect`
5. Reportar al usuario como test frágil con sugerencia de refactorización

Resultado: Se reporta como test frágil. No se modifica el test sin aprobación del usuario.

---

### Ejemplo 3: Test falla por factory desactualizada

El usuario dice: "Ejecuta los tests de categories"

Acciones:
1. Ejecutar con `run_and_summarize.sh spec/services/categories/`
2. Diagnosticar: `ActiveRecord::RecordInvalid: Validation failed: Code can't be blank`
3. Leer factory `spec/factories/categories.rb`: no tiene campo `code`
4. Leer modelo `app/models/category.rb`: se añadió `validates :code, presence: true`
5. Evaluar: factory desactualizada, test de alto valor
6. Actualizar `spec/factories/categories.rb` añadiendo `code { Faker::Alphanumeric.alpha(number: 6) }`

Resultado: Factory actualizada, tests pasan. El test no se tocó.

---

## Ejecución rápida

```bash
bin/rails-validate test spec/path
bin/rails-validate test spec/path --json  # Resultado parseable
```

Formato de salida esperado (`--json`):
```json
{
  "spec_path": "spec/path",
  "examples": 15,
  "failures": 0,
  "pending": 0,
  "status": "pass",
  "duration": "2.34s"
}
```

---

## Notas de Rendimiento

- Leer el stack trace completo antes de proponer solución — el error real suele estar en la línea del modelo, no del test
- Un fix que resuelve 10 tests a la vez (causa raíz común) es mejor que 10 fixes individuales
- No reportar completado hasta haber ejecutado la suite completa y verificado que no hay regresiones

---

## Resolución de Problemas

### Devise: falta user.confirm en request specs
Causa: Devise requiere confirmación de email antes de autenticar
Solución: Llamar `user.confirm` antes de `sign_in user` en el bloque `before` del test. No modificar el test — si el test ya existe y falla, el setup de producción debe incluir la confirmación

### Pundit redirect vs raise
Causa: `ApplicationController` tiene `rescue_from Pundit::NotAuthorizedError` que captura el error y redirige. Los tests que esperan `raise_error` nunca verán la excepción
Solución: El test correcto usa `expect(response).to be_redirect`. Si el test existente usa `raise_error`, reportar como test frágil al usuario

### Tests pasan localmente pero fallan en CI
Causa: Orden de ejecución o datos residuales entre tests (test pollution)
Solución: Ejecutar con `bundle exec rspec --order random` para detectar dependencias entre tests. El fix suele ser añadir `DatabaseCleaner` o mover factories a `let` en lugar de variables de instancia

### Error: "PG::ConnectionBad" o "Mysql2::Error::ConnectionError"
Causa: Base de datos de test no accesible
Solución: `bundle exec rails db:create db:migrate RAILS_ENV=test`

### Error: "Factory not registered: :nombre"
Causa: Factory no existe o tiene nombre incorrecto
Solución: Verificar que existe `spec/factories/[plural].rb` con `factory :[singular]`

### shoulda-matchers validate_uniqueness_of falla con "Can't figure out a good value"
Causa: No hay `subject` explícito con un objeto válido
Solución: Añadir `subject { build(:[singular]) }` antes del bloque `it`

### Se necesitan tests nuevos, no correr los existentes
Causa: El código no tiene cobertura de tests
Solución: Usar `/rails-test-coverage` para analizar criticidad y generar tests de alto valor
