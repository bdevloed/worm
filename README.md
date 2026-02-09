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
sudo apt install fzf openssh-client docker.io lsof

# macOS
brew install fzf openssh docker lsof
```

Make scripts executable:
```bash
chmod +x tunnel-app.sh container-tunnel-caddy
```

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
3. Creates tunnels with naming: `<service>.<project>.<host>.localhost:<port>`

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
# Creates: http://my-app.dev.example.com.localhost:8890/sparql
```

### Choose Another Service
```bash
./tunnel-app.sh -o my-app
# Select "frontend" from menu
# Creates: http://frontend.my-app.dev.example.com.localhost:8080
```

### Verbose Mode
```bash
./tunnel-app.sh -v -o
# Shows debug information including SSH commands
```

## How It Works

1. **Discovery**: Queries Docker on remote hosts to find running Compose projects
2. **Caching**: Caches project lists for performance (use `--refresh` to update)
3. **Tunneling**: Creates SSH tunnels with local port forwarding
4. **Reverse Proxy**: Configures Caddy to proxy domain names to local ports
5. **Domain Resolution**: Uses `*.localhost` which automatically resolves to 127.0.0.1

## Domain Naming

- **Default mode**: `<project>.<ssh-host>.localhost:8890`
- **Other service mode**: `<service>.<project>.<ssh-host>.localhost:<port>`
- Virtuoso services automatically get `/sparql` suffix

## Requirements

- SSH access to remote hosts (configured in `~/.ssh/config`)
- Docker running on remote hosts with Compose projects
- Local Docker for Caddy reverse proxy
- Ports 8000+ available locally

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
- `docker-compose.yml`: Caddy reverse proxy configuration

## License

MIT
