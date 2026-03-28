#!/usr/bin/env bash
# ExtracttaSyncRB - One-Shot Installer

INSTALL_DIR="/opt/extracttaSyncRB"
LOG_DIR="/opt/extracttaSync/logs"
BIN_PATH="/usr/local/bin/extracttaSyncRB"

echo "--- Instalando ExtracttaSyncRB ---"
sudo mkdir -p "$INSTALL_DIR" "$LOG_DIR"
sudo chown $USER:$USER "$INSTALL_DIR"

# Configuração do MongoDB [cite: 35, 36]
read -p "Instalar MongoDB 8.0 local agora? (s/n): " INST_LOCAL
if [[ "$INST_LOCAL" == "s" ]]; then
    # Executa o setup padrão (ajuste os parâmetros conforme sua necessidade)
    bash ./setup-and-report.sh A "rsExtracttaSync" "/opt/mongo" 37017 [cite: 26]
    M_URI="mongodb://usrExtracttaSync:EeUSSpgcnr26@127.0.0.1:37017/extrattaSyncCtrl?authSource=admin"
else
    read -p "Informe a URI do MongoDB (com permissão readWrite): " M_URI
fi

echo "MONGO_URI=\"$M_URI\"" > "$INSTALL_DIR/config.env"

# Instalação do Binário Global
sudo cp extracttaSyncRB "$BIN_PATH"
sudo chmod +x "$BIN_PATH"
sudo cp extracttaSync-SER.sh "$INSTALL_DIR/"

# Configuração de Logrotate [cite: 34]
sudo tee /etc/logrotate.d/extracttasyncrb <<EOF
$LOG_DIR/ExtracttaSyncReport.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
}
EOF

echo "Instalação concluída! Use o comando: extracttaSyncRB"