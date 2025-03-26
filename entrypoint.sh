#!/bin/sh
set -e  # Exit on any error

# Function to start DBus (Only if needed)
start_dbus() {
    if ! ps aux | grep -q "[d]bus-daemon"; then
        echo "Starting DBus..."
        dbus-daemon --system --nofork &
        # Wait for DBus to be ready
        sleep 1
    else
        echo "DBus already running."
    fi
}

# Function to initialize TPM (swtpm setup)
initialize_tpm() {
    echo "Initializing virtual TPM (swtpm)..."
    if [ ! -d /tmp/tpmdir ]; then
        swtpm_setup --tpm2 --tpmstate /tmp/tpmdir \
            --createek --decryption --create-ek-cert \
            --create-platform-cert --display
    else
        echo "TPM state directory already initialized."
    fi
}

# Function to start swtpm emulator
start_swtpm() {
    echo "Starting swtpm emulator..."
    if ! ps aux | grep -q "[s]wtpm"; then
        swtpm socket --tpm2 --tpmstate dir=/tmp/tpmdir \
            --flags startup-clear \
            --ctrl type=tcp,port=2322 \
            --server type=tcp,port=2321 --daemon
    else
        echo "swtpm emulator already running."
    fi
}

# Function to configure TPM2 Access Broker (tpm2-abrmd)
configure_tpm2_abrmd() {
    echo "Configuring TPM2 Access Broker..."
    export TPM2TOOLS_TCTI="tabrmd:bus_name=com.intel.tss2.Tabrmd"
    export TCTI="tabrmd"

    # Ensure correct D-Bus policy for tpm2-abrmd
    if [ ! -f /etc/dbus-1/system.d/tpm2-abrmd.conf ]; then
        echo "Creating DBus configuration for tpm2-abrmd..."
        cat <<EOF > /etc/dbus-1/system.d/tpm2-abrmd.conf
<busconfig>
  <policy user="root">
    <allow own="com.intel.tss2.Tabrmd"/>
    <allow send_destination="com.intel.tss2.Tabrmd"/>
    <allow receive_sender="com.intel.tss2.Tabrmd"/>
  </policy>
</busconfig>
EOF
    else
        echo "DBus configuration for tpm2-abrmd already exists."
    fi

    # Start tpm2-abrmd (TPM2 Access Broker and Resource Manager)
    echo "Starting TPM2 Access Broker and Resource Manager..."
    tpm2-abrmd --logger=stdout --tcti=swtpm: --allow-root --flush-all &
}

# Main script execution
echo "Setting up TPM state directory..."
mkdir -p /tmp/tpmdir
mkdir -p /run/dbus
touch /run/dbus/system_bus_socket

# Start services
initialize_tpm
start_swtpm
configure_tpm2_abrmd

# Start the Keylime agent
echo "🔧 Starting Keylime agent..."
exec /bin/keylime_agent
