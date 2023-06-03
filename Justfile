SRC_DIR := "./src"

JULIA := "julia"

# Get an interactive shell with the module in scope
interactive:
    {{ JULIA }} --project -ie "using Pandemic"

# Format all files in `target`
format target=SRC_DIR:
    {{ JULIA }} -E 'using JuliaFormatter; format("{{ target }}")'

# Run unit tests
test *args="":
    {{ JULIA }} --project -e "using Pkg; Pkg.test(allow_reresolve=false, {{ args }})"
alias t := test
