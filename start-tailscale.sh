#!/bin/sh

# 1. Start tailscaled in the background with userspace networking and persistent state
echo "Starting tailscale daemon process..."
/usr/sbin/tailscaled --tun=userspace-networking --state=/workspace/tailscale.state &
Tailscale_PID=$!

# 2. Loop internally until the daemon's local socket is fully responsive
echo "Waiting for tailscaled socket file to be created..."
while [ ! -S /var/run/tailscale/tailscaled.sock ]; do
    sleep 1
done
# Give the daemon a brief moment to settle its socket listeners
sleep 2

echo "Checking Tailscale authentication state..."
STATUS=$(tailscale status 2>&1)

if echo "$STATUS" | grep -q "Logged in"; then
    echo "Tailscale is already authenticated via persistent storage."
else
    echo "Tailscale is logged out."
    if [ -n "$TS_AUTHKEY" ]; then
        echo "Found TS_AUTHKEY environment variable. Authenticating..."
        tailscale up --authkey="$TS_AUTHKEY" --ssh --accept-routes
    else
        echo "ERROR: TS_AUTHKEY environment variable is empty or missing!"
    fi
fi

# Keep the script running attached to the tailscaled PID
wait $Tailscale_PID