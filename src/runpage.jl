using Mimi
using Distributions
using CSVFiles
using DataFrames
using CSV
using Random

# standard output folder:
global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/"

# set default; interannual global mean standard deviation
global set_gvarsd = 0.11294 # default from https://github.com/jkikstra/climvar
# in case you so desire, set one default; interannual regional mean standard deviation [normally read from rvarsd_regionalvariabilitystandarddeviation.csv]
# global set_rvarsd = 0.29175 # default from mean of mean of SDs: https://github.com/jkikstra/climvar/blob/master/IlyasPastVariability.ipynb
# global v_multiplier = 1 # introduced for sensitivity analysis for variability; default = 1 -> variability according to empirical results.

# set default monte carlo parameters to the full set of probability distributions
global use_only_varMC = false
global use_no_varMC = false
global use_linear = false
global use_logburke = true
global use_logpopulation = false

# set only when doing specific variability sensitivity analysis
global globallyset_use_interannvar = false

# simple: evaluate the differences between variability and non-variability
function overview_deterministic()


    include("getpagefunction.jl")
    include("utils/mctools.jl")


    df_overview = DataFrame(ModelName = String[], SCC = Float64[], Tot_discountedimpacts = Float64[],
                                                                DiscontCost_ann = Float64[],
                                                                DiscontDays_ann = Int64[],
                                                                # BurkeDamCons_ann = Float64[],
                                                                BurkeDamGDP_ann = Float64[],
                                                                # NonMarketCons_ann = Float64[],
                                                                NonMarketGDP_ann = Float64[])

    global use_annual = false
    global use_interannvar = false

    m_PAGEICE = getpage()
    run(m_PAGEICE)
    scc_PAGEICE = compute_scc(m_PAGEICE, year=2020)

    global use_annual = true
    global use_interannvar = false

    m_nonvar = getpage()
    run(m_nonvar)
    scc_nonvar = compute_scc(m_nonvar, year=2020)

    global use_annual = true
    global use_interannvar = true
    global v_multiplier = 1

    Random.seed!(2110);
    m_var = getpage()
    run(m_var)
    scc_var = compute_scc(m_nonvar, year=2020)

    # NB rcons_per_cap_MarketRemainConsumption_ann is not a sum.
    push!(df_overview, ["PAGE-ICE", scc_PAGEICE, m_PAGEICE[:EquityWeighting, :td_totaldiscountedimpacts],
                                    m_PAGEICE[:Discontinuity, :rcons_per_cap_DiscRemainConsumption_ann_sum],
                                    m_PAGEICE[:Discontinuity, :occurdis_occurrencedummy_ann_sum],
                                    # m_PAGEICE[:MarketDamagesBurke, :rcons_per_cap_MarketRemainConsumption_ann],
                                    m_PAGEICE[:MarketDamagesBurke, :rgdp_per_cap_MarketRemainGDP_ann_sum],
                                    # m_PAGEICE[:NonMarketDamages, :rcons_per_cap_MarketRemainConsumption_ann],
                                    m_PAGEICE[:NonMarketDamages, :rgdp_per_cap_NonMarketRemainGDP_ann_sum]])
    push!(df_overview, ["PAGE-ANN", scc_nonvar, m_nonvar[:EquityWeighting, :td_totaldiscountedimpacts_ann],
                                    m_nonvar[:Discontinuity, :rcons_per_cap_DiscRemainConsumption_ann_sum],
                                    m_nonvar[:Discontinuity, :occurdis_occurrencedummy_ann_sum],
                                    # m_nonvar[:MarketDamagesBurke, :rcons_per_cap_MarketRemainConsumption_ann],
                                    m_nonvar[:MarketDamagesBurke, :rgdp_per_cap_MarketRemainGDP_ann_sum],
                                    # m_nonvar[:NonMarketDamages, :rcons_per_cap_MarketRemainConsumption_ann],
                                    m_nonvar[:NonMarketDamages, :rgdp_per_cap_NonMarketRemainGDP_ann_sum]])
    push!(df_overview, ["PAGE-VAR", scc_var, m_var[:EquityWeighting, :td_totaldiscountedimpacts_ann],
                                    m_var[:Discontinuity, :rcons_per_cap_DiscRemainConsumption_ann_sum],
                                    m_var[:Discontinuity, :occurdis_occurrencedummy_ann_sum],
                                    # m_var[:MarketDamagesBurke, :rcons_per_cap_MarketRemainConsumption_ann],
                                    m_var[:MarketDamagesBurke, :rgdp_per_cap_MarketRemainGDP_ann_sum],
                                    # m_var[:NonMarketDamages, :rcons_per_cap_MarketRemainConsumption_ann],
                                    m_var[:NonMarketDamages, :rgdp_per_cap_NonMarketRemainGDP_ann_sum]])


    showall(df_overview)

end

