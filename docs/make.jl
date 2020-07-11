using Documenter, MinHash

DocMeta.setdocmeta!(MinHash, :DocTestSetup, :(using MinHash); recursive=true)

makedocs(;
    modules=[MinHash],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/jakobnissen/MinHash.jl/blob/{commit}{path}#L{line}",
    sitename="MinHash.jl",
    authors="Jakob Nybo Nissen",
    assets=String[],
)

deploydocs(;
    repo="github.com/jakobnissen/MinHash.jl.git",
)
