# MinHash

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://jakobnissen.github.io/MinHash.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://jakobnissen.github.io/MinHash.jl/dev)
[![Build Status](https://travis-ci.com/jakobnissen/MinHash.jl.svg?branch=master)](https://travis-ci.com/jakobnissen/MinHash.jl)
[![Codecov](https://codecov.io/gh/jakobnissen/MinHash.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/jakobnissen/MinHash.jl)

_Efficient minhashing in Julia_

`MinHash.jl` offers generic, efficient MinHash sketching, and functions to efficiently compute the number of shared minhashes between sketches. This package is envisioned to be used as a dependency for other Julia packages that needs minhashing.

## Interface

### Types
__`MinHasher{F}(s::Integer)`__

A MinHasher object performs the minhashing, using function `F` as a hash function, and storing the `s` smallest hashes only. `F` defaults to `Base.hash`.

__`MinHashSketch(::MinHasher)`__

Stores the information of a `MinHasher` (namely, the hash function, maximal number of hashes, and the hashes themselves) in a more efficient type. This type should be used to store the actual hashes.

### Methods
__`update!(::MinHasher, it)`__

Iterate over `it`, adding each element to the minhasher.

__`sketch(F, it, s::Integer)`__
Hash all elements of `it` using function `F`, storing at most the `s` smallest hashes. Equivalent to:
```
hasher = MinHasher{F}(s)
update!(hasher, it)
return MinHashSketch(hasher)
```

__`sketch(it, s::Integer)`__

Same as `sketch(Base.hash, it, s)`

__`intersectionlength(a::MinHashSketch, b::MinHashSketch)`__

Efficiently compute the number of hashes both in `a` and `b`. Does not check that the hash functions for the two sketches are the same, result will be meaningless if they are not.

__`intersectionlength(::AbstractVector{MinHashSketch})`__

Efficiently compute a lower triangular matrix (of type `Matrix{Int}`) of shared hashes for all pairs in the input vector. For long vectors, this is much more efficient than calculating the distances pairwise.
