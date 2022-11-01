ARG JULIA_VERSION

FROM julia:${JULIA_VERSION}

WORKDIR /root

COPY cluster.sh cluster.sh
COPY deployment.yaml deployment.yaml
RUN apt update && \
    apt install --no-install-recommends -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
        tee /usr/share/keyrings/cloud.google.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
        tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    apt update && \
    apt install --no-install-recommends -y \
        kubectl \
        google-cloud-sdk-gke-gcloud-auth-plugin \
        procps
ENV KUBECONFIG=/root/secret/kubeconfig.yaml \
    GOOGLE_APPLICATION_CREDENTIALS=/root/secret/gsa-key.json

COPY Project.toml Project.toml
COPY Manifest.toml Manifest.toml
COPY spec-file.txt spec-file.txt
RUN julia -e 'using Pkg; Pkg.activate("."); Pkg.instantiate(); import Conda; Conda.list()' && \
    /root/.julia/conda/3/bin/conda install -y --file spec-file.txt && \
    apt install --no-install-recommends -y openssh-client && \
    mkdir /root/.ssh && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 8888

CMD ["/root/.julia/conda/3/bin/jupyter", "lab", "--allow-root", "--no-browser", "--ip=0.0.0.0", "--port=8888"]
