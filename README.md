# Umbrel Portainer PID Fix

Para os apps Portainer e Arcane ao subir o sistema, apaga o `docker.pid` do Docker-in-Docker do app e inicia de novo (rodando apenas uma vez na inicialização). Se o app não estiver instalado, ele é ignorado.

Fluxo (por app suportado):
- para/pausa o app (`portainer`, `arcane`)
- remove `/home/umbrel/umbrel/app-data/<app>/data/docker/docker.pid` (e quaisquer `*.pid` no mesmo diretório)
- inicia o app

Cobertura de apps:
- Portainer: `/home/umbrel/umbrel/app-data/portainer/data/docker/docker.pid`
- Arcane: `/home/umbrel/umbrel/app-data/arcane/data/docker/docker.pid`

## Instalação (1 linha)

```bash
curl -fsSL https://raw.githubusercontent.com/sandman21vs/umbrel-portainer-pidfix/refs/heads/main/umbrel-portainer-pidfix/install.sh | sudo bash
```

## Desinstalação

```bash
curl -fsSL https://raw.githubusercontent.com/sandman21vs/umbrel-portainer-pidfix/refs/heads/main/umbrel-portainer-pidfix/uninstall.sh | sudo bash
```
