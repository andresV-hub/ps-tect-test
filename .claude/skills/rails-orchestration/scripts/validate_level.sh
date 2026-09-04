#!/usr/bin/env bash
set -euo pipefail

# ---- Help ----
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'EOF'
Uso: validate_level.sh [--json] file1 [file2 ...]

Valida que todos los archivos de un nivel de orquestación existen en disco.
Se usa entre niveles para verificar que el nivel anterior está completo
antes de continuar al siguiente.

Argumentos:
  file1 ...  Lista de rutas de archivo a verificar (relativas o absolutas)

Opciones:
  --json    Salida como JSON estructurado (por defecto: legible)
  --help    Muestra este mensaje

Ejemplos:
  validate_level.sh app/models/category.rb app/services/categories/create.rb
  validate_level.sh --json app/models/category.rb app/policies/category_policy.rb
  validate_level.sh --json app/models/category.rb | jq '.failed'
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

if [[ ${#ARGS[@]} -eq 0 ]]; then
  echo "Uso: validate_level.sh [--json] file1 [file2 ...]" >&2
  exit 2
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
    $JSON_OUTPUT || echo "FALTA: $name"
  fi
}

$JSON_OUTPUT || echo "=== Validación de Nivel ==="

# ---- Verificar cada archivo ----
for file in "${ARGS[@]}"; do
  check "$file" "$( [[ -f "$file" ]] && echo true || echo false )"
done

# ---- Output ----
if $JSON_OUTPUT; then
  CHECKS_JSON=$(IFS=,; echo "${CHECKS[*]}")
  echo "{\"passed\":$PASSED,\"failed\":$FAILED,\"checks\":[$CHECKS_JSON]}"
else
  echo ""
  if [[ $FAILED -eq 0 ]]; then
    echo "Todos los archivos presentes. Es seguro continuar al siguiente nivel."
  else
    echo "$FAILED archivos faltan — NO continuar al siguiente nivel"
  fi
fi

exit $( [[ $FAILED -eq 0 ]] && echo 0 || echo 1 )
