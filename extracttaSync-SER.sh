#!/usr/bin/env bash
# ExtracttaSync Service Engine Report
MONGO_URI=$1
MODE=$2
HOST=$(hostname)
DATE=$(date +"%Y-%m-%dT%H:%M:%S%z")

get_logs() {
    local path=$1
    [[ -f "$path" ]] && tail -n 10 "$path" | jq -R -s -c --arg d "$DATE" 'split("\n") | map(select(length > 0) | {logTime: $d, message: .})' || echo "[]"
}

gen_json() {
    local svc=$1
    local id=$(systemctl show "$svc" -p Id --value)
    local state=$(systemctl show "$svc" -p ActiveState --value)
    local restarts=$(systemctl show "$svc" -p NRestarts --value) [cite: 5, 12]
    local env_file=$(systemctl cat "$svc" | grep "^EnvironmentFile=" | cut -d'=' -f2 | tr -d '-') [cite: 67]
    local log_p=$(grep "^LOG_FILE=" "$env_file" 2>/dev/null | cut -d'=' -f2 | tr -d '"\r')

    echo "{\"service\": \"${id%.service}\", \"state\": \"$state\", \"restarts\": $restarts, \"logs\": $(get_logs "$log_p")}"
}

# Agregação [cite: 21, 22]
SERVICES=$(systemctl list-units --type=service --all | awk '{print $1}' | grep -E "MongoSync|ExtracttaSync")
JSON="{\"host\": \"$HOST\", \"reportDate\": \"$DATE\", \"services\": ["
first=1
for s in $SERVICES; do
    [[ $first -eq 0 ]] && JSON+=","
    JSON+=$(gen_json "$s")
    first=0
done
JSON+="]}"

# Saídas conforme MODE [cite: 13, 14, 36]
[[ "$MODE" == "S" || "$MODE" == "A" ]] && echo "$JSON" | jq .
[[ "$MODE" == "F" || "$MODE" == "A" ]] && echo "$JSON" > "ExtracttaSync-$HOST-Report.rpt"
[[ "$MODE" == "M" || "$MODE" == "A" ]] && echo "$JSON" | mongosh "$MONGO_URI" --quiet --eval "db.fullServicesReportByHost.insertOne(JSON.parse(stdin.read()))" >/dev/null