---
name: rails-architecture-review
description: "Genera blueprints tecnicos para decisiones arquitectonicas complejas. Usar cuando el Oracle escala via 'escalar_a_oracle', o el usuario dice 'revisa la arquitectura de', 'blueprint para' o 'decisión arquitectónica sobre'. No usar para code reviews simples (usar rails-code-review), generación de CRUDs o refactorizaciones rutinarias."
compatibility: "Ruby 3.4+, Rails 8"
metadata:
  version: 1.2.0
---

# Rails Architecture Review

Skill para el agente Oracle. Genera blueprints tecnicos ejecutables cuando el orchestrator escala decisiones arquitectonicas complejas.

Sigue TODAS las reglas criticas de `CLAUDE.md`. Consulta ese archivo antes de proponer cualquier patron arquitectonico para verificar compatibilidad con las directrices del proyecto.

## Cuando se usa esta skill

- El orchestrator escala con `"escalar_a_oracle": true`
- Hay conflicto entre reglas de CLAUDE.md y la implementacion tecnica
- Logica de negocio extremadamente compleja (>200 lineas)
- Decisiones que afectan multiples modulos
- Integraciones con APIs externas sin documentacion
- Performance critica (queries complejos, concurrencia)
- Modelos con mas de 10 asociaciones

## PASO 1: Analisis de Contexto

Antes de generar el blueprint:

1. **Leer CLAUDE.md** para confirmar reglas aplicables
2. **Leer `db/schema.rb`** para entender estructura de BD
3. **Leer modelos involucrados** en `app/models/`
4. **Leer servicios existentes** en `app/services/` del dominio
5. **Verificar patrones existentes** en el codebase para el tipo de problema

## PASO 2: Evaluacion de Complejidad

Clasificar el problema:

| Tipo | Ejemplo | Enfoque |
|------|---------|---------|
| Conflicto de reglas | CLAUDE.md dice X pero el caso requiere Y | Dictaminar excepcion justificada o reforzar regla |
| Logica compleja | Calculo multi-paso con dependencias | Descomponer en servicios atomicos |
| Performance | N+1, queries lentos, concurrencia | Analizar query plan, proponer indices/caching |
| Integracion | API externa sin docs | Definir interfaz, adapters, error handling |
| Arquitectura nueva | Patron no cubierto (websockets, jobs) | Proponer arquitectura compatible con MVC+Servicios |

## PASO 3: Generar Blueprint

El blueprint DEBE tener exactamente estas 6 secciones:

### Seccion 1: Diagnostico de causa raiz

```markdown
## 1. Diagnostico

**Problema:** [Descripcion concisa del problema]
**Causa raiz:** [Por que ocurre, no solo que ocurre]
**Impacto:** [Que modulos/funcionalidades se ven afectados]
**Contexto:** [Estado actual del codebase relevante]
```

### Seccion 2: Patron arquitectonico propuesto

```markdown
## 2. Patron Propuesto

**Patron:** [Nombre del patron o approach]
**Justificacion:** [Por que este patron y no otro]

**Pseudocodigo:**

[Estructura de archivos a crear/modificar]
[Flujo de datos entre componentes]
[Ejemplo de codigo con el patron aplicado]

**Alternativas descartadas:**
- [Alternativa 1]: [Por que no]
- [Alternativa 2]: [Por que no]
```

### Seccion 3: Constraints para implementacion

```markdown
## 3. Constraints

**Reglas de CLAUDE.md aplicables:**
- [Regla 1 y como se cumple]
- [Regla 2 y como se cumple]

**Dependencias:**
- [Gemas necesarias (verificar Gemfile)]
- [Migraciones requeridas]
- [Servicios existentes que se reutilizan]

**Limites:**
- [Maximo N archivos nuevos]
- [No modificar X archivo sin justificacion]
- [Restricciones de performance]
```

### Seccion 4: Criterios de aprobacion para el validator

```markdown
## 4. Criterios de Aprobacion

El validator DEBE verificar:

- [ ] [Criterio 1 especifico y verificable]
- [ ] [Criterio 2 especifico y verificable]
- [ ] [Criterio N especifico y verificable]

**Tests requeridos:**
- [ ] [Test 1: que debe probar]
- [ ] [Test 2: que debe probar]
```

### Seccion 5: Consideraciones de seguridad

```markdown
## 5. Seguridad

**Riesgos identificados:**
- [Riesgo 1]: [Mitigacion]
- [Riesgo 2]: [Mitigacion]

**Verificaciones obligatorias:**
- [ ] Autorizacion con Pundit en todos los endpoints
- [ ] Validacion de inputs en servicios
- [ ] Sin SQL injection (usar parametros, no interpolacion)
- [ ] Sin mass assignment (strong params)
- [ ] Borrado logico con Discard (no delete fisico)
```

