module QuantumAcademy

import Base

using Base: Callable
using LinearAlgebra: eigen

export FinDiffHamiltonian, DenseEigenProp, wavefunction

struct FinDiffHamiltonian{T <: Real, F <: Callable} <: AbstractMatrix{T}
    potential::F
    length::T
    width::T
    nlength::Int
    nwidth::Int
end

function FinDiffHamiltonian{T}(
    potential::F,
    length::T,
    width::T,
    nlength::Int,
    nwidth::Int
) where {T <: Real, F <: Callable}
    FinDiffHamiltonian{T, F}(potential, length, width, nlength, nwidth)
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
            Vij = H.potential(T((ix-1) // (H.nlength - 1)), T((iy-1) // (H.nwidth - 1)))
            return (T(H.nlength) / H.length)^2 + (T(H.nwidth) / H.width)^2 + Vij
        elseif abs(iy - jy) == 1 || abs(iy - jy) == H.nlength - 1
            return -(T(H.nwidth) / H.width)^2 / 2
        end
    elseif iy == jy && (abs(ix - jx) == 1 || abs(ix - jx) == H.nwidth - 1)
        return -(T(H.nlength) / H.length)^2 / 2
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
    vals, vecs = eigen(convert(Matrix{T}, hamiltonian); sortby=nothing)
    DenseEigenProp{T, TH}(hamiltonian, vals, vecs, similar(vecs))
end

function DenseEigenProp(hamiltonian::TH) where TH
    DenseEigenProp{eltype(TH)}(hamiltonian)
end

function (prop::DenseEigenProp)(t::Real)
    for j in axes(prop.hamiltonian, 1)
        c = cis(-prop.values[j] * t)
        for i in axes(prop.hamiltonian, 1)
            prop.scratch[i, j] = c * prop.vectors[i, j]
        end
    end
    prop.scratch * prop.vectors'
end

wavefunction(ψ, nlength, nwidth) = vec([
    ψ(x, y) for x in range(0, 1; length=nlength), y in range(0, 1; length=nwidth)
])

end # module QuantumAcademy
