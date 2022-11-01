#!/bin/bash

# Copy the ssh public key from the kubernetes secret.
cp /root/secret/public /root/.ssh/id_ed25519.pub

# Add the public key to the list of authorized keys.
cat /root/.ssh/id_ed25519.pub >> /root/.ssh/authorized_keys

# Start the ssh server.
/usr/sbin/sshd -D
