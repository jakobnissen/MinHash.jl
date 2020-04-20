mutable struct HashSet
    data::Vector{UInt}
    mask::UInt
    len::Int

    function HashSet(N::Integer)
        # Min 8 otherwise a size 4 will never repopulate and get stuck
        len = max(8, nextpow(2, N))
        new(zeros(UInt, len), (len - 1) % UInt, 0)
    end
end

function Base.show(io::IO, s::HashSet)
    print(io, "HashSet($(s.len) / $(Int(s.mask) + 1))")
end

Base.length(s::HashSet) = s.len

# Hashes are already uniformly distributed, so we just use hash as index then search
# linearly until we find the hash or an empty slot (0 is empty)
function Base.in(h::UInt, s::HashSet)
    pos = (h & s.mask) + 1
    @inbounds v = s.data[pos]
    @inbounds while !iszero(v)
        v == h && return true
        pos = (pos & s.mask) + 1
        v = s.data[pos]
    end
    return false
end

function Base.empty!(s::HashSet)
    fill!(s.data, 0)
    s.len = 0
    return s
end

# This simple structure do not support deletion, so when it gets too full, we simply
# empty it and then repopulate it from a vector containing all the hashes we need
function repopulate!(s::HashSet, h::Vector{UInt})
    empty!(s)
    @inbounds for i in h
        unsafe_push!(s, i)
    end
    s.len = length(h)
end

function unsafe_push!(s::HashSet, h::UInt)
    pos = (h & s.mask) + 1
    @inbounds v = s.data[pos]
    @inbounds while !iszero(v)
        pos = (pos & s.mask) + 1
        v = s.data[pos]
    end
    s.len += 1
    @inbounds s.data[pos] = h
end

function Base.push!(s::HashSet, h::UInt, heap::Vector{UInt})
    if s.len > (s.mask - s.mask >>> 2)
        repopulate!(s, heap)
        # h may have been in the heap already
        if !(h in s)
            unsafe_push!(s, h)
        end
    else
        unsafe_push!(s, h)
    end
end
