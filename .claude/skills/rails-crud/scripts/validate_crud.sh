#!/usr/bin/env bash
set -euo pipefail

# ---- Help ----
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'EOF'
Uso: validate_crud.sh [--json] ModelName

Valida que una implementación CRUD esté completa para el modelo indicado.
Comprueba: modelo, servicios (create/update/search), decorators (show/table),
controller, policy, vistas (index/show/new/edit/_form), factory, I18n y specs.
También detecta violaciones de CLAUDE.md (private en services/decorators,
ActiveRecord directo en controller, keyword splat de params).

Opciones:
  --json    Salida como JSON estructurado (por defecto: legible)
  --help    Muestra este mensaje

Ejemplos:
  validate_crud.sh Category
  validate_crud.sh --json Category
  validate_crud.sh --json Category | jq '.failed'
EOF
  exit 0
fi

# ---- Parse flags ----
JSON_OUTPUT=false
ARGS=()
for arg in "$@"; do
  case "$arg" in
    --json|-j) JSON_OUTPUT=true ;;
    *) ARGS+=("$arg") ;;
  esac
done

MODEL="${ARGS[0]:?Uso: validate_crud.sh [--json] ModelName}"
MODEL_LOWER=$(echo "$MODEL" | sed 's/\([A-Z]\)/_\L\1/g' | sed 's/^_//')
MODEL_PLURAL="${MODEL_LOWER}s"

# ---- Check helper ----
PASSED=0
FAILED=0
CHECKS=()

check() {
  local name="$1"
  local result="$2"
  if [[ "$result" == "true" ]]; then
    PASSED=$((PASSED + 1))
    CHECKS+=("{\"name\":\"$name\",\"status\":\"pass\"}")
    $JSON_OUTPUT || echo "OK  $name"
  else
    FAILED=$((FAILED + 1))
    CHECKS+=("{\"name\":\"$name\",\"status\":\"fail\"}")
    $JSON_OUTPUT || echo "FALTA  $name"
  fi
}

check_violation() {
  local name="$1"
  local result="$2"
  if [[ "$result" == "true" ]]; then
    PASSED=$((PASSED + 1))
    CHECKS+=("{\"name\":\"$name\",\"status\":\"pass\"}")
    $JSON_OUTPUT || echo "OK  $name"
  else
    FAILED=$((FAILED + 1))
    CHECKS+=("{\"name\":\"$name\",\"status\":\"fail\"}")
    $JSON_OUTPUT || echo "VIOLACION  $name"
  fi
}

$JSON_OUTPUT || echo "=== Validando CRUD para $MODEL ==="

# ---- Archivos ----
check "Modelo" "$( [[ -f "app/models/${MODEL_LOWER}.rb" ]] && echo true || echo false )"

for svc in create update search; do
  check "Service: $svc" "$( [[ -f "app/services/${MODEL_PLURAL}/${svc}.rb" ]] && echo true || echo false )"
done

check "ShowDecorator" "$( [[ -f "app/decorators/${MODEL_PLURAL}/${MODEL_LOWER}_show_decorator.rb" ]] && echo true || echo false )"
check "TableDecorator" "$( [[ -f "app/decorators/${MODEL_PLURAL}/${MODEL_LOWER}_table_decorator.rb" ]] && echo true || echo false )"

check "Controller" "$( [[ -f "app/controllers/admin/${MODEL_PLURAL}_controller.rb" ]] && echo true || echo false )"
check "Policy" "$( [[ -f "app/policies/${MODEL_LOWER}_policy.rb" ]] && echo true || echo false )"

for view in index show new edit _form; do
  check "Vista: $view" "$( [[ -f "app/views/admin/${MODEL_PLURAL}/${view}.html.erb" ]] && echo true || echo false )"
done

