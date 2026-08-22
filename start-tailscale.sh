#!/bin/sh

# 1. Start tailscaled in the background with userspace networking and persistent state
echo "Starting tailscale daemon process..."
/usr/sbin/tailscaled --tun=userspace-networking --state=/workspace/tailscale.state &
Tailscale_PID=$!

# 2. Loop internally until the daemon's local socket is fully responsive
echo "Waiting for tailscaled daemon to initialize..."
until tailscale status >/dev/null 2>&1; do
    sleep 1
done

# 3. Check if we are already logged in via the persistent state file
if tailscale status | grep -q "Logged in"; then
    echo "Tailscale is already authenticated via persistent storage."
else
    # 4. If not logged in, authenticate using the RunPod environment variable key
    if [ -n "$TS_AUTHKEY" ]; then
        echo "Authenticating Tailscale with provided auth key..."
        tailscale up --authkey="$TS_AUTHKEY" --ssh
    else
        echo "WARNING: Tailscale is logged out and no TS_AUTHKEY environment variable was found!"
    fi
fi

# 5. Bring the tailscaled process back to the foreground so Supervisor tracks it properly
wait $Tailscale_PID