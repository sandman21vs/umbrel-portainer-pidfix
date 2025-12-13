# umbrel-portainer-pidfix/install.sh (SUBSTITUA O ARQUIVO INTEIRO)
#!/usr/bin/env bash
set -euo pipefail

REPO_NAME="umbrel-portainer-pidfix"
INSTALL_DIR="/opt/${REPO_NAME}"
BIN_DIR="/usr/local/bin"
SCRIPT_BIN="${BIN_DIR}/umbrel-portainer-pidfix"
UNIT_FILE="/etc/systemd/system/umbrel-portainer-pidfix.service"

# caminho do .pid (ajuste aqui se mudar no futuro)
PID_DIR="/home/umbrel/umbrel/app-data/portainer/data/docker"
PID_FILE="${PID_DIR}/docker.pid"

need_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "Rode como root: sudo $0"
    exit 1
  fi
}

install_files() {
  mkdir -p "${INSTALL_DIR}"
  mkdir -p "${BIN_DIR}"

  cat > "${INSTALL_DIR}/run.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

PID_DIR="/home/umbrel/umbrel/app-data/portainer/data/docker"
PID_FILE="${PID_DIR}/docker.pid"

log() { echo "[umbrel-portainer-pidfix] $*"; }

# 1) apagar pid stale (e qualquer pid parecido, por segurança)
if [[ -d "${PID_DIR}" ]]; then
  if [[ -f "${PID_FILE}" ]]; then
    log "Removendo pid: ${PID_FILE}"
    rm -f "${PID_FILE}"
  else
    log "PID não existe: ${PID_FILE}"
  fi

  # remove outros .pid antigos no mesmo diretório (opcional)
  find "${PID_DIR}" -maxdepth 1 -type f -name "*.pid" -print -delete || true
else
  log "Diretório não existe: ${PID_DIR}"
fi

# 2) reiniciar o app Portainer no Umbrel (compatível com versões diferentes)
if [[ -x /home/umbrel/umbrel/scripts/app ]]; then
  log "Reiniciando Portainer via scripts/app"
  /home/umbrel/umbrel/scripts/app restart portainer || true
elif command -v umbreld >/dev/null 2>&1; then
  log "Reiniciando Portainer via umbreld"
  umbreld client apps.restart.mutate --appId portainer || true
else
  log "Não achei scripts/app nem umbreld. Tentando restart por docker-compose do app (fallback)."
  COMPOSE_YML="/home/umbrel/umbrel/app-data/portainer/docker-compose.yml"
  if [[ -f "${COMPOSE_YML}" ]]; then
    (cd "/home/umbrel/umbrel" && docker compose -f "${COMPOSE_YML}" restart) || true
  else
    log "Fallback falhou: compose não encontrado em ${COMPOSE_YML}"
  fi
fi

log "OK"
EOF

  chmod +x "${INSTALL_DIR}/run.sh"

  cat > "${SCRIPT_BIN}" <<EOF
#!/usr/bin/env bash
exec "${INSTALL_DIR}/run.sh" "\$@"
EOF
  chmod +x "${SCRIPT_BIN}"

  cat > "${UNIT_FILE}" <<EOF
[Unit]
Description=Umbrel Portainer PID fix (remove docker.pid e reinicia Portainer)
After=network-online.target docker.service
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=${SCRIPT_BIN}
TimeoutStartSec=120

[Install]
WantedBy=multi-user.target
EOF
}

enable_service() {
  systemctl daemon-reload
  systemctl enable umbrel-portainer-pidfix.service
}

show_done() {
  echo "Instalado: ${SCRIPT_BIN}"
  echo "Service:  ${UNIT_FILE}"
  echo "Status:   systemctl status umbrel-portainer-pidfix --no-pager"
  echo "Testar:   sudo ${SCRIPT_BIN}"
}

need_root
install_files
enable_service
show_done
