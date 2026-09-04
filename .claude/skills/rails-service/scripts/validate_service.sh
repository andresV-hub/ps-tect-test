#!/usr/bin/env bash
set -euo pipefail

# ---- Help ----
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'EOF'
Uso: validate_service.sh [--json] path/to/service.rb

Valida que un servicio Rails cumpla los patrones de CLAUDE.md:
  - Hereda de BaseService o Base::Search
  - Implementa service_execute
  - No contiene métodos privados
  - Retorna el objeto
  - Servicios create/update usan sin bang (no create!/update!)

Opciones:
  --json    Salida como JSON estructurado (por defecto: legible)
  --help    Muestra este mensaje

Ejemplos:
  validate_service.sh app/services/categories/create.rb
  validate_service.sh --json app/services/categories/create.rb
  validate_service.sh --json app/services/categories/create.rb | jq '.failed'
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

FILE="${ARGS[0]:?Uso: validate_service.sh [--json] path/to/service.rb}"

if [[ ! -f "$FILE" ]]; then
  if $JSON_OUTPUT; then
    echo "{\"file\":\"$FILE\",\"passed\":0,\"failed\":1,\"checks\":[{\"name\":\"Archivo existe\",\"status\":\"fail\"}]}"
  else
    echo "FALLO: File not found: $FILE"
  fi
  exit 1
fi

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
    $JSON_OUTPUT || echo "OK: $name"
  else
    FAILED=$((FAILED + 1))
    CHECKS+=("{\"name\":\"$name\",\"status\":\"fail\"}")
    $JSON_OUTPUT || echo "FALLO: $name"
  fi
}

check_warn() {
  local name="$1"
  local result="$2"
  if [[ "$result" == "true" ]]; then
    PASSED=$((PASSED + 1))
    CHECKS+=("{\"name\":\"$name\",\"status\":\"pass\"}")
    $JSON_OUTPUT || echo "OK: $name"
  else
    PASSED=$((PASSED + 1))
    CHECKS+=("{\"name\":\"$name\",\"status\":\"warn\"}")
    $JSON_OUTPUT || echo "AVISO: $name"
  fi
}

$JSON_OUTPUT || echo "=== Validando Servicio: $FILE ==="

# ---- Validaciones ----
herencia=$(grep -q "< BaseService\|< Base::Search" "$FILE" && echo true || echo false)
check "Hereda de BaseService/Base::Search" "$herencia"

service_execute=$(grep -q "def service_execute" "$FILE" && echo true || echo false)
check_warn "Implementa service_execute (ok si es Base::Search/Find/Discard)" "$service_execute"

no_private=$(grep -qn "^\s*private" "$FILE" && echo false || echo true)
check "Sin métodos privados" "$no_private"

retorna_objeto=$(grep -q "return\|^\s*@" "$FILE" && echo true || echo false)
check_warn "Retorna objeto" "$retorna_objeto"

basename_file=$(basename "$FILE" .rb)
if [[ "$basename_file" == "create" || "$basename_file" == "update" ]]; then
  no_bang=$(grep -q "create!\|update!" "$FILE" && echo false || echo true)
  check_warn "Servicio de formulario usa sin bang" "$no_bang"
fi

# ---- Output ----
if $JSON_OUTPUT; then
  CHECKS_JSON=$(IFS=,; echo "${CHECKS[*]}")
  echo "{\"file\":\"$FILE\",\"passed\":$PASSED,\"failed\":$FAILED,\"checks\":[$CHECKS_JSON]}"
else
  echo "=== Listo === passed=$PASSED failed=$FAILED"
fi

exit $( [[ $FAILED -eq 0 ]] && echo 0 || echo 1 )
