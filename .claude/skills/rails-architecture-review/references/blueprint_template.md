# Blueprint Template

Template completo para el PASO 3 del rails-architecture-review. Cada blueprint generado DEBE seguir exactamente esta estructura con las 6 secciones obligatorias.

---

```markdown
# Blueprint: [Titulo descriptivo del problema arquitectonico]

**Escalado por:** [orchestrator / usuario]
**Consulta original:** [La pregunta o problema que motivo el escalamiento]
**Complejidad:** [Alta / Muy Alta / Critica]

---

## 1. Diagnostico

**Problema:** [Descripcion concisa del problema tecnico]
**Causa raiz:** [Por que ocurre, no solo que ocurre — la raiz real del problema]
**Impacto:** [Que modulos, funcionalidades o flujos se ven afectados]
**Contexto:** [Estado actual del codebase relevante para entender el problema]

---

## 2. Patron Propuesto

**Patron:** [Nombre del patron o approach arquitectonico]
**Justificacion:** [Por que este patron y no otro — referencia a CLAUDE.md si aplica]

**Pseudocodigo:**

[Estructura de archivos a crear o modificar:]

app/
  services/
    domain/
      new_service.rb       # Descripcion de responsabilidad
      another_service.rb   # Descripcion de responsabilidad
  models/
    domain_model.rb        # Cambios necesarios

[Flujo de datos entre componentes:]

Controller -> ServiceA -> ServiceB -> Model
           <- decorator  <- result  <-

[Ejemplo de codigo con el patron aplicado:]

module Domain
  class NewService < BaseService
    def initialize(param_a:, param_b:)
      @param_a = param_a
      @param_b = param_b
    end

    def service_execute
      # implementacion
    end
  end
end

**Alternativas descartadas:**
- [Alternativa 1]: [Por que no — razon tecnica o conflicto con CLAUDE.md]
- [Alternativa 2]: [Por que no — razon tecnica o conflicto con CLAUDE.md]

---

## 3. Constraints

**Reglas de CLAUDE.md aplicables:**
- [Regla 1 y como se cumple en este blueprint]
- [Regla 2 y como se cumple en este blueprint]

**Dependencias:**
- [Gemas necesarias — verificar que estan en Gemfile antes de proponer]
- [Migraciones requeridas — tabla, columnas, indices]
- [Servicios existentes que se reutilizan en lugar de duplicar]

**Limites:**
- [Maximo N archivos nuevos por nivel de orchestrator]
- [No modificar X archivo sin justificacion explicita]
- [Restricciones de performance si aplica — ej: sin N+1, max 3 queries]

---

## 4. Criterios de Aprobacion

El validator DEBE verificar:

- [ ] [Criterio 1: especifico y verificable mecanicamente]
- [ ] [Criterio 2: especifico y verificable mecanicamente]
- [ ] [Criterio N: especifico y verificable mecanicamente]

Ejemplos de criterios bien formulados:
- [ ] Ningun controlador llama directamente a ActiveRecord (grep -r "Model\.find" app/controllers)
- [ ] Todos los servicios heredan de BaseService o Base::Search
- [ ] Cobertura de tests >= 90% para servicios nuevos
- [ ] Sin N+1 detectable en logs con bullet gem

**Tests requeridos:**
- [ ] [Test 1: que escenario debe probar y que resultado espera]
- [ ] [Test 2: que escenario debe probar y que resultado espera]

---

## 5. Seguridad

**Riesgos identificados:**
- [Riesgo 1]: [Descripcion] -> [Mitigacion concreta]
- [Riesgo 2]: [Descripcion] -> [Mitigacion concreta]

**Verificaciones obligatorias:**
- [ ] Autorizacion con Pundit en todos los endpoints nuevos
- [ ] Validacion de inputs en servicios (no solo en modelo)
- [ ] Sin SQL injection (usar parametros nombrados, no interpolacion de strings)
- [ ] Sin mass assignment (strong params con lista explicita de campos permitidos)
- [ ] Borrado logico con Discard (no delete fisico salvo justificacion)

---

## 6. UX (incluir solo si el blueprint afecta vistas o interaccion con usuario)

**Flujos de usuario afectados:**
- [Flujo 1]: [Impacto en la experiencia y recomendacion de UI]
- [Flujo 2]: [Impacto en la experiencia y recomendacion de UI]

**I18n:**
- [ ] Traducciones en ambos idiomas (es/en) en config/locales/models/{model}.{locale}.yml
- [ ] Mensajes flash concordantes con genero gramatical (genders.masculine / genders.feminine)
- [ ] Labels via human_attribute_name, no strings hardcoded

**Accesibilidad:**
- [ ] Formularios con labels correctos asociados a inputs
- [ ] Navegacion coherente con el resto del proyecto

---

## Recomendacion de Niveles para Orchestrator

| Nivel | Archivos | Skill | Paralelizable |
|-------|----------|-------|---------------|
| 1     | [lista de archivos del nivel 1] | [rails-crud / rails-service / etc] | Si / No |
| 2     | [lista de archivos del nivel 2] | [rails-service / rails-table-decorator] | Si / No |
| ...   | ...      | ...   | ...           |

**Nota:** Cada nivel debe tener maximo 5 archivos. Si un nivel supera ese limite, dividir en subniveles.
```
