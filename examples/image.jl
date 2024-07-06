using QuantumAcademy
using CairoMakie

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

function V3(x, y)
    r = 0.07
    h = 10
    oftype(x,h/(sqrt(0.001 + (x-0.5)^2+(y-0.5)^2)))
end

heatmap([V3(x, y) for x in 0:0.01:0.99, y in 0:0.01:0.99])

NL = 60
NW = 60

L = 500.0 |> Float32
W = 500.0 |> Float32

H = FinDiffHamiltonian{Float64}(V3, L, W, NL, NW)

@time U = DenseEigenProp(H)

ψ0 = wavefunction(NL, NW) do x, y
    r = 0.33
    dx = x - 0.25
    dy = y - 0.5
    a = (dx / 0.1)^2 + (dy / 0.25)^2
    return exp(-a + im * dx / 0.02) |> Complex{Float32}
end

@time U1 = U(Float32(25))
# @time U1 = cis(-Float16(25) * H)

xs = range(0; step=1/NL, length=NL)
ys = range(0; step=1/NW, length=NW)

fig = Figure()
ax = Axis(fig[1, 1]; aspect=DataAspect())
heatmap!(ax, xs, ys, abs2.(reshape(ψ0, NL, NW)))

hidedecorations!(ax)
hidespines!(ax)

Vxs = range(0; step=1/250, length=250)
Vs = [V3(x, y) for x in Vxs, y in Vxs]
contour!(ax, Vxs, Vxs, Vs; color=:white, levels=1:1)

fig

# animation settings
nframes = 20*70
framerate = 20

ψs = accumulate(1:nframes; init=ψ0) do x, _
    U1 * x
end

@time record(fig, "animation.mp4", ψs; framerate = framerate) do ψ
    heatmap!(ax, xs, ys, abs2.(reshape(ψ, NL, NW)))
    contour!(ax, Vxs, Vxs, Vs; color=:white, levels=1:1)
end
