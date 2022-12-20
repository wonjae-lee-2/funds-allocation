FROM julia:1.8.3

WORKDIR /root

COPY Project.toml Project.toml
COPY Manifest.toml Manifest.toml
RUN julia -e 'using Pkg; Pkg.activate("."); Pkg.instantiate(); import Conda; Conda.update(); Conda.add("jupyterlab")'

CMD ["/bin/bash"]
