ARG JULIA_VERSION

FROM julia:${JULIA_VERSION}

WORKDIR /root

COPY ssh-server.sh ssh-server.sh
RUN apt update && \
    apt install --no-install-recommends -y openssh-server && \
    mkdir /root/.ssh && \
    service ssh start

COPY Project.toml Project.toml
COPY Manifest.toml Manifest.toml
COPY spec-file.txt spec-file.txt
RUN julia -e 'using Pkg; Pkg.activate("."); Pkg.instantiate()' && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 22

CMD ["sh", "ssh-server.sh"]
