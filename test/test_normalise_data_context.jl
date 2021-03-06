@testset "Test Normalisation" begin
    @info "Test: Ellipse Parameter Cooordinate System Conversion"

    @testset "From Unnormalised to Normalised and back" begin
        ðâ = [10, 5, 25, 25, Ï/4]
        geo_to_alg = GeometricToAlgebraic()
        s = 0.01
        mâ = 25
        mâ = 25
        ð = SMatrix{3,3,Float64}(s,0,0,0,s,0,-s*mâ,-s*mâ,1)
        normalise = NormaliseDataContext(tuple(ð))
        ðâ = geo_to_alg(ðâ)
        ðâ = ðâ / norm(ðâ)
        ðâ² = normalise(ToNormalisedSpace(), ðâ)
        ðâ = normalise(FromNormalisedSpace(), ðâ²)
        @test all(ðâ .â ðâ)
    end
end
