mutable struct HashSet
    data::Vector{UInt}
    mask::UInt
    len::Int
    haszero::Bool # 0 is interpreted as absence of hash, so we need this

    function HashSet(N::Integer)
        # Min 8 otherwise a size 4 will never repopulate and get stuck
        len = max(8, nextpow(2, N))
        new(zeros(UInt, len), (len - 1) % UInt, 0, false)
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
    return iszero(h) & s.haszero
end

function Base.empty!(s::HashSet)
    fill!(s.data, 0)
    s.len = 0
    s.haszero = false
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
    s.haszero |= iszero(h)
    pos = (h & s.mask) + 1
    @inbounds v = s.data[pos]
    @inbounds while !iszero(v)
        pos = (pos & s.mask) + 1
        v = s.data[pos]
    end
    s.len += 1
    @inbounds s.data[pos] = h
end

# The HashSet doesn't actually check if the hash is already in the set or not
# it just adds it - so only push when item is not already in set.
function Base.push!(s::HashSet, h::UInt, heap::Vector{UInt})
    s.len > (s.mask - s.mask >>> 2) && repopulate!(s, heap)
    unsafe_push!(s, h)
end
