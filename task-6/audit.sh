#!/bin/bash

# Скрипт для выделения подозрительных событий из Kubernetes audit.log
# Вывод в формате { "events": { "category": [...] } }
# Сохранение в audit-extract.json
# Использование: ./audit_check.sh <путь_к_audit.log>

AUDIT_LOG="${1:-audit.log}"
OUTPUT_FILE="audit-extract.json"

if [ ! -f "$AUDIT_LOG" ]; then
    echo "{\"error\": \"Файл $AUDIT_LOG не найден!\"}"
    exit 1
fi

# Функция для сбора событий по категории
collect_events() {
    local category="$1"
    local jq_filter="$2"

    jq -c "
        $jq_filter |
        . + {category: \"$category\"}
    " "$AUDIT_LOG" 2>/dev/null
}

# Формируем JSON с категориями и сохраняем в файл
jq -n \
    --argjson secrets_access "$(collect_events "secrets_access" 'select(.objectRef.resource=="secrets" and .verb=="get")' | jq -s '.')" \
    --argjson kubectl_exec "$(collect_events "kubectl_exec" 'select(.verb=="create" and .objectRef.subresource=="exec")' | jq -s '.')" \
    --argjson privileged_pod "$(collect_events "privileged_pod" 'select(.objectRef.resource=="pods" and .verb=="create" and .requestObject.spec.containers[].securityContext.privileged==true)' | jq -s '.')" \
    --argjson audit_policy_change "$(grep -i 'audit-policy' "$AUDIT_LOG" 2>/dev/null | jq -R -s 'split("\n") | map(select(. != "")) | map(fromjson? // {"raw": .}) | map(. + {category: "audit_policy_change"})')" \
    '{
        events: {
            secrets_access: $secrets_access,
            kubectl_exec: $kubectl_exec,
            privileged_pod: $privileged_pod,
            audit_policy_change: $audit_policy_change
        }
    }' > "$OUTPUT_FILE"

# Проверяем результат
if [ -f "$OUTPUT_FILE" ]; then
    echo "Результат сохранен в $OUTPUT_FILE"
    echo "Размер файла: $(du -h "$OUTPUT_FILE" | cut -f1)"

    # Показываем статистику
    echo ""
    echo "Статистика:"
    jq -r '
        .events |
        "secrets_access: \(.secrets_access | length)",
        "kubectl_exec: \(.kubectl_exec | length)",
        "privileged_pod: \(.privileged_pod | length)",
        "audit_policy_change: \(.audit_policy_change | length)"
    ' "$OUTPUT_FILE"
else
    echo "Ошибка при сохранении файла"
fi