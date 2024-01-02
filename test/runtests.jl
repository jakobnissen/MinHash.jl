using MinHash
using DataStructures: DataStructures
using Test

@testset "HashSet" begin
    include("hashset.jl")
end

@testset "MinHashing" begin
    include("minhashing.jl")
end

@testset "Distance" begin
    include("distance.jl")
end
