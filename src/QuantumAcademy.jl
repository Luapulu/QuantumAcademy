module QuantumAcademy

import Base

using Base: Callable
using LinearAlgebra

export FinDiffHamiltonian, DenseEigenProp, wavefunction

struct FinDiffHamiltonian{T <: Real, F <: Callable} <: AbstractMatrix{Complex}
    potential::F
    length::T
    width::T
    nlength::Int
    nwidth::Int
    kpointx::T
    kpointy::T
end

function FinDiffHamiltonian{T}(
    potential::F,
    length::Real,
    width::Real,
    nlength::Int,
    nwidth::Int;
    kpointx::T=0.0,
    kpointy::T=0.0
) where {T <: Real, F <: Callable}
    FinDiffHamiltonian{T, F}(potential, length, width, nlength, nwidth, kpointx, kpointy)
end

function Base.size(H::FinDiffHamiltonian)
    N = H.nlength * H.nwidth
    return (N, N)
end

function _to_cartesian_index(i, n)
    d = fld(i-1, n)
    ix = i - d * n
    iy = d + 1
    return ix, iy
end

function Base.getindex(H::FinDiffHamiltonian{T}, i::Int, j::Int) where T
    ix, iy = _to_cartesian_index(i, H.nlength)
    jx, jy = _to_cartesian_index(j, H.nlength)

    if ix == jx
        if iy == jy
            Vij = H.potential(T((ix-1) // H.nlength), T((iy-1) // H.nwidth))
            return (T(H.nlength) / H.length)^2 + (T(H.nwidth) / H.width)^2 + π^2/2*(1/H.length^2*H.kpointx^2 + 1/H.width^2*H.kpointy^2) + Vij
        elseif abs(iy - jy) == 1 || abs(iy - jy) == H.nwidth - 1
            return -(T(H.nwidth) / H.width)^2 / 2 - H.kpointy*H.nwidth/H.width^2*π/2*sign(iy-jy - fld(iy,H.nwidth)*H.nwidth + fld(jy,H.nwidth)*H.nwidth)im
        end
    elseif iy == jy && (abs(ix - jx) == 1 || abs(ix - jx) == H.nlength - 1)
        return -(T(H.nlength) / H.length)^2 / 2 - H.kpointx*H.nlength/H.length^2*π/2*sign(ix-jx - fld(ix,H.nlength)*H.nlength + fld(jx,H.nlength)*H.nlength)im
    end

    return zero(T)
end

struct DenseEigenProp{T <: Real, TH}
    hamiltonian::TH
    values::Vector{T}
    vectors::Matrix{Complex{T}}
    scratch::Matrix{Complex{T}}
end

function DenseEigenProp{T}(hamiltonian::TH) where {T <: Real, TH}
    vals, vecs = eigen(convert(Matrix{Complex}, hamiltonian); sortby=nothing)
    DenseEigenProp{T, TH}(hamiltonian, vals, vecs, similar(vecs))
end

function DenseEigenProp(hamiltonian::TH) where TH
    DenseEigenProp{Real}(hamiltonian)
end

function (prop::DenseEigenProp{T})(t::Real) where T
    for j in axes(prop.hamiltonian, 1)
        c = cis(-prop.values[j] * T(t))
        for i in axes(prop.hamiltonian, 1)
            prop.scratch[i, j] = c * prop.vectors[i, j]
        end
    end
    prop.scratch * prop.vectors'
end

function wavefunction(ψ, nlength, nwidth; normalise=true)
    rx = range(0; step=1/nlength, length=nlength)
    ry = range(0;  step=1/nwidth,  length=nwidth)
    v = vec([ψ(x, y) for x in rx, y in ry])
    normalise && normalize!(v)
    return v
end

function calculate_bandstructure(V, L, W, NL, NW, path)
    #This function serves to calculate the band structure of the cell. The basic assumption is that the periodic boundary conditions are representative of an infinite perfect crystal, so the Hamiltonian can be rewritten as one for Bloch functions. We'll use the existing (finite difference) numerical implementation of the Hamiltonian, and only add the option to specify the k-point. The Hamiltonian then must be diagonalised at each k-point (So, very expensive!), and this gives us the energy levels at that k-point. Then simply return a list of energy eigenvalues for every k-point in path. Note that the eigenvectors are not the true wavefunctions, but the Bloch-functions.
    energies = Array{Float64}(undef, NL*NW, size(path,1))
    for i in 1:size(path,1)
        H = FinDiffHamiltonian{Float64}(V, L, W, NL, NW; kpointx = path[i,1], kpointy =path[i,2])
        energies[:,i] = eigvals(H)
    end
    return energies
end

end # module QuantumAcademy