check "Factory" "$( [[ -f "spec/factories/${MODEL_PLURAL}.rb" ]] && echo true || echo false )"
check "I18n ES" "$( [[ -f "config/locales/models/${MODEL_LOWER}.es.yml" ]] && echo true || echo false )"
check "I18n EN" "$( [[ -f "config/locales/models/${MODEL_LOWER}.en.yml" ]] && echo true || echo false )"
check "Model spec" "$( [[ -f "spec/models/${MODEL_LOWER}_spec.rb" ]] && echo true || echo false )"
check "Request spec" "$( [[ -f "spec/requests/admin/${MODEL_PLURAL}_spec.rb" ]] && echo true || echo false )"

# ---- Violaciones ----
if [[ -d "app/services/${MODEL_PLURAL}" ]]; then
  private_in_services=$(grep -rn "private" "app/services/${MODEL_PLURAL}/" 2>/dev/null | grep -v "^Binary" || true)
  check_violation "Sin métodos privados en services" "$( [[ -z "$private_in_services" ]] && echo true || echo false )"
fi

if [[ -d "app/decorators/${MODEL_PLURAL}" ]]; then
  private_in_decorators=$(grep -rn "private" "app/decorators/${MODEL_PLURAL}/" 2>/dev/null | grep -v "^Binary" || true)
  check_violation "Sin métodos privados en decorators" "$( [[ -z "$private_in_decorators" ]] && echo true || echo false )"
fi

if [[ -f "app/controllers/admin/${MODEL_PLURAL}_controller.rb" ]]; then
  ar_direct=$(grep -n "${MODEL}\.find\|${MODEL}\.all\|${MODEL}\.where\|${MODEL}\.kept" "app/controllers/admin/${MODEL_PLURAL}_controller.rb" 2>/dev/null || true)
  check_violation "Sin ActiveRecord directo en controller" "$( [[ -z "$ar_direct" ]] && echo true || echo false )"

  splat_params=$(grep -n "\*\*${MODEL_LOWER}_params" "app/controllers/admin/${MODEL_PLURAL}_controller.rb" 2>/dev/null || true)
  check_violation "Sin keyword splat de params" "$( [[ -z "$splat_params" ]] && echo true || echo false )"
fi

# ---- N-M cableado en controller (has_many :through) ----
# Si el modelo declara relaciones has_many :through, el controller DEBE permitir
# <singular>_ids como array y pasarlo a los services Create/Update. El form, el
# service y el decorator pueden tener la sync, pero si el controller no reenvía
# el param, asignar la asociación no tiene efecto (bug silencioso).
if [[ -f "app/models/${MODEL_LOWER}.rb" && -f "app/controllers/admin/${MODEL_PLURAL}_controller.rb" ]]; then
  through_assocs=$(grep -oE "has_many :[a-z_]+, through:" "app/models/${MODEL_LOWER}.rb" 2>/dev/null | sed -E 's/has_many :([a-z_]+), through:/\1/' || true)
  if [[ -n "$through_assocs" ]]; then
    controller="app/controllers/admin/${MODEL_PLURAL}_controller.rb"
    nm_ok=true
    while IFS= read -r assoc; do
      [[ -z "$assoc" ]] && continue
      sing=$(echo "$assoc" | sed -E 's/ies$/y/; s/s$//')
      grep -q "${sing}_ids: \[\]" "$controller" || nm_ok=false
      grep -q "${sing}_ids: ${MODEL_LOWER}_params\[:${sing}_ids\]" "$controller" || nm_ok=false
    done <<< "$through_assocs"
    check "N-M cableado en controller (<assoc>_ids en permit + Create/Update)" "$( [[ "$nm_ok" == "true" ]] && echo true || echo false )"
  fi
fi

# ---- Output ----
if $JSON_OUTPUT; then
  CHECKS_JSON=$(IFS=,; echo "${CHECKS[*]}")
  echo "{\"model\":\"$MODEL\",\"passed\":$PASSED,\"failed\":$FAILED,\"checks\":[$CHECKS_JSON]}"
else
  echo ""
  echo "=== Fin de validación === passed=$PASSED failed=$FAILED"
fi

exit $( [[ $FAILED -eq 0 ]] && echo 0 || echo 1 )
