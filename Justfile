SRC_DIR := "./src"

interactive:
    julia --project -ie "using Pandemic"
alias i := interactive

format target=SRC_DIR:
    julia -E 'using JuliaFormatter; format("{{ target }}")'
alias f := format

notebook:
    julia -e 'using Pluto; Pluto.run()'
alias n := notebook
