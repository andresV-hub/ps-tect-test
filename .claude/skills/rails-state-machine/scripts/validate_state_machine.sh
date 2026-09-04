#!/usr/bin/env bash
set -euo pipefail

# ---- Help ----
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'EOF'
Uso: validate_state_machine.sh [--json] path/to/model.rb

Valida que un modelo con state machine cumpla los patrones de CLAUDE.md:
  - include AASM
  - include Discard::Model
  - Método available_frontend_events definido
  - Asociación has_many :state_changes presente
  - default_scope presente
  - Columna aasm definida con aasm column:
  - Sin métodos privados

Opciones:
  --json    Salida como JSON estructurado (por defecto: legible)
  --help    Muestra este mensaje

Ejemplos:
  validate_state_machine.sh app/models/order.rb
  validate_state_machine.sh --json app/models/order.rb
  validate_state_machine.sh --json app/models/order.rb | jq '.failed'
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

MODEL_FILE="${ARGS[0]:?Uso: validate_state_machine.sh [--json] path/to/model.rb}"

if [[ ! -f "$MODEL_FILE" ]]; then
  if $JSON_OUTPUT; then
    echo "{\"file\":\"$MODEL_FILE\",\"passed\":0,\"failed\":1,\"checks\":[{\"name\":\"Archivo existe\",\"status\":\"fail\"}]}"
  else
    echo "FALLO: File not found: $MODEL_FILE"
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

$JSON_OUTPUT || echo "=== Validando State Machine: $MODEL_FILE ==="

# ---- Validaciones ----
check "AASM incluido" "$( grep -q "include AASM" "$MODEL_FILE" && echo true || echo false )"
check "Discard incluido" "$( grep -q "include Discard::Model" "$MODEL_FILE" && echo true || echo false )"
check "available_frontend_events definido" "$( grep -q "available_frontend_events" "$MODEL_FILE" && echo true || echo false )"
check "Asociación state_changes presente" "$( grep -q "has_many :state_changes" "$MODEL_FILE" && echo true || echo false )"
check "default_scope presente" "$( grep -q "default_scope" "$MODEL_FILE" && echo true || echo false )"
check_warn "Columna aasm definida" "$( grep -q "aasm column:" "$MODEL_FILE" && echo true || echo false )"
check "Sin métodos privados" "$( grep -qn "^\s*private" "$MODEL_FILE" && echo false || echo true )"

# ---- Output ----
if $JSON_OUTPUT; then
  CHECKS_JSON=$(IFS=,; echo "${CHECKS[*]}")
  echo "{\"file\":\"$MODEL_FILE\",\"passed\":$PASSED,\"failed\":$FAILED,\"checks\":[$CHECKS_JSON]}"
else
  echo "=== Listo === passed=$PASSED failed=$FAILED"
fi

exit $( [[ $FAILED -eq 0 ]] && echo 0 || echo 1 )
