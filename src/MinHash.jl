module MinHash

using DataStructures

include("hashset.jl")
include("minhash.jl")
include("distance.jl")

export MinHasher,
update!,
MinHashSketch,
minhash,
intersectionlength

end
