### A Pluto.jl notebook ###
# v0.19.45

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ e22afb18-acbe-49ec-8b0f-0d5d311b9e09
begin
	import LinearAlgebra
	using LinearAlgebra
end

# ╔═╡ f49b5d6e-464f-49d0-a3f2-1af2084d6dc2
using PlutoTest

# ╔═╡ 30a856d7-01f1-411a-ab26-589dfbed9a73
using PlutoUI: Slider

# ╔═╡ 52aaf95c-818a-495b-86c3-d1cc73f60033
using Base: Callable

# ╔═╡ edbc5861-96b0-4d29-b158-f60f82c77f37
using KrylovKit

# ╔═╡ 896a6291-0027-4849-85cf-43e05082e5a8
using GLMakie

# ╔═╡ dcbacb58-a77d-4ec2-aa10-bf6b72d5f33e
import Base

# ╔═╡ 51954bdb-3cd7-428e-a7ad-7a02be2f06b4
function wavefunction(ψ, nx, ny; normalise=true)
    rx = range(0; step=1/nx, length=nx)
    ry = range(0;  step=1/ny,  length=ny)
    mat = [ψ(x, y) for x in rx, y in ry]
    normalise && normalize!(mat)
    return mat
end

# ╔═╡ 504fa869-0faa-4f0c-943a-94dd1b57757b
testnx, testny = (6, 6)

# ╔═╡ e6a95c73-cc53-4323-a033-afb10b5511c3
testnn = testnx * testny

# ╔═╡ 44773e3c-37e1-4c1f-a859-c20943edd5f2
testv = randn(testnn)

# ╔═╡ 989bbaf8-f3e1-4c0e-941b-25480bbcb272
testwf = wavefunction(testnx, testny) do x, y
	cospi(4x) * sinpi(2y)
end

# ╔═╡ e4abdbe5-9da6-4454-9817-d97cbc471c93
begin
	abstract type BoundaryCondition end
	struct Periodic <: BoundaryCondition end
	struct Box <: BoundaryCondition end
end

# ╔═╡ 9e7c66f3-a2f2-4470-bd7b-651963a8ad77
begin #We Change one thing about the Hamiltonian: We add the k-points
	struct FinDiffHamiltonian{
	    BC <: BoundaryCondition,
	    T <: Real,
	    F <: Callable
	} <: AbstractMatrix{ComplexF64}
	    V::F
	    xlen::T
	    ylen::T
		kx::T
		ky::T
	    nx::Int
	    ny::Int
		function FinDiffHamiltonian{BC, T, F}(V, xlen, ylen, kx, ky, nx, ny) where {
			BC <: BoundaryCondition, T <: Real, F <: Callable
		}
			nx < 3 && throw(ArgumentError("nx=$nx must not be smaller than 3"))
			#ny < 3 && throw(ArgumentError("ny=$ny must not be smaller than 3"))
			new{BC, T, F}(V, xlen, ylen, kx, ky, nx, ny)
		end
	end

	function FinDiffHamiltonian{BC, T}(V::F, xlen, ylen, kx, ky, nx, ny) where {
		BC <: BoundaryCondition, T <: Real, F <: Callable
	}
		FinDiffHamiltonian{BC, T, F}(V::F, xlen, ylen, kx, ky, nx, ny)
	end

	function FinDiffHamiltonian{BC}(V::F, xlen::TX, ylen::TY, kx::TZ, ky::TA, nx, ny) where {
		BC <: BoundaryCondition, TX <: Real, TY <: Real, TZ <: Real, TA <: Real, F <: Callable
	}
		FinDiffHamiltonian{BC, promote_type(promote_type(TX, TY), promote_type(TZ, TA)), F}(V::F, xlen, ylen, kx, ky, nx, ny)
	end
end

# ╔═╡ c23f8ec1-694a-473e-8486-f854aaadcc62
const FDH = FinDiffHamiltonian

# ╔═╡ a548bf6d-02fa-4fed-97a3-ba48e35f6f7f
Base.size(H::FinDiffHamiltonian) = (N = H.nx * H.ny; (N, N))

# ╔═╡ f6116b00-3e5c-4fde-a7fa-2b7444c66fa3
testxl, testyl = (3.5, 8.0)

# ╔═╡ 74930cbb-7b22-49aa-962a-a9d1a631f454
testkx, testky = (0.5, 0.5)

# ╔═╡ 97dbb2a4-d43f-4401-a167-8862837c196f
testV(x, y) = sinpi(4x) * cospi(2*y)

# ╔═╡ f3ed8512-bd49-4b7c-bd97-d5316a0fa9a5
testH = FinDiffHamiltonian{Periodic}(testV, testxl, testyl, testkx, testky, testnx, testny)

# ╔═╡ 50bf1130-d60d-40d4-aea0-024af72a69bd
# non-allocating version of Base reshape.
# Makes no difference in benchmarking, but let's optimise just cause we can.
reshape2(a, dims) = invoke(Base._reshape, Tuple{AbstractArray,typeof(dims)}, a, dims)

