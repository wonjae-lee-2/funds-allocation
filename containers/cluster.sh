#!/bin/bash

# Ask for the desired number of workers to create.
echo
read -p "How many workers would you like to create? " NUM_WORKERS

# Copy the SSH private and public key to the `.ssh` folder.
cp -t ~/.ssh ~/secret/id_ed25519 ~/secret/id_ed25519.pub

# Save the namespace for subsequent kubectl commands.
kubectl config set-context --current --namespace=julia

# Create a Kubernetes secret from the public key.
kubectl create secret generic ssh-key --from-file=public=./.ssh/id_ed25519.pub -n julia

# Update the `deployment.yml` with the desired numer of workers.
sed -i "s/replicas:.*$/replicas: ${NUM_WORKERS}/g" deployment.yaml

# Create worker pods.
kubectl apply -f deployment.yaml

# Wait until all worker pods are ready.
kubectl wait deployment/worker -n julia --for=condition=Available --timeout=600s

# Wait few more seconds to make sure all the pods are ready.
sleep 10

# Set parameters for the loop.
i=1
POD_NAMES=$(kubectl get pods -n julia -o jsonpath="{.items[*].metadata.name}")

# Forward ports to all pods for SSH.
for POD_NAME in ${POD_NAMES}
do
    kubectl port-forward -n julia pod/${POD_NAME} $((60000 + i)):22 &
    i=$((i + 1))
done