# explore the sensitivity of the SCC for changes in the amplitude of variability for a deterministic run --- only for PAGE-VAR, ovbiously
function var_sensitivity_deterministic(scenario::String = "NDCs")
    global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/VarSensitivityTests/deterministic/"
    df_varmultiplier_mybday = DataFrame(Multiplier = Float64[], SCC_2020 = Float64[], NonMarketCost = Float64[], MarketBurkeCost = Float64[], DiscontCost = Float64[])
    df_varmultiplier_vbday = DataFrame(Multiplier = Float64[], SCC_2020 = Float64[], NonMarketCost = Float64[], MarketBurkeCost = Float64[], DiscontCost = Float64[])
    df_varmultiplier_mbday = DataFrame(Multiplier = Float64[], SCC_2020 = Float64[], NonMarketCost = Float64[], MarketBurkeCost = Float64[], DiscontCost = Float64[])
    df_varmultiplier_rbday = DataFrame(Multiplier = Float64[], SCC_2020 = Float64[], NonMarketCost = Float64[], MarketBurkeCost = Float64[], DiscontCost = Float64[])
    df_varmultiplier_lbday = DataFrame(Multiplier = Float64[], SCC_2020 = Float64[], NonMarketCost = Float64[], MarketBurkeCost = Float64[], DiscontCost = Float64[])
    mybday = 21101996
    vbday = 28041993
    mbday = 20041995
    rbday = 3111994
    lbday = 2111995


    global use_annual = true
    global use_interannvar = true
    global globallyset_use_interannvar = true

    for i = collect(range(0, stop = 3, length = 31))
        global v_multiplier = i
        println("var multiplier = ", v_multiplier)


        # for random seed 1.
        Random.seed!(mybday)
        include("getpagefunction.jl")
        include("utils/mctools.jl")
        Random.seed!(mybday)
        m_varmultiplier = getpage(scenario)
        Random.seed!(mybday)
        run(m_varmultiplier)
        Random.seed!(mybday)
        global randomdraw = mybday
        scc_varmultiplier = compute_scc(m_varmultiplier, year=2020)

        push!(df_varmultiplier_mybday, [i, scc_varmultiplier, m_varmultiplier[:NonMarketDamages, :rgdp_per_cap_NonMarketRemainGDP_ann_sum], m_varmultiplier[:MarketDamagesBurke, :rgdp_per_cap_MarketRemainGDP_ann_sum], m_varmultiplier[:Discontinuity, :rcons_per_cap_DiscRemainConsumption_ann_sum]])

        # for random seed 2.
        Random.seed!(vbday)
        include("getpagefunction.jl")
        include("utils/mctools.jl")
        Random.seed!(vbday)
        m_varmultiplier = getpage(scenario)
        Random.seed!(vbday)
        run(m_varmultiplier)
        Random.seed!(vbday)
        global randomdraw = vbday
        scc_varmultiplier = compute_scc(m_varmultiplier, year=2020)

        push!(df_varmultiplier_vbday, [i, scc_varmultiplier, m_varmultiplier[:NonMarketDamages, :rgdp_per_cap_NonMarketRemainGDP_ann_sum], m_varmultiplier[:MarketDamagesBurke, :rgdp_per_cap_MarketRemainGDP_ann_sum], m_varmultiplier[:Discontinuity, :rcons_per_cap_DiscRemainConsumption_ann_sum]])

        # for random seed 3.
        Random.seed!(mbday)
        include("getpagefunction.jl")
        include("utils/mctools.jl")
        Random.seed!(mbday)
        m_varmultiplier = getpage(scenario)
        Random.seed!(mbday)
        run(m_varmultiplier)
        Random.seed!(mbday)
        global randomdraw = mbday
        scc_varmultiplier = compute_scc(m_varmultiplier, year=2020)

        push!(df_varmultiplier_mbday, [i, scc_varmultiplier, m_varmultiplier[:NonMarketDamages, :rgdp_per_cap_NonMarketRemainGDP_ann_sum], m_varmultiplier[:MarketDamagesBurke, :rgdp_per_cap_MarketRemainGDP_ann_sum], m_varmultiplier[:Discontinuity, :rcons_per_cap_DiscRemainConsumption_ann_sum]])

        # for random seed 4.
        Random.seed!(rbday)
        include("getpagefunction.jl")
        include("utils/mctools.jl")
        Random.seed!(rbday)
        m_varmultiplier = getpage(scenario)
        Random.seed!(rbday)
        run(m_varmultiplier)
        Random.seed!(rbday)
        global randomdraw = rbday
        scc_varmultiplier = compute_scc(m_varmultiplier, year=2020)

        push!(df_varmultiplier_rbday, [i, scc_varmultiplier, m_varmultiplier[:NonMarketDamages, :rgdp_per_cap_NonMarketRemainGDP_ann_sum], m_varmultiplier[:MarketDamagesBurke, :rgdp_per_cap_MarketRemainGDP_ann_sum], m_varmultiplier[:Discontinuity, :rcons_per_cap_DiscRemainConsumption_ann_sum]])

        # for random seed 5.
        Random.seed!(lbday)
        include("getpagefunction.jl")
        include("utils/mctools.jl")
        Random.seed!(lbday)
        m_varmultiplier = getpage(scenario)
        Random.seed!(lbday)
        run(m_varmultiplier)
        Random.seed!(lbday)
        global randomdraw = lbday
        scc_varmultiplier = compute_scc(m_varmultiplier, year=2020)

        push!(df_varmultiplier_lbday, [i, scc_varmultiplier, m_varmultiplier[:NonMarketDamages, :rgdp_per_cap_NonMarketRemainGDP_ann_sum], m_varmultiplier[:MarketDamagesBurke, :rgdp_per_cap_MarketRemainGDP_ann_sum], m_varmultiplier[:Discontinuity, :rcons_per_cap_DiscRemainConsumption_ann_sum]])

    end
    # showall(df_varmultiplier)
    CSV.write(string(dir_output, "df_varmultiplier_mybday.csv"), df_varmultiplier_mybday, delim = ',')
    CSV.write(string(dir_output, "df_varmultiplier_vbday.csv"), df_varmultiplier_vbday, delim = ',')
    CSV.write(string(dir_output, "df_varmultiplier_rbday.csv"), df_varmultiplier_mbday, delim = ',')
    CSV.write(string(dir_output, "df_varmultiplier_mbday.csv"), df_varmultiplier_rbday, delim = ',')
    CSV.write(string(dir_output, "df_varmultiplier_lbday.csv"), df_varmultiplier_lbday, delim = ',')
