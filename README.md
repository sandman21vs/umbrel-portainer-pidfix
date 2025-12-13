
# Umbrel Portainer PID Fix

Remove o arquivo `docker.pid` do Docker-in-Docker do app Portainer no Umbrel e reinicia o Portainer **uma vez na inicialização**.

Caminho do pid (padrão):
- `/home/umbrel/umbrel/app-data/portainer/data/docker/docker.pid`

## Instalação (1 linha)

> Substitua `SEU_USUARIO/SEU_REPO` pelo seu repositório.

```bash
curl -fsSL https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPO/main/install.sh | sudo bash
