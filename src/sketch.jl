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
    print(io, " minhash: ", heaptop, '\n')
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

function initialize!(s::MinHasher, it)
    len, filled = _length(s), s.filled
    vec, set = s.heap, s.set
    itval = iterate(it)
    @inbounds while (itval !== nothing) & (len > filled)
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

function continue!(s::MinHasher, it, itval)
    heap, set = s.heap, s.set
    largest = first(heap)
    while itval !== nothing
        i, state = itval
        h = call(s, i)
        if h < largest && !(h in set)
            push!(set, h, heap)
            heappop!(heap, Base.Order.Reverse)
            heappush!(heap, h, Base.Order.Reverse)
            largest = first(heap)
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
    func::Function
    requested::Int
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
    print(io, " minhash: ", isempty(s) ? "" : repr(s.hashes[1]))
end

Base.show(io::IO, s::MinHashSketch) = print(io, typeof(s), "()")

function sketch(F, it, s::Integer)
    sk = MinHasher{F}(s)
    update!(sk, it)
    sketch = MinHashSketch(sk)
    return sketch
end
sketch(it, s::Integer) = sketch(hash, it, s)
