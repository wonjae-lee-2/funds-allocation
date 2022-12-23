FROM julia:1.8.3

WORKDIR /root

COPY Dockerfile/gurobi.lic gurobi.lic
RUN apt update && \
    apt install -y --no-install-recommends wget && \
    rm -rf /var/lib/apt/lists/* && \
    wget https://packages.gurobi.com/10.0/gurobi10.0.0_armlinux64.tar.gz && \
    tar -xf gurobi10.0.0_armlinux64.tar.gz -C /opt && \
    rm gurobi10.0.0_armlinux64.tar.gz && \
    mv gurobi.lic /opt/gurobi1000
ENV GUROBI_HOME="/opt/gurobi1000/armlinux64"
ENV PATH="$PATH:$GUROBI_HOME/bin"
ENV LD_LIBRARY_PATH="$GUROBI_HOME/lib"

RUN mkdir /root/funds-allocation
WORKDIR /root/funds-allocation

COPY Project.toml Project.toml
COPY Manifest.toml Manifest.toml
COPY src/ src/
COPY temp/ temp/
RUN julia --project=. -e 'import Pkg; Pkg.instantiate(); import Conda; Conda.update(); Conda.add("jupyterlab=3.5.2")'
ENV JULIA_PROJECT="@."
ENV JULIA_NUM_THREADS="auto"

CMD ["julia", "src/FundsAllocation.jl"]
