# A MinHasher maintains the N smallest hashes by continually removing the top hash
# using a heap. To make sure we don't have the same hashes multiple times, we use a
# HashSet to check for duplicates. A Hash set is like an optimized version of Set.

# F is type parameter because we want the user to choose a hash function with no
# runtime performance. The maximal number of hashes kept is the length of the heap vector.
"""
    MinHasher{F}

A type used to minhash any iterable object with function `F`.

See also: [`update!`](@ref), [`sketch`](@ref)
"""
mutable struct MinHasher{F}
    filled::Int
    heap::Vector{UInt64}
    set::HashSet

    function MinHasher{F}(size::Integer) where F
        heap = Vector{UInt64}(undef, size)
        set = HashSet(4*size)
        new(0, heap, set)
    end
end

MinHasher(size::Integer) = MinHasher{hash}(size)
call(::MinHasher{F}, x) where F = F(x)

function Base.show(io::IO, ::MIME"text/plain", s::MinHasher)
    print(io, typeof(s), ":\n")
    print(io, " hashes:  ", s.filled, " / ", _length(s), '\n')
    heaptop = isinitialized(s) ? repr(first(s.heap)) : "< uninitialized >"
    print(io, " maxhash: ", heaptop, '\n')
    print(io, " hashset: ", s.set)
end

_length(s::MinHasher) = length(s.heap)
Base.show(io::IO, s::MinHasher) = print(io, typeof(s), "()")
isinitialized(s::MinHasher) = _length(s) == s.filled

function Base.empty!(x::MinHasher)
    x.filled = 0
    empty!(x.set)
    return x
end

# The first N hashes will always be the N smallest hashes. So we don't need to use the heap
# to remove largest hash. We only use the HashSet (and we don't even need to repopulate
# that). We build the heap after seeing all N distinct hashes.
function initialize!(s::MinHasher, it)
    len, filled = _length(s), s.filled
    vec, set = s.heap, s.set
    itval = iterate(it)
    @inbounds while (len > filled) && (itval !== nothing)
        i, state = itval
        h = call(s, i)
        if !(h in set)
            filled += 1
            vec[filled] = h
            unsafe_push!(set, h)
        end
        itval = iterate(it, state)
    end
    if !isinitialized(s) && (filled == len)
        heapify!(vec, Base.Order.Reverse)
    end
    s.filled = filled
    return itval
end

# After the first N hashes, we need to use the heap to discard the largest hash when we
# see a smaller one.
function continue!(s::MinHasher, it, itval)
    heap, set = s.heap, s.set
    largest = first(heap)
    while itval !== nothing
        i, state = itval
        h = call(s, i)
        if h < largest && !(h in set)
            push!(set, h, heap)
            setfirst!(heap, h, Base.Order.Reverse)
            largest = first(heap)
        end
        itval = iterate(it, state)
    end
end

"Replace root node in heap, preserving heap property"
function setfirst!(h::Vector, v, order::Base.Order.Ordering)
    val = convert(eltype(h), v)
    @inbounds h[1] = val
    DataStructures.percolate_down!(h, 1, val, order, length(h))
    return h
end

"""
    update!(s::MinHasher, it)

Add hashes of all elements of iterable `it` to MinHasher `s`.

See also: [`sketch`](@ref)
"""
function update!(s::MinHasher, it)
    itval = initialize!(s, it)
    continue!(s, it, itval)
    return s
end

"""
    MinHashSketch

Holds the N smallest hashes of an iterable. Construct from a `MinHasher`.

# Examples

```jldoctest
julia> x = MinHashSketch(update!(MinHasher(10), 1:1000))
MinHashSketch:
 hashes:  10 / 10
 maxhash: 0x0214ce7a1c004d40

julia> length(x)
10
```
"""
struct MinHashSketch
    func::Any # hash function
    requested::Int # maximal number of hashes to keep
    hashes::Vector{UInt64}
end

function MinHashSketch(s::MinHasher{F}) where F
    return MinHashSketch(F, _length(s), sort!(s.heap[1:s.filled]))
end

Base.length(s::MinHashSketch) = length(s.hashes)
Base.isempty(s::MinHashSketch) = iszero(length(s))

function Base.show(io::IO, ::MIME"text/plain", s::MinHashSketch)
    print(io, typeof(s), ":\n")
    print(io, " hashes:  ", length(s.hashes), " / ", s.requested, '\n')
    print(io, " maxhash: ", isempty(s) ? "" : repr(s.hashes[end]))
end

Base.show(io::IO, s::MinHashSketch) = print(io, typeof(s), "()")

"""
    sketch([F=hash], it, s::Integer)

Hash every element of iterable `it` using function `F`, and return a `MinHashSketch`
containing at most the `s` smallest hashes.

# Examples:

```jldoctest
julia> sketch("ACGDEFG", 3)
MinHashSketch:
 hashes:  3 / 3
 maxhash: 0x3e1b023d3c92ff8f
```

See also: [`update!`](@ref)
"""
function sketch(F, it, s::Integer)
    sk = MinHasher{F}(s)
    update!(sk, it)
    sketch = MinHashSketch(sk)
    return sketch
end
sketch(it, s::Integer) = sketch(hash, it, s)
