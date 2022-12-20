import Pkg
Pkg.add([
    (name="Conda", version="1.7.0"),
    (name="CPLEX", version="0.9.4"),
    (name="HiGHS", version="1.3.0"),
    (name="HTTP", version="1.6.0"),
    (name="DataFrames", version="1.4.4"),
    (name="IJulia", version="1.23.3"),
    (name="JSON", version="0.21.3"),
    (name="JuMP", version="1.5.0"),
    (name="XLSX", version="0.8.4")
])
import Conda
Conda.add("jupyterlab")
