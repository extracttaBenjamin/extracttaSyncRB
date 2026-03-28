# 1. Setup do Repositório e Pastas
rm -rf ~/extracttaSyncRPT && mkdir -p ~/extracttaSyncRPT/{src,config,output,data}
cd ~/extracttaSyncRPT && git init

# 2. Criando o Arquivo de Configuração Padrão (Exemplo)
cat << 'EOF' > config/settings.conf
# Configurações extracttaSyncRPT
APP_NAME="extracttaSyncRPT"
VERSION="1.1.0"

# Caminhos
OUTPUT_DIR="$HOME/extracttaSyncRPT/output"
DB_NAME="extractta_db"
COLLECTION="reports"

# Flags de Saída (true/false)
OUT_SCREEN=true
OUT_FILE=true
OUT_JSON_MONGO=true
EOF

# 3. Criando o Motor de Extração (Lógica de Formatação)
cat << 'EOF' > src/engine.sh
#!/bin/bash
source "$HOME/extracttaSyncRPT/config/settings.conf"

# Dados simulados (Poderia ser um SQL ou Log aqui)
ID="EXP-$(date +%s)"
TS=$(date +'%Y-%m-%dT%H:%M:%SZ')
STATUS="SUCCESS"
DATA_VAL="1500.50"

# --- FORMATO 1: TELA (REPORT) ---
if [ "$OUT_SCREEN" = true ]; then
    echo -e "\n--- [REPORT: $APP_NAME] ---"
    echo "ID: $ID"
    echo "TIMESTAMP: $TS"
    echo "STATUS: $STATUS"
    echo "VALOR: $DATA_VAL"
    echo "---------------------------\n"
fi

# --- FORMATO 2: ARQUIVO (TXT/LOG) ---
if [ "$OUT_FILE" = true ]; then
    FILE_PATH="$OUTPUT_DIR/report_$(date +%Y%m%d).txt"
    echo "[$TS] ID:$ID | STATUS:$STATUS | VALOR:$DATA_VAL" >> "$FILE_PATH"
    echo "💾 Salvo em Arquivo: $FILE_PATH"
fi

# --- FORMATO 3: JSON (MONGODB) ---
if [ "$OUT_JSON_MONGO" = true ]; then
    JSON_PATH="$OUTPUT_DIR/mongo_import_$(date +%s).json"
    cat << JEOF > "$JSON_PATH"
{
  "report_id": "$ID",
  "timestamp": { "\$date": "$TS" },
  "status": "$STATUS",
  "payload": {
    "value": $DATA_VAL,
    "source": "extractta-sync-service"
  }
}
JEOF
    echo "📋 JSON para MongoDB gerado: $JSON_PATH"
    echo "💡 Dica: mongoimport --db $DB_NAME --collection $COLLECTION --file $JSON_PATH"
fi
EOF

# 4. Criando o Executável Global
cat << 'EOF' > extracttaSyncRPT
#!/bin/bash
# Ponto de entrada que chama o motor
bash "$HOME/extracttaSyncRPT/src/engine.sh"
EOF

# 5. Finalização, Permissões e Git
chmod +x extracttaSyncRPT src/engine.sh
sudo cp extracttaSyncRPT /usr/local/bin/
git add .
git commit -m "Add multi-format support: Screen, File and JSON for MongoDB"

echo -e "\n🔥 Instalação finalizada! Comando: 'extracttaSyncRPT'"