end

# var_sensitivity_deterministic()

############# to be done!! #############
#  explore the sensitivity of the SCC for changes in the amplitude of variability for a deterministic run --- only for PAGE-VAR, ovbiously
function var_sensitivity_properMC(numMCruns::Int64 = 2000, scenario::String = "NDCs")
    ######
    ######
    ######
    ######
    ######
    ######
    ###### everything in function below this needs to be rewritten to useful MC stuff.
    global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/VarSensitivityTests/montecarlo/"
    global use_no_varMC = false # needs to be full ramge, without variability fluctuating, as we push it ourselves
    df_varmultiplier = DataFrame(Multiplier = Float64[], SCC_2020 = Float64[], NonMarketCost = Float64[], MarketBurkeCost = Float64[], DiscontCost = Float64[])

    global use_annual = true
    global use_interannvar = true
    global globallyset_use_interannvar = true

    for i = collect(range(0, stop = 3, length = 31))
        global v_multiplier = i
        println("var multiplier = ", v_multiplier)

        Random.seed!(2110);
        include("getpagefunction.jl")
        include("utils/mctools.jl")

        m_varmultiplier = getpage(scenario)
        run(m_varmultiplier)
        scc_varmultiplier = compute_scc(m_varmultiplier, year=2020)

        # do monte carlo runs for every iteration here, to get an idea of the range, rather than just one draw with an arbitrary randseed.

        push!(df_varmultiplier, [i, scc_varmultiplier, m_varmultiplier[:NonMarketDamages, :rgdp_per_cap_NonMarketRemainGDP_ann_sum], m_varmultiplier[:MarketDamagesBurke, :rgdp_per_cap_MarketRemainGDP_ann_sum], m_varmultiplier[:Discontinuity, :rcons_per_cap_DiscRemainConsumption_ann_sum]])
    end
    showall(df_varmultiplier)
    CSV.write(string(dir_output, "df_varmultiplier.csv"), df_varmultiplier, delim = ',')
end
# explore the sensitivity of random.seed by doing several runs. deterministic --- only for PAGE-VAR, to illustrate the point, but also only one affected by it in deterministic runs
function var_sensitivity_randomseed(scenario::String = "NDCs")
    global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/RandomSeedSensitivity/page-var/"
    df_varmultiplier = DataFrame(RandomSeed = Int64[], SCC_2020 = Float64[], NonMarketCost = Float64[], MarketBurkeCost = Float64[], DiscontCost = Float64[])

    global use_annual = true
    global use_interannvar = true
    global globallyset_use_interannvar = false

    i = 0
    while i < 50000
        # println("random seed = ", i)

        Random.seed!(i);
        include("getpagefunction.jl")
        include("utils/mctools.jl")

        m_varmultiplier = getpage(scenario)
        run(m_varmultiplier)
        scc_varmultiplier = compute_scc(m_varmultiplier, year=2020)

        # do monte carlo runs for every iteration here, to get an idea of the range, rather than just one draw with an arbitrary randseed.

        push!(df_varmultiplier, [i, scc_varmultiplier, m_varmultiplier[:NonMarketDamages, :rgdp_per_cap_NonMarketRemainGDP_ann_sum], m_varmultiplier[:MarketDamagesBurke, :rgdp_per_cap_MarketRemainGDP_ann_sum], m_varmultiplier[:Discontinuity, :rcons_per_cap_DiscRemainConsumption_ann_sum]])
        i = i + 1
    end
    showall(df_varmultiplier)
    CSV.write(string(dir_output, "df_varmultiplier.csv"), df_varmultiplier, delim = ',')
end

# explore the sensitivity of random.seed by doing several runs. deterministic --- only for PAGE-VAR, to illustrate the point, but also only one affected by it in deterministic runs
function var_sensitivity_randomseed_deterministic_combo(numSeedRuns::Int64 = 100, scenario::String = "NDCs")
    global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/RandomSeedSensitivity_Determinstic_Combo/page-var/"
    df_varmultiplier = DataFrame(RandomSeed = Float64[], mean_SCC = Float64[], sd_SCC = Float64[])

    # GOAL: create what is in var_sensitivity_deterministic but then with means and error bars

    global use_annual = true
    global use_interannvar = true
    global globallyset_use_interannvar = true
    include("getpagefunction.jl")
    include("utils/mctools.jl")

    for i = collect(range(0, stop = 3, length = 51))
        global v_multiplier = i
        println("var multiplier = ", v_multiplier)
        ii = 1
        scc_array = zeros(numSeedRuns)

        while ii < numSeedRuns
            # println("random seed = ", ii)

            Random.seed!(ii);
            include("getpagefunction.jl")
            include("utils/mctools.jl")


            m = getpage(scenario)
            run(m)
            scc_varmultiplier = compute_scc(m, year=2020)

            scc_array[ii] = scc_varmultiplier

            ii = ii + 1
        end
        push!(df_varmultiplier, [i, mean(scc_array), std(scc_array)])
    end
    showall(df_varmultiplier)
    CSV.write(string(dir_output, "df_varmultiplier.csv"), df_varmultiplier, delim = ',')
