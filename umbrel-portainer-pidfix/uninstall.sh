# umbrel-portainer-pidfix/uninstall.sh (SUBSTITUA O ARQUIVO INTEIRO)
#!/usr/bin/env bash
set -euo pipefail

REPO_NAME="umbrel-portainer-pidfix"
INSTALL_DIR="/opt/${REPO_NAME}"
SCRIPT_BIN="/usr/local/bin/umbrel-portainer-pidfix"
UNIT_FILE="/etc/systemd/system/umbrel-portainer-pidfix.service"

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Rode como root: sudo $0"
  exit 1
fi

systemctl disable --now umbrel-portainer-pidfix.service 2>/dev/null || true
rm -f "${UNIT_FILE}" || true
systemctl daemon-reload || true

rm -f "${SCRIPT_BIN}" || true
rm -rf "${INSTALL_DIR}" || true

echo "Removido."
