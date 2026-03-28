#!/usr/bin/env bash
# ExtracttaSync Service Engine Report (Distro-Agnostic)

MONGO_URI=$1
MODE=$2
HOST=$(hostname)
DATE=$(date +"%Y-%m-%dT%H:%M:%S%z")

get_logs() {
    local p=$1
    [[ -f "$p" ]] && tail -n 10 "$p" | jq -R -s -c --arg d "$DATE" 'split("\n") | map(select(length > 0) | {logTime: $d, message: .})' || echo "[]"
}

gen_json() {
    local svc=$1
    # Captura agnóstica via systemctl show [cite: 3, 4, 5]
    local id=$(systemctl show "$svc" -p Id --value)
    local state=$(systemctl show "$svc" -p ActiveState --value)
    local sub=$(systemctl show "$svc" -p SubState --value)
    local restarts=$(systemctl show "$svc" -p NRestarts --value) [cite: 19]
    
    # Busca o arquivo de log no EnvironmentFile [cite: 67]
    local env_f=$(systemctl cat "$svc" | grep "^EnvironmentFile=" | cut -d'=' -f2 | tr -d '-')
    local log_p=$(grep "^LOG_FILE=" "$env_f" 2>/dev/null | cut -d'=' -f2 | tr -d '"\r')

    echo "{\"service\": \"${id%.service}\", \"state\": \"$state($sub)\", \"restarts\": $restarts, \"logs\": $(get_logs "$log_p")}"
}

SERVICES=$(systemctl list-units --type=service --all | awk '{print $1}' | grep -E "MongoSync|ExtracttaSync") [cite: 2, 21]

JSON="{\"host\": \"$HOST\", \"reportDate\": \"$DATE\", \"services\": ["
first=1
for s in $SERVICES; do
    [[ $first -eq 0 ]] && JSON+=","
    JSON+=$(gen_json "$s")
    first=0
done
JSON+="]}"

# Saídas [cite: 13, 14, 16]
[[ "$MODE" == "S" || "$MODE" == "A" ]] && echo "$JSON" | jq .
[[ "$MODE" == "F" || "$MODE" == "A" ]] && echo "$JSON" > "ExtracttaSync-$HOST-Report.rpt"
[[ "$MODE" == "M" || "$MODE" == "A" ]] && echo "$JSON" | mongosh "$MONGO_URI" --quiet --eval "db.fullServicesReportByHost.insertOne(JSON.parse(stdin.read()))" >/dev/null [cite: 36]