# ╔═╡ 7af30430-cacc-4956-919c-d5707ec0cbf1
function LinearAlgebra.mul!(
	w::AbstractVector, H::FinDiffHamiltonian{Periodic, T}, v::AbstractVector
) where T <: Real
	
	wmat = reshape2(w, (H.nx, H.ny))
	vmat = reshape2(v, (H.nx, H.ny))

	ax = (H.nx / H.xlen)^2
	ay = (H.ny / H.ylen)^2
	h  = T(1//2)

	V(ix, iy) = H.V(T((ix-1) // H.nx), T((iy-1) // H.ny))

	# adding @inbounds and @simd doesn't improve performance much
	Threads.@threads for iy in 1:H.ny
		iyb = mod1(iy-1, H.ny)
		iyt = mod1(iy+1, H.ny)

		# left
		H1y  = (ax * (-h) + H.kx*H.nx/H.xlen^2*π/2*im) * vmat[end, iy] + (ax +(π^2/2)/H.xlen^2*H.kx^2) * vmat[1, iy] + (ax * (-h) - H.kx*H.nx/H.xlen^2*π/2*im) * vmat[2, iy]#Kinetic energy in x-direction, including contribution from k-vector
		H1y += (ay * (-h) + H.ky*H.ny/H.ylen^2*π/2*im) * vmat[1, iyb] + (ay + (π^2/2)/H.ylen^2*H.ky^2) * vmat[1, iy] + (ay * (-h) - H.ky*H.ny/H.ylen^2*π/2*im) * vmat[1, iyt]#Kinetic energy in y-direction, including contribution from k-vector
		H1y += V(1, iy) * vmat[1, iy]#Potential energy term
		wmat[1, iy] = H1y

		# middle
		for ix in 2:(H.nx-1)
			# 10% faster not to evaluate mod1 for ix indices here
			Hxy  = (ax * (-h) + H.kx*H.nx/H.xlen^2*π/2*im) * vmat[ix-1, iy] + (ax +(π^2/2)/H.xlen^2*H.kx^2) * vmat[ix, iy] + (ax * (-h) - H.kx*H.nx/H.xlen^2*π/2*im) * vmat[ix+1, iy]#Kinetic energy in x-direction, including contribution from k-vector
			Hxy += (ay * (-h) + H.ky*H.ny/H.ylen^2*π/2*im) * vmat[ix, iyb] + (ay + (π^2/2)/H.ylen^2*H.ky^2) * vmat[ix, iy] + (ay * (-h) - H.ky*H.ny/H.ylen^2*π/2*im) * vmat[ix, iyt]#Kinetic energy in y-direction, including contribution from k-vector
			Hxy += V(ix, iy) * vmat[ix, iy] #Potential energy term
			wmat[ix, iy] = Hxy
		end

		# right
		Hey  = (ax * (-h) + H.kx*H.nx/H.xlen^2*π/2*im) * vmat[end-1, iy] + (ax +(π^2/2)/H.xlen^2*H.kx^2) * vmat[end, iy] + (ax * (-h) - H.kx*H.nx/H.xlen^2*π/2*im) * vmat[1, iy]#Kinetic energy in x-direction
		Hey += (ay * (-h) + H.ky*H.ny/H.ylen^2*π/2*im) * vmat[end, iyb] + (ay + (π^2/2)/H.ylen^2*H.ky^2) * vmat[end, iy] + (ay * (-h) - H.ky*H.ny/H.ylen^2*π/2*im) * vmat[end, iyt]#Kinetic energy in y-direction
		Hey += V(H.nx, iy) * vmat[end, iy]#Potential energy term
		wmat[end, iy] = Hey
	end

	conj(w)
end

# ╔═╡ 98600be8-5246-41b6-8100-b221e76ee818
function Base.getindex(
	H::FDH{Periodic, T}, (ix, iy), (jx, jy)
) where T <: Real
	@boundscheck begin
		checkbounds(H, ix, iy)
		checkbounds(H, jx, jy)
	end
    ax = (H.nx / H.xlen)^2
    ay = (H.ny / H.ylen)^2
    if ix == jx
        if iy == jy
            Vxy = H.V(T((ix-1) // H.nx), T((iy-1) // H.ny))
            return Complex(ax + ay +  π^2/2*(1/H.xlen^2*H.kx^2 + 1/H.ylen^2*H.ky^2)+ Vxy)
        elseif abs(iy - jy) == 1 
            return -ay / 2 - H.ky*H.ny/H.ylen^2*π/2*sign(iy - jy)im
		elseif abs(iy - jy) == H.ny - 1
			return -ay / 2 + H.ky*H.ny/H.ylen^2*π/2*sign(iy - jy)im
        end
    elseif iy == jy && abs(ix - jx) == 1 
        return -ax / 2 - H.kx*H.nx/H.xlen^2*π/2*sign(ix - jx)im
	elseif iy == jy && abs(ix - jx) == H.nx - 1
		return -ax / 2 + H.kx*H.nx/H.xlen^2*π/2*sign(ix - jx)im
    end

    return zero(Complex)
end

# ╔═╡ fa349d2c-4db0-4293-a956-91d9cbe686b4
function Base.getindex(H::FDH{Periodic, T}, i::Integer, j::Integer) where T <: Real
	inds = Base.CartesianIndices((H.nx, H.ny))
	ic = inds[i] |> Tuple
	jc = inds[j] |> Tuple
	return H[ic, jc]
end

# ╔═╡ bec6b558-b794-4d7e-9dd0-fba13a4b5c61
md"### Wave Function"

# ╔═╡ 61883ba0-0da8-43ec-9f3a-e5f6367492f3
md"### Finite Differences Hamiltonian"

# ╔═╡ 2dc5d157-0e41-42d8-9462-4c3dfe67ac4e
@test testH * testv ≈ Matrix(testH) * testv

# ╔═╡ d36a8189-ec05-4f51-9eb1-0125332bde43
permutedims(hcat([testH * [i == j ? 1 : 0 for i in 1:size(testH)[1]] for j in 1:size(testH)[1]]...)) - transpose(Matrix(testH))

# ╔═╡ c1d6ca48-e9b5-46ac-944a-4ef6c97b0588
Base.size(testH)

# ╔═╡ 2b9dce1b-22be-4448-9035-2d6804ddd4c5
@show typeof(testH)

# ╔═╡ 5133587f-265a-40a7-8d5d-08d28ccab7a7
LinearAlgebra.ishermitian(H::FinDiffHamiltonian) = true

# ╔═╡ 78553187-2839-4afd-b2aa-f500a2a87b20
@test ishermitian(testH)

# ╔═╡ c42390d6-0a93-438e-b8b1-bdaf13078a8c
@test ishermitian(Matrix(testH))

# ╔═╡ 65f5fdfd-ef28-4dc0-b20b-d73c7e34b0fd
function LinearAlgebra.opnormInf(H::FDH{Periodic})
	ax = (H.nx / H.xlen)^2
    ay = (H.ny / H.ylen)^2
	return maximum(CartesianIndices((H.nx, H.ny))) do i
		ix, iy = Tuple(i)
		Vxy = H.V((ix-1) / H.nx, (iy-1) / H.ny)
		return abs(ax + ay + Vxy) + abs(ax) + abs(ay)
	end
end

# ╔═╡ 1f657f58-99b6-4c15-b8e2-28e7f43d4841
md"# Calculating the band structure"

# ╔═╡ 97a257f0-f329-4770-be0e-bcfa4cc1cc20
md"The band structure is usually calculated along a series of paths which connect special high-symmetry points. We write a function to generate these paths:"

# ╔═╡ 70391d80-3c75-4289-9e8b-e96d21bc84e4
function pathmaker(point1, point2, length)
    point1x, point1y = point1
    point2x, point2y = point2
    pathx = range(point1x,point2x, length)
    pathy = range(point1y, point2y, length)
    return vcat(pathx', pathy')
end

# ╔═╡ b475cced-47e3-4eb3-b7fa-d4cc2163d2b9
md"Define the points:"

# ╔═╡ 13c643a7-8b24-4059-b562-27b045f5e88d
Γ = (0.0, 0.0)

# ╔═╡ ae10e404-0fe5-44e9-8f66-b28ad9e468df
Y = (0.0,0.5)

# ╔═╡ 490f5f38-fe28-4301-986d-4326e796bc78
X = (0.5,0.0)

# ╔═╡ 2ca31a82-7dff-4f8d-b52c-60d683997bfa
S = (0.5,0.5)

# ╔═╡ ba607fc6-b47f-43d0-8e61-2ffa8f439019
number = 10 #Number of points on each path

# ╔═╡ 0faf5296-0fcc-4a24-8d77-dea9dc07c570
path_part1 = pathmaker(Γ, Y,number)

# ╔═╡ 082e998f-d6ba-4532-bb11-b1452776c633
path_part2 = pathmaker(Y, S, number)

# ╔═╡ 413e6f8d-9b10-4f4c-b97d-29f8239ab5d4
path_part3 = pathmaker(S, X, number)

# ╔═╡ eec63e8a-0795-49b2-b77f-d35ad7d1746c
path_part4 = pathmaker(X, Γ, number)

# ╔═╡ fc3a9e49-8b07-49fe-b66c-2602c11aad23
full_path = vcat(path_part1',path_part2',path_part3',path_part4')

# ╔═╡ a6d894b2-54a2-4ee2-95ee-54a370e120ff
md"We define the system:"

# ╔═╡ 1c392cc4-f300-4a64-bc43-4ab035fb53cf
begin
	NL = 15
	NW = 15
	
	L = 500.0
	W = 500.0
end

# ╔═╡ 73d87fea-b054-4b6c-a7f6-379f855b7d5e
function V1(x,y)
    zero(x)
end

# ╔═╡ 8d413a89-8453-40f8-ac32-f2efdb4b7994
md"We write a function to calculate the band structure"

# ╔═╡ a6e86bb5-c8d4-4c53-8bac-241b153fcb0a
function calculate_bandstructure(V, L, W, NL, NW, path, bandmax)
    #This function serves to calculate the band structure of the cell. The basic assumption is that the periodic boundary conditions are representative of an infinite perfect crystal, so the Hamiltonian can be rewritten as one for Bloch functions. We'll use the existing (finite difference) numerical implementation of the Hamiltonian, and only add the option to specify the k-point. The Hamiltonian then must be diagonalised at each k-point (So, very expensive!), and this gives us the energy levels at that k-point. Then simply return a list of energy eigenvalues for every k-point in path. Note that the eigenvectors are not the true wavefunctions, but the Bloch-functions.
	if bandmax > NL*NW
		bandmax = NL*NW 
	end
    energies = Array{Float64}(undef, bandmax, size(path,1))
    for i in 1:size(path,1)
        H = FinDiffHamiltonian{Periodic}(V, L, W, path[i,1], path[i,2], NL, NW)
        energies[:,i] = eigvals(Hermitian(H), 1:bandmax)
    end
    return energies
end

# ╔═╡ 56306ae6-f2e3-4a30-a4a1-85249d574fa3
#We want the whole thing as a 2d plot, so the paths need to be converted to single arrays. We want the lengths of each path to correspond to that in reciprocal space, so we calculate the reciprocal lattice vectors: 
k_1 = 2π/L

# ╔═╡ 75995bcd-bf03-4471-b257-937425271da2
k_2 = 2π/W

# ╔═╡ efc8d22e-bfc3-4821-9b65-ce3c090b0da4
trafo_matrix = [[k_1, 0];;[0,k_2]]
#First we convert the path to cartesian reciprocal space coordinates:

# ╔═╡ 59050e00-b58d-4fd9-b24b-f2e63526c288
full_path_real = zeros(Float64, (size(full_path)))

# ╔═╡ 14a3b8d9-d647-4cd5-a12a-6685a034fa8c
for i in range(1,step=1, length=size(full_path)[1])
    full_path_real[i,:] = trafo_matrix*full_path[i,:]
end

#Then we use the distance between each points pairwise to get our x-values.

# ╔═╡ 3d68ffb1-6891-4b15-b136-3db1b05b0c26
x_values_for_plot = zeros(Float64, (1,size(full_path)[1]))

# ╔═╡ 02cb1431-921a-4c3e-a394-8e563278236e
for i in range(2,step=1, length=size(full_path)[1]-1)
    x_values_for_plot[i] = x_values_for_plot[i-1] + norm(full_path_real[i,:] - full_path_real[i-1,:])
end

#Now we just plot the x_values vs the y values: The energies. Since we have several bands, we iterate over them when plotting. The eigenvalues are sorted by size, so this leads to correct line plots automatically.

# ╔═╡ b91ca1bd-6ae2-4b57-837d-529174f911e7
md"Now we try with the KrylovKit, for which we write another function to calculate the band structure, this time with the different method for calculating the eigenstates."

# ╔═╡ c27909e0-3f46-4976-946f-60b2e5fa6a4d
function calculate_bandstructureK(V, L, W, NL, NW, path, bandmax)
    #This doesn't seem to work very well! I'm not totally sure why - probably a mix of different approximations that Krylov-methods make, that make getting the exact eigenvalues hard.  
    energies = Array{Float64}(undef, bandmax, Base.size(path,1))
    for i in 1:size(path,1)
        H = FinDiffHamiltonian{Periodic}(V, L, W, path[i,1], path[i,2], NL, NW)
		energies[:,i] = eigsolve(H, bandmax, :SR, krylovdim=NL*NW)[1][1:bandmax]
    end
    return energies
end

# ╔═╡ bccd9224-3169-4d5c-be79-d8500c9f8bb0
md"# We now try with a real potential!"

# ╔═╡ be744d7b-7a95-4600-b49b-34dc4fdcd181
#For a more realistic system
begin
	NL2 = 40
	NW2 = 40
	
end

# ╔═╡ f1fbbdf5-4323-4bc9-93d7-65d31acc1d03
function V2(x,y)
	return -1/sqrt((x-0.5)^2 + (y-0.5)^2 + 0.025)
end

# ╔═╡ 89b7a48f-8d51-47de-9c1c-e9d245d4c856
function V3(x,y)
	return -1/sqrt((x - 0.1)^2 + y^2 + 0.000000000000000001) + 1/sqrt((x + 0.1)^2 + y^2 + 0.000000000000000001)
end

# ╔═╡ dcf42053-e09c-473f-97cb-e41fc9192dbf
energies = calculate_bandstructure(V3, L, W, NL, NW, full_path, 1000)

# ╔═╡ 3feef9cd-c70d-459e-be90-5535577942d6
let 

	f = Figure()
ax = Axis(f[1, 1],
    title = "Band structure",
    xlabel = "k point",
    ylabel = "energy [eV]",
)


for i in range(1,step=1, length=1)
    #The object energies[i,:] is a vector of energies, each associated with the corresponding x_values_for_plot. So we just plot these against each other
    lines!(ax, vec(x_values_for_plot),energies[i,:], color = :blue)
end

f
end

# ╔═╡ 57f3eb01-1330-41e8-8abc-91c672a62827
function V4(x,y)
	return 10*sin(0.1*x)*cos(0.1*y)
end

# ╔═╡ 4751a10a-11e7-41f9-ba95-ba8654271a79
function V5(x,y)
	if sqrt((x-0.5)^2 + (y-0.5)^2 + 0.000000000000000001) < 0.1
		return -1/sqrt((x-0.5)^2 + (y-0.5)^2 + 0.000000000000000001)
	else
		return 0.0
	end
end

# ╔═╡ 4437c613-9a3a-42e3-a60c-5290764923fc
V = V2

# ╔═╡ d7b8fcfa-9eef-4403-8c21-9f39ca33c4dd
# ╠═╡ show_logs = false
energies2 = calculate_bandstructureK(V, L, W, NL, NW, full_path, 4)

# ╔═╡ 6771cd71-d2ce-4f69-abc6-0b17be7ff938
let 

	f = Figure()
ax = Axis(f[1, 1],
    title = "Band structure",
    xlabel = "k point",
    ylabel = "energy [eV]",
)


for i in range(1,step=1, length=size(energies2)[1])
    #The object energies[i,:] is a vector of energies, each associated with the corresponding x_values_for_plot. So we just plot these against each other
    lines!(ax, vec(x_values_for_plot),energies2[i,:], color = :blue)
end

f
end

# ╔═╡ fe3e2333-2911-439a-b6da-4a6004e7fa62
md"We want to visualize which bands belong to which real-space orbital. We visualize the electronic density, and the total density is equal to the sum of the densities over all k-points. However, in this case, we don't want to take the k-points along the representative paths, since these are not distributed evenly through k-space. We want to define a grid in k-space, which includes the point (0,0), and an equally spaced grid of points, with all points between 0 and 1."

# ╔═╡ a6dff627-59ae-4312-9a69-f603fac17b38
function gridmaker(Nx, Ny)
	tuple([[i/Nx, j/Ny] for i in 0:Nx for j in 0:Ny]...)
end

# ╔═╡ 28d6afcf-bd5a-4673-a638-4510dd1b3bf9
regrid = gridmaker(2,2)

# ╔═╡ 74035528-e0d7-4ec9-bf3a-d2d7848f05fd
md"Now that we have a grid on which to calculate our k-points, we want a function similar to calculate_bandstructure(), except we want it to return not a set of eigenvalues for each k-point, but rather a charge density for each eigenvalue-level/band, summed over all k-points. 

For this, we use the eigvecs() function on the Hamiltonian, and calculate the square of each eigenvector. The result is summed over all k-points."

# ╔═╡ dfea351e-a9f2-4d03-8aa4-52819afe7f3c
function calculate_band_charges(V, L, W, NL, NW, grid, upto)
    #This function calculates the charge densities for each of the bands. It can be made more efficient, since we rarely care about ALL the bands, so you might add a way to specify over which bands the charge density should be calculated. 
	if upto > NL*NW
		upto = NL*NW
	end
    dens = zeros(NL*NW,upto)
    kdens = zeros(NL*NW,upto)
    for i in 1:size(grid,1)
        H = Hermitian(FinDiffHamiltonian{Periodic}(V, L, W, grid[i][1], grid[i][2], NL, NW))
        kdens = eigen(H, 1:upto).vectors
		for j in 1:upto
			kdens[:,j] = abs2.(kdens[:,j])
		end
		dens += Real.(kdens)
    end
    return dens
end

# ╔═╡ 6c3f4048-d685-4e76-b7ec-87cf837a77fd
bandmaxi = 200

# ╔═╡ ef12d042-cac5-4ff4-9dd5-a838073424bf
md"We now have an array whose columns are the charge densities in the cell for each energy eigenvalue. We now plot the charge density, and the bandstructure, with the band corresponding to the plotted charge density being highlighted in red."

# ╔═╡ 6a706a54-ebfe-447b-92bd-6715ed5c2747
band = 7

# ╔═╡ 59843a53-614b-472e-b7c3-8f9256843745
@bind anisotropy Slider(0.001:0.001:1)

# ╔═╡ 1a3d8eb6-0bdb-4741-9a19-8750b0f02e08
dimension = 5

# ╔═╡ b35ea1cd-1467-43c3-b3d3-1fc24fb83ab0
L2 = dimension

# ╔═╡ 311e4d05-cf9f-4c2d-8ec9-30cada21b022
W2 = dimension*anisotropy

# ╔═╡ 29c85202-9adb-4543-bea4-816e5d9b99cc
energiesP = calculate_bandstructure(V, L2, W2, NL2, NW2, full_path, bandmaxi)

# ╔═╡ 8ea0a7ea-5700-4bea-a02e-0f6269677d05
let 

	f = Figure()
ax = Axis(f[1, 1],
    title = "Band structure",
    xlabel = "k point",
    ylabel = "energy [eV]",
)


for i in range(1,step=1, length=size(energiesP)[1])[1:4]
    #The object energies[i,:] is a vector of energies, each associated with the corresponding x_values_for_plot. So we just plot these against each other
    lines!(ax, vec(x_values_for_plot),energiesP[i,:], color = :blue)
end

f
end

# ╔═╡ b278b93d-b507-4e99-817d-f1172481eb2c
chrg = calculate_band_charges(V, L2, W2, NL2, NW2, regrid, bandmaxi)

# ╔═╡ 9e0322d7-89d3-426e-be99-4d8fbf3818fb
let fig = Figure()
	wft = chrg[:,band]
	ax = Axis(fig[1, 1]; aspect=L2/W2)
	hidedecorations!(ax)
	hidespines!(ax)

	xs = range(0; step=L2/NL2, length=NL2)
	ys = range(0; step=W2/NW2, length=NW2)
	heatmap!(ax, xs, ys, reshape(abs2.(wft), (NL2, NL2)))
	
	Vs = [V(x/L2, y/W2) for x in xs, y in ys]
	contour!(ax, xs, ys, Vs; color=:white)
	
	fig
end

# ╔═╡ 3e9fd512-4280-4b25-ae26-b9b90c819ae8
let 

	f = Figure()


minband = energiesP[band,argmin(energiesP[band,:])]
maxband = energiesP[band,argmax(energiesP[band,:])]

	ax = Axis(f[1, 1],
    title = "Band structure",
    xlabel = "k point",
    ylabel = "energy [eV]",
	limits = (nothing, (minband -5*abs(minband), maxband + abs(maxband)))
)

for i in range(1,step=1, length=size(energiesP)[1])
    #The object energies[i,:] is a vector of energies, each associated with the corresponding x_values_for_plot. So we just plot these against each other
    lines!(ax, vec(x_values_for_plot),energiesP[i,:], color = :blue)
end

lines!(ax, vec(x_values_for_plot),energiesP[band,:], color = :red)

f
end

# ╔═╡ 6ed345e4-063b-467f-9783-77f05805ada1
md"Questions to think about: 

 - How are the size of the cell and the spectrum connected?
 - How does delocalisation of the charge connect to band dispersion?
 - Why does a very large cell always seem to lead to a single low energy eigenvalue?
 - What effect does anisotropy have on the band structure?
 - Which effects are physical, and which are dominated by the grain size?

One idea I have for mitigating grain size effects: Cap the potential energy at the kinetic energy that can be maximally achieved with a given grain size."

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
GLMakie = "e9467ef8-e4e7-5192-8a1a-b1aee30e663a"
KrylovKit = "0b1a1467-8014-51b9-945f-bf0ae24f4b77"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
PlutoTest = "cb4044da-4d16-4ffa-a6a3-8cad7f73ebdc"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
GLMakie = "~0.10.3"
KrylovKit = "~0.8.1"
PlutoTest = "~0.2.2"
PlutoUI = "~0.7.59"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.4"
manifest_format = "2.0"
project_hash = "3e76eb8f10bd0cb493025ff8c2a5c6e0894d9750"

[[deps.AbstractFFTs]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "d92ad398961a3ed262d8bf04a1a2b8340f915fef"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.5.0"
weakdeps = ["ChainRulesCore", "Test"]

    [deps.AbstractFFTs.extensions]
    AbstractFFTsChainRulesCoreExt = "ChainRulesCore"
    AbstractFFTsTestExt = "Test"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "6e1d2a35f2f90a4bc7c2ed98079b2ba09c35b83a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.2"

[[deps.AbstractTrees]]
git-tree-sha1 = "2d9c9a55f9c93e8887ad391fbae72f8ef55e1177"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.4.5"

[[deps.Adapt]]
deps = ["LinearAlgebra", "Requires"]
git-tree-sha1 = "6a55b747d1812e699320963ffde36f1ebdda4099"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "4.0.4"
weakdeps = ["StaticArrays"]

    [deps.Adapt.extensions]
    AdaptStaticArraysExt = "StaticArrays"

[[deps.AliasTables]]
deps = ["PtrArrays", "Random"]
git-tree-sha1 = "9876e1e164b144ca45e9e3198d0b689cadfed9ff"
uuid = "66dad0bd-aa9a-41b7-9441-69ab47430ed8"
version = "1.1.3"

[[deps.Animations]]
deps = ["Colors"]
git-tree-sha1 = "e81c509d2c8e49592413bfb0bb3b08150056c79d"
uuid = "27a7e980-b3e6-11e9-2bcd-0b925532e340"
version = "0.4.1"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Automa]]
deps = ["PrecompileTools", "TranscodingStreams"]
git-tree-sha1 = "588e0d680ad1d7201d4c6a804dcb1cd9cba79fbb"
uuid = "67c07d97-cdcb-5c2c-af73-a7f9c32a568b"
version = "1.0.3"

[[deps.AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "01b8ccb13d68535d73d2b0c23e39bd23155fb712"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.1.0"

[[deps.AxisArrays]]
deps = ["Dates", "IntervalSets", "IterTools", "RangeArrays"]
git-tree-sha1 = "16351be62963a67ac4083f748fdb3cca58bfd52f"
uuid = "39de3d68-74b9-583c-8d2d-e117c070f3a9"
version = "0.4.7"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9e2a6b69137e6969bab0152632dcb3bc108c8bdd"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+1"

[[deps.CEnum]]
git-tree-sha1 = "389ad5c84de1ae7cf0e28e381131c98ea87d54fc"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.5.0"

[[deps.CRC32c]]
uuid = "8bf52ea8-c179-5cab-976a-9e18b702a9bc"

[[deps.CRlibm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e329286945d0cfc04456972ea732551869af1cfc"
uuid = "4e9b3aee-d8a1-5a3d-ad8b-7d824db253f0"
version = "1.0.1+0"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "a2f1c8c668c8e3cb4cca4e57a8efdb09067bb3fd"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.18.0+2"

[[deps.Calculus]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f641eb0a4f00c343bbc32346e1217b86f3ce9dad"
uuid = "49dc2e85-a5d0-5ad3-a950-438e2897f1b9"
version = "0.5.1"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra"]
git-tree-sha1 = "71acdbf594aab5bbb2cec89b208c41b4c411e49f"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.24.0"
weakdeps = ["SparseArrays"]

    [deps.ChainRulesCore.extensions]
    ChainRulesCoreSparseArraysExt = "SparseArrays"

[[deps.ColorBrewer]]
deps = ["Colors", "JSON", "Test"]
git-tree-sha1 = "61c5334f33d91e570e1d0c3eb5465835242582c4"
uuid = "a2cac450-b92f-5266-8821-25eda20663c8"
version = "0.4.0"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "PrecompileTools", "Random"]
git-tree-sha1 = "4b270d6465eb21ae89b732182c20dc165f8bf9f2"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.25.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "b10d0b65641d57b8b4d5e234446582de5047050d"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.5"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "Requires", "Statistics", "TensorCore"]
git-tree-sha1 = "a1f44953f2382ebb937d60dafbe2deea4bd23249"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.10.0"
weakdeps = ["SpecialFunctions"]

    [deps.ColorVectorSpace.extensions]
    SpecialFunctionsExt = "SpecialFunctions"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "362a287c3aa50601b0bc359053d5c2468f0e7ce0"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.11"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "b1c55339b7c6c350ee89f2c1604299660525b248"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.15.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.ConstructionBase]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "260fd2400ed2dab602a7c15cf10c1933c59930a2"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.5.5"
weakdeps = ["IntervalSets", "StaticArrays"]

    [deps.ConstructionBase.extensions]
    ConstructionBaseIntervalSetsExt = "IntervalSets"
    ConstructionBaseStaticArraysExt = "StaticArrays"

[[deps.Contour]]
git-tree-sha1 = "439e35b0b36e2e5881738abc8857bd92ad6ff9a8"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.6.3"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "1d0a14036acb104d9e89698bd408f63ab58cdc82"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.20"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelaunayTriangulation]]
deps = ["EnumX", "ExactPredicates", "Random"]
git-tree-sha1 = "1755070db557ec2c37df2664c75600298b0c1cfc"
uuid = "927a84f5-c5f4-47a5-9785-b46e178433df"
version = "1.0.3"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Distributions]]
deps = ["AliasTables", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SpecialFunctions", "Statistics", "StatsAPI", "StatsBase", "StatsFuns"]
git-tree-sha1 = "9c405847cc7ecda2dc921ccf18b47ca150d7317e"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.109"

    [deps.Distributions.extensions]
    DistributionsChainRulesCoreExt = "ChainRulesCore"
    DistributionsDensityInterfaceExt = "DensityInterface"
    DistributionsTestExt = "Test"

    [deps.Distributions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    DensityInterface = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
    Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.DualNumbers]]
deps = ["Calculus", "NaNMath", "SpecialFunctions"]
git-tree-sha1 = "5837a837389fccf076445fce071c8ddaea35a566"
uuid = "fa6b7ba4-c1ee-5f82-b5fc-ecf0adba8f74"
version = "0.6.8"

[[deps.EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e3290f2d49e661fbd94046d7e3726ffcb2d41053"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.2.4+0"

[[deps.EnumX]]
git-tree-sha1 = "bdb1942cd4c45e3c678fd11569d5cccd80976237"
uuid = "4e289a0a-7415-4d19-859d-a7e5c4648b56"
version = "1.0.4"

[[deps.ExactPredicates]]
deps = ["IntervalArithmetic", "Random", "StaticArrays"]
git-tree-sha1 = "b3f2ff58735b5f024c392fde763f29b057e4b025"
uuid = "429591f6-91af-11e9-00e2-59fbe8cec110"
version = "2.2.8"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1c6317308b9dc757616f0b5cb379db10494443a7"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.6.2+0"

[[deps.Extents]]
git-tree-sha1 = "94997910aca72897524d2237c41eb852153b0f65"
uuid = "411431e0-e8b7-467b-b5e0-f676ba4f2910"
version = "0.1.3"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "PCRE2_jll", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "ab3f7e1819dba9434a3a5126510c8fda3a4e7000"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "6.1.1+0"

[[deps.FFTW]]
deps = ["AbstractFFTs", "FFTW_jll", "LinearAlgebra", "MKL_jll", "Preferences", "Reexport"]
git-tree-sha1 = "4820348781ae578893311153d69049a93d05f39d"
uuid = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
version = "1.8.0"

[[deps.FFTW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c6033cc3892d0ef5bb9cd29b7f2f0331ea5184ea"
uuid = "f5851436-0d7a-5f13-b9de-f02708fd171a"
version = "3.3.10+0"

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "82d8afa92ecf4b52d78d869f038ebfb881267322"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.16.3"

[[deps.FilePaths]]
deps = ["FilePathsBase", "MacroTools", "Reexport", "Requires"]
git-tree-sha1 = "919d9412dbf53a2e6fe74af62a73ceed0bce0629"
uuid = "8fc22ac5-c921-52a6-82fd-178b2807b824"
version = "0.8.3"

[[deps.FilePathsBase]]
deps = ["Compat", "Dates", "Mmap", "Printf", "Test", "UUIDs"]
git-tree-sha1 = "9f00e42f8d99fdde64d40c8ea5d14269a2e2c1aa"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.21"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FillArrays]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "0653c0a2396a6da5bc4766c43041ef5fd3efbe57"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "1.11.0"
weakdeps = ["PDMats", "SparseArrays", "Statistics"]

    [deps.FillArrays.extensions]
    FillArraysPDMatsExt = "PDMats"
    FillArraysSparseArraysExt = "SparseArrays"
    FillArraysStatisticsExt = "Statistics"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Zlib_jll"]
git-tree-sha1 = "db16beca600632c95fc8aca29890d83788dd8b23"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.96+0"

[[deps.Format]]
git-tree-sha1 = "9c68794ef81b08086aeb32eeaf33531668d5f5fc"
uuid = "1fa38f19-a742-5d3f-a2b9-30dd87b9d5f8"
version = "1.3.7"

[[deps.FreeType]]
deps = ["CEnum", "FreeType2_jll"]
git-tree-sha1 = "907369da0f8e80728ab49c1c7e09327bf0d6d999"
uuid = "b38be410-82b0-50bf-ab77-7b57e271db43"
version = "4.1.1"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "5c1d8ae0efc6c2e7b1fc502cbe25def8f661b7bc"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.13.2+0"

[[deps.FreeTypeAbstraction]]
deps = ["ColorVectorSpace", "Colors", "FreeType", "GeometryBasics"]
git-tree-sha1 = "2493cdfd0740015955a8e46de4ef28f49460d8bc"
uuid = "663a7486-cb36-511b-a19d-713bb74d65c9"
version = "0.10.3"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1ed150b39aebcc805c26b93a8d0122c940f64ce2"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.14+0"

[[deps.GLFW]]
deps = ["GLFW_jll"]
git-tree-sha1 = "35dbc482f0967d8dceaa7ce007d16f9064072166"
uuid = "f7f18e0c-5ee9-5ccd-a5bf-e8befd85ed98"
version = "3.4.1"

[[deps.GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll"]
git-tree-sha1 = "ff38ba61beff76b8f4acad8ab0c97ef73bb670cb"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.3.9+0"

[[deps.GLMakie]]
deps = ["ColorTypes", "Colors", "FileIO", "FixedPointNumbers", "FreeTypeAbstraction", "GLFW", "GeometryBasics", "LinearAlgebra", "Makie", "Markdown", "MeshIO", "ModernGL", "Observables", "PrecompileTools", "Printf", "ShaderAbstractions", "StaticArrays"]
git-tree-sha1 = "4e351a8ce824acea8dcefcd6cfe0cd8c2ea130e3"
uuid = "e9467ef8-e4e7-5192-8a1a-b1aee30e663a"
version = "0.10.3"

[[deps.GPUArraysCore]]
deps = ["Adapt"]
git-tree-sha1 = "ec632f177c0d990e64d955ccc1b8c04c485a0950"
uuid = "46192b85-c4d5-4398-a991-12ede77f4527"
version = "0.1.6"

[[deps.GeoInterface]]
deps = ["Extents"]
git-tree-sha1 = "801aef8228f7f04972e596b09d4dba481807c913"
uuid = "cf35fbd7-0cd7-5166-be24-54bfbe79505f"
version = "1.3.4"

[[deps.GeometryBasics]]
deps = ["EarCut_jll", "Extents", "GeoInterface", "IterTools", "LinearAlgebra", "StaticArrays", "StructArrays", "Tables"]
git-tree-sha1 = "b62f2b2d76cee0d61a2ef2b3118cd2a3215d3134"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.4.11"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE2_jll", "Zlib_jll"]
git-tree-sha1 = "7c82e6a6cd34e9d935e9aa4051b66c6ff3af59ba"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.80.2+0"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[deps.GridLayoutBase]]
deps = ["GeometryBasics", "InteractiveUtils", "Observables"]
git-tree-sha1 = "fc713f007cff99ff9e50accba6373624ddd33588"
uuid = "3955a311-db13-416c-9275-1d80ed98e5e9"
version = "0.11.0"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "129acf094d168394e80ee1dc4bc06ec835e510a3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+1"

[[deps.HypergeometricFunctions]]
deps = ["DualNumbers", "LinearAlgebra", "OpenLibm_jll", "SpecialFunctions"]
git-tree-sha1 = "f218fe3736ddf977e0e772bc9a586b2383da2685"
uuid = "34004b35-14d8-5ef3-9330-4cdb6864b03a"
version = "0.3.23"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "b6d6bfdd7ce25b0f9b2f6b3dd56b2673a66c8770"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.5"

[[deps.ImageAxes]]
deps = ["AxisArrays", "ImageBase", "ImageCore", "Reexport", "SimpleTraits"]
git-tree-sha1 = "2e4520d67b0cef90865b3ef727594d2a58e0e1f8"
uuid = "2803e5a7-5153-5ecf-9a86-9b4c37f5f5ac"
version = "0.6.11"

[[deps.ImageBase]]
deps = ["ImageCore", "Reexport"]
git-tree-sha1 = "eb49b82c172811fd2c86759fa0553a2221feb909"
uuid = "c817782e-172a-44cc-b673-b171935fbb9e"
version = "0.1.7"

[[deps.ImageCore]]
deps = ["ColorVectorSpace", "Colors", "FixedPointNumbers", "MappedArrays", "MosaicViews", "OffsetArrays", "PaddedViews", "PrecompileTools", "Reexport"]
git-tree-sha1 = "b2a7eaa169c13f5bcae8131a83bc30eff8f71be0"
uuid = "a09fc81d-aa75-5fe9-8630-4744c3626534"
version = "0.10.2"

[[deps.ImageIO]]
deps = ["FileIO", "IndirectArrays", "JpegTurbo", "LazyModules", "Netpbm", "OpenEXR", "PNGFiles", "QOI", "Sixel", "TiffImages", "UUIDs"]
git-tree-sha1 = "437abb322a41d527c197fa800455f79d414f0a3c"
uuid = "82e4d734-157c-48bb-816b-45c225c6df19"
version = "0.6.8"

[[deps.ImageMetadata]]
deps = ["AxisArrays", "ImageAxes", "ImageBase", "ImageCore"]
git-tree-sha1 = "355e2b974f2e3212a75dfb60519de21361ad3cb7"
uuid = "bc367c6b-8a6b-528e-b4bd-a4b897500b49"
version = "0.9.9"

[[deps.Imath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "0936ba688c6d201805a83da835b55c61a180db52"
uuid = "905a6f67-0a94-5f89-b386-d35d92009cd1"
version = "3.1.11+0"

[[deps.IndirectArrays]]
git-tree-sha1 = "012e604e1c7458645cb8b436f8fba789a51b257f"
uuid = "9b13fd28-a010-5f03-acff-a1bbcff69959"
version = "1.0.0"

[[deps.Inflate]]
git-tree-sha1 = "d1b1b796e47d94588b3757fe84fbf65a5ec4a80d"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.5"

[[deps.IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "be50fe8df3acbffa0274a744f1a99d29c45a57f4"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2024.1.0+0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.Interpolations]]
deps = ["Adapt", "AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "88a101217d7cb38a7b481ccd50d21876e1d1b0e0"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.15.1"
weakdeps = ["Unitful"]

    [deps.Interpolations.extensions]
    InterpolationsUnitfulExt = "Unitful"

[[deps.IntervalArithmetic]]
deps = ["CRlibm_jll", "MacroTools", "RoundingEmulator"]
git-tree-sha1 = "433b0bb201cd76cb087b017e49244f10394ebe9c"
uuid = "d1acc4aa-44c8-5952-acd4-ba5d80a2a253"
version = "0.22.14"

    [deps.IntervalArithmetic.extensions]
    IntervalArithmeticDiffRulesExt = "DiffRules"
    IntervalArithmeticForwardDiffExt = "ForwardDiff"
    IntervalArithmeticRecipesBaseExt = "RecipesBase"

    [deps.IntervalArithmetic.weakdeps]
    DiffRules = "b552c78f-8df3-52c6-915a-8e097449b14b"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    RecipesBase = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"

[[deps.IntervalSets]]
git-tree-sha1 = "dba9ddf07f77f60450fe5d2e2beb9854d9a49bd0"
uuid = "8197267c-284f-5f27-9208-e0e47529a953"
version = "0.7.10"

    [deps.IntervalSets.extensions]
    IntervalSetsRandomExt = "Random"
    IntervalSetsRecipesBaseExt = "RecipesBase"
    IntervalSetsStatisticsExt = "Statistics"

    [deps.IntervalSets.weakdeps]
    Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
    RecipesBase = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
    Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[deps.Isoband]]
deps = ["isoband_jll"]
git-tree-sha1 = "f9b6d97355599074dc867318950adaa6f9946137"
uuid = "f1662d9f-8043-43de-a69a-05efc1cc6ff4"
version = "0.1.1"

[[deps.IterTools]]
git-tree-sha1 = "42d5f897009e7ff2cf88db414a389e5ed1bdd023"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.10.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "7e5d6779a1e09a36db2a7b6cff50942a0a7d0fca"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.5.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.JpegTurbo]]
deps = ["CEnum", "FileIO", "ImageCore", "JpegTurbo_jll", "TOML"]
git-tree-sha1 = "fa6d0bcff8583bac20f1ffa708c3913ca605c611"
uuid = "b835a17e-a41a-41e7-81f0-2f016b05efe0"
version = "0.1.5"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "c84a835e1a09b289ffcd2271bf2a337bbdda6637"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "3.0.3+0"

[[deps.KernelDensity]]
deps = ["Distributions", "DocStringExtensions", "FFTW", "Interpolations", "StatsBase"]
git-tree-sha1 = "7d703202e65efa1369de1279c162b915e245eed1"
uuid = "5ab0869b-81aa-558d-bb23-cbf5423bbe9b"
version = "0.6.9"

[[deps.KrylovKit]]
deps = ["GPUArraysCore", "LinearAlgebra", "PackageExtensionCompat", "Printf", "VectorInterface"]
git-tree-sha1 = "3c2a016489c38f35160a246c91a3f3353c47bb68"
uuid = "0b1a1467-8014-51b9-945f-bf0ae24f4b77"
version = "0.8.1"
weakdeps = ["ChainRulesCore"]

    [deps.KrylovKit.extensions]
    KrylovKitChainRulesCoreExt = "ChainRulesCore"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "170b660facf5df5de098d866564877e119141cbd"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.2+0"

[[deps.LLVMOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "d986ce2d884d49126836ea94ed5bfb0f12679713"
uuid = "1d63c593-3942-5779-bab2-d838dc0a180e"
version = "15.0.7+0"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "70c5da094887fd2cae843b8db33920bac4b6f07d"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.2+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "50901ebc375ed41dbf8058da26f9de442febbbec"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.1"

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

[[deps.LazyModules]]
git-tree-sha1 = "a560dd966b386ac9ae60bdd3a3d3a326062d3c3e"
uuid = "8cdb02fc-e678-4876-92c5-9defec4f444e"
version = "0.3.1"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.4.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.6.4+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0b4a5d71f3e5200a7dff793393e09dfc2d874290"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+1"

[[deps.Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll"]
git-tree-sha1 = "9fd170c4bbfd8b935fdc5f8b7aa33532c991a673"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.11+0"

[[deps.Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "6f73d1dd803986947b2c750138528a999a6c7733"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.6.0+0"

[[deps.Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "fbb1f2bef882392312feb1ede3615ddc1e9b99ed"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.49.0+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "f9557a255370125b405568f9767d6d195822a175"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.17.0+0"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "0c4f9c4f1a50d8f35048fa0532dabbadf702f81e"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.40.1+0"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "5ee6203157c120d79034c748a2acba45b82b8807"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.40.1+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "a2d09619db4e765091ee5c6ffe8872849de0feea"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.28"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "oneTBB_jll"]
git-tree-sha1 = "80b2833b56d466b3858d565adcd16a4a05f2089b"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2024.1.0+0"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "2fa9ee3e63fd3a4f7a9a4f4744a52f4856de82df"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.13"

[[deps.Makie]]
deps = ["Animations", "Base64", "CRC32c", "ColorBrewer", "ColorSchemes", "ColorTypes", "Colors", "Contour", "Dates", "DelaunayTriangulation", "Distributions", "DocStringExtensions", "Downloads", "FFMPEG_jll", "FileIO", "FilePaths", "FixedPointNumbers", "Format", "FreeType", "FreeTypeAbstraction", "GeometryBasics", "GridLayoutBase", "ImageIO", "InteractiveUtils", "IntervalSets", "Isoband", "KernelDensity", "LaTeXStrings", "LinearAlgebra", "MacroTools", "MakieCore", "Markdown", "MathTeXEngine", "Observables", "OffsetArrays", "Packing", "PlotUtils", "PolygonOps", "PrecompileTools", "Printf", "REPL", "Random", "RelocatableFolders", "Scratch", "ShaderAbstractions", "Showoff", "SignedDistanceFields", "SparseArrays", "Statistics", "StatsBase", "StatsFuns", "StructArrays", "TriplotBase", "UnicodeFun", "Unitful"]
git-tree-sha1 = "e11b0666b457e3bb60119f2ed4d063d2b68954d3"
uuid = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"
version = "0.21.3"

[[deps.MakieCore]]
deps = ["ColorTypes", "GeometryBasics", "IntervalSets", "Observables"]
git-tree-sha1 = "638bc817096742e8302f7b0b972ee5701fe00e97"
uuid = "20f20a25-4f0e-4fdf-b5d1-57303727442b"
version = "0.8.3"

[[deps.MappedArrays]]
git-tree-sha1 = "2dab0221fe2b0f2cb6754eaa743cc266339f527e"
uuid = "dbb5928d-eab1-5f90-85c2-b9b0edb7c900"
version = "0.4.2"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MathTeXEngine]]
deps = ["AbstractTrees", "Automa", "DataStructures", "FreeTypeAbstraction", "GeometryBasics", "LaTeXStrings", "REPL", "RelocatableFolders", "UnicodeFun"]
git-tree-sha1 = "1865d0b8a2d91477c8b16b49152a32764c7b1f5f"
uuid = "0a4f8689-d25c-4efe-a92b-7142dfc1aa53"
version = "0.6.0"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+1"

[[deps.MeshIO]]
deps = ["ColorTypes", "FileIO", "GeometryBasics", "Printf"]
git-tree-sha1 = "8c26ab950860dfca6767f2bbd90fdf1e8ddc678b"
uuid = "7269a6da-0436-5bbc-96c2-40638cbb6118"
version = "0.4.11"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "ec4f7fbeab05d7747bdf98eb74d130a2a2ed298d"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.2.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.ModernGL]]
deps = ["Libdl"]
git-tree-sha1 = "b76ea40b5c0f45790ae09492712dd326208c28b2"
uuid = "66fc600b-dfda-50eb-8b99-91cfa97b1301"
version = "1.1.7"

[[deps.MosaicViews]]
deps = ["MappedArrays", "OffsetArrays", "PaddedViews", "StackViews"]
git-tree-sha1 = "7b86a5d4d70a9f5cdf2dacb3cbe6d251d1a61dbe"
uuid = "e94cdb99-869f-56ef-bcf0-1ae2bcbe0389"
version = "0.3.4"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.1.10"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "0877504529a3e5c3343c6f8b4c0381e57e4387e4"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.2"

[[deps.Netpbm]]
deps = ["FileIO", "ImageCore", "ImageMetadata"]
git-tree-sha1 = "d92b107dbb887293622df7697a2223f9f8176fcd"
uuid = "f09324ee-3d7c-5217-9330-fc30815ba969"
version = "1.1.1"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.Observables]]
git-tree-sha1 = "7438a59546cf62428fc9d1bc94729146d37a7225"
uuid = "510215fc-4207-5dde-b226-833fc4488ee2"
version = "0.5.5"

[[deps.OffsetArrays]]
git-tree-sha1 = "e64b4f5ea6b7389f6f046d13d4896a8f9c1ba71e"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.14.0"
weakdeps = ["Adapt"]

    [deps.OffsetArrays.extensions]
    OffsetArraysAdaptExt = "Adapt"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.23+4"

[[deps.OpenEXR]]
deps = ["Colors", "FileIO", "OpenEXR_jll"]
git-tree-sha1 = "327f53360fdb54df7ecd01e96ef1983536d1e633"
uuid = "52e1d378-f018-4a11-a4be-720524705ac7"
version = "0.3.2"

[[deps.OpenEXR_jll]]
deps = ["Artifacts", "Imath_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "8292dd5c8a38257111ada2174000a33745b06d4e"
uuid = "18a262bb-aa17-5467-a713-aee519bc75cb"
version = "3.2.4+0"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+2"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a028ee3cb5641cccc4c24e90c36b0a4f7707bdf5"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.0.14+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "dfdf5519f235516220579f949664f1bf44e741c5"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.3"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.42.0+1"

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "949347156c25054de2db3b166c52ac4728cbad65"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.31"

[[deps.PNGFiles]]
deps = ["Base64", "CEnum", "ImageCore", "IndirectArrays", "OffsetArrays", "libpng_jll"]
git-tree-sha1 = "67186a2bc9a90f9f85ff3cc8277868961fb57cbd"
uuid = "f57f5aa1-a3ce-4bc8-8ab9-96f992907883"
version = "0.4.3"

[[deps.PackageExtensionCompat]]
git-tree-sha1 = "fb28e33b8a95c4cee25ce296c817d89cc2e53518"
uuid = "65ce6f38-6b18-4e1d-a461-8949797d7930"
version = "1.0.2"
weakdeps = ["Requires", "TOML"]

[[deps.Packing]]
deps = ["GeometryBasics"]
git-tree-sha1 = "ec3edfe723df33528e085e632414499f26650501"
uuid = "19eb6ba3-879d-56ad-ad62-d5c202156566"
version = "0.5.0"

[[deps.PaddedViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "0fac6313486baae819364c52b4f483450a9d793f"
uuid = "5432bcbf-9aad-5242-b902-cca2824c8663"
version = "0.5.12"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "8489905bcdbcfac64d1daa51ca07c0d8f0283821"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.1"

[[deps.Pixman_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LLVMOpenMP_jll", "Libdl"]
git-tree-sha1 = "35621f10a7531bc8fa58f74610b1bfb70a3cfc6b"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.43.4+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.10.0"

[[deps.PkgVersion]]
deps = ["Pkg"]
git-tree-sha1 = "f9501cc0430a26bc3d156ae1b5b0c1b47af4d6da"
uuid = "eebad327-c553-4316-9ea0-9fa01ccd7688"
version = "0.3.3"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "PrecompileTools", "Printf", "Random", "Reexport", "Statistics"]
git-tree-sha1 = "7b1a9df27f072ac4c9c7cbe5efb198489258d1f5"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.4.1"

[[deps.PlutoTest]]
deps = ["HypertextLiteral", "InteractiveUtils", "Markdown", "Test"]
git-tree-sha1 = "17aa9b81106e661cffa1c4c36c17ee1c50a86eda"
uuid = "cb4044da-4d16-4ffa-a6a3-8cad7f73ebdc"
version = "0.2.2"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "ab55ee1510ad2af0ff674dbcced5e94921f867a9"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.59"

[[deps.PolygonOps]]
git-tree-sha1 = "77b3d3605fc1cd0b42d95eba87dfcd2bf67d5ff6"
uuid = "647866c9-e3ac-4575-94e7-e3d426903924"
version = "0.1.2"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "5aa36f7049a63a1528fe8f7c3f2113413ffd4e1f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "9306f6085165d270f7e3db02af26a400d580f5c6"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.3"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "763a8ceb07833dd51bb9e3bbca372de32c0605ad"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.10.0"

[[deps.PtrArrays]]
git-tree-sha1 = "f011fbb92c4d401059b2212c05c0601b70f8b759"
uuid = "43287f4e-b6f4-7ad1-bb20-aadabca52c3d"
version = "1.2.0"

[[deps.QOI]]
deps = ["ColorTypes", "FileIO", "FixedPointNumbers"]
git-tree-sha1 = "18e8f4d1426e965c7b532ddd260599e1510d26ce"
uuid = "4b34888f-f399-49d4-9bb3-47ed5cae4e65"
version = "1.0.0"

[[deps.QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "9b23c31e76e333e6fb4c1595ae6afa74966a729e"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.9.4"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.RangeArrays]]
git-tree-sha1 = "b9039e93773ddcfc828f12aadf7115b4b4d225f5"
uuid = "b3c3ace0-ae52-54e7-9d0b-2c1406fd6b9d"
version = "0.3.2"

[[deps.Ratios]]
deps = ["Requires"]
git-tree-sha1 = "1342a47bf3260ee108163042310d26f2be5ec90b"
uuid = "c84ed2f1-dad5-54f0-aa8e-dbefe2724439"
version = "0.4.5"
weakdeps = ["FixedPointNumbers"]

    [deps.Ratios.extensions]
    RatiosFixedPointNumbersExt = "FixedPointNumbers"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "ffdaf70d81cf6ff22c2b6e733c900c3321cab864"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "1.0.1"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "f65dcb5fa46aee0cf9ed6274ccbd597adc49aa7b"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.7.1"

[[deps.Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "d483cd324ce5cf5d61b77930f0bbd6cb61927d21"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.4.2+0"

[[deps.RoundingEmulator]]
git-tree-sha1 = "40b9edad2e5287e05bd413a38f61a8ff55b9557b"
uuid = "5eaf0fd0-dfba-4ccb-bf02-d820a40db705"
version = "0.2.1"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SIMD]]
deps = ["PrecompileTools"]
git-tree-sha1 = "2803cab51702db743f3fda07dd1745aadfbf43bd"
uuid = "fdea26ae-647d-5447-a871-4b548cad5224"
version = "3.5.0"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "3bac05bc7e74a75fd9cba4295cde4045d9fe2386"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.2.1"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.ShaderAbstractions]]
deps = ["ColorTypes", "FixedPointNumbers", "GeometryBasics", "LinearAlgebra", "Observables", "StaticArrays", "StructArrays", "Tables"]
git-tree-sha1 = "79123bc60c5507f035e6d1d9e563bb2971954ec8"
uuid = "65257c39-d410-5151-9873-9b3e5be5013e"
version = "0.4.1"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[deps.SignedDistanceFields]]
deps = ["Random", "Statistics", "Test"]
git-tree-sha1 = "d263a08ec505853a5ff1c1ebde2070419e3f28e9"
uuid = "73760f76-fbc4-59ce-8f25-708e95d2df96"
version = "0.4.0"

[[deps.SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "5d7e3f4e11935503d3ecaf7186eac40602e7d231"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.4"

[[deps.Sixel]]
deps = ["Dates", "FileIO", "ImageCore", "IndirectArrays", "OffsetArrays", "REPL", "libsixel_jll"]
git-tree-sha1 = "2da10356e31327c7096832eb9cd86307a50b1eb6"
uuid = "45858cf5-a6b0-47a3-bbea-62219f50df47"
version = "0.1.3"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "66e0a8e672a0bdfca2c3f5937efb8538b9ddc085"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.1"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.10.0"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "2f5d4697f21388cbe1ff299430dd169ef97d7e14"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.4.0"
weakdeps = ["ChainRulesCore"]

    [deps.SpecialFunctions.extensions]
    SpecialFunctionsChainRulesCoreExt = "ChainRulesCore"

[[deps.StackViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "46e589465204cd0c08b4bd97385e4fa79a0c770c"
uuid = "cae243ae-269e-4f55-b966-ac2d0dc13c15"
version = "0.1.1"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "PrecompileTools", "Random", "StaticArraysCore"]
git-tree-sha1 = "6e00379a24597be4ae1ee6b2d882e15392040132"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.9.5"
weakdeps = ["ChainRulesCore", "Statistics"]

    [deps.StaticArrays.extensions]
    StaticArraysChainRulesCoreExt = "ChainRulesCore"
    StaticArraysStatisticsExt = "Statistics"

[[deps.StaticArraysCore]]
git-tree-sha1 = "192954ef1208c7019899fbf8049e717f92959682"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.3"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.10.0"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1ff449ad350c9c4cbc756624d6f8a8c3ef56d3ed"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.7.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "5cf7606d6cef84b543b483848d4ae08ad9832b21"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.34.3"

[[deps.StatsFuns]]
deps = ["HypergeometricFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "cef0472124fab0695b58ca35a77c6fb942fdab8a"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "1.3.1"

    [deps.StatsFuns.extensions]
    StatsFunsChainRulesCoreExt = "ChainRulesCore"
    StatsFunsInverseFunctionsExt = "InverseFunctions"

    [deps.StatsFuns.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.StructArrays]]
deps = ["ConstructionBase", "DataAPI", "Tables"]
git-tree-sha1 = "f4dc295e983502292c4c3f951dbb4e985e35b3be"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.6.18"
weakdeps = ["Adapt", "GPUArraysCore", "SparseArrays", "StaticArrays"]

    [deps.StructArrays.extensions]
    StructArraysAdaptExt = "Adapt"
    StructArraysGPUArraysCoreExt = "GPUArraysCore"
    StructArraysSparseArraysExt = "SparseArrays"
    StructArraysStaticArraysExt = "StaticArrays"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.2.1+1"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits"]
git-tree-sha1 = "cb76cf677714c095e535e3501ac7954732aeea2d"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.11.1"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TiffImages]]
deps = ["ColorTypes", "DataStructures", "DocStringExtensions", "FileIO", "FixedPointNumbers", "IndirectArrays", "Inflate", "Mmap", "OffsetArrays", "PkgVersion", "ProgressMeter", "SIMD", "UUIDs"]
git-tree-sha1 = "bc7fd5c91041f44636b2c134041f7e5263ce58ae"
uuid = "731e570b-9d59-4bfa-96dc-6df516fadf69"
version = "0.10.0"

[[deps.TranscodingStreams]]
git-tree-sha1 = "d73336d81cafdc277ff45558bb7eaa2b04a8e472"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.10.10"
weakdeps = ["Random", "Test"]

    [deps.TranscodingStreams.extensions]
    TestExt = ["Test", "Random"]

[[deps.Tricks]]
git-tree-sha1 = "eae1bb484cd63b36999ee58be2de6c178105112f"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.8"

[[deps.TriplotBase]]
git-tree-sha1 = "4d4ed7f294cda19382ff7de4c137d24d16adc89b"
uuid = "981d1d27-644d-49a2-9326-4793e63143c3"
version = "0.1.0"

[[deps.URIs]]
git-tree-sha1 = "67db6cc7b3821e19ebe75791a9dd19c9b1188f2b"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.Unitful]]
deps = ["Dates", "LinearAlgebra", "Random"]
git-tree-sha1 = "dd260903fdabea27d9b6021689b3cd5401a57748"
uuid = "1986cc42-f94f-5a68-af5c-568840ba703d"
version = "1.20.0"

    [deps.Unitful.extensions]
    ConstructionBaseUnitfulExt = "ConstructionBase"
    InverseFunctionsUnitfulExt = "InverseFunctions"

    [deps.Unitful.weakdeps]
    ConstructionBase = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.VectorInterface]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "7aff7d62bffad9bba9928eb6ab55226b32a351eb"
uuid = "409d34a3-91d5-4945-b6ec-7529ddf182d8"
version = "0.4.6"

[[deps.WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "c1a7aa6219628fcd757dede0ca95e245c5cd9511"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "1.0.0"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Zlib_jll"]
git-tree-sha1 = "52ff2af32e591541550bd753c0da8b9bc92bb9d9"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.12.7+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "afead5aba5aa507ad5a3bf01f58f82c8d1403495"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.8.6+0"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6035850dcc70518ca32f012e46015b9beeda49d8"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.11+0"

[[deps.Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "12e0eb3bc634fa2080c1c37fccf56f7c22989afd"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.0+4"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "34d526d318358a859d7de23da945578e8e8727b7"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.4+0"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "d2d1a5c49fae4ba39983f63de6afcbea47194e85"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.6+0"

[[deps.Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "0e0dc7431e7a0587559f9294aeec269471c991a4"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "5.0.3+4"

[[deps.Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "89b52bc2160aadc84d707093930ef0bffa641246"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.7.10+4"

[[deps.Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll"]
git-tree-sha1 = "26be8b1c342929259317d8b9f7b53bf2bb73b123"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.4+4"

[[deps.Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "34cea83cb726fb58f325887bf0612c6b3fb17631"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.2+4"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "47e45cd78224c53109495b3e324df0c37bb61fbe"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.11+0"

[[deps.Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8fdda4c692503d44d04a0603d9ac0982054635f9"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.1+0"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "bcd466676fef0878338c61e655629fa7bbc69d8e"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.17.0+0"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e92a1a012a10506618f10b7047e478403a046c77"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.5.0+0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.isoband_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51b5eeb3f98367157a7a12a1fb0aa5328946c03c"
uuid = "9a68df92-36a6-505f-a73e-abb412b6bfb4"
version = "0.2.3+0"

[[deps.libaom_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1827acba325fdcdf1d2647fc8d5301dd9ba43a9d"
uuid = "a4ae2306-e953-59d6-aa16-d00cac43593b"
version = "3.9.0+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "5982a94fcba20f02f42ace44b9894ee2b140fe47"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.1+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+1"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "daacc84a041563f965be61859a36e17c4e4fcd55"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.2+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "d7015d2e18a5fd9a4f47de711837e980519781a4"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.43+1"

[[deps.libsixel_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Pkg", "libpng_jll"]
git-tree-sha1 = "d4f63314c8aa1e48cd22aa0c17ed76cd1ae48c3c"
uuid = "075b6546-f08a-558a-be8f-8157d0f608a5"
version = "1.10.3+0"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "b910cb81ef3fe6e78bf6acee440bda86fd6ae00c"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+1"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.52.0+1"

[[deps.oneTBB_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "7d0ea0f4895ef2f5cb83645fa689e52cb55cf493"
uuid = "1317d2d5-d96f-522e-a858-c73665f53c3e"
version = "2021.12.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"
"""

# ╔═╡ Cell order:
# ╠═dcbacb58-a77d-4ec2-aa10-bf6b72d5f33e
# ╠═e22afb18-acbe-49ec-8b0f-0d5d311b9e09
# ╠═f49b5d6e-464f-49d0-a3f2-1af2084d6dc2
# ╠═30a856d7-01f1-411a-ab26-589dfbed9a73
# ╠═52aaf95c-818a-495b-86c3-d1cc73f60033
# ╠═edbc5861-96b0-4d29-b158-f60f82c77f37
# ╠═896a6291-0027-4849-85cf-43e05082e5a8
# ╟─bec6b558-b794-4d7e-9dd0-fba13a4b5c61
# ╠═51954bdb-3cd7-428e-a7ad-7a02be2f06b4
# ╠═504fa869-0faa-4f0c-943a-94dd1b57757b
# ╠═e6a95c73-cc53-4323-a033-afb10b5511c3
# ╠═44773e3c-37e1-4c1f-a859-c20943edd5f2
# ╠═989bbaf8-f3e1-4c0e-941b-25480bbcb272
# ╟─61883ba0-0da8-43ec-9f3a-e5f6367492f3
# ╠═e4abdbe5-9da6-4454-9817-d97cbc471c93
# ╠═9e7c66f3-a2f2-4470-bd7b-651963a8ad77
# ╠═c23f8ec1-694a-473e-8486-f854aaadcc62
# ╠═a548bf6d-02fa-4fed-97a3-ba48e35f6f7f
# ╠═f6116b00-3e5c-4fde-a7fa-2b7444c66fa3
# ╠═74930cbb-7b22-49aa-962a-a9d1a631f454
# ╠═97dbb2a4-d43f-4401-a167-8862837c196f
# ╠═f3ed8512-bd49-4b7c-bd97-d5316a0fa9a5
# ╠═50bf1130-d60d-40d4-aea0-024af72a69bd
# ╠═7af30430-cacc-4956-919c-d5707ec0cbf1
# ╠═98600be8-5246-41b6-8100-b221e76ee818
# ╠═fa349d2c-4db0-4293-a956-91d9cbe686b4
# ╠═2dc5d157-0e41-42d8-9462-4c3dfe67ac4e
# ╠═d36a8189-ec05-4f51-9eb1-0125332bde43
# ╠═c1d6ca48-e9b5-46ac-944a-4ef6c97b0588
# ╠═2b9dce1b-22be-4448-9035-2d6804ddd4c5
# ╠═5133587f-265a-40a7-8d5d-08d28ccab7a7
# ╠═78553187-2839-4afd-b2aa-f500a2a87b20
# ╠═c42390d6-0a93-438e-b8b1-bdaf13078a8c
# ╠═65f5fdfd-ef28-4dc0-b20b-d73c7e34b0fd
# ╟─1f657f58-99b6-4c15-b8e2-28e7f43d4841
# ╟─97a257f0-f329-4770-be0e-bcfa4cc1cc20
# ╠═70391d80-3c75-4289-9e8b-e96d21bc84e4
# ╟─b475cced-47e3-4eb3-b7fa-d4cc2163d2b9
# ╠═13c643a7-8b24-4059-b562-27b045f5e88d
# ╠═ae10e404-0fe5-44e9-8f66-b28ad9e468df
# ╠═490f5f38-fe28-4301-986d-4326e796bc78
# ╠═2ca31a82-7dff-4f8d-b52c-60d683997bfa
# ╠═ba607fc6-b47f-43d0-8e61-2ffa8f439019
# ╠═0faf5296-0fcc-4a24-8d77-dea9dc07c570
# ╠═082e998f-d6ba-4532-bb11-b1452776c633
# ╠═413e6f8d-9b10-4f4c-b97d-29f8239ab5d4
# ╠═eec63e8a-0795-49b2-b77f-d35ad7d1746c
# ╠═fc3a9e49-8b07-49fe-b66c-2602c11aad23
# ╟─a6d894b2-54a2-4ee2-95ee-54a370e120ff
# ╠═1c392cc4-f300-4a64-bc43-4ab035fb53cf
# ╠═73d87fea-b054-4b6c-a7f6-379f855b7d5e
# ╟─8d413a89-8453-40f8-ac32-f2efdb4b7994
# ╠═a6e86bb5-c8d4-4c53-8bac-241b153fcb0a
# ╠═dcf42053-e09c-473f-97cb-e41fc9192dbf
# ╠═56306ae6-f2e3-4a30-a4a1-85249d574fa3
# ╠═75995bcd-bf03-4471-b257-937425271da2
# ╠═efc8d22e-bfc3-4821-9b65-ce3c090b0da4
# ╠═59050e00-b58d-4fd9-b24b-f2e63526c288
# ╠═14a3b8d9-d647-4cd5-a12a-6685a034fa8c
# ╠═3d68ffb1-6891-4b15-b136-3db1b05b0c26
# ╠═02cb1431-921a-4c3e-a394-8e563278236e
# ╠═3feef9cd-c70d-459e-be90-5535577942d6
# ╟─b91ca1bd-6ae2-4b57-837d-529174f911e7
# ╠═c27909e0-3f46-4976-946f-60b2e5fa6a4d
# ╠═d7b8fcfa-9eef-4403-8c21-9f39ca33c4dd
# ╠═6771cd71-d2ce-4f69-abc6-0b17be7ff938
# ╟─bccd9224-3169-4d5c-be79-d8500c9f8bb0
# ╠═be744d7b-7a95-4600-b49b-34dc4fdcd181
# ╠═f1fbbdf5-4323-4bc9-93d7-65d31acc1d03
# ╠═89b7a48f-8d51-47de-9c1c-e9d245d4c856
# ╠═57f3eb01-1330-41e8-8abc-91c672a62827
# ╠═4751a10a-11e7-41f9-ba95-ba8654271a79
# ╠═4437c613-9a3a-42e3-a60c-5290764923fc
# ╠═b35ea1cd-1467-43c3-b3d3-1fc24fb83ab0
# ╠═311e4d05-cf9f-4c2d-8ec9-30cada21b022
# ╠═29c85202-9adb-4543-bea4-816e5d9b99cc
# ╠═8ea0a7ea-5700-4bea-a02e-0f6269677d05
# ╠═fe3e2333-2911-439a-b6da-4a6004e7fa62
# ╠═a6dff627-59ae-4312-9a69-f603fac17b38
# ╠═28d6afcf-bd5a-4673-a638-4510dd1b3bf9
# ╠═74035528-e0d7-4ec9-bf3a-d2d7848f05fd
# ╠═dfea351e-a9f2-4d03-8aa4-52819afe7f3c
# ╠═b278b93d-b507-4e99-817d-f1172481eb2c
# ╠═6c3f4048-d685-4e76-b7ec-87cf837a77fd
# ╟─ef12d042-cac5-4ff4-9dd5-a838073424bf
# ╠═6a706a54-ebfe-447b-92bd-6715ed5c2747
# ╟─9e0322d7-89d3-426e-be99-4d8fbf3818fb
# ╠═59843a53-614b-472e-b7c3-8f9256843745
# ╠═1a3d8eb6-0bdb-4741-9a19-8750b0f02e08
# ╠═3e9fd512-4280-4b25-ae26-b9b90c819ae8
# ╟─6ed345e4-063b-467f-9783-77f05805ada1
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