end



# do a single run with variability
function singlerun_var(scenario::String = "NDCs")

    global use_annual = true
    global use_interannvar = true

    Random.seed!(2110);

    include("getpagefunction.jl")
    include("utils/mctools.jl")


    m_var = getpage(scenario)
    run(m_var)
    # scc_var = compute_scc(m_var, year=2020)

    # println(m_var[:Discontinuity, :rcons_per_cap_DiscRemainConsumption_ann_sum])
    # explore(m_var)
end




# do Monte Carlo runs for PAGE-ICE, PAGE-ANN, and PAGE-VAR
function do_variability_MCs(numMCruns::Int64 = 2000, scenario::String = "NDCs", calc_scc::Bool=true)

    include("getpagefunction.jl")
    include("utils/mctools.jl")
    include("mcs.jl")
    include("compute_scc.jl")

    global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEICE"
    global use_annual = false
    global use_interannvar = false
    global v_multiplier = 0

    Random.seed!(2110);
    do_monte_carlo_runs(numMCruns, dir_output)
    global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEICE/scc"
    if calc_scc
        get_scc_mcs(numMCruns, 2020, dir_output)
    end


    include("getpagefunction.jl")
    include("utils/mctools.jl")
    include("mcs.jl")
    include("compute_scc.jl")

    global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEANN"
    global use_annual = true
    global use_interannvar = false
    global v_multiplier = 0

    Random.seed!(2110);
    do_monte_carlo_runs(numMCruns, dir_output)
    global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEANN/scc"
    if calc_scc
        get_scc_mcs(numMCruns, 2020, dir_output)
    end


    include("getpagefunction.jl")
    include("utils/mctools.jl")
    include("mcs.jl")
    include("compute_scc.jl")

    global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR"
    global use_annual = true
    global use_interannvar = true
    global v_multiplier = 1

    Random.seed!(2110);
    do_monte_carlo_runs(numMCruns, dir_output)
    global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/scc"
    if calc_scc
        get_scc_mcs(numMCruns, 2020, dir_output)
    end

end

# do Monte Carlo runs for multiple different scenarios
function do_var_scenario_MCs(numMCruns::Int64=100)
    global use_annual = true
    global use_interannvar = true
    randomdraw = rand(1:1000000000000)

    ## THESE TWO SCENARIOS SEEM NOT TO BE WORKING:
    # global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/1_5C"
    # global scenario = "1.5 degC Target"
    # include("getpagefunction.jl")
    # include("utils/mctools.jl")
    # include("mcs.jl")
    # Random.seed!(2110);
    # get_scc_mcs(numMCruns, 2020, dir_output, scenario)
    #
    #
    # global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/2_0C"
    # global scenario = "2 degC Target"
    # include("getpagefunction.jl")
    # include("utils/mctools.jl")
    # include("mcs.jl")
    # Random.seed!(2110);
    # get_scc_mcs(numMCruns, 2020, dir_output, scenario=scenario)

    global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/onlyvarMC/2_5C"
    global scenario = "2.5 degC Target"
    include("getpagefunction.jl")
    include("utils/mctools.jl")
    include("mcs.jl")
    Random.seed!(randomdraw);
    get_scc_mcs(numMCruns, 2020, dir_output, scenario)

    global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/onlyvarMC/NDC"
    global scenario = "NDCs"
    include("getpagefunction.jl")
    include("utils/mctools.jl")
    include("mcs.jl")
    Random.seed!(randomdraw);
    get_scc_mcs(numMCruns, 2020, dir_output, scenario)

    global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/onlyvarMC/BAU"
    global scenario = "BAU"
    include("getpagefunction.jl")
    include("utils/mctools.jl")
    include("mcs.jl")
    Random.seed!(randomdraw);
    get_scc_mcs(numMCruns, 2020, dir_output, scenario)

    global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/onlyvarMC/RCP2_6_SSP1"
    global scenario = "RCP2.6 & SSP1"
    include("getpagefunction.jl")
    include("utils/mctools.jl")
    include("mcs.jl")
    Random.seed!(randomdraw);
    get_scc_mcs(numMCruns, 2020, dir_output, scenario)

    global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/onlyvarMC/RCP4_5_SSP2"
    global scenario = "RCP4.5 & SSP2"
    include("getpagefunction.jl")
    include("utils/mctools.jl")
    include("mcs.jl")
    Random.seed!(randomdraw);
    get_scc_mcs(numMCruns, 2020, dir_output, scenario)

    global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/onlyvarMC/RCP8_5_SSP5"
    global scenario = "RCP8.5 & SSP5"
    include("getpagefunction.jl")
    include("utils/mctools.jl")
    include("mcs.jl")
    Random.seed!(randomdraw);
    get_scc_mcs(numMCruns, 2020, dir_output, scenario)
