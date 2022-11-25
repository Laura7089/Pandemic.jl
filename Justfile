SRC_DIR := "./src"
REG_NAME := "pandemicreg"

# Get an interactive shell with the module in scope
interactive:
    julia --project -ie "using Pandemic"

# Format all files in `target`
format target=SRC_DIR:
    julia -E 'using JuliaFormatter; format("{{ target }}")'

# Get an interactive notebook
notebook:
    julia -e 'using Pluto; Pluto.run()'

# Create a local registry and register the package with it
registry:
    julia <(echo ' \
        using LocalRegistry; \
        try \
            create_registry("{{ REG_NAME }}", ""); \
        catch end; \
        \
        using Pkg; \
        Pkg.activate("."); \
        using Pandemic; \
        register(Pandemic, registry = "{{ REG_NAME }}"); \
    ')
