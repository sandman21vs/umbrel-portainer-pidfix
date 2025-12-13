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

stop_portainer() {
  if [[ -x /home/umbrel/umbrel/scripts/app ]]; then
    log "Parando Portainer via scripts/app"
    /home/umbrel/umbrel/scripts/app stop portainer || log "Falha ao parar via scripts/app"
  elif command -v umbreld >/dev/null 2>&1; then
    log "Parando Portainer via umbreld"
    umbreld client apps.stop.mutate --appId portainer || log "Falha ao parar via umbreld"
  else
    local compose="/home/umbrel/umbrel/app-data/portainer/docker-compose.yml"
    if [[ -f "${compose}" ]]; then
      log "Parando Portainer via docker compose"
      (cd "/home/umbrel/umbrel" && docker compose -f "${compose}" stop) || log "Falha ao parar via docker compose"
    else
      log "Não encontrei método para parar o Portainer"
    fi
  fi
}

start_portainer() {
  if [[ -x /home/umbrel/umbrel/scripts/app ]]; then
    log "Iniciando Portainer via scripts/app"
    /home/umbrel/umbrel/scripts/app start portainer || log "Falha ao iniciar via scripts/app"
  elif command -v umbreld >/dev/null 2>&1; then
    log "Iniciando Portainer via umbreld"
    umbreld client apps.start.mutate --appId portainer || log "Falha ao iniciar via umbreld"
  else
    local compose="/home/umbrel/umbrel/app-data/portainer/docker-compose.yml"
    if [[ -f "${compose}" ]]; then
      log "Iniciando Portainer via docker compose"
      (cd "/home/umbrel/umbrel" && docker compose -f "${compose}" start) || log "Falha ao iniciar via docker compose"
    else
      log "Não encontrei método para iniciar o Portainer"
    fi
  fi
}

remove_pid() {
  if [[ -d "${PID_DIR}" ]]; then
    if [[ -f "${PID_FILE}" ]]; then
      log "Removendo pid: ${PID_FILE}"
      rm -f "${PID_FILE}"
    else
      log "PID não existe: ${PID_FILE}"
    fi

    find "${PID_DIR}" -maxdepth 1 -type f -name "*.pid" -print -delete || true
  else
    log "Diretório não existe: ${PID_DIR}"
  fi
}

stop_portainer
remove_pid
start_portainer

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
Description=Umbrel Portainer PID fix (para, remove docker.pid e inicia Portainer)
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
