# MinHash.jl

_Efficient minhashing in Julia_

MinHash.jl offers generic, efficient MinHash sketching, and functions to efficiently compute the number of shared minhashes between sketches. This package is envisioned to be used as a dependency for other Julia packages that needs minhashing.

The API is very simple. Below is a short demonstration - read the docstrings below for more info.

```
julia> using MinHash

julia> hasher = MinHasher(100) # Same as MinHasher{hash}(100), keep 100 hashes
MinHasher{hash}:
 hashes:  0 / 100
 maxhash: < uninitialized >
 hashset: HashSet(0 / 512)

julia> update!(hasher, 'a':'z') # update with any iterable
MinHasher{hash}:
 hashes:  26 / 100
 maxhash: < uninitialized >
 hashset: HashSet(26 / 512)

julia> update!(hasher, 1:100) # only 100 hashes are kept
MinHasher{hash}:
 hashes:  100 / 100
 maxhash: 0xd0196f660622f483
 hashset: HashSet(126 / 512)

julia> sk = MinHashSketch(hasher) # can be used on noninitialized hasher
MinHashSketch:
 hashes:  100 / 100
 maxhash: 0xd0196f660622f483

julia sk2 = sketch(1:1000, 100) # quickly keep 100 hashes of 1:1000
MinHashSketch:
 hashes:  100 / 100
 maxhash: 0xfff598f76319355e

julia> intersectionlength(sk, sk2) # calc number of hashes in sk and sk2
80
```


```@autodocs
Modules = [MinHash]
```