end
# do Monte Carlo runs for multiple different scenarios
function scenario_pathways()
    global use_annual = true
    global use_interannvar = true
    randomdraw = rand(1:1000000000000)

    ## THESE TWO SCENARIOS SEEM NOT TO BE WORKING:
    # global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/1_5C"
    # global scenario = "1.5 degC Target"
    # include("getpagefunction.jl")
    # include("utils/mctools.jl")
    # include("mcs.jl")
    # Random.seed!(2110);
    # get_scc_mcs(numMCruns, 2020, dir_output, scenario)
    #
    #
    # global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/2_0C"
    # global scenario = "2 degC Target"
    # include("getpagefunction.jl")
    # include("utils/mctools.jl")
    # include("mcs.jl")
    # Random.seed!(2110);
    # get_scc_mcs(numMCruns, 2020, dir_output, scenario=scenario)

    global scenario = "2.5 degC Target"
    include("getpagefunction.jl")
    include("utils/mctools.jl")
    Random.seed!(randomdraw)
    m_25 = getpage(scenario)
    run(m_25)

    global scenario = "NDCs"
    include("getpagefunction.jl")
    include("utils/mctools.jl")
    Random.seed!(randomdraw)
    m_ndc = getpage(scenario)
    run(m_ndc)

    global scenario = "BAU"
    include("getpagefunction.jl")
    include("utils/mctools.jl")
    Random.seed!(randomdraw)
    m_bau = getpage(scenario)
    run(m_bau)

    global scenario = "RCP2.6 & SSP1"
    include("getpagefunction.jl")
    include("utils/mctools.jl")
    Random.seed!(randomdraw)
    m_26_1 = getpage(scenario)
    run(m_26_1)

    global scenario = "RCP4.5 & SSP2"
    include("getpagefunction.jl")
    include("utils/mctools.jl")
    Random.seed!(randomdraw)
    m_45_2 = getpage(scenario)
    run(m_45_2)

    global scenario = "RCP8.5 & SSP5"
    include("getpagefunction.jl")
    include("utils/mctools.jl")
    Random.seed!(randomdraw)
    m_85_5 = getpage(scenario)
    run(m_85_5)


    ## Using DataFrames
    global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/scenarioIllustration/"
    df_temp = DataFrame(year = Int64[], sc25 = Float64[], scndc = Float64[], scbau = Float64[], sc261 = Float64[], sc452 = Float64[], sc855 = Float64[])
    # df_emis = DataFrame(year = Int64[], sc25 = Float64[], scndc = Float64[], scbau = Float64[], sc261 = Float64[], sc452 = Float64[], sc855 = Float64[])
    df_gdp = DataFrame(year = Int64[], sc25 = Float64[], scndc = Float64[], scbau = Float64[], sc261 = Float64[], sc452 = Float64[], sc855 = Float64[])
    df_imp = DataFrame(year = Int64[], sc25 = Float64[], scndc = Float64[], scbau = Float64[], sc261 = Float64[], sc452 = Float64[], sc855 = Float64[])

    for year in 2015:2300
        yr = year - 2015 + 1
        # save file with annual temperatures
        push!(df_temp, [year, m_25[:ClimateTemperature, :rt_g_globaltemperature_ann][yr], m_ndc[:ClimateTemperature, :rt_g_globaltemperature_ann][yr], m_bau[:ClimateTemperature, :rt_g_globaltemperature_ann][yr], m_26_1[:ClimateTemperature, :rt_g_globaltemperature_ann][yr], m_45_2[:ClimateTemperature, :rt_g_globaltemperature_ann][yr], m_85_5[:ClimateTemperature, :rt_g_globaltemperature_ann][yr] ])
        # # save file with annual emissions
        # push!(df_emis, [year, m_25[:EquityWeighting, :cons_percap_consumption_ann[yr]], m_ndc[:EquityWeighting, :cons_percap_consumption_ann[yr]], m_bau[:EquityWeighting, :cons_percap_consumption_ann[yr]], m_26_1[:EquityWeighting, :cons_percap_consumption_ann[yr]], m_45_2[:EquityWeighting, :cons_percap_consumption_ann[yr]], m_85_5[:EquityWeighting, :cons_percap_consumption_ann[yr]] ])
        # save file with annual GDP
        push!(df_gdp, [year, m_25[:EquityWeighting, :cons_percap_consumption_ann][yr], m_ndc[:EquityWeighting, :cons_percap_consumption_ann][yr], m_bau[:EquityWeighting, :cons_percap_consumption_ann][yr], m_26_1[:EquityWeighting, :cons_percap_consumption_ann][yr], m_45_2[:EquityWeighting, :cons_percap_consumption_ann][yr], m_85_5[:EquityWeighting, :cons_percap_consumption_ann][yr] ])
        # save file with annual total impacts
        push!(df_imp, [year, m_25[:EquityWeighting, :te_totaleffect_ann_yr][yr], m_ndc[:EquityWeighting, :te_totaleffect_ann_yr][yr], m_bau[:EquityWeighting, :te_totaleffect_ann_yr][yr], m_26_1[:EquityWeighting, :te_totaleffect_ann_yr][yr], m_45_2[:EquityWeighting, :te_totaleffect_ann_yr][yr], m_85_5[:EquityWeighting, :te_totaleffect_ann_yr][yr] ])
    end
    CSV.write(string(dir_output, "df_temp.csv"), df_temp)
    # CSV.write(string(dir_output, "df_emis.csv"), df_emis)
    CSV.write(string(dir_output, "df_gdp.csv"), df_gdp)
    CSV.write(string(dir_output, "df_imp.csv"), df_imp)

end

