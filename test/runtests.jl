using QuantumAcademy
using Test
using Unitful, UnitfulAtomic
using LinearAlgebra

@testset "PeriodicFinDiffHamiltonian" begin
    @testset "Constant Potential" begin
        V(x, y) = 5.0
        V0 = V(0, 0)

        # x-coordinate is first coordinate
        NL = 8
        NW = 16
        L = austrip(100u"nm")
        W = austrip(200u"nm")

        H = FinDiffHamiltonian{Float64}(V, L, W, NL, NW)

        @test H.length isa Float64
        @test H.width isa Float64
        @test H.nlength isa Int
        @test H.nwidth isa Int

        @test eltype(H) == Complex
        @test size(H) == (NL * NW, NL * NW)

        ial2 = (NL / L)^2
        iaw2 = (NW / W)^2
        @test H[1:3, 1:3] ≈ [
            V0+ial2+iaw2       -ial2/2             0;
                 -ial2/2  V0+ial2+iaw2       -ial2/2;
                       0       -ial2/2  V0+ial2+iaw2]

        U = DenseEigenProp(H)

        @test U(0) ≈ Matrix(UniformScaling{ComplexF64}(1), NL * NW, NL * NW)

        nx = 2
        ny = 3
        ψ0 = wavefunction((x, y) -> cospi(2*x*nx + 2*y*ny), NL, NW)
        E = 2(sinpi(nx/NL)^2*(NL/L)^2 + sinpi(ny/NW)^2*(NW/W)^2) + V0

        @test abs(norm(ψ0) - 1) < 1e-12

        t1 = 231.7

        ψ1 = U(t1) * ψ0
        ψtest1 = cis(-t1 * E) .* ψ0
        ψtest2 = cis(Hermitian(-t1 * H)) * ψ0

        @test U(t1)' * U(t1) ≈ Matrix(UniformScaling{ComplexF64}(1), NL * NW, NL * NW)

        @test abs(norm(ψ1) - 1) < 1e-12
        @test abs(dot(ψ0, ψ1) - cis(-t1 * E)) < 1e-12
        @test abs(dot(ψ0, ψtest2) - cis(-t1 * E)) < 1e-12

        @test maximum(abs, U(2π / E) * ψ0 .- ψ0) < 1e-12
        @test maximum(abs, U(π / E) * ψ0 .+ ψ0) < 1e-12

        # Energy
        @test abs(dot(ψ0, H, ψ0) / dot(ψ0, ψ0) - E) < 1e-12
        @test abs(dot(ψ1, H, ψ1) - dot(ψ0, H, ψ0)) < 1e-12
        @test abs(dot(ψtest1, H, ψtest1) - dot(ψ0, H, ψ0)) < 1e-12
        @test abs(dot(ψtest2, H, ψtest2) - dot(ψ0, H, ψ0)) < 1e-12

        @test maximum(abs, H * ψ0 .- E * ψ0) < 1e-12
        @test maximum(abs, ψ1 .- ψtest1) < 1e-12
        @test maximum(abs, ψ1 .- ψtest2) < 1e-12

        H2 = FinDiffHamiltonian{Float64}(V, L, W, NL, NW, kpointx=0.1, kpointy=0.1)
        @test  eltype(H2) == Complex
        @show H2[1:3, 1:3]
    end
end

@testset "Molecular_Dynamics" begin
    
    function ionic_potential(ionx,iony,(x,y),scale)
        return scale/sqrt((ionx-x)^2 + (iony - y)^2)
    end

    NL = 8
    NW = 16
    L = austrip(100u"nm")
    W = austrip(200u"nm")

    initial_positions = [(0.1, 0.1), (0.2,0.2), (0.3,0.3)]
    initial_velocities = [(0.1, 0.1), (-0.1,-0.1), (0.3,0.3)]
    scales = [[0.01],[0.01],[0.01]]
    num_electrons = 3

    Structure = Molecular_Structure(L,W,initial_positions, initial_velocities, ionic_potential, scales,num_electrons)
    @test Structure.length isa Float64
    @test Structure.width isa Float64
    Structuredeltat = QuantumAcademy.propagate(Structure, 0.001, NL, NW)
    @show sum(force_field(Structure)(x/NL*L,y/NW*W) for x in 1:NL for y in 1:NW)
    @show ionic_force(Structure)

end