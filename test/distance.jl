function test_pairwise(F::Function, a, b, s::Integer)
    s1 = sketch(F, a, s)
    s2 = sketch(F, b, s)
    @test intersectionlength(s1, s2) == length(intersect(s1.hashes, s2.hashes))
end

function test_multi(F::Function, x, s)
    sketches = [sketch(F, i, s) for i in x]
    m = intersectionlength(sketches)
    println(m)
    allgood = true
    for i in 1:length(sketches) - 1
        for j in i+1:length(sketches)
            tp = intersectionlength(sketches[i], sketches[j])
            allgood &= tp == m[j, i]
        end
    end
    @test allgood
end

@testset "Pairwise" begin
    test_pairwise(hash, 1:100, 60:200, 40)
    test_pairwise(hash, 1:100, 'A':'z', 40)
    test_pairwise(hash, 1:100, 'A':'z', 1)
    test_pairwise(hash, 'A':'g', 'W':'s', 10)

    @test sketch(hash, 500:600, 50) == sketch(500:600, 60)
    @test sketch(hash, 'A':'z', 40) == sketch('A':'z', 40)
end

@testset "Multi" begin
    xs = [collect(Set(rand(1:250, 100))) for i in 1:5]
    test_multi(hash, xs, 50)
end

@testset "Misc" begin
    s = sketch('A':'z', 38)
    @test length(s) == 38
    s = sketch(5:55, 250)
    @test length(s) == 51
    @test !isempty!(s)
    @test isempty(sketch(hash, 1:0, 100))
end