# do deterministic runs for PAGE-ICE, PAGE-ANN, and PAGE-VAR and output various variables for analysis (using DataFrame)
function compare_deterministic_ICEANNVAR(scenario::String = "NDCs")
    # for saving the results
    df_ICE_global = DataFrame(ModelName = String[], year = String[], SCC = Float64[], g_temp = Float64[],
                                td_totdiscountimpact = Float64[])
    df_ICE_regional = DataFrame(ModelName = String[], year = String[],
                                r_temp = Float64[], gdprem_marketburke = Float64[],
                                consremain_marketburke = Float64[], gdprem_nonmarket = Float64[],
                                consremain_nonmarket = Float64[], consremain_discon = Float64[],
                                impact_equity = Float64[], adaptation_equity = Float64[]) # NOTE; no easy way to do SCC yet regionally.
    df_ANN_global = DataFrame(ModelName = String[], year = String[], SCC = Float64[], g_temp = Float64[],
                                td_totdiscountimpact = Float64[])
    df_ANN_regional = DataFrame(ModelName = String[], year = String[],
                                r_temp = Float64[], gdprem_marketburke = Float64[],
                                consremain_marketburke = Float64[], gdprem_nonmarket = Float64[],
                                consremain_nonmarket = Float64[], consremain_discon = Float64[],
                                impact_equity = Float64[], adaptation_equity = Float64[])
    df_VAR_global = DataFrame(ModelName = String[], year = String[], SCC = Float64[], g_temp = Float64[],
                                td_totdiscountimpact = Float64[])
    df_VAR_regional = DataFrame(ModelName = String[], year = String[],
                                r_temp = Float64[], gdprem_marketburke = Float64[],
                                consremain_marketburke = Float64[], gdprem_nonmarket = Float64[],
                                consremain_nonmarket = Float64[], consremain_discon = Float64[],
                                impact_equity = Float64[], adaptation_equity = Float64[])

    # timestep PAGE-ICE:
    global use_annual = false
    global use_interannvar = false
    global v_multiplier = 0

    include("getpagefunction.jl")
    include("utils/mctools.jl")

    m_ICE = getpage(scenario)
    run(m_ICE)

    # get intermediary variables
        ### variables I want: summary variables of ClimateTemperature MarketDamagesBurke, NonMarketDamages, Discontinuity, EquityWeighting
        ###   which are [annual versions]:
        ###     Climate:        rt_g_globaltemperature_ann**, rtl_realizedtemperature_ann
        ###     Burke:          rgdp_per_cap_MarketRemainGDP_ann, rcons_per_cap_MarketRemainConsumption_ann
        ###     NonMarket:      rgdp_per_cap_NonMarketRemainGDP_ann, rcons_per_cap_NonMarketRemainConsumption_ann
        ###     Discontinuity:  rcons_per_cap_DiscRemainConsumption_ann
        ###     Equity:         td_totaldiscountedimpacts**, addt_equityweightedimpact_discountedaggregated_ann, aact_equityweightedadaptation_discountedaggregated_ann
        ###   **not regional

    var1 = m_ICE[:ClimateTemperature, :rt_g_globaltemperature]
    var2 = m_ICE[:ClimateTemperature, :rtl_realizedtemperature]
    var3 = m_ICE[:MarketDamagesBurke, :rgdp_per_cap_MarketRemainGDP]
    var4 = m_ICE[:MarketDamagesBurke, :rcons_per_cap_MarketRemainConsumption]
    var5 = m_ICE[:NonMarketDamages, :rgdp_per_cap_NonMarketRemainGDP]
    var6 = m_ICE[:NonMarketDamages, :rcons_per_cap_NonMarketRemainConsumption]
    var7 = m_ICE[:Discontinuity, :rcons_per_cap_DiscRemainConsumption]
    var8 = m_ICE[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated]
    var9 = m_ICE[:EquityWeighting, :aact_equityweightedadaptation_discountedaggregated]
    var10 = m_ICE[:EquityWeighting, :td_totaldiscountedimpacts_ts]


    # create timeseries of SCC:
    t = 1
    for y in [2020, 2030, 2040, 2050, 2075, 2100, 2150, 2200, 2250, 2300]
        scc_ICE = compute_scc(m_ICE, year=y)
        push!(df_ICE_global, ["PAGE-ICE", string(y), scc_ICE, var1[t], var10[t]])

        for r = 1:1
            push!(df_ICE_regional, ["PAGE-ICE", string(y),
                            var2[t,r], var3[t,r],
                            var4[t,r], var5[t,r],
                            var6[t,r], var7[t,r],
                            var8[t,r], var9[t,r]])
        end
        t = t + 1
    end





    # PAGE-ANN:
    global use_annual = true
    global use_interannvar = false
    global v_multiplier = 0

    include("getpagefunction.jl")
    include("utils/mctools.jl")

    m_ANN = getpage(scenario)
    run(m_ANN)

    # get intermediary variables
    var1 = m_ANN[:ClimateTemperature, :rt_g_globaltemperature_ann]
    var2 = m_ANN[:ClimateTemperature, :rtl_realizedtemperature_ann]
    var3 = m_ANN[:MarketDamagesBurke, :rgdp_per_cap_MarketRemainGDP_ann]
    var4 = m_ANN[:MarketDamagesBurke, :rcons_per_cap_MarketRemainConsumption_ann]
    var5 = m_ANN[:NonMarketDamages, :rgdp_per_cap_NonMarketRemainGDP_ann]
    var6 = m_ANN[:NonMarketDamages, :rcons_per_cap_NonMarketRemainConsumption_ann]
    var7 = m_ANN[:Discontinuity, :rcons_per_cap_DiscRemainConsumption_ann]
    var8 = m_ANN[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated_ann]
    var9 = m_ANN[:EquityWeighting, :aact_equityweightedadaptation_discountedaggregated_ann]
    var10 = m_ANN[:EquityWeighting, :td_totaldiscountedimpacts_ann_yr]

    # create timeseries of SCC:
    for y in [2020, 2030, 2040, 2050, 2075, 2100, 2150, 2200, 2250, 2300]
        yr = y - 2015 + 1

        scc_ANN = compute_scc(m_ANN, year=y)
        push!(df_ANN_global, ["PAGE-ANN", string(y), scc_ANN, var1[yr], var10[yr]])
    end
    for y in collect(2015:2300)
        yr = y - 2015 + 1
        for r = 1:1
            push!(df_ANN_regional, ["PAGE-ANN", string(y),
                            var2[yr,r], var3[yr,r],
                            var4[yr,r], var5[yr,r],
                            var6[yr,r], var7[yr,r],
                            var8[yr,r], var9[yr,r]])
        end
    end

    # PAGE-VAR:
    global use_annual = true
    global use_interannvar = true
    global v_multiplier = 1

    Random.seed!(2110);

    include("getpagefunction.jl")
    include("utils/mctools.jl")

    m_VAR = getpage(scenario)
    run(m_VAR)

    # get intermediary variables
    var1 = m_VAR[:ClimateTemperature, :rt_g_globaltemperature_ann]
    var2 = m_VAR[:ClimateTemperature, :rtl_realizedtemperature_ann]
    var3 = m_VAR[:MarketDamagesBurke, :rgdp_per_cap_MarketRemainGDP_ann]
    var4 = m_VAR[:MarketDamagesBurke, :rcons_per_cap_MarketRemainConsumption_ann]
    var5 = m_VAR[:NonMarketDamages, :rgdp_per_cap_NonMarketRemainGDP_ann]
    var6 = m_VAR[:NonMarketDamages, :rcons_per_cap_NonMarketRemainConsumption_ann]
    var7 = m_VAR[:Discontinuity, :rcons_per_cap_DiscRemainConsumption_ann]
    var8 = m_VAR[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated_ann]
    var9 = m_VAR[:EquityWeighting, :aact_equityweightedadaptation_discountedaggregated_ann]
    var10 = m_VAR[:EquityWeighting, :td_totaldiscountedimpacts_ann_yr]

    # create timeseries of SCC:
    for y in [2020, 2030, 2040, 2050, 2075, 2100, 2150, 2200, 2250, 2300]
        yr = y - 2015 + 1
        scc_VAR = compute_scc(m_ANN, year=y)
        push!(df_VAR_global, ["PAGE-VAR", string(y), scc_VAR, var1[yr], var10[yr]])
    end
    for y in collect(2015:2300)
        yr = y - 2015 + 1
        for r = 1:1
            push!(df_VAR_regional, ["PAGE-VAR", string(y),
                            var2[yr,r], var3[yr,r],
                            var4[yr,r], var5[yr,r],
                            var6[yr,r], var7[yr,r],
                            var8[yr,r], var9[yr,r]])
        end
    end



    # showall(df_ICE_global)
    # showall(df_ICE_regional)
    # showall(df_ANN_global)
    # showall(df_ANN_regional)
    # showall(df_VAR_global)
    # showall(df_VAR_regional)
    global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/ICEvANNvVAR/"
    CSV.write(string(dir_output, scenario, "/df_ICE_global.csv"), df_ICE_global, delim = ',')
    CSV.write(string(dir_output, scenario, "/df_ICE_regional.csv"), df_ICE_regional, delim = ',')
    CSV.write(string(dir_output, scenario, "/df_ANN_global.csv"), df_ANN_global, delim = ',')
    CSV.write(string(dir_output, scenario, "/df_ANN_regional.csv"), df_ANN_regional, delim = ',')
    CSV.write(string(dir_output, scenario, "/df_VAR_global.csv"), df_VAR_global, delim = ',')
    CSV.write(string(dir_output, scenario, "/df_VAR_regional.csv"), df_VAR_regional, delim = ',')

    # explore(m_ICE)
    # explore(m_ANN)
    # explore(m_VAR)
