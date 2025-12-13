
# Umbrel Portainer PID Fix

Remove o arquivo `docker.pid` do Docker-in-Docker do app Portainer no Umbrel e reinicia o Portainer **uma vez na inicialização**.

Caminho do pid (padrão):
- `/home/umbrel/umbrel/app-data/portainer/data/docker/docker.pid`

## Instalação (1 linha)


```bash
curl -fsSL https://raw.githubusercontent.com/sandman21vs/umbrel-portainer-pidfix/main/install.sh | sudo bash
