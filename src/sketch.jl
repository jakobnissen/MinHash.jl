mutable struct MinHasher
    filled::Int
    heap::BinaryMaxHeap{UInt64}
    set::HashSet

    function MinHasher(size::Integer)
        heap = BinaryMaxHeap{UInt64}()
        resize!(heap.valtree, size)
        set = HashSet(4*size)
        new(0, heap, set)
    end
end

function Base.show(io::IO, ::MIME"text/plain", s::MinHasher)
    print(io, typeof(s), ":\n")
    print(io, " hashes:  ", s.filled, " / ", length(s), '\n')
    heaptop = isinitialized(s) ? repr(top(s.heap)) : "< uninitialized >"
    print(io, " minhash: ", heaptop, '\n')
    print(io, " hashset: ", s.set)
end

Base.length(s::MinHasher) = length(s.heap)
Base.show(io::IO, s::MinHasher) = print(io, typeof(s), "()")
isinitialized(s::MinHasher) = length(s) == s.filled

function Base.empty!(x::MinHasher)
    x.filled = 0
    empty!(x.set)
    return x
end

function initialize!(s::MinHasher, it)
    len, filled = length(s), s.filled
    vec, set = s.heap.valtree, s.set
    itval = iterate(it)
    @inbounds while (itval !== nothing) & (len > filled)
        i, state = itval
        h = hash(i)
        if !(h in set)
            filled += 1
            vec[filled] = h
            unsafe_push!(set, h)
        end
        itval = iterate(it, state)
    end
    if !isinitialized(s) && (filled == len)
        # This loop gives the heap actual heap property.
        for i in 2:length(vec)
            DataStructures._heap_bubble_up!(s.heap.comparer, vec, i)
        end
    end
    s.filled = filled
    return itval
end

function continue!(s::MinHasher, it, itval)
    heap, set = s.heap, s.set
    largest = top(heap)
    while itval !== nothing
        i, state = itval
        h = hash(i)
        if h < largest && !(h in set)
            push!(set, h, heap)
            largest = pop!(heap)
            push!(heap, h)
        end
        itval = iterate(it, state)
    end
end

function update!(s::MinHasher, it)
    itval = initialize!(s, it)
    continue!(s, it, itval)
    return s
end

struct MinHashSketch
    requested::Int
    hashes::Vector{UInt64}
end

MinHashSketch(s::MinHasher) = MinHashSketch(length(s), sort!(s.heap.valtree[1:s.filled]))

Base.length(s::MinHashSketch) = length(s.hashes)
Base.isempty(s::MinHashSketch) = iszero(length(s))

function Base.show(io::IO, ::MIME"text/plain", s::MinHashSketch)
    print(io, typeof(s), ":\n")
    print(io, " hashes:  ", length(s.hashes), " / ", s.requested, '\n')
    print(io, " minhash: ", isempty(s) ? "" : repr(s.hashes[1]))
end

Base.show(io::IO, s::MinHashSketch) = print(io, typeof(s), "()")

function sketch(it, s::Integer)
    sk = MinHasher(s)
    update!(sk, it)
    sketch = MinHashSketch(sk)
    return sketch
end
