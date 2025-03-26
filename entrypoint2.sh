#!/bin/bash

# Create a directory for TPM state
echo "Setting up swtpm (Software TPM)..."
mkdir -p /tmp/tpmdir

# Initialize the TPM state directory
swtpm_setup --tpm2 --tpmstate /tmp/tpmdir \
            --createek --decryption --create-ek-cert \
            --create-platform-cert --display

# Start the swtpm daemon
echo "Starting swtpm daemon..."
swtpm socket --tpm2 --tpmstate dir=/tmp/tpmdir \
            --flags startup-clear \
            --ctrl type=tcp,port=2322 \
            --server type=tcp,port=2321 --daemon
sleep 2  # Ensure swtpm is fully initialized

# Start the Keylime agent
echo "Starting Keylime Agent..."
exec /bin/keylime_agent
