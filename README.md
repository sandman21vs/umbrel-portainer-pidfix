# Umbrel Portainer PID Fix

Para o app Portainer ao subir o sistema, apaga o `docker.pid` do Docker-in-Docker do app e inicia o Portainer de novo (rodando apenas uma vez na inicialização).

Fluxo:
- para/pausa o Portainer
- remove `/home/umbrel/umbrel/app-data/portainer/data/docker/docker.pid` (e quaisquer `*.pid` no mesmo diretório)
- inicia o Portainer

## Instalação (1 linha)

```bash
curl -fsSL https://raw.githubusercontent.com/sandman21vs/umbrel-portainer-pidfix/refs/heads/main/umbrel-portainer-pidfix/install.sh | sudo bash
```

## Desinstalação

```bash
curl -fsSL https://raw.githubusercontent.com/sandman21vs/umbrel-portainer-pidfix/refs/heads/main/umbrel-portainer-pidfix/uninstall.sh | sudo bash
```
