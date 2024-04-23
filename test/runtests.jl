using Test, QuantumAcademy
using Unitful, UnitfulAtomic
using LinearAlgebra: UniformScaling

@testset "PeriodicFinDiffHamiltonian" begin
    @testset "Constant Potential" begin
        V(x, y) = 5.0
        L = austrip(100u"nm")
        W = austrip(200u"nm")

        NL = 6
        NW = 4

        H = FinDiffHamiltonian{Float64}(V, L, W, NL, NW)

        @test H.length isa Float64
        @test H.width isa Float64
        @test H.nlength isa Int
        @test H.nwidth isa Int

        @test eltype(H) == Float64
        @test size(H) == (NL * NW, NL * NW)

        ial2 = (NL / L)^2
        iaw2 = (NW / W)^2
        @test H[1:3, 1:3] ≈ [
            5+ial2+iaw2      -ial2/2            0;
            -ial2/2      5+ial2+iaw2      -ial2/2;
                      0      -ial2/2  5+ial2+iaw2]

        U = DenseEigenProp(H)

        @test U(0) ≈ Matrix(UniformScaling(1), NL * NW, NL * NW)

        nx = 5
        ny = 7
        ψ0 = wavefunction((x, y) -> cispi(2 * nx * x) * cispi(2 * ny * y), NL, NW)
        t1 = austrip(100u"ns")

        ψtest1 = cis( t1 * (
            -5.0 +
            -2 * nx^2 / L^2 * sinpi(2*nx/NL)^2 +
            -2 * ny^2 / W^2 * sinpi(2*ny/NW)^2
        )) .* ψ0

        @show maxerr = maximum(abs2, U(t1) * ψ0 - ψtest1)
        @show abs2.(U(t1) * ψ0 - ψtest1)
        @test U(t1) * ψ0 ≈ ψtest1
    end
end
