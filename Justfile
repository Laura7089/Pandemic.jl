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

# Create a local registry and register the package with it
registry:
    {{ JULIA }} --project <(echo ' \
        using LocalRegistry; \
        try create_registry("{{ REG_NAME }}", "", push = true); \
        catch end; \
        using Pandemic; \
        register(Pandemic, registry = "{{ REG_NAME }}"); \
    ')
