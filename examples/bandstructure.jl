using QuantumAcademy
using CairoMakie
using LinearAlgebra


#First, we get the path along the high symmetry lines. It is not guaranteed that everything interesting happens along these lines, but it makes plotting easier, and is an often used convention in solid state physics. 

#High symmetry points:

function pathmaker(point1, point2, length)
    point1x, point1y = point1
    point2x, point2y = point2
    pathx = range(point1x,point2x, length)
    pathy = range(point1y, point2y, length)
    return vcat(pathx', pathy')
end

Γ = (0.0, 0.0)
Y = (0.0,0.5)
X = (0.5,0.0)
S = (0.5,0.5)

number = 10

#We follow the path Γ -> Y -> S -> X -> Γ

path_part1 = pathmaker(Γ, Y,number)
path_part2 = pathmaker(Y, S, number)
path_part3 = pathmaker(S, X, number)
path_part4 = pathmaker(X, Γ, number)

#Concatenate the four paths into one single path:

full_path = vcat(path_part1',path_part2',path_part3',path_part4')

#Define system: 

NL = 6
NW = 6

L = 500.0
W = 500.0

function V1(x,y)
    zero(x)
end

function V2(x, y)
    w = 0.05
    d = 0.05
    b = 0.25
    h = 10
    if 0.5 - w/2 < x < 0.5 + w/2
        b1 = 0.5 - b/2 - d/2
        b2 = 0.5 - b/2 + d/2
        b3 = 0.5 + b/2 - d/2
        b4 = 0.5 + b/2 + d/2

        m1 = 0.5 - d/2
        m2 = 0.5 + d/2
        if y < b1 || y > b4 || (b2 < y < m1) || (m2 < y < b3)
            return oftype(x, h)
        end
    end

    zero(x)
end

energies = QuantumAcademy.calculate_bandstructure(V1, L, W, NL, NW, full_path)

#We want the whole thing as a 2d plot, so the paths need to be converted to single arrays. We want the lengths of each path to correspond to that in reciprocal space, so we calculate the reciprocal lattice vectors: 
k_1 = 2π/L
k_2 = 2π/W
trafo_matrix = [[k_1, 0];;[0,k_2]]
#First we convert the path to cartesian reciprocal space coordinates: 
full_path_real = zeros(Float64, (size(full_path)))
for i in range(1,step=1, length=size(full_path)[1])
    full_path_real[i,:] = trafo_matrix*full_path[i,:]
end

#Then we use the distance between each points pairwise to get our x-values. 
x_values_for_plot = zeros(Float64, (1,size(full_path)[1]))
for i in range(2,step=1, length=size(full_path)[1]-1)
    x_values_for_plot[i] = x_values_for_plot[i-1] + norm(full_path_real[i,:] - full_path_real[i-1,:])
end

#Now we just plot the x_values vs the y values: The energies. Since we have several bands, we iterate over them when plotting. The eigenvalues are sorted by size, so this leads to correct line plots automatically. 

f = Figure()
ax = Axis(f[1, 1],
    title = "Band structure",
    xlabel = "k point",
    ylabel = "energy [eV]",
)


for i in range(1,step=1, length=size(energies)[1])
    #The object energies[i,:] is a vector of energies, each associated with the corresponding x_values_for_plot. So we just plot these against each other
    lines!(ax, vec(x_values_for_plot),energies[i,:])
end

save("band_structure.png", f)

energies