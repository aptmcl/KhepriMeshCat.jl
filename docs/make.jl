using KhepriMeshCat
using Documenter

DocMeta.setdocmeta!(KhepriMeshCat, :DocTestSetup, :(using KhepriMeshCat); recursive=true)

makedocs(;
    modules=[KhepriMeshCat],
    authors="António Menezes Leitão <antonio.menezes.leitao@gmail.com>",
    repo="https://github.com/aptmcl/KhepriMeshCat.jl/blob/{commit}{path}#{line}",
    sitename="KhepriMeshCat.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://aptmcl.github.io/KhepriMeshCat.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/aptmcl/KhepriMeshCat.jl",
)
