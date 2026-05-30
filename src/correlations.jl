
@kwdef mutable struct CelestialBody
    name::String = ""
    r::Float64 = 0.0
end


@kwdef mutable struct PlanetarySystem
    planet::CelestialBody = CelestialBody()
    moons::Vector{CelestialBody} = []
end


function correl_df(df::AbstractDataFrame)
    pars = names(df)
    cmat = cor(Matrix(df))
    insertcols(DataFrame(cmat, pars), 1, :pars=>pars)
end


round_down(val) = (val >= 0) ? floor(val; digits=1) : ceil(val; digits=1)


function add_sig_label(x, y, label)
    pv = pvalue(CorrelationTest(x, y))
    txt = (pv <= 0.01) ? "**" :
          (pv <= 0.05) ? "*" : "ns"
    "$(label) $(txt)"
end


function collect_planets_moons(data::AbstractDataFrame, dep::Symbol; moon_threshold=0.8)
    cordf = correl_df(data)
    df = filter!(:pars => p -> p != string(dep), copy(cordf))
    sort!(df, dep, by=abs, rev=true)

    x = data[!, dep]
    planets = PlanetarySystem[]

    while size(df, 1) > 0
        planet = Symbol(df[1, :pars])
        r = round_down(df[1, dep])

        dft = filter!(planet => p -> abs(p) >= moon_threshold,
                      sort!(select(df, [:pars, planet]), planet, by=abs, rev=true))
        transform!(dft, planet => p -> round_down.(p), renamecols=false)

        moons = CelestialBody[]
        moonlst = dft[2:end, :pars]
        filter!(:pars => p -> !(p in moonlst) && p != string(planet), df)

        for m in moonlst
            y = data[!, m]
            moon_name = add_sig_label(x, y, m)
            moon_r = cordf[cordf.pars .== m, dep][1]
            push!(moons, CelestialBody(moon_name, moon_r))
        end

        y = data[!, planet]
        planet_name = add_sig_label(x, y, string(planet))
        push!(planets, PlanetarySystem(CelestialBody(planet_name, r), moons))
    end

    planets
end
