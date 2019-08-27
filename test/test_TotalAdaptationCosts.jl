using DataFrames
using Test

for testscen in 1:2
    valdir, scenario, use_permafrost, use_seaice = get_scenario(testscen)
    println(scenario)

    m = page_model()
    include("../src/components/TotalAdaptationCosts.jl")

    add_comp!(m, TotalAdaptationCosts)

    set_param!(m, :TotalAdaptationCosts, :pop_population, readpagedata(m, "test/validationdata/$valdir/pop_population.csv"))
    set_param!(m, :TotalAdaptationCosts, :ac_adaptationcosts_economic, readpagedata(m, "test/validationdata/ac_adaptationcosts_economic.csv"))
    set_param!(m, :TotalAdaptationCosts, :ac_adaptationcosts_noneconomic, readpagedata(m, "test/validationdata/ac_adaptationcosts_noneconomic.csv"))
    set_param!(m, :TotalAdaptationCosts, :ac_adaptationcosts_sealevelrise, readpagedata(m, "test/validationdata/$valdir/ac_adaptationcosts_sealevelrise.csv"))

    run(m)

    # Generated data
    adapt_cost = m[:TotalAdaptationCosts, :act_adaptationcosts_total]
    adapt_cost_per_cap = m[:TotalAdaptationCosts, :act_percap_adaptationcosts]

    # Recorded data
    cost_compare = readpagedata(m, "test/validationdata/$valdir/act_adaptationcosts_tot.csv")
    cost_cap_compare = readpagedata(m, "test/validationdata/$valdir/act_percap_adaptationcosts.csv")

    @test adapt_cost ≈ cost_compare rtol=1e-3
    @test adapt_cost_per_cap ≈ cost_cap_compare rtol=1e-6
end
