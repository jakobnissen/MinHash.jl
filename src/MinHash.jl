module MinHash

using DataStructures

include("hashset.jl")
include("sketch.jl")
include("distance.jl")

export MinHasher,
update!,
MinHashSketch,
sketch,
intersectionlength

end
