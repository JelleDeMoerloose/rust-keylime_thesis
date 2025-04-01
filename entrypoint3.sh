#!/bin/bash
set -e  # Exit immediately if a command fails

# Create a temporary directory for the TPM emulator
mkdir -p /tmp/tpmdir

# Reset and restart the DBus system
rm -rf /var/run/dbus
mkdir /var/run/dbus
dbus-daemon --system

# List DBus system configuration files (for debugging)
ls /etc/dbus-1/system.d/

# Set up the TPM emulator (swtpm)
swtpm_setup --tpm2 \
    --tpmstate /tmp/tpmdir \
    --createek --decryption --create-ek-cert \
    --create-platform-cert \
    --display

# Start the TPM emulator as a socket server
swtpm socket --tpm2 \
    --tpmstate dir=/tmp/tpmdir \
    --flags startup-clear \
    --ctrl type=tcp,port=2322 \
    --server type=tcp,port=2321 \
    --daemon

# Start tpm2-abrmd (TPM Access Broker & Resource Manager)
tpm2-abrmd \
    --logger=stdout \
    --tcti=swtpm: \
    --allow-root \
    --flush-all &

# Start the Keylime Agent with debug logs
export RUST_LOG=keylime_agent=trace
exec /bin/keylime_
exec /bin/keylime_agent
