#!/bin/bash

# Get user input for the Julia version to use in containers.
echo
read -p "Which version of Julia would you like to use in containers? " JULIA_VERSION

# Update the `compose.yaml` in the root folder.
sed -i -e "s/JULIA_VERSION:.*$/JULIA_VERSION: $JULIA_VERSION/g" \
    -e "s/funds-allocation-scheduler:.*$/funds-allocation-scheduler:$JULIA_VERSION/g" \
    -e "s/funds-allocation-worker:.*$/funds-allocation-worker:$JULIA_VERSION/g" \
    ./compose.yaml

# Update the `deployment.yaml` in the containers sub-folder.
sed -i "s/funds-allocation-worker:.*$/funds-allocation-worker:$JULIA_VERSION/g" ./containers/deployment.yaml

# Update Julia packages and Jupyter.
julia --project=. -e 'import Pkg; Pkg.update(); import Conda; Conda.update(); Conda.export_list(joinpath(pwd(), "spec-file.txt"))'

# Copy package information to the containers sub-folder.
cp -t ./containers Manifest.toml Project.toml spec-file.txt

# Remove local images in the `compose.yaml`.
docker rmi $(docker images -q */*/*/funds-allocation-*)
docker system prune -f

# Build the images in the `compose.yaml`.
docker compose build --no-cache

# Delete existing images and push new images to Goole Artifact Registry. (Runing this part in a folder synced by Rclone causes a permission error.)
cd ~
gcloud artifacts docker images delete us-central1-docker.pkg.dev/project-lee-1/docker/funds-allocation-scheduler --quiet
gcloud artifacts docker images delete us-central1-docker.pkg.dev/project-lee-1/docker/funds-allocation-worker --quiet
docker compose -f ~/github/funds-allocation/compose.yaml push
