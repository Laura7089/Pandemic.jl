SRC_DIR := "./src"
TEST_DIR := "./test"

JULIA := "julia"

# Get an interactive shell with the module in scope
interactive:
    {{ JULIA }} --project -ie "using Pandemic"

# Format all files in `target`
format target:
    {{ JULIA }} -E 'using JuliaFormatter; format("{{ target }}")'
alias f := format

# Format all source files
format_all: (format SRC_DIR) (format TEST_DIR)
alias fa := format_all

# Run unit tests
test *args="":
    {{ JULIA }} --project -e "using Pkg; Pkg.test(allow_reresolve=false, {{ args }})"
alias t := test
