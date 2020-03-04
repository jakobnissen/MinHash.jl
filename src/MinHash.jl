module MinHash

using DataStructures

include("hashset.jl")
include("sketch.jl")
include("distance.jl")

#Keep the commented while developing for each of testing
export MinHasher,
update!,
MinHashSketch,
sketch,
intersections

end # module
