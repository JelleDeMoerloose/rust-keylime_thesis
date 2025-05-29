#!/bin/bash

# Start D-Bus service
echo "Starting dbus-daemon..."
mkdir /run/dbus #https://stackoverflow.com/questions/64380418/failed-to-open-connection-to-system-message-bus-failed-to-connect-to-socket-v
dbus-daemon --system --fork

# Initialize and start swtpm (Software TPM)
echo "Starting Software TPM (swtpm)..."
mkdir -p /tmp/tpmdir
swtpm_setup --tpm2 --tpmstate /tmp/tpmdir --createek --decryption --create-ek-cert --create-platform-cert --display

echo "Starting swtpm daemon..."
swtpm socket --tpm2 --tpmstate dir=/tmp/tpmdir --flags startup-clear --ctrl type=tcp,port=2322 --server type=tcp,port=2321 --daemon

# Wait for swtpm to initialize properly
sleep 2

# Start tpm2-abrmd with tabrmd TCTI (use tabrmd TCTI to connect to swtpm)
echo "Starting tpm2-abrmd..."
tpm2-abrmd --tcti=tabrmd:bus_type=system --allow-root &  # Start the TPM2 Resource Manager as a background process

# Wait for tpm2-abrmd to initialize properly
sleep 2

# Now, setup and start the Keylime agent
echo "Starting Keylime Agent..."
exec /bin/keylime_agent