### Seccion 6: Consideraciones de UX (si aplica)

```markdown
## 6. UX

**Flujos de usuario afectados:**
- [Flujo 1]: [Impacto y recomendacion]
- [Flujo 2]: [Impacto y recomendacion]

**I18n:**
- [ ] Traducciones en ambos idiomas (es/en)
- [ ] Mensajes flash concordantes con genero gramatical
- [ ] Labels via human_attribute_name

**Accesibilidad:**
- [ ] Formularios con labels correctos
- [ ] Navegacion coherente
```

**Nota:** La seccion 6 (UX) se incluye cuando el blueprint afecta vistas o interaccion con el usuario. Validar con `bin/ai-design` si hay incertidumbre.

## PASO 4: Validar Blueprint

Antes de entregar, verificar:

1. **Compatibilidad con CLAUDE.md**: Todas las reglas criticas se respetan
2. **Atomizacion posible**: El orchestrator puede dividir en tareas de max 5 archivos
3. **Skills existentes**: Se referencian skills apropiadas para cada parte
4. **Completitud**: No hay ambiguedades que bloqueen al developer
5. **Testabilidad**: Los criterios de aprobacion son verificables mecanicamente

## Ejemplos

### Ejemplo 1: Escalación desde orchestrator

Disparador: orchestrator escala con `"escalar_a_oracle": true`

Acciones:
1. Leer contexto de escalación
2. Leer CLAUDE.md, db/schema.rb y modelos involucrados
3. Analizar tipo de complejidad (PASO 2)
4. Generar blueprint con las 6 secciones obligatorias

Resultado: Blueprint ejecutable con alternativas evaluadas y tabla de niveles para el orchestrator

### Ejemplo 2: Petición directa del usuario

El usuario dice: "blueprint para integración con API de facturación electrónica"

Acciones:
1. Leer CLAUDE.md para reglas aplicables (Adapter pattern, servicios, error handling)
2. Verificar patrones existentes en app/services/
3. Generar blueprint con sección de seguridad y constraints de gemas

Resultado: Blueprint con pseudocodigo, constraints y criterios de aprobacion verificables

---

## Resolución de Problemas

### El blueprint resulta demasiado grande para una sola tarea

Causa: Arquitectura con muchos archivos interdependientes
Solución: Asegurarse de que la "Recomendacion de Niveles" descompone en tareas de max 5 archivos cada una

### Conflicto entre CLAUDE.md y el patron propuesto

Causa: La situacion requiere una excepcion justificada
Solución: Documentar explicitamente en Seccion 3 (Constraints) la excepcion, su justificacion y como se mitiga el riesgo

### Criterios de aprobacion no verificables mecanicamente

Causa: Criterios demasiado subjetivos ("debe verse bien", "debe ser rapido")
Solución: Reformular como checks concretos: porcentaje de cobertura, ausencia de N+1, tiempo de respuesta < Xms

### Solo se necesita verificar cumplimiento de reglas
Causa: No hay decisión arquitectónica, solo validar que el código sigue CLAUDE.md
Solución: Usar `/rails-code-review` para auditoría automática contra reglas

---

## Notas de Rendimiento

- Leer COMPLETO schema.rb y modelos antes de proponer arquitectura
- No proponer patrones sin verificar gemas disponibles en Gemfile
- El blueprint debe ser ejecutable sin ambiguedades — si algo no esta claro, especificarlo

---

## Referencias

El template completo del blueprint con todas las secciones y ejemplos de cada campo esta en `references/blueprint_template.md`.

---

## Formato de Salida

```markdown
# Blueprint: [Titulo descriptivo]

**Escalado por:** [orchestrator/usuario]
**Consulta original:** [La pregunta que motivo el escalamiento]
**Complejidad:** [Alta/Muy Alta/Critica]

## 1. Diagnostico
[...]

## 2. Patron Propuesto
[...]

## 3. Constraints
[...]

## 4. Criterios de Aprobacion
[...]

## 5. Seguridad
[...]

## 6. UX (si aplica)
[...]

## Recomendacion de Niveles para Orchestrator

| Nivel | Archivos | Skill | Paralelizable |
|-------|----------|-------|---------------|
| 1 | [lista] | [skill] | Si/No |
| 2 | [lista] | [skill] | Si/No |
| ... | ... | ... | ... |
```
