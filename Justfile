SRC_DIR := "./src"
REG_NAME := "pandemicreg"

JULIA := "julia"

# Get an interactive shell with the module in scope
interactive:
    {{ JULIA }} --project -ie "using Pandemic"

# Format all files in `target`
format target=SRC_DIR:
    {{ JULIA }} -E 'using JuliaFormatter; format("{{ target }}")'

# Get an interactive notebook
notebook:
    {{ JULIA }} -e 'using Pluto; Pluto.run()'
