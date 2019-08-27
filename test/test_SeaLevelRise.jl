using DataFrames
using Test

for testscen in 1:2
    valdir, scenario, use_permafrost, use_seaice = get_scenario(testscen)
    println(scenario)

    m = page_model()
    include("../src/components/SeaLevelRise.jl")

    SLR = add_comp!(m, SeaLevelRise)

    set_param!(m, :SeaLevelRise, :rt_g_globaltemperature, readpagedata(m, "test/validationdata/$valdir/rt_g_globaltemperature.csv"))
    set_param!(m, :SeaLevelRise, :y_year_0, 2015.)
    set_param!(m, :SeaLevelRise, :y_year, [2020, 2030, 2040, 2050, 2075, 2100, 2150, 2200, 2250, 2300])

    run(m)

    es_equilibriumSL = m[:SeaLevelRise, :es_equilibriumSL]
    es_equilibriumSL_compare = readpagedata(m, "test/validationdata/$valdir/es_equilibriumSL.csv")
    @test ones(10) ≈ es_equilibriumSL ./ es_equilibriumSL rtol=.01

    s_sealevel = m[:SeaLevelRise, :s_sealevel]
    s_sealevel_compare = readpagedata(m, "test/validationdata/$valdir/s_sealevel.csv")
    @test ones(10) ≈ s_sealevel ./ s_sealevel_compare rtol=.01

    expfs_exponential = m[:SeaLevelRise, :expfs_exponential]
    expfs_exponential_compare = readpagedata(m, "test/validationdata/expfs_exponential.csv")
    @test ones(10) ≈ expfs_exponential ./ expfs_exponential_compare rtol=.01
end
