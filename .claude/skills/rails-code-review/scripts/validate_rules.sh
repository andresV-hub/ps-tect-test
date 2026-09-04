#!/usr/bin/env bash
set -euo pipefail

# ---- Help ----
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'EOF'
Uso: validate_rules.sh [--json] [directory]

Valida un proyecto Rails contra las reglas de CLAUDE.md buscando violaciones
en el código fuente:
  1. ActiveRecord directo en controladores
  2. Métodos privados en servicios
  3. Scopes personalizados en modelos
  4. Modelos sin include Discard::Model
  5. State machines sin available_frontend_events
  6. Strings hardcoded en vistas

Argumentos:
  directory  Raíz del proyecto Rails (por defecto: directorio actual)

Opciones:
  --json    Salida como JSON estructurado (por defecto: legible con colores)
  --help    Muestra este mensaje

Ejemplos:
  validate_rules.sh
  validate_rules.sh /path/to/rails/app
  validate_rules.sh --json .
  validate_rules.sh --json . | jq '.failed'
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

TARGET="${ARGS[0]:-.}"
APP_DIR="${TARGET}/app"

# ---- Color helpers (no-op in JSON mode) ----
red()    { $JSON_OUTPUT || printf '\033[0;31m%s\033[0m\n' "$*"; }
yellow() { $JSON_OUTPUT || printf '\033[0;33m%s\033[0m\n' "$*"; }
green()  { $JSON_OUTPUT || printf '\033[0;32m%s\033[0m\n' "$*"; }
info()   { $JSON_OUTPUT || printf '==> %s\n' "$*"; }

if [ ! -d "${APP_DIR}" ]; then
  if $JSON_OUTPUT; then
    echo "{\"target\":\"$TARGET\",\"passed\":0,\"failed\":1,\"checks\":[{\"name\":\"Directorio app existe\",\"status\":\"fail\"}]}"
  else
    red "ERROR: '${APP_DIR}' no encontrado. Pasa la raíz del proyecto Rails como primer argumento."
  fi
  exit 2
fi

# ---- Check helpers ----
PASSED=0
FAILED=0
CHECKS=()

# check: pass when no matches (violations absent)
check_no_matches() {
  local name="$1"
  local matches="$2"
  local is_warning="${3:-false}"
  if [[ -z "$matches" ]]; then
    PASSED=$((PASSED + 1))
    CHECKS+=("{\"name\":\"$name\",\"status\":\"pass\"}")
    green "  OK: $name"
  else
    if [[ "$is_warning" == "true" ]]; then
      PASSED=$((PASSED + 1))
      CHECKS+=("{\"name\":\"$name\",\"status\":\"warn\"}")
      yellow "  WARNING: $name"
      $JSON_OUTPUT || echo "$matches" | sed 's/^/    /'
    else
      FAILED=$((FAILED + 1))
      CHECKS+=("{\"name\":\"$name\",\"status\":\"fail\"}")
      red "  VIOLATION: $name"
      $JSON_OUTPUT || echo "$matches" | sed 's/^/    /'
    fi
  fi
  $JSON_OUTPUT || echo ""
}

$JSON_OUTPUT || { echo ""; echo "Validación de reglas CLAUDE.md de Rails"; echo "Destino: ${TARGET}"; echo "========================================"; echo ""; }

# ---- 1. ActiveRecord directo en controladores ----
info "Comprobando: ActiveRecord directo en controladores..."
MATCHES=$(grep -rn "User\.find\|User\.where\|User\.all\|\.find(\|\.where(\|\.all\b" "${APP_DIR}/controllers/" 2>/dev/null || true)
check_no_matches "Sin ActiveRecord directo en controladores" "$MATCHES"

# ---- 2. Métodos privados en servicios ----
info "Comprobando: Métodos privados en servicios..."
MATCHES=$(grep -rn "^  private$" "${APP_DIR}/services/" 2>/dev/null || true)
check_no_matches "Sin métodos privados en servicios" "$MATCHES"

# ---- 3. Scopes personalizados en modelos ----
info "Comprobando: Scopes personalizados en modelos..."
MATCHES=$(grep -rn "scope :" "${APP_DIR}/models/" 2>/dev/null | grep -v "default_scope" || true)
check_no_matches "Sin scopes personalizados en modelos" "$MATCHES"

# ---- 4. Modelos sin Discard ----
info "Comprobando: Modelos sin include Discard::Model..."
MISSING=$(grep -rL "include Discard::Model" "${APP_DIR}/models/"*.rb 2>/dev/null || true)
check_no_matches "Todos los modelos incluyen Discard::Model" "$MISSING" "true"

# ---- 5. State Machines sin available_frontend_events ----
info "Comprobando: State Machines sin available_frontend_events..."
AASM_FILES=$(grep -rl "include AASM" "${APP_DIR}/models/"*.rb 2>/dev/null || true)
if [[ -n "$AASM_FILES" ]]; then
  MISSING_EVENTS=$(grep -L "def available_frontend_events" $AASM_FILES 2>/dev/null || true)
  check_no_matches "Todos los modelos AASM tienen available_frontend_events" "$MISSING_EVENTS"
else
  PASSED=$((PASSED + 1))
  CHECKS+=("{\"name\":\"Todos los modelos AASM tienen available_frontend_events\",\"status\":\"pass\"}")
  green "  OK: No se encontraron modelos AASM"
  $JSON_OUTPUT || echo ""
fi

# ---- 6. Strings hardcoded en vistas ----
info "Comprobando: Strings hardcoded en vistas..."
MATCHES=$(grep -rn '"[A-Z]' "${APP_DIR}/views/" 2>/dev/null | grep -v "I18n\|t(\|human_attribute_name" || true)
check_no_matches "Sin strings hardcoded en vistas" "$MATCHES" "true"

# ---- Output ----
if $JSON_OUTPUT; then
  CHECKS_JSON=$(IFS=,; echo "${CHECKS[*]}")
  echo "{\"target\":\"$TARGET\",\"passed\":$PASSED,\"failed\":$FAILED,\"checks\":[$CHECKS_JSON]}"
else
  echo "================================"
  if [[ "$FAILED" -eq 0 ]]; then
    green "Todas las comprobaciones pasaron (0 violaciones)"
  else
    red "${FAILED} violación(es) encontrada(s) - revisa la salida anterior"
  fi
fi

exit $( [[ $FAILED -eq 0 ]] && echo 0 || echo 1 )
