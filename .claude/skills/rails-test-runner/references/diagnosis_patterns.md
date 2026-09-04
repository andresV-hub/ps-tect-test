# Patrones de Diagnóstico para rails-test-runner

Referencia detallada de errores, causas y soluciones. Consultar desde `SKILL.md` paso 2 y 3.

---

## Tabla de Errores Comunes

| Sintoma en output de RSpec | Causa probable | Donde revisar | Solucion tipica |
|----------------------------|----------------|---------------|-----------------|
| `undefined method 'X' for #<Model>` | Metodo no existe en modelo/servicio | Codigo de produccion | Implementar metodo faltante |
| `Validation failed: X can't be blank` | Validacion agregada sin actualizar factory | Factory + Modelo | Actualizar factory con atributo requerido |
| `NameError: uninitialized constant` | Clase/modulo no existe o mal nombre | Archivo referenciado | Crear clase o corregir namespace |
| `NoMethodError: undefined method 'execute'` | Servicio no hereda de BaseService | Definicion de servicio | Agregar `< BaseService` |
| `Pundit::NotAuthorizedError` | Policy no permite accion (sin rescue_from) | Policy + ApplicationController | Verificar con `be_redirect`, no `raise_error` |
| `ActiveRecord::RecordNotFound` | Registro no existe en test | Test setup | Crear registro con factory antes de consultar |
| `ActionController::UrlGenerationError` | Ruta no existe | routes.rb | Agregar ruta faltante |
| `I18n::MissingTranslationData` | Clave I18n no existe | config/locales/*.yml | Agregar traduccion |
| `FactoryBot::DuplicateDefinitionError` | Factory duplicada | spec/factories/ | Renombrar o unificar factory |
| `ActiveRecord::RecordInvalid` | Datos de factory invalidos | Factory | Ajustar factory para cumplir validaciones |
| `expected: X got: Y` | Logica cambio o test fragil | Evaluar valor del test | Ver seccion de evaluacion de valor |
| `AASM::InvalidTransition` | Transicion no permitida desde estado actual | Modelo + test setup | Verificar estado inicial en factory o let |
| `Devise::MissingWarden` | Falta include en request specs | spec/rails_helper.rb | Anadir `include Devise::Test::IntegrationHelpers` |
| `PG::UniqueViolation` o `Mysql2::Error: Duplicate entry` | Factory genera emails/campos unicos que colisionan | Factory | Usar `Faker::Internet.unique.email` |
| `NoMethodError: undefined method 'confirm'` | Usuario no confirmado antes de sign_in | Test setup | Llamar `user.confirm` antes de `sign_in user` |

---

## Interpretacion de Output de RSpec

### Fallo simple

```
Failures:
  1) Users::Create .execute con parametros invalidos retorna objeto con errores
     Failure/Error: expect(result.errors).to be_present
       expected #<ActiveModel::Errors []> to be present
     # ./spec/services/users/create_spec.rb:28:in `block (4 levels) in <top (required)>'
```

**Lectura:**
- `Users::Create` — clase testeada
- `.execute con parametros invalidos` — contexto
- `retorna objeto con errores` — descripcion del test
- `Failure/Error` — la assertion que fallo
- `./spec/services/users/create_spec.rb:28` — linea exacta del test

**Diagnostico:** El servicio usa `create!` (bang) en lugar de `create` (sin bang). Los errores de validacion no se capturan en el objeto, se lanzan como excepcion.

---

### Multiple fallo por misma causa

```
Failures:
  1) Admin::CategoriesController GET /admin/categories devuelve 200
     Failure/Error: get admin_categories_path
     NameError: uninitialized constant Admin::CategoriesController
  2) Admin::CategoriesController POST /admin/categories crea categoria
     Failure/Error: post admin_categories_path
     NameError: uninitialized constant Admin::CategoriesController
```

**Diagnostico:** La clase no existe. Un solo fix (crear el controlador) resuelve ambos fallos. Implementar UNA sola vez y re-ejecutar todos los afectados.

---

### Fallo por Pundit en request spec

```
Failures:
  1) Admin::CategoriesController con usuario regular redirige
     Failure/Error:
       expect {
         get admin_categories_path
       }.to raise_error(Pundit::NotAuthorizedError)
     expected Pundit::NotAuthorizedError but nothing was raised
```

**Diagnostico:** `ApplicationController` tiene `rescue_from Pundit::NotAuthorizedError` que captura el error y redirige. El test espera `raise_error` pero el controlador redirige antes de que la excepcion llegue al test.

**Correccion en codigo de produccion:** NO modificar el test. El test esta mal escrito pero segun CLAUDE.md no se modifica. Evaluar si es un caso de refactorizacion sugerida al usuario.

**Nota importante:** Si el test SÍ puede refactorizarse (es nuevo o el usuario lo solicita), la forma correcta es:
```ruby
# Correcto para ApplicationController con rescue_from
expect(response).to be_redirect
```

---

### Fallo por orden en colecciones

```
Failures:
  1) CategoriesSearch .execute devuelve categorias en orden correcto
     Failure/Error: expect(result.map(&:name)).to eq(['Alpha', 'Beta', 'Gamma'])
       expected: ["Alpha", "Beta", "Gamma"]
            got: ["Beta", "Alpha", "Gamma"]
```

**Diagnostico:** Test fragil — verifica orden especifico de registros. Los registros se insertan en orden distinto o la BD no garantiza orden sin `ORDER BY`.

**Evaluacion:** Test de bajo valor si el contrato del servicio no especifica orden. Sugerir refactorizacion a `contain_exactly`.

---

## Patrones de Tests Fragiles

### Patron 1: Verificacion de orden en colecciones

```ruby
# Fragil — falla si BD devuelve distinto orden
expect(users.map(&:name)).to eq(['Alice', 'Bob', 'Charlie'])

# Robusto — independiente del orden
expect(users.map(&:name)).to contain_exactly('Alice', 'Bob', 'Charlie')
```

---

### Patron 2: Verificacion de estructura interna

```ruby
# Fragil — accede a variable de instancia privada
expect(service.instance_variable_get(:@cache)).to eq({})

# Robusto — verifica comportamiento publico
expect(service.cached?).to be false
```

---

### Patron 3: Over-mocking de dependencias

```ruby
# Fragil — si cambias la implementacion interna, el test sigue pasando aunque este roto
allow(Order).to receive(:find).and_return(mock_order)
allow(mock_order).to receive(:update!).and_return(true)
allow(PaymentService).to receive(:execute).and_return(true)
allow(EmailService).to receive(:execute).and_return(true)

result = described_class.execute(order_id: 1)
expect(result).to be_truthy  # Solo verifica que retorna algo truthy

# Robusto — verifica comportamiento observable con BD real
order = create(:order, state: :pending, total: 100)
result = described_class.execute(order_id: order.id, payment_method: 'card')
expect(result).to be_persisted
expect(order.reload.state).to eq('completed')
expect(order.payments.last.amount).to eq(100)
```

---

### Patron 4: Verificacion de metodos privados

```ruby
# Fragil — prueba detalle de implementacion con send
expect(service.send(:internal_calculation, 10)).to eq(20)

# Robusto — prueba el resultado publico
result = service.execute(input: 10)
expect(result.total).to eq(20)
```

---

### Patron 5: Verificacion de llamadas a metodos en vez de resultados

```ruby
# Fragil — verifica que se llamen metodos en orden concreto
expect(ServiceA).to receive(:execute).ordered
expect(ServiceB).to receive(:execute).ordered
orchestrator.execute

# Robusto — verifica que el resultado sea el correcto
order = create(:order, state: :pending)
orchestrator.execute(order_id: order.id)
expect(order.reload.state).to eq('completed')
expect(order.processed_at).to be_present
```

---

## Ejemplos de Output de RSpec y su Interpretacion

### Output limpio (todos pasan)

```
Finished in 2.34 seconds (files took 1.23 seconds to load)
127 examples, 0 failures
```

**Interpretacion:** Suite completa verde. No hay accion requerida.

---

### Output con fallos y pendientes

```
Finished in 3.12 seconds (files took 1.45 seconds to load)
89 examples, 3 failures, 2 pending

Failed examples:
  rspec ./spec/models/user_spec.rb:42 # User validaciones custom rechaza email invalido
  rspec ./spec/services/users/create_spec.rb:15 # Users::Create .execute con params validos crea registro
  rspec ./spec/policies/user_policy_spec.rb:8 # UserPolicy para un admin permite index
```

**Interpretacion:**
- 3 tests fallan en 3 archivos distintos — probablemente causas distintas
- 2 pendientes — tests marcados con `pending` o `xit`, no bloquean
- Empezar por el error mas simple para descartar causa comun

---

### Output con fallo en bloque before

```
Failures:
  1) Admin::UsersController GET /admin/users devuelve 200
     Failure/Error: sign_in admin
     Devise::MissingWarden:
       Devise could not find the `Warden::Proxy` instance on your request environment.
```

**Interpretacion:** Falta `include Devise::Test::IntegrationHelpers` en el grupo de request specs en `spec/rails_helper.rb` o en el archivo de spec.

---

### Output con stack trace largo

```
Failures:
  1) Orders::Process .execute procesa el pedido
     Failure/Error: @order.update!(state: :completed)
     ActiveRecord::RecordInvalid:
       Validation failed: Total must be greater than 0
     # ./app/services/orders/process.rb:18:in `service_execute'
     # ./app/services/base_service.rb:8:in `execute'
     # ./spec/services/orders/process_spec.rb:12:in `block (3 levels)'
```

**Interpretacion:**
- El error ocurre en `app/services/orders/process.rb:18` — esa es la linea del codigo de produccion
- La causa es una validacion en el modelo Order: `total must be greater than 0`
- El test probablemente crea una factory de order sin `total` o con `total: 0`
- Fix: actualizar factory o el `let(:order)` del test para incluir `total: 100`
