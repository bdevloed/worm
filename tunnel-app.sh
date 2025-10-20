#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="${HOME}/.cache/worm"
mkdir -p "$CACHE_DIR"

REFRESH=false
SEARCH=""
PORTS=""
P_ARG=""
R_ARG=""
V_ARG=""
O_ARG=""
CONTAINER=""

IGNORE_FILE="${SCRIPT_DIR}/ignore-hosts.txt"

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --refresh)
      REFRESH=true
      shift
      ;;
    -o|--other)
      O_ARG="-o"
      shift
      ;;
    -v|--verbose)
      V_ARG="-v"
      shift
      ;;
    -p|--ports)
      PORTS="$2"
      shift 2
      ;;
    -c|--container)
      CONTAINER="$2"
      shift 2
      ;;
    *)
      SEARCH="$1"
      shift
      ;;
  esac
done

# Handle ports if given
if [[ -n "$PORTS" ]]; then
  P_ARG="-p ${PORTS%%:*}"
  R_ARG="-r ${PORTS##*:}"
fi

# --- Collect hosts from SSH config ---
ALL_HOSTS=($(grep -E '^Host ' ~/.ssh/config | awk '{print $2}'))

# Remove ignored hosts if ignore file exists
if [[ -f "$IGNORE_FILE" ]]; then
  IGNORED=($(<"$IGNORE_FILE"))
  for ignore in "${IGNORED[@]}"; do
    ALL_HOSTS=("${ALL_HOSTS[@]/$ignore}")
  done
fi

# --- Step 1: Select host (single select) ---
if command -v fzf >/dev/null 2>&1; then
  selected_host=$(printf "%s\n" "${ALL_HOSTS[@]}" | fzf --prompt="Select host > " --height=40%)
else
  echo "Available hosts:"
  printf "  %s\n" "${ALL_HOSTS[@]}"
  echo ""
  read -p "Enter host name: " selected_host
fi

if [[ -z "$selected_host" ]]; then
  echo "No host selected, exiting."
  exit 0
fi

echo "Selected host: $selected_host"
echo ""

# --- Step 2: Fetch or use cached projects for selected host ---
cache_file="${CACHE_DIR}/${selected_host}.txt"

if [[ "$REFRESH" == true || ! -f "$cache_file" ]]; then
  echo "Fetching Docker Compose projects from $selected_host..."
  # Get all unique Docker Compose project names from running containers
  projects=$(ssh -n "$selected_host" "docker ps --filter 'label=com.docker.compose.project' --format '{{.Label \"com.docker.compose.project\"}}' 2>/dev/null | sort -u" || true)

  if [[ -z "$projects" ]]; then
    echo "No Docker Compose projects found on $selected_host"
    exit 1
  fi

  echo "$projects" > "$cache_file"
  echo "Cached projects for $selected_host"
  echo ""
else
  echo "Using cached projects for $selected_host"
  projects=$(<"$cache_file")
  echo ""
fi

# --- Step 3: Build project options ---
options=()
for project in $projects; do
  [[ -z "$project" ]] && continue
  options+=("$project")
done

# Apply search filter if provided
if [[ -n "$SEARCH" ]]; then
  options=($(printf "%s\n" "${options[@]}" | grep -i "$SEARCH" || true))
fi

# Handle no matches
if [[ ${#options[@]} -eq 0 ]]; then
  echo "No matches found."
  exit 1
fi

# --- Step 4: Select project ---
if [[ -z "$SEARCH" ]]; then
  # No search term - always show fzf
  if command -v fzf >/dev/null 2>&1; then
    selected_project=$(printf "%s\n" "${options[@]}" | fzf --prompt="Select project > " --height=40%)
  else
    echo "Available projects:"
    printf "  %s\n" "${options[@]}"
    echo ""
    read -p "Enter project name: " selected_project
  fi
else
  # Search term provided - auto-select if only one match
  if [[ ${#options[@]} -eq 1 ]]; then
    selected_project="${options[0]}"
    echo "Auto-selected: $selected_project"
  else
    if command -v fzf >/dev/null 2>&1; then
      selected_project=$(printf "%s\n" "${options[@]}" | fzf --prompt="Select project > " --height=40%)
    else
      echo "Available projects:"
      printf "  %s\n" "${options[@]}"
      echo ""
      read -p "Enter project name: " selected_project
    fi
  fi
fi

if [[ -z "$selected_project" ]]; then
  echo "No project selected, exiting."
  exit 0
fi

# --- Step 5: Connect ---
echo "Connecting to $selected_host, project: $selected_project $P_ARG $R_ARG ${V_ARG:+verbose mode} ${O_ARG:+choose service} ${CONTAINER:+container: $CONTAINER}"

# Build args array to avoid empty string arguments
args=()
[[ -n "$V_ARG" ]] && args+=("$V_ARG")
[[ -n "$O_ARG" ]] && args+=("$O_ARG")
[[ -n "$R_ARG" ]] && args+=("$R_ARG")
args+=("$selected_host" "$selected_project")
[[ -n "$CONTAINER" ]] && args+=("$CONTAINER")

$SCRIPT_DIR/container-tunnel-caddy "${args[@]}"
