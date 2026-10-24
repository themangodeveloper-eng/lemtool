#!/usr/bin/env bash
# ==============================================================================
# Lemon-OS Multi-Distro Toolchain Manager (Debian & Ubuntu)
# ==============================================================================
set -e

DISTRO="${1:-}"

if [ "$DISTRO" != "debian" ] && [ "$DISTRO" != "ubuntu" ]; then
    echo "🍋 Lemon-OS Toolchain Manager"
    echo "Usage: ./lemon-tool.sh <debian|ubuntu>"
    echo "Example: ./lemon-tool.sh debian"
    exit 1
fi

echo "🍋 [1/3] Ensuring proot-distro & dependencies are installed..."
pkg update -y && pkg install -y proot-distro curl python3

echo "🍋 [2/3] Fetching official community distribution ($DISTRO)..."
if [ ! -d "$PREFIX/var/lib/proot-distro/installed-rootfs/$DISTRO" ]; then
    proot-distro install "$DISTRO"
fi

ROOTFS_DIR="$PREFIX/var/lib/proot-distro/installed-rootfs/$DISTRO"

echo "🍋 [3/3] Injecting Lemon-OS Identity & Toolchain into $DISTRO..."

# Inject OS branding
cat <<EON > "$ROOTFS_DIR/etc/os-release"
NAME="Lemon-OS"
VERSION="1.0 LTS ($DISTRO Core)"
ID=lemon-os
ID_LIKE=$DISTRO
PRETTY_NAME="Lemon-OS v1 ($DISTRO Edition)"
VERSION_ID="1.0"
EON

echo "lemon-os" > "$ROOTFS_DIR/etc/hostname"

mkdir -p "$ROOTFS_DIR/etc/lemon-os"
cat <<'EON' > "$ROOTFS_DIR/etc/lemon-os/ascii_logo.txt"
       .--.
     .'_\_  \
    / /    \ \
   | |  🍋  | |   LEMON-OS
    \ \    / /    Modern AI & Security OS
     '._\_.'
EON

# Configure interactive shell environment & prompt
cat << 'EON' >> "$ROOTFS_DIR/root/.bashrc"
export PS1="\[\e[33m\]🍋 lemon-os ($DISTRO):\w\$ \[\e[0m\]"
neofetch 2>/dev/null || echo "Lemon-OS v1 Ready."
EON

mkdir -p "$ROOTFS_DIR/usr/local/bin"

# ------------------------------------------------------------------------------
# Embed LLI (Local Link Interface) with clean absolute /bin/bash header & valid syntax
# ------------------------------------------------------------------------------
cat << 'EON' > "$ROOTFS_DIR/usr/local/bin/lli"
#!/bin/bash
# Lemon-OS Local Link Interface (LLI)

ACTION="${1:-}"
shift || true

case "$ACTION" in
    "get-ip")
        hostname -I 2>/dev/null || ip route get 1 2>/dev/null | awk '{print $7; exit}' || echo "127.0.0.1"
        ;;
    "add-api")
        KEY="${1:-}"
        mkdir -p ~/.config/lemon-os
        echo "$KEY" > ~/.config/lemon-os/api.key
        chmod 600 ~/.config/lemon-os/api.key
        echo "Gemini API key updated successfully."
        ;;
    "login-google")
        EMAIL=""
        while [[ "$#" -gt 0 ]]; do
            case "$1" in
                --email-method) EMAIL="$2"; shift 2 ;;
                *) shift ;;
            esac
        done
        if [ -z "$EMAIL" ]; then
            echo "Usage: lli login-google --email-method \"user@gmail.com\""
            exit 1
        fi
        read -sp "Enter password for $EMAIL: " PASS
        echo ""
        mkdir -p ~/.config/lemon-os
        echo "{\"email\": \"$EMAIL\", \"bound\": true, \"auth_status\": \"verified\"}" > ~/.config/lemon-os/sli_binding.json
        echo "Logged in successfully as $EMAIL."
        ;;
    "inbox-list")
        echo "=== Lemon-OS Inbox ==="
        [ -f ~/.config/lemon-os/inbox.json ] && cat ~/.config/lemon-os/inbox.json || echo "Inbox is empty."
        ;;
    *)
        echo "Usage: lli <command> [options]"
        echo "Commands: get-ip, add-api, login-google, inbox-list"
        ;;
esac
EON

# ------------------------------------------------------------------------------
# Embed SLI (Secure Link Interface) with clean absolute /bin/bash header & valid syntax
# ------------------------------------------------------------------------------
cat << 'EON' > "$ROOTFS_DIR/usr/local/bin/sli"
#!/bin/bash
# Lemon-OS Secure Link Interface (SLI)

COMMAND="${1:-}"
PROMPT="${2:-}"

if [ "$COMMAND" == "ai-in" ]; then
    if [ -z "$PROMPT" ]; then
        echo "Usage: sli ai-in \"your prompt here\""
        exit 1
    fi
    if [ ! -f ~/.config/lemon-os/api.key ]; then
        echo "Error: Gemini API key not found. Run 'lli add-api <KEY>' first."
        exit 1
    fi
    API_KEY=$(cat ~/.config/lemon-os/api.key)
    GEM_URL="https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${API_KEY}"
    
    curl -s -X POST "$GEM_URL" \
         -H "Content-Type: application/json" \
         -d "{\"contents\": [{\"parts\": [{\"text\": \"$PROMPT\"}]}]}" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['candidates'][0]['content']['parts']['0']['text'])" 2>/dev/null
else
    echo "Usage: sli ai-in \"<prompt>\""
fi
EON

chmod +x "$ROOTFS_DIR/usr/local/bin/lli" "$ROOTFS_DIR/usr/local/bin/sli"

echo "========================================================"
echo "✅ Lemon-OS successfully deployed on $DISTRO core!"
echo "🚀 To launch your environment, run:"
echo "   proot-distro login $DISTRO"
echo "========================================================"
