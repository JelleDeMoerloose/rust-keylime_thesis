  cat > /home/vagrant/keylime-docker/entrypoint.sh << 'EOF'
  #!/bin/sh
  set -e
  
  # Wait for TPM simulator if needed
  if [ -n "$TCTI" ] && [[ "$TCTI" == *"mssim"* ]]; then
    echo "Waiting for TPM simulator..."
    sleep 2
  fi
  
  # Run the keylime agent
  cd /rust-keylime
  echo "Starting Keylime agent..."
  exec ./keylime_agent
  EOF
  
  chmod +x /home/vagrant/keylime-docker/entrypoint.sh
