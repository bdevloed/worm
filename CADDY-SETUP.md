# Worm with Caddy Reverse Proxy

Access your remote Docker containers via clean domain aliases like `myapp.server1.local` (no port numbers needed!)

## Features

- **Clean URLs**: Access tunnels via `http://project.host.local` instead of `localhost:8892`
- **Auto port allocation**: No manual port management
- **Caddy reverse proxy**: Runs in Docker, auto-reloads configuration
- **Multiple tunnels**: Run multiple tunnels simultaneously with unique domains

## Setup

### 1. First-time setup

```bash
# Start Caddy (happens automatically on first tunnel)
docker compose up -d
```

### 2. Create a tunnel

```bash
# Interactive selection
./tunnel-app.sh

# Direct selection with search
./tunnel-app.sh myproject

# Specify container (default: virtuoso)
./tunnel-app.sh -c api myproject

# Specify remote port (default: 8890)
./tunnel-app.sh --ports 0:3000 myproject
```

### 3. Access your service

Open browser to: `http://myproject.server1.local`

No port number needed! 🎉

## How It Works

1. Script finds available local port (e.g., 8891)
2. Opens SSH tunnel: `localhost:8891` → `remote-container-ip:8890`
3. Updates `/etc/hosts`: `127.0.0.1 myproject.server1.local`
4. Updates Caddy config: `myproject.server1.local` → `localhost:8891`
5. Caddy reloads automatically

## Commands

```bash
# List active tunnels
./list-tunnels

# Stop Caddy
docker compose down

# View Caddy logs
docker compose logs -f caddy
```

## Cleanup

When you press `Ctrl+C` on a tunnel:
- SSH tunnel closes
- `/etc/hosts` entry removed
- Caddy config updated
- Port freed

## Troubleshooting

### Caddy not starting
```bash
docker compose logs caddy
```

### Domain not resolving
```bash
# Check /etc/hosts
grep worm /etc/hosts

# Verify Caddy is running
docker ps | grep worm-caddy
```

### Can't access URL
```bash
# Check tunnel is active
./list-tunnels

# Test port directly
curl localhost:8891  # Use your actual port

# Check Caddy config
docker exec worm-caddy caddy config
```

## Notes

- Requires sudo for `/etc/hosts` updates (prompted once per tunnel)
- Caddy runs on ports 80 (HTTP) - ensure they're available
- Domain format: `<project>.<ssh-host>.local`