end

# do deterministic runs for PAGE-ICE, PAGE-ANN, and PAGE-VAR and output various variables for analysis (using DataFrame)
function compare_stochastic_ICEANNVAR_fullMCoptions(numMCruns::Int64 = 10000, scenario::String = "NDCs", onlyvar::Bool=false, novar::Bool=false)
    global use_only_varMC = onlyvar
    global use_no_varMC = novar

    ### PAGE-ICE ###
    if use_only_varMC
        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/ICEANNVARmcAugust_onlyvarMC/page-ice/"
    elseif use_no_varMC
        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/ICEANNVARmcAugust_novarMC/page-ice/"
    else
        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/ICEANNVARmcAugust_fullMC/page-ice/"
    end
    global use_annual = false
    global use_interannvar = false
    # global v_multiplier = 0
    include("getpagefunction.jl")
    include("utils/mctools.jl")
    include("mcs.jl")
    Random.seed!(21101996);
    do_monte_carlo_runs(numMCruns, dir_output)
    # get_scc_mcs(numMCruns, 2020, dir_output, scenario)

    ### PAGE-ANN ###
    if use_only_varMC
        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/ICEANNVARmcAugust_onlyvarMC/page-ann/"
    elseif use_no_varMC
        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/ICEANNVARmcAugust_novarMC/page-ann/"
    else
        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/ICEANNVARmcAugust_fullMC/page-ann/"
    end
    global use_annual = true
    global use_interannvar = false
    # global v_multiplier = 0
    include("getpagefunction.jl")
    include("utils/mctools.jl")
    include("mcs.jl")
    Random.seed!(21101996);
    do_monte_carlo_runs(numMCruns, dir_output)
    # get_scc_mcs(numMCruns, 2020, dir_output, scenario)


    ### PAGE-VAR ###
    if use_only_varMC
        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/ICEANNVARmcAugust_onlyvarMC/page-var/"
    elseif use_no_varMC
        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/ICEANNVARmcAugust_novarMC/page-var/"
    else
        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/ICEANNVARmcAugust_fullMC/page-var/"
    end
    global use_annual = true
    global use_interannvar = true
    # global v_multiplier = 1
    include("getpagefunction.jl")
    include("utils/mctools.jl")
    include("mcs.jl")
    Random.seed!(21101996);
    do_monte_carlo_runs(numMCruns, dir_output)
    # get_scc_mcs(numMCruns, 2020, dir_output, scenario)

