
function draw_orbits!(ax; fontsize=16)
    rg = [0:0.01:2π...]
    cosx, siny = cos.(rg), sin.(rg)
    for r ∈ [0.9:-0.1:0.1...]
        lines!(ax, cosx .* r, siny .* r, linestyle=:dash, color=:gray60)
        rpos = (r * cos(0.5π), r * sin(0.5π))
        text!(ax, position=rpos, string(round(1-r; digits=1)),
              color=:gray30, align=(:center, :center), fontsize=fontsize)
    end
end


function draw_center(ax, dep; fontsize=16)
    scatter!(ax, 0, 0, label="DEP: $(dep)", color=:white)
    text!(ax, position=(0, 0), "DEP",
          color=:black, align=(:center, :center), fontsize=fontsize)
end


function draw_object!(ax, x, y; m_label, t_label, m_color, t_color,
                      m_strokecolor, m_strokewidth=2, m_size=32, t_fontsize=16)
    scatter!(ax, x, y, label=m_label, color=m_color,
             strokewidth=m_strokewidth, strokecolor=m_strokecolor,
             markersize=m_size)
    text!(ax, position=(x, y), t_label, color=t_color,
          align=(:center, :center), fontsize=t_fontsize)
end


function find_angles(n::Int)
    Δ = 2π / n
    θstart = 2π * rand()
    angles = [(θstart + (i-1) * Δ) % 2π for i ∈ 1:n]
    sample(angles, n, replace=false)
end


function find_angles(n::Int, r, locs; threshold=0.1)
    Δ = 2π / n

    function n_angles(n, Δ)
        θstart = 2π * rand()
        [(θstart + (i-1) * Δ) % 2π for i ∈ 1:n]
    end

    function calculate_positions(angles)
        [(x=(1-r) * cos(θ), y=(1-r) * sin(θ)) for θ ∈ angles]
    end

    function check_distance(pos, locs)
        for l ∈ locs, p ∈ pos
            d = sqrt((p.x - l.x)^2 + (p.y - l.y)^2)
            if d < threshold
                return true
            end
        end
        return false
    end

    angles = n_angles(n, Δ)
    for i ∈ 1:50
        pos = calculate_positions(angles)
        if !check_distance(pos, locs)
            break
        end
        if i <= 50
            angles = n_angles(n, Δ)
        end
    end

    sample(angles, n, replace=false)
end


function plot_solar_corr_map(psv::Vector{PlanetarySystem}, dep::Symbol)
    dpi = 300
    fontsize = 16
    chtsize = 3    # inches
    sz_px = (chtsize * dpi, chtsize * dpi)
    fig = Figure(resolution=sz_px, font="Arial", fontsize=fontsize)
    ax = Axis(fig[1, 1])

    draw_orbits!(ax; fontsize=fontsize)
    draw_center(ax, string(dep); fontsize=fontsize)

    df = to_df(psv)
    nplanet = 0
    locs = []

    for g ∈ groupby(df, :abs_r)
        angles = find_angles(size(g, 1), g.abs_r[1], locs; threshold=0.15)
        locs = []
        for (i, row) in enumerate(eachrow(g))
            nplanet += 1
            pos = draw_planet!(ax, row, angles[i], nplanet, fontsize)
            draw_moons!(ax, row, pos, fontsize)
            push!(locs, pos)
        end
    end

    Legend(fig[1,2], ax, valign=:top, rowgap=10, framevisible=false)
    hidedecorations!(ax)
    hidespines!(ax)
    colsize!(fig.layout, 1, Aspect(1, 1.0))
    resize_to_layout!(fig)
    fig
end


function to_df(psv::Vector{PlanetarySystem})
    nt = map(psv) do p
        planet = p.planet
        (name=planet.name, r=planet.r, abs_r=abs(planet.r), moons=p.moons)
    end
    df = sort!(DataFrame(nt), :abs_r, rev=true)
    filter(:abs_r => >(0), df)
end


function draw_planet!(ax, row, θ, nplanet, fontsize)
    xp, yp = (1-row.abs_r) * cos(θ), (1-row.abs_r) * sin(θ)
    clr = (row.r >= 0) ? :black : :red
    draw_object!(ax, xp, yp,
                 m_label="$(nplanet): $(row.name)", t_label=string(nplanet),
                 m_color=:white, t_color=clr,
                 m_strokecolor=clr, m_strokewidth=2,
                 m_size=32, t_fontsize=fontsize)
    (x=xp, y=yp)
end


function draw_moons!(ax, row, Δ, fontsize)
    aZ = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    m_pos = find_angles(size(row.moons, 1))
    fsz = (size(row.moons, 1) > 7) ? fontsize - 1 : fontsize
    for (j, moon) in enumerate(row.moons)
        m_lbl = "$(aZ[(j%52)])"
        xm, ym = Δ.x + 0.05 * cos(m_pos[j]), Δ.y + 0.05 * sin(m_pos[j])
        clr = (moon.r >= 0) ? :black : :red
        draw_object!(ax, xm, ym,
                     m_label="\t$(m_lbl): $(moon.name)", t_label=m_lbl,
                     m_color=:white, t_color=clr,
                     m_strokecolor=:transparent, m_strokewidth=0,
                     m_size=0, t_fontsize=fsz)
    end
end


function viz(csv_fname::AbstractString, dep::Symbol)
    df = CSV.read(csv_fname, DataFrame)
    planets = collect_planets_moons(df, dep)
    plot_solar_corr_map(planets, dep)
end
