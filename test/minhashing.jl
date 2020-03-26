function cmp_minhashes(h1::MinHasher, h2::MinHasher)
    return MinHashSketch(h1).hashes ==  MinHashSketch(h2).hashes
end

function test_minhasher(h::MinHasher{F}, x, s::Integer) where F
    truth = sort!(collect(Set([F(i) for i in x])))[1:s]
    h = MinHashSketch(h).hashes
    if truth != h
        println(x)
    end
    @test truth == h
end

function test_minhashing(F, x, s::Integer)
    h = MinHasher{F}(s)
    MinHash.update!(h, x)
    test_minhasher(h, x, s)
end

hashtwo(x) = hash(x, 0x80fa8f430b9cd13a)

@testset "Basic functionality" begin
    for F in (hash, hashtwo)
        test_minhashing(F, join(rand('A':'z', 100)), 20)
        test_minhashing(F, 1:10000, 1000)
        test_minhashing(F, 1:1000, 1000)
        test_minhashing(F, rand(UInt8, 1000), 50)
    end
    # Test default function is hashing as we expect
    h0 = MinHashSketch(MinHash.update!(MinHasher{hash}(25), 1:1000)).hashes
    h1 = MinHashSketch(MinHash.update!(MinHasher(25), 1:1000)).hashes
    @test h0 == h1
end

function test_update(F, s::Integer, x::AbstractVector, partitions::Vector)
    h1 = MinHasher{F}(s)
    h2 = MinHasher{F}(s)
    MinHash.update!(h1, x)
    for p in partitions
        MinHash.update!(h2, x[p])
    end
    @test cmp_minhashes(h1, h2)
end

@testset "Updating" begin
    for F in (hash, hashtwo)
        test_update(F, 20, 'A':'z', [1:20, 10:40, 38:58])
        test_update(F, 1000, 1:10000, [7000:10000, 1:5000, 4000:7500])
        test_update(F, 75, rand(UInt8, 1000), [1:0, 1:1000, 1:0])
    end
end

function test_empty!(s::Integer, x)
    h0 = MinHash.update!(MinHasher(s), x)
    h1 = MinHash.update!(MinHasher(s), 1:100)
    empty!(h1)
    MinHash.update!(h1, x)
    @test cmp_minhashes(h0, h1)
end

@testset "Emptying" begin
    test_empty!(40, 'A':'z')
    test_empty!(100, 1:1000)
end


function test_sketch(F, x, s::Integer)
    truth = sort!([F(i) for i in x])[1:s]
    @test sketch(F, x, s).hashes == truth
end


@testset "Sketch" begin
    for F in (hash, hashtwo)
        test_sketch(F, 'A':'z', 10)
        test_sketch(F, 1:1000, 200)
    end
end
