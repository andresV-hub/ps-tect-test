#!/usr/bin/env bash
set -euo pipefail

# ---- Help ----
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'EOF'
Uso: run_and_summarize.sh [--json] spec/path

Ejecuta rspec sobre la ruta indicada y muestra un resumen de resultados.
El exit code refleja si hay fallos (1) o todo pasa (0).

Argumentos:
  spec/path  Ruta al spec file o directorio a ejecutar

Opciones:
  --json    Salida como JSON estructurado con ejemplos, fallos y estado
            (por defecto: legible con output completo de rspec)
  --help    Muestra este mensaje

Ejemplos:
  run_and_summarize.sh spec/models/category_spec.rb
  run_and_summarize.sh spec/services/categories/
  run_and_summarize.sh --json spec/models/category_spec.rb
  run_and_summarize.sh --json spec/models/category_spec.rb | jq '.failed'
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

SPEC_PATH="${ARGS[0]:?Uso: run_and_summarize.sh [--json] spec/path}"

# ---- Ejecutar rspec ----
$JSON_OUTPUT || echo "=== Ejecutando: bundle exec rspec $SPEC_PATH ==="
OUTPUT=$(bundle exec rspec "$SPEC_PATH" --format documentation 2>&1) || true
RSPEC_EXIT=$?

# ---- Parsear resultados ----
EXAMPLES=$(echo "$OUTPUT" | grep -oP '\d+(?= example)' | tail -1 || echo "0")
FAILURES=$(echo "$OUTPUT" | grep -oP '\d+(?= failure)' | tail -1 || echo "0")
PENDING=$(echo "$OUTPUT" | grep -oP '\d+(?= pending)' | tail -1 || echo "0")

# Fallback: contar líneas FAILED si el formato es distinto
if [[ "$FAILURES" == "0" ]]; then
  FAILURES=$(echo "$OUTPUT" | grep -c "FAILED\|Failure/Error" || true)
fi

PASSED=$((${EXAMPLES:-0} - ${FAILURES:-0} - ${PENDING:-0}))
[[ $PASSED -lt 0 ]] && PASSED=0

STATUS="pass"
[[ "$FAILURES" -gt 0 ]] && STATUS="fail"

# ---- Output ----
if $JSON_OUTPUT; then
  # Extraer nombres de tests fallidos
  FAILED_TESTS=()
  while IFS= read -r line; do
    if echo "$line" | grep -qP "^\s+\d+\)"; then
      test_name=$(echo "$line" | sed 's/^\s*[0-9]*)\s*//')
      escaped=$(echo "$test_name" | sed 's/"/\\"/g')
      FAILED_TESTS+=("\"$escaped\"")
    fi
  done <<< "$OUTPUT"

  FAILED_JSON=$(IFS=,; echo "${FAILED_TESTS[*]:-}")
  echo "{\"spec_path\":\"$SPEC_PATH\",\"status\":\"$STATUS\",\"examples\":${EXAMPLES:-0},\"passed\":$PASSED,\"failed\":${FAILURES:-0},\"pending\":${PENDING:-0},\"failed_tests\":[$FAILED_JSON]}"
else
  echo "$OUTPUT"
  echo ""
  echo "=== Resumen ==="
  echo "$OUTPUT" | tail -5
  echo "Total de fallos detectados: $FAILURES"
fi

exit $( [[ ${FAILURES:-0} -eq 0 ]] && echo 0 || echo 1 )
