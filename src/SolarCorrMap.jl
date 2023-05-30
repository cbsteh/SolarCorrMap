module SolarCorrMap

using CairoMakie
using DataFrames
using StatsBase
using CSV
using HypothesisTests

include("correlations.jl")
include("drawmap.jl")

export CelestialBody, PlanetarySystem
export correl_df, collect_planets_moons, plot_solar_corr_map, viz

end   # module