end


# function explore_discontinuity(scenario::String = "NDCs")
#     global use_annual = true
#     global use_interannvar = true
#     global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcDiscontuinty"
#     include("getpagefunction.jl")
#     include("utils/mctools.jl")
#     include("mcs.jl")
#     Random.seed!(2110);
#     get_scc_mcs(numMCruns, 2020, dir_output, scenario)
# end




##########################################################
# choose what to run:
##########################################################
# global use_linear = true
# global use_logburke = false
# global use_logpopulation = false
# println("Deterministic, for full linear interpolation:")
# overview_deterministic()
# global use_linear = false
# global use_logburke = true
# global use_logpopulation = false
# println("\n Deterministic, for full logarithmic interpolation:")
# overview_deterministic()
# global use_linear = false
# global use_logburke = false
# global use_logpopulation = true
# println("\n Deterministic, for full partial logarithmic (socioeconomics) interpolation:")
# overview_deterministic()

# # test pulse_size
# global use_linear = false
# global use_logburke = true
# global use_logpopulation = false
# println("\n\n Deterministic, for Burke log interpolation:")
#
# global use_annual = false
# global use_interannvar = false
# println("PAGE-ICE (timestep)")
# include("getpagefunction.jl")
# include("utils/mctools.jl")
# m_nonvar = getpage()
# run(m_nonvar)
# for pulse = [0.00001,  0.01,  1., 50.,  500.,  2000., 5000., 7500., 10000., 50000., 100000., 1000000., 10000000., 100000000.]
#     scc_nonvar = compute_scc(m_nonvar, year=2020, pulse_size = pulse)
#     println(string("SCC for pulse_size ", pulse, " = ", scc_nonvar))
# end
#
# global use_annual = true
# global use_interannvar = false
# println("PAGE-ANN (annual, no variability)")
# include("getpagefunction.jl")
# include("utils/mctools.jl")
# m_nonvar = getpage()
# run(m_nonvar)
# for pulse = [0.00001,  0.01,  1., 50.,  500.,  2000., 5000., 7500., 10000., 50000., 100000., 1000000., 10000000., 100000000.]
#     scc_nonvar = compute_scc(m_nonvar, year=2020, pulse_size = pulse)
#     println(string("SCC for pulse_size ", pulse, " = ", scc_nonvar))
# end
#
# global use_annual = true
# global use_interannvar = true
# println("PAGE-VAR (annual, with variability)")
# include("getpagefunction.jl")
# include("utils/mctools.jl")
# m_nonvar = getpage()
# run(m_nonvar)
# for pulse = [0.00001,  0.01,  1., 50.,  500.,  2000., 5000., 7500., 10000., 50000., 100000., 1000000., 10000000., 100000000.]
#     scc_nonvar = compute_scc(m_nonvar, year=2020, pulse_size = pulse)
#     println(string("SCC for pulse_size ", pulse, " = ", scc_nonvar))
# end


# var_sensitivity_deterministic()
# var_sensitivity_properMC()
# var_sensitivity_randomseed()
# var_sensitivity_randomseed_deterministic_combo(10)

### compare ICE v ANN v VAR with 3 different selected sets of MC parameters:
# ## only var:
# compare_stochastic_ICEANNVAR_fullMCoptions(5000, "NDCs", true, false)
# ## no var, all other uncertainties:
# compare_stochastic_ICEANNVAR_fullMCoptions(5000, "NDCs", false, true)
# ## full set of uncertainties:
# compare_stochastic_ICEANNVAR_fullMCoptions(5000, "NDCs", false, false)

# singlerun_var("NDCs")

# do_variability_MCs(10000, "NDCs", true)

# do_var_scenario_MCs(2000) # NOTE: still to make appropriate changes in `mcs.jl`
#
# for sc in ["2.5 degC Target", "NDCs", "BAU", "RCP2.6 & SSP1", "RCP4.5 & SSP2", "RCP8.5 & SSP5"]
#     compare_deterministic_ICEANNVAR(sc)
# end

# scenario_pathways()

## for visualising output in easy-to-use (but limited for annual) GUI (for model "m")
# explore(m)
