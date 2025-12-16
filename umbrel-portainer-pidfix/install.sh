# umbrel-portainer-pidfix/install.sh (SUBSTITUA O ARQUIVO INTEIRO)
#!/usr/bin/env bash
set -euo pipefail

REPO_NAME="umbrel-portainer-pidfix"
INSTALL_DIR="/opt/${REPO_NAME}"
BIN_DIR="/usr/local/bin"
SCRIPT_BIN="${BIN_DIR}/umbrel-portainer-pidfix"
UNIT_FILE="/etc/systemd/system/umbrel-portainer-pidfix.service"

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

# Lista de apps e diretórios do Docker-in-Docker que podem deixar docker.pid para trás
APP_PID_DIRS=(
  "portainer:/home/umbrel/umbrel/app-data/portainer/data/docker"
  "arcane:/home/umbrel/umbrel/app-data/arcane/data/docker"
)

log() { echo "[umbrel-portainer-pidfix] $*"; }

stop_app() {
  local app="$1"

  if [[ -x /home/umbrel/umbrel/scripts/app ]]; then
    log "Parando ${app} via scripts/app"
    /home/umbrel/umbrel/scripts/app stop "${app}" || log "Falha ao parar ${app} via scripts/app"
    return
  elif command -v umbreld >/dev/null 2>&1; then
    log "Parando ${app} via umbreld"
    umbreld client apps.stop.mutate --appId "${app}" || log "Falha ao parar ${app} via umbreld"
    return
  else
    local compose="/home/umbrel/umbrel/app-data/${app}/docker-compose.yml"
    if [[ -f "${compose}" ]]; then
      log "Parando ${app} via docker compose"
      (cd "/home/umbrel/umbrel" && docker compose -f "${compose}" stop) || log "Falha ao parar ${app} via docker compose"
    else
      log "Não encontrei método para parar o app ${app}"
    fi
  fi
}

start_app() {
  local app="$1"

  if [[ -x /home/umbrel/umbrel/scripts/app ]]; then
    log "Iniciando ${app} via scripts/app"
    /home/umbrel/umbrel/scripts/app start "${app}" || log "Falha ao iniciar ${app} via scripts/app"
    return
  elif command -v umbreld >/dev/null 2>&1; then
    log "Iniciando ${app} via umbreld"
    umbreld client apps.start.mutate --appId "${app}" || log "Falha ao iniciar ${app} via umbreld"
    return
  else
    local compose="/home/umbrel/umbrel/app-data/${app}/docker-compose.yml"
    if [[ -f "${compose}" ]]; then
      log "Iniciando ${app} via docker compose"
      (cd "/home/umbrel/umbrel" && docker compose -f "${compose}" start) || log "Falha ao iniciar ${app} via docker compose"
    else
      log "Não encontrei método para iniciar o app ${app}"
    fi
  fi
}

cleanup_pid_dir() {
  local app="$1"
  local pid_dir="$2"
  local pid_file="${pid_dir}/docker.pid"

  if [[ ! -d "${pid_dir}" ]]; then
    log "App ${app}: diretório não existe (${pid_dir}), pulando limpeza"
    return
  fi

  if [[ -f "${pid_file}" ]]; then
    log "App ${app}: removendo pid: ${pid_file}"
    rm -f "${pid_file}"
  else
    log "App ${app}: PID padrão não existe (${pid_file})"
  fi

  find "${pid_dir}" -maxdepth 1 -type f -name "*.pid" -print -delete || true
}

process_app() {
  local app="$1"
  local pid_dir="$2"

  if [[ ! -d "${pid_dir}" ]]; then
    log "App ${app}: diretório do Docker não encontrado (${pid_dir}), pulando"
    return
  fi

  log "App ${app}: iniciando correção de PID"
  stop_app "${app}"
  cleanup_pid_dir "${app}" "${pid_dir}"
  start_app "${app}"
}

for entry in "${APP_PID_DIRS[@]}"; do
  IFS=":" read -r app pid_dir <<<"${entry}"
  process_app "${app}" "${pid_dir}"
done

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
Description=Umbrel Portainer PID fix (para, remove docker.pid e inicia Portainer/Arcane)
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
