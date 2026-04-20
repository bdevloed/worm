# Worm - SSH Tunnel Manager with Caddy Reverse Proxy

A tool to create SSH tunnels to Docker Compose containers with automatic Caddy reverse proxy setup, using `*.localhost` domains.

Inspired by/built upon [kobemertens/worm](https://github.com/kobemertens/worm). This was also a vibe code experimemt. Issues/pr's welcome.

## Features

- 🔌 SSH tunnels to remote Docker containers
- 🌐 Automatic domain aliases using `*.localhost` (no `/etc/hosts` editing needed)
- 🔄 Caddy reverse proxy for clean HTTP access
- 🎯 Interactive service selection with fzf
- 📦 Works with Docker Compose projects
- 🚀 Discovers projects automatically from running containers

## Installation

Install dependencies:
```bash
# Ubuntu/Debian
sudo apt install fzf openssh-client docker.io

# macOS
brew install fzf openssh docker
```

Make scripts executable:
```bash
chmod +x tunnel-app.sh container-tunnel-caddy list-tunnels
```

Caddy starts automatically the first time you open a tunnel. **Don't run `docker compose up -d` directly** — the Caddy container bind-mounts `~/.cache/worm/sockets/`, and if Docker creates that directory first it will be owned by `root` and the script won't be able to write sockets into it. Always use `./tunnel-app.sh` (which creates the directory first).

## Usage

### Interactive Mode (No Arguments)

```bash
./tunnel-app.sh
```

Shows an fzf menu to select from all available Docker Compose projects across all SSH hosts.

### Search/Filter Mode

```bash
./tunnel-app.sh contactgegevens
```

Auto-selects if only one match, otherwise shows filtered fzf menu.

### Choose Service Mode (`-o`)

```bash
./tunnel-app.sh -o
```

1. Select a project
2. Select a service from that project
3. Creates tunnels with naming: `<service>.<project>.<host>.localhost`

### Options

- `-o, --other`: Choose a specific service interactively
- `-v, --verbose`: Enable verbose logging
- `-r PORT`: Specify remote port (default: 8890)
- `--refresh`: Refresh project cache
- `-h`: Show help

## Examples

### Default (Virtuoso)
```bash
./tunnel-app.sh my-app
# Creates: http://my-app.dev.example.com.localhost/sparql
```

### Choose Another Service
```bash
./tunnel-app.sh -o my-app
# Select "frontend" from menu
# Creates: http://frontend.my-app.dev.example.com.localhost
```

### Verbose Mode
```bash
./tunnel-app.sh -v -o
# Shows debug information including SSH commands
```

## How It Works

1. **Discovery**: Queries Docker on remote hosts to find running Compose projects
2. **Caching**: Caches project lists for performance (use `--refresh` to update)
3. **Tunneling**: Opens `ssh -L <unix-socket>:<container>:<port>` per service — each tunnel binds to a Unix domain socket under `~/.cache/worm/sockets/`, not a TCP port. Nothing on `localhost:<port>` is reachable, so the only way in is through Caddy.
4. **Reverse Proxy**: Generates a `Caddyfile` with one `<domain>:80 { reverse_proxy unix//sockets/<domain>.sock }` block per tunnel and hot-reloads Caddy via its admin API.
5. **Domain Resolution**: Uses `*.localhost` which automatically resolves to 127.0.0.1.

## Domain Naming

- **Default mode**: `<project>.<ssh-host>.localhost`
- **Other service mode**: `<service>.<project>.<ssh-host>.localhost`
- Virtuoso services automatically get `/sparql` suffix

All URLs are served on port 80 by Caddy — no port suffix needed.

## Requirements

- SSH access to remote hosts (configured in `~/.ssh/config`)
- Docker running on remote hosts with Compose projects
- Local Docker for Caddy reverse proxy
- Port 80 available locally (for Caddy)

## Troubleshooting

### No projects found
```bash
./tunnel-app.sh --refresh
```

### Connection refused
Check if Caddy is running:
```bash
docker ps | grep worm-caddy
```

### SSH key issues
Ensure your SSH keys are properly configured in `~/.ssh/config`

## Files

- `tunnel-app.sh`: Main entry point, handles project selection
- `container-tunnel-caddy`: Core tunneling logic with Caddy integration
- `list-tunnels`: Show active tunnels and prune stale state
- `docker-compose.yml`: Caddy reverse proxy configuration (base)
- `docker-compose.macos.yml`: macOS overlay (bridge network + port mappings)

## License

MIT
