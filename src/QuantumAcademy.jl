module QuantumAcademy

import Base

using Base: Callable
using LinearAlgebra

export FinDiffHamiltonian, DenseEigenProp, wavefunction, Molecular_Structure, force_field, ionic_force

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
            return (Complex(H.nlength) / H.length)^2 + (Complex(H.nwidth) / H.width)^2 + π^2/2*(1/H.length^2*H.kpointx^2 + 1/H.width^2*H.kpointy^2) + Vij
        elseif abs(iy - jy) == 1 || abs(iy - jy) == H.nwidth - 1
            return -(Complex(H.nwidth) / H.width)^2 / 2 - H.kpointy*H.nwidth/H.width^2*π/2*sign(iy-jy - fld(iy,H.nwidth)*H.nwidth + fld(jy,H.nwidth)*H.nwidth)im
        end
    elseif iy == jy && (abs(ix - jx) == 1 || abs(ix - jx) == H.nlength - 1)
        return -(Complex(H.nlength) / H.length)^2 / 2 - H.kpointx*H.nlength/H.length^2*π/2*sign(ix-jx - fld(ix,H.nlength)*H.nlength + fld(jx,H.nlength)*H.nlength)im
    end

    return zero(Complex)
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

function Force_Calculator(F::Function, V::Function, NELECT::Int, NL::Int, NW::Int, L::Float64, W::Float64)
    #We calculate the Hellman-Feynmann forces, which are the expectation value of the derivative of the Hamiltonian with respect the state. In the Born-Oppenheimer approximation we assume that the system is always in the ground state, and we have a slater determinant of the NELECT eigenstates corresponding to the lowest energy eigenvalues. We don't actually have to calculate this, since the expectation value is just the integral over the derivative of the external potential with the density, which can be calculated as the sum of the densities of the single orbitals. Therefore, all we need are the derivative with respect to the potential and the NELECT lowest eigenvectors. 
    orbitals = eigvecs(FinDiffHamiltonian{Float64}(V, L, W, NL, NW))[1:NELECT,:]
    density = conj(orbitals[1,:]).*orbitals[1,:]
    for i in 2:NELECT
        density = density + conj(orbitals[i,:]).*orbitals[i,:]
    end
    sum(F(x/NL*L,y/NW*W)*density[x+(y-1)*NL] for x in 1:NL for y in 1:NW)
end


#This part is for implementing a simple MD algorithm, which outputs MD trajectories after getting initial structures and velocities. 
#module QuantumAcademy is used as a force calculator, where it solves the Schrödinger equation and then calculates the Hellman-Feynmann forces on the ions. 

# Define the Molecular_Structure type
mutable struct Molecular_Structure
    length::Float64
    width::Float64
    positions::Vector{Tuple{Float64, Float64}}
    speeds::Vector{Tuple{Float64, Float64}}
    potential_function::Function
    potential_params::Vector{Vector{Any}}
    num_electrons::Int
end

# Making Molecular_Structure act as an AbstractVector
Base.size(ms::Molecular_Structure) = (length(ms.positions),)
Base.getindex(ms::Molecular_Structure, i::Int) = (ms.positions[i], ms.speeds[i])
Base.setindex!(ms::Molecular_Structure, value::Tuple{Tuple{Float64, Float64}, Tuple{Float64, Float64}}, i::Int) = (
    ms.positions[i] = value[1];
    ms.speeds[i] = value[2];
)

# Function to generate the forces acting on the electrons for the entire structure
# Helper function to compute the force on a single atom
function force_field(ms::Molecular_Structure)
    return (x,y) -> begin
        δ = 1e-8
        total_dVdx = zeros(Float64,length(ms.positions))
        total_dVdy = zeros(Float64,length(ms.positions))
        for (i, (pos, params)) in enumerate(zip(ms.positions, ms.potential_params))
            # Compute the partial derivatives numerically for each atom's potential
            dVdx = (ms.potential_function(pos[1], pos[2], (x + δ, y), params...) - ms.potential_function(pos[1], pos[2], (x - δ, y), params...)) / (2 * δ)
            dVdy = (ms.potential_function(pos[1], pos[2], (x, y + δ), params...) - ms.potential_function(pos[1], pos[2], (x, y - δ), params...)) / (2 * δ)
            
            # Sum the contributions
            total_dVdx[i] += dVdx
            total_dVdy[i] += dVdy
        end
        # The force is the negative gradient of the potential
        return [-total_dVdx, -total_dVdy]
    end
end

function ionic_force(ms::Molecular_Structure)
    forcesx = zeros(Float64, length(ms.positions))
    forcesy = zeros(Float64, length(ms.positions))

    δ = 1e-8
    for i in 1:length(ms.positions)
        x, y = ms.positions[i]
        
        # Create a structure without the i-th atom
        other_positions = [ms.positions[j] for j in 1:length(ms.positions) if j != i]
        other_params = [ms.potential_params[j] for j in 1:length(ms.potential_params) if j != i]
        
        # Potential function excluding the i-th atom
        potential_excluding_i(x, y) = sum(ms.potential_function(pos[1], pos[2], (x, y), p...) for (pos, p) in zip(other_positions, other_params))
        
        # Calculate the gradient of the potential function numerically
        dVdx = (potential_excluding_i(x + δ, y) - potential_excluding_i(x - δ, y)) / (2 * δ)
        dVdy = (potential_excluding_i(x, y + δ) - potential_excluding_i(x, y - δ)) / (2 * δ)
        
        # The force is the negative gradient of the potential
        forcesx[i] = -dVdx
        forcesy[i] = -dVdy
    end
    return [forcesx, forcesy]
end

function potential_field(ms::Molecular_Structure)
    return (x, y) -> sum(ms.potential_function(pos[1], pos[2], (x,y), params...) for (pos, params) in zip(ms.positions, ms.potential_params))
end

# Propagator function to advance the structure by one time step
function propagate(ms::Molecular_Structure, timestep::Float64, NL, NW)
    # We use the Leap-frog algorithm to update the positions and speeds at every time step. 
    ms.positions = [ (x + vx * timestep, y + vy * timestep) for ((x, y), (vx, vy)) in zip(ms.positions, ms.speeds) ]
    ms.speeds = [ (vx + fx*timestep, vy + fy*timestep) for ((fx, fy), (vx, vy)) in zip(ionic_force(ms) + Force_Calculator(force_field(ms), potential_field(ms), ms.num_electrons, NL, NW, ms.length, ms.width), ms.speeds) ]
    return ms
end

end # module QuantumAcademy
