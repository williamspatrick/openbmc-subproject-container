#!/bin/bash
set -e

# Initialize dbus-broker on container startup
# Based on ptest-runner initialization steps

# Setup systemd machine ID
if [ ! -f /etc/machine-id ] || [ ! -s /etc/machine-id ]; then
    systemd-machine-id-setup 2>/dev/null || true
fi

# Create journal directory and start journald
mkdir -p /run/systemd/journal
if [ ! -e /run/systemd/journal/socket ]; then
    (systemd-socket-activate -d -l /run/systemd/journal/socket -- /usr/lib/systemd/systemd-journald &) 2>/dev/null || true
    # Wait for journal socket with timeout
    for i in {1..50}; do
        [ -e /run/systemd/journal/socket ] && break
        sleep 0.1
    done
fi

# Configure dbus to allow root (as shown in ptest-runner)
if [ -f /usr/share/dbus-1/system.conf ]; then
    # Make a copy we can modify
    mkdir -p /etc/dbus-1
    cp /usr/share/dbus-1/system.conf /etc/dbus-1/system.conf 2>/dev/null || true
    
    # Allow root instead of messagebus user
    sed -i 's/user>messagebus/user>root/' /etc/dbus-1/system.conf 2>/dev/null || true
    sed -i 's/deny own=/allow own=/' /etc/dbus-1/system.conf 2>/dev/null || true
    sed -i 's/deny send_type=/allow send_type=/' /etc/dbus-1/system.conf 2>/dev/null || true
fi

# Create dbus runtime directory and start dbus-broker
mkdir -p /run/dbus
if [ ! -e /run/dbus/system_bus_socket ]; then
    # Use the modified config if it exists, otherwise use default
    DBUS_CONFIG="/etc/dbus-1/system.conf"
    if [ ! -f "$DBUS_CONFIG" ]; then
        DBUS_CONFIG="/usr/share/dbus-1/system.conf"
    fi
    
    (systemd-socket-activate -l /run/dbus/system_bus_socket -- dbus-broker-launch --config "$DBUS_CONFIG" --scope system &) 2>/dev/null || true
    
    # Wait for dbus socket with timeout
    for i in {1..50}; do
        [ -e /run/dbus/system_bus_socket ] && break
        sleep 0.1
    done
    
    # Set DBUS environment variable
    export DBUS_SYSTEM_BUS_ADDRESS="unix:path=/run/dbus/system_bus_socket"
fi

# Export dbus address for child processes
export DBUS_SYSTEM_BUS_ADDRESS="unix:path=/run/dbus/system_bus_socket"

# Execute the command passed to the container
exec "$@"
