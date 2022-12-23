import Pkg
Pkg.add([
    (name="Conda", version="1.7.0"),
    (name="Gurobi", version="0.11.4"),
    (name="HTTP", version="1.6.2"),
    (name="DataFrames", version="1.4.4"),
    (name="IJulia", version="1.24.0"),
    (name="JSON", version="0.21.3"),
    (name="JuMP", version="1.5.0"),
    (name="XLSX", version="0.8.4")
])
import Conda
Conda.update()
Conda.add("jupyterlab=3.5.2")
