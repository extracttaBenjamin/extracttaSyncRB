#!/usr/bin/env bash
# ExtracttaSyncRB - Distro-Agnostic One-Shot Installer

INSTALL_DIR="/opt/extracttaSyncRB"
LOG_DIR="/opt/extracttaSync/logs"
BIN_PATH="/usr/local/bin/extracttaSyncRB"

# Detecção de Distribuição
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_FAMILY=$ID
else
    echo "Erro: Não foi possível detectar a distribuição."
    exit 1
fi

echo "### Instalando ExtracttaSyncRB em sistema: $OS_FAMILY ###"

# 1. Preparação de Diretórios
sudo mkdir -p "$INSTALL_DIR" "$LOG_DIR"
sudo chown $USER:$USER "$INSTALL_DIR"

# 2. Instalação de Dependências e MongoDB 8.0
install_mongo_repo() {
    case "$OS_FAMILY" in
        ubuntu|debian)
            sudo apt-get update && sudo apt-get install -y gnupg jq git make gcc 
            # Adicionar repo oficial MongoDB 8.0 para APT aqui se necessário
            sudo apt-get install -y mongodb-org
            ;;
        centos|rhel|almalinux|rocky)
            sudo yum install -y jq git make gcc policycoreutils-python-utils selinux-policy-devel 
            sudo tee /etc/yum.repos.d/mongodb-org-8.0.repo <<EOF
[mongodb-org-8.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/9/mongodb-org/8.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-8.0.asc
EOF
            sudo yum install -y mongodb-org 
            ;;
        sles|opensuse*)
            sudo zypper install -y mongodb-org jq git make gcc 
            ;;
    esac
}

read -p "Deseja configurar MongoDB 8.0 local agora? (s/n): " INST_LOCAL
if [[ "$INST_LOCAL" == "s" ]]; then
    install_mongo_repo
    # Executa o setup de Replica Set (baseado no seu setup-and-report.sh)
    bash ./setup-and-report.sh A "rsExtracttaSync" "/opt/mongo" 37017 
    M_URI="mongodb://usrExtracttaSync:EeUSSpgcnr26@127.0.0.1:37017/extrattaSyncCtrl?authSource=admin" [cite: 35, 36]
else
    read -p "Informe a URI do MongoDB remoto: " M_URI
fi

echo "MONGO_URI=\"$M_URI\"" > "$INSTALL_DIR/config.env"

# 3. Instalação Global
sudo cp extracttaSyncRB "$BIN_PATH"
sudo chmod +x "$BIN_PATH"
sudo cp extracttaSync-SER.sh "$INSTALL_DIR/"

echo "Instalação concluída! Comando: extracttaSyncRB"