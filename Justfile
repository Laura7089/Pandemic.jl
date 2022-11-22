SRC_DIR := "./src"

interactive:
    julia --project -ie "using Pandemic"
alias i := interactive

format target=SRC_DIR:
    julia -e 'using JuliaFormatter; format("{{ target }}")'
alias f := format
