push!(LOAD_PATH, "../src")
using QuantumAcademy
using Test
using Unitful, UnitfulAtomic
using LinearAlgebra: UniformScaling, norm
using PlotlyJS

@testset "PeriodicFinDiffHamiltonian" begin
    @testset "Constant Potential" begin
        V(x, y) = 0.0000005
        L = austrip(100u"nm") #Always x-coordinate, first coordinate
        W = austrip(200u"nm")

        NL = 10 #Always x-coordinate, first coordinate
        NW = 10 

        H = FinDiffHamiltonian{Float64}(V, L, W, NL, NW)

        @test H.length isa Float64
        @test H.width isa Float64
        @test H.nlength isa Int
        @test H.nwidth isa Int

        @test eltype(H) == Float64
        @test size(H) == (NL * NW, NL * NW)

        ial2 = (NL / L)^2
        iaw2 = (NW / W)^2
        if NL > 3 && NW > 3
            @test H[1:3, 1:3] ≈ [
                0.0000005+ial2+iaw2      -ial2/2            0;
                -ial2/2      0.0000005+ial2+iaw2      -ial2/2;
                        0      -ial2/2  0.0000005+ial2+iaw2]
        end #Won't work for smaller sizes

        U = DenseEigenProp(H)

        @test U(0) ≈ Matrix(UniformScaling(1), NL * NW, NL * NW)
        
        nx = 2
        ny = 3
        ψ0 = wavefunction((x, y) -> cospi(2*x*nx/NL + 2*y*ny/NW), NL, NW)
        #display(plot(heatmap(z=reshape(ψ0, (NL,NW)))))
        t1 = austrip(100u"ns")

        @test U(t1)*adjoint(U(t1)) ≈ Matrix(UniformScaling(1), NL * NW, NL * NW)

        # for nxe in range(-NL,NL), nye in range(-NW,NW)
        #     ψ0e = wavefunction((x, y) -> cospi(2*x*nxe/NL + 2*y*nye/NW), NL, NW)
        #     @test abs((adjoint(ψ0e) * U(t1) * ψ0e)/norm(ψ0e)^2) ≈ 1.0
        # end

        E_0 = 2(sinpi(nx/NL)^2*(NL/L)^2 + sinpi(ny/NW)^2*(NW/W)^2) + 0.0000005

        ψtest1 = cis( -t1 * E_0) .* ψ0
        @test abs((adjoint(ψ0) * U(t1) * ψ0)) ≈ 1.0
        @test adjoint(ψ0) * H * ψ0/(adjoint(ψ0) * ψ0) ≈ E_0 + im*0
        @test U(t1) * ψ0 ≈ ψtest1
    end
end
