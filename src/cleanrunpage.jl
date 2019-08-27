using Mimi
using Distributions
using DataFrames
using CSV
using Random

# standard output folder:
global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/"

function set_default_bools()
    # use annual version
    global use_annual = true
    # use interannual variability
    global use_interannvar = true

    # set default monte carlo parameters to the full set of probability distributions
    global use_only_varMC = false
    global use_no_varMC = false
    # set default interpolation parameters
    global use_linear = false
    global use_logburke = true
    global use_logpopulation = false

    # set only when doing specific variability sensitivity analysis
    global globallyset_use_interannvar = false
end

# set default; interannual global mean standard deviation
global set_gvarsd = 0.11294 # default from https://github.com/jkikstra/climvar
# in case you so desire, set one default; interannual regional mean standard deviation [normally read from rvarsd_regionalvariabilitystandarddeviation.csv]
# global v_multiplier = 1 # introduced for sensitivity analysis for variability; default = 1 -> variability according to empirical results
set_default_bools()


#############################################
# overview of data needed in dissertation:
    # number = function, letter = plot
#############################################
# 0) no plot, overview deterministic, to determine interpolation style.
#
# 1)* scenario development: GDP, Impacts, temperatures, (emissions)
# 2)* plot (deterministic with standard deviations per var_multiplier) with dependence on random.seed +  (before fixing in compute_scc)
# 3)* plot (deterministic with standard deviations per var_multiplier) with dependence on random.seed +  (after fixing in compute_scc)
# 4) a) MC-violin of PAGE-ANN v PAGE-VAR with no variation in MC
#    b) MC-violin of PAGE-ANN v PAGE-VAR with only variation in MC
#    c) MC-violin of PAGE-ANN v PAGE-VAR with full variation in MC
# 5) MC-violin of PAGE-VAR for the 4 selected scenarios (no BAU and 8.5, which develop to surreal >6C )
# 6) a) MC-violin of discontinuity trigger day (for NDCs for PAGE-ICE, PAGE-ANN, and PAGE-VAR)
#    b) MC-violin of MarketDamagesBurke costs (consumption) (for NDCs for PAGE-ICE, PAGE-ANN, and PAGE-VAR)
#    c) MC-violin of discontinuity costs (consumption) (for NDCs for PAGE-ICE, PAGE-ANN, and PAGE-VAR)
# 7) NEW PLOT TO PRODUCE: plot timeseries changes in damages for (PAGE-VAR minus PAGE-ANN) per region
# 8) a) NEW PLOT TO PRODUCE: a plot like 3) but then with just dependence on the var_multiplier; SET random.seed similar for every run (=deterministic???).
#    b) for var_multiplier, do scatter+lin-fit, with uncertainties: g = sns.lmplot('X', 'Y', df, col='Z', sharex=False, sharey=False)

###################
# 0)
###################
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

###################
# 1)
###################
# do deterministic scenario development: GDP, Impacts, temperatures, (emissions)
###################
# done? => yes. http://localhost:8888/notebooks/Documents/GitHub/PAGEoutput/Plots%20for%20PAGE%20analysis.ipynb#Scenario-development
# done second: adding 1.5 and 2 degree? => not yet. Implemented. Now running for 100.
###################
function scenario_pathways()
    randomdraw = rand(1:1000000000000)

    # THESE TWO SCENARIOS SEEM NOT TO BE WORKING:
    global scenario = "1.5 degC Target"
    include("getpagefunction.jl")
    Random.seed!(randomdraw)
    m_15 = getpage(scenario)
    run(m_15)

    global scenario = "2 degC Target"
    include("getpagefunction.jl")
    Random.seed!(randomdraw)
    m_20 = getpage(scenario)
    run(m_20)

    global scenario = "2.5 degC Target"
    include("getpagefunction.jl")
    Random.seed!(randomdraw)
    m_25 = getpage(scenario)
    run(m_25)

    global scenario = "NDCs"
    include("getpagefunction.jl")
    Random.seed!(randomdraw)
    m_ndc = getpage(scenario)
    run(m_ndc)

    global scenario = "BAU"
    include("getpagefunction.jl")
    Random.seed!(randomdraw)
    m_bau = getpage(scenario)
    run(m_bau)

    global scenario = "RCP2.6 & SSP1"
    include("getpagefunction.jl")
    Random.seed!(randomdraw)
    m_26_1 = getpage(scenario)
    run(m_26_1)

    global scenario = "RCP4.5 & SSP2"
    include("getpagefunction.jl")
    Random.seed!(randomdraw)
    m_45_2 = getpage(scenario)
    run(m_45_2)

    global scenario = "RCP8.5 & SSP5"
    include("getpagefunction.jl")
    Random.seed!(randomdraw)
    m_85_5 = getpage(scenario)
    run(m_85_5)


    ## Using DataFrames
    global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/scenarioIllustration/"
    # all scenarios:
    df_temp = DataFrame(year = Int64[], sc15 = Float64[], sc20 = Float64[], sc25 = Float64[], scndc = Float64[], scbau = Float64[], sc261 = Float64[], sc452 = Float64[], sc855 = Float64[])
    # df_emis = DataFrame(year = Int64[], sc15 = Float64[], sc20 = Float64[], sc25 = Float64[], scndc = Float64[], scbau = Float64[], sc261 = Float64[], sc452 = Float64[], sc855 = Float64[])
    df_gdp = DataFrame(year = Int64[], sc15 = Float64[], sc20 = Float64[], sc25 = Float64[], scndc = Float64[], scbau = Float64[], sc261 = Float64[], sc452 = Float64[], sc855 = Float64[])
    df_imp = DataFrame(year = Int64[], sc15 = Float64[], sc20 = Float64[], sc25 = Float64[], scndc = Float64[], scbau = Float64[], sc261 = Float64[], sc452 = Float64[], sc855 = Float64[])
    # df_pop = DataFrame(year = Int64[], sc15 = Float64[], sc20 = Float64[], sc25 = Float64[], scndc = Float64[], scbau = Float64[], sc261 = Float64[], sc452 = Float64[], sc855 = Float64[])

    for year in 2015:2300
        yr = year - 2015 + 1
        # save file with annual temperatures
        push!(df_temp, [year, m_15[:ClimateTemperature, :rt_g_globaltemperature_ann][yr], m_20[:ClimateTemperature, :rt_g_globaltemperature_ann][yr], m_25[:ClimateTemperature, :rt_g_globaltemperature_ann][yr], m_ndc[:ClimateTemperature, :rt_g_globaltemperature_ann][yr], m_bau[:ClimateTemperature, :rt_g_globaltemperature_ann][yr], m_26_1[:ClimateTemperature, :rt_g_globaltemperature_ann][yr], m_45_2[:ClimateTemperature, :rt_g_globaltemperature_ann][yr], m_85_5[:ClimateTemperature, :rt_g_globaltemperature_ann][yr] ])
        # # save file with annual emissions
        # push!(df_emis, [year, m_15[:ClimateTemperature, :rt_g_globaltemperature_ann][yr], m_20[:ClimateTemperature, :rt_g_globaltemperature_ann][yr], m_25[:EquityWeighting, :cons_percap_consumption_ann[yr]], m_ndc[:EquityWeighting, :cons_percap_consumption_ann[yr]], m_bau[:EquityWeighting, :cons_percap_consumption_ann[yr]], m_26_1[:EquityWeighting, :cons_percap_consumption_ann[yr]], m_45_2[:EquityWeighting, :cons_percap_consumption_ann[yr]], m_85_5[:EquityWeighting, :cons_percap_consumption_ann[yr]] ])
        # save file with annual GDP
        push!(df_gdp, [year, m_15[:EquityWeighting, :cons_percap_consumption_ann][yr], m_20[:EquityWeighting, :cons_percap_consumption_ann][yr], m_25[:EquityWeighting, :cons_percap_consumption_ann][yr], m_ndc[:EquityWeighting, :cons_percap_consumption_ann][yr], m_bau[:EquityWeighting, :cons_percap_consumption_ann][yr], m_26_1[:EquityWeighting, :cons_percap_consumption_ann][yr], m_45_2[:EquityWeighting, :cons_percap_consumption_ann][yr], m_85_5[:EquityWeighting, :cons_percap_consumption_ann][yr]
        ])
        # save file with annual total impacts
        push!(df_imp, [year, m_15[:EquityWeighting, :te_totaleffect_ann_yr][yr], m_20[:EquityWeighting, :te_totaleffect_ann_yr][yr], m_25[:EquityWeighting, :te_totaleffect_ann_yr][yr], m_ndc[:EquityWeighting, :te_totaleffect_ann_yr][yr], m_bau[:EquityWeighting, :te_totaleffect_ann_yr][yr], m_26_1[:EquityWeighting, :te_totaleffect_ann_yr][yr], m_45_2[:EquityWeighting, :te_totaleffect_ann_yr][yr], m_85_5[:EquityWeighting, :te_totaleffect_ann_yr][yr] ])
        # # save file with population
        # push!(df_imp, [year, m_15[:Population, :pop_population][yr], m_20[:Population, :pop_population][yr], m_25[:Population, :pop_population][yr], m_ndc[:EquityWeighting, :te_totaleffect_ann_yr][yr], m_bau[:EquityWeighting, :te_totaleffect_ann_yr][yr], m_26_1[:EquityWeighting, :te_totaleffect_ann_yr][yr], m_45_2[:EquityWeighting, :te_totaleffect_ann_yr][yr], m_85_5[:EquityWeighting, :te_totaleffect_ann_yr][yr] ])
    end
    # # six scenarios:
    # df_temp = DataFrame(year = Int64[], sc25 = Float64[], scndc = Float64[], scbau = Float64[], sc261 = Float64[], sc452 = Float64[], sc855 = Float64[])
    # # df_emis = DataFrame(year = Int64[], sc25 = Float64[], scndc = Float64[], scbau = Float64[], sc261 = Float64[], sc452 = Float64[], sc855 = Float64[])
    # df_gdp = DataFrame(year = Int64[], sc25 = Float64[], scndc = Float64[], scbau = Float64[], sc261 = Float64[], sc452 = Float64[], sc855 = Float64[])
    # df_imp = DataFrame(year = Int64[], sc25 = Float64[], scndc = Float64[], scbau = Float64[], sc261 = Float64[], sc452 = Float64[], sc855 = Float64[])
    #
    # for year in 2015:2300
    #     yr = year - 2015 + 1
    #     # save file with annual temperatures
    #     push!(df_temp, [year, m_25[:ClimateTemperature, :rt_g_globaltemperature_ann][yr], m_ndc[:ClimateTemperature, :rt_g_globaltemperature_ann][yr], m_bau[:ClimateTemperature, :rt_g_globaltemperature_ann][yr], m_26_1[:ClimateTemperature, :rt_g_globaltemperature_ann][yr], m_45_2[:ClimateTemperature, :rt_g_globaltemperature_ann][yr], m_85_5[:ClimateTemperature, :rt_g_globaltemperature_ann][yr] ])
    #     # # save file with annual emissions
    #     # push!(df_emis, [year, m_25[:EquityWeighting, :cons_percap_consumption_ann[yr]], m_ndc[:EquityWeighting, :cons_percap_consumption_ann[yr]], m_bau[:EquityWeighting, :cons_percap_consumption_ann[yr]], m_26_1[:EquityWeighting, :cons_percap_consumption_ann[yr]], m_45_2[:EquityWeighting, :cons_percap_consumption_ann[yr]], m_85_5[:EquityWeighting, :cons_percap_consumption_ann[yr]] ])
    #     # save file with annual GDP
    #     push!(df_gdp, [year, m_25[:EquityWeighting, :cons_percap_consumption_ann][yr], m_ndc[:EquityWeighting, :cons_percap_consumption_ann][yr], m_bau[:EquityWeighting, :cons_percap_consumption_ann][yr], m_26_1[:EquityWeighting, :cons_percap_consumption_ann][yr], m_45_2[:EquityWeighting, :cons_percap_consumption_ann][yr], m_85_5[:EquityWeighting, :cons_percap_consumption_ann][yr] ])
    #     # save file with annual total impacts
    #     push!(df_imp, [year, m_25[:EquityWeighting, :te_totaleffect_ann_yr][yr], m_ndc[:EquityWeighting, :te_totaleffect_ann_yr][yr], m_bau[:EquityWeighting, :te_totaleffect_ann_yr][yr], m_26_1[:EquityWeighting, :te_totaleffect_ann_yr][yr], m_45_2[:EquityWeighting, :te_totaleffect_ann_yr][yr], m_85_5[:EquityWeighting, :te_totaleffect_ann_yr][yr] ])
    # end


    CSV.write(string(dir_output, "df_temp.csv"), df_temp)
    # CSV.write(string(dir_output, "df_emis.csv"), df_emis)
    CSV.write(string(dir_output, "df_gdp.csv"), df_gdp)
    CSV.write(string(dir_output, "df_imp.csv"), df_imp)
end
# scenario_pathways()


###################
# 2)
###################
# plot (deterministic with standard deviations per var_multiplier) with dependence on random.seed +  (before fixing in compute_scc)
###################
# data done? => yes, for 1000 runs x points on 0 to 3 var_multiplier, with mean variability parameters for the mean of the full record. http://localhost:8888/notebooks/Documents/GitHub/PAGEoutput/Plots%20for%20PAGE%20analysis.ipynb#for-1000-Random-Seeds
###################
# ---------- see older plots, not going to reproduce: data already gone ---------



###################
# 3)
###################
#  plot (deterministic with standard deviations per var_multiplier) with dependence on random.seed +  (after fixing in compute_scc)
###################
# data done? => yes. for 100 x 31 (on 0 to 3 var_multiplier)
# plot done? => yes. NB. LOOKS AWFUL? Something wrong? CHECK later.
###################
# explore the sensitivity of random.seed by doing several runs. deterministic --- only for PAGE-VAR, to illustrate the point, but also only one affected by it in deterministic runs
function var_sensitivity_randomseed_deterministic_combo(numSeedRuns::Int64 = 100, numVarSteps::Int64 = 31, scenario::String = "NDCs")
    global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/RandomSeedSensitivity_Determinstic_Combo/page-var-fixseed/"
    df_varmultiplier = DataFrame(RandomSeed = Float64[], mean_SCC = Float64[], sd_SCC = Float64[])
    # GOAL: create what is in var_sensitivity_deterministic but then with means and error bars
    global use_annual = true
    global use_interannvar = true
    global globallyset_use_interannvar = true
    include("getpagefunction.jl")
    include("utils/mctools.jl")

    for i = collect(range(0, stop = 3, length = numVarSteps))
        global v_multiplier = i
        println("var multiplier = ", v_multiplier)
        scc_array = zeros(numSeedRuns)

        for ii = 1:numSeedRuns
            # println("random seed = ", ii)

            Random.seed!(rand(1:1000000000000));
            include("getpagefunction.jl")
            include("utils/mctools.jl")

            m = getpage(scenario)
            run(m)
            scc_varmultiplier = compute_scc(m, year=2020)

            scc_array[ii] = scc_varmultiplier

            if isequal(mod(ii,(numSeedRuns/10)), 0)
                progress = ii/numSeedRuns * 100.
                println(string(progress, "%"))
            end
        end
        push!(df_varmultiplier, [i, mean(scc_array), std(scc_array)])
    end
    showall(df_varmultiplier)
    CSV.write(string(dir_output, "df_varmultiplier_manyruns.csv"), df_varmultiplier, delim = ',')
end
# var_sensitivity_randomseed_deterministic_combo(1000, 6)

###################
# 4)
###################
#    a) MC-violin of *SCC* PAGE-ANN v PAGE var with no variation in MC
#    b) MC-violin of *SCC* PAGE-ANN v PAGE var with only variation in MC
#    c) MC-violin of *SCC* PAGE-ANN v PAGE var with full variation in MC
###################
# data done? => running for 1 000. now.
# plot done? => script basically done.
###################
# do stochastic runs for PAGE-ICE, PAGE-ANN, and PAGE-VAR and output various variables for analysis (using DataFrame)
function scc_stochastic_ICEANNVAR_fullMCoptions(numMCruns::Int64 = 10000, scenario::String = "NDCs",
                                        onlyvar::Bool=false, novar::Bool=false, fullvar::Bool=false,
                                        onlyscc::Bool=false, onlyMC::Bool=false)
    global use_only_varMC = onlyvar
    global use_no_varMC = novar
    global use_fullvarMC = fullvar
    randseed = rand(1:1000000000000)


    ### PAGE-ICE ###
    if use_only_varMC
        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/ICEANNVARmcAugust_onlyvarMC/page-ice/"
    elseif use_no_varMC
        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/ICEANNVARmcAugust_novarMC/page-ice/"
    elseif use_fullvarMC
        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/ICEANNVARmcAugust_fullMC/page-ice/"
        println("PAGE-ICE: fullvar /n")
        global use_annual = false
        global use_interannvar = false
        include("getpagefunction.jl")
        include("utils/mctools.jl")
        include("mcs.jl")
        Random.seed!(randseed);
        get_scc_mcs(numMCruns, 2020, dir_output, scenario)
    else
        println("no Monte Carlo option provided")
    end
    # global use_annual = false
    # global use_interannvar = false
    # include("getpagefunction.jl")
    # include("utils/mctools.jl")
    # include("mcs.jl")
    # Random.seed!(randseed);
    # if onlyscc
    #     get_scc_mcs(numMCruns, 2020, dir_output, scenario)
    # elseif onlyMC
    #     do_monte_carlo_runs(numMCruns, dir_output, scenario)
    # else
    #     get_scc_mcs(numMCruns, 2020, dir_output, scenario)
    #     do_monte_carlo_runs(numMCruns, dir_output, scenario)
    # end

    ### PAGE-ANN ###
    if use_only_varMC
        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/ICEANNVARmcAugust_onlyvarMC/page-ann/"
    elseif use_no_varMC
        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/ICEANNVARmcAugust_novarMC/page-ann/"
    elseif use_fullvarMC
        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/ICEANNVARmcAugust_fullMC/page-ann/"
        println("PAGE-ANN: fullvar /n")
        global use_annual = true
        global use_interannvar = false
        include("getpagefunction.jl")
        include("utils/mctools.jl")
        include("mcs.jl")
        Random.seed!(randseed);
        get_scc_mcs(numMCruns, 2020, dir_output, scenario)
    else
        println("no Monte Carlo option provided")
    end
    # global use_annual = true
    # global use_interannvar = false
    # include("getpagefunction.jl")
    # include("utils/mctools.jl")
    # include("mcs.jl")
    # Random.seed!(randseed);
    # if onlyscc
    #     get_scc_mcs(numMCruns, 2020, dir_output, scenario)
    # elseif onlyMC
    #     do_monte_carlo_runs(numMCruns, dir_output, scenario)
    # else
    #     get_scc_mcs(numMCruns, 2020, dir_output, scenario)
    #     do_monte_carlo_runs(numMCruns, dir_output, scenario)
    # end


    ### PAGE-VAR ###
    if use_only_varMC
        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/ICEANNVARmcAugust_onlyvarMC/page-var/"
    elseif use_no_varMC
        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/ICEANNVARmcAugust_novarMC/page-var/"
        println("PAGE-VAR: novar /n")
        global use_annual = true
        global use_interannvar = true
        include("getpagefunction.jl")
        include("utils/mctools.jl")
        include("mcs.jl")
        Random.seed!(randseed);
        get_scc_mcs(numMCruns, 2020, dir_output, scenario)
    elseif use_fullvarMC
        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/ICEANNVARmcAugust_fullMC/page-var/"
        println("PAGE-VAR: fullvar /n")
        global use_annual = true
        global use_interannvar = true
        include("getpagefunction.jl")
        include("utils/mctools.jl")
        include("mcs.jl")
        Random.seed!(randseed);
        get_scc_mcs(numMCruns, 2020, dir_output, scenario)
    else
        println("no Monte Carlo option provided")
    end
    # global use_annual = true
    # global use_interannvar = true
    # include("getpagefunction.jl")
    # include("utils/mctools.jl")
    # include("mcs.jl")
    # Random.seed!(randseed);
    # if onlyscc
    #     get_scc_mcs(numMCruns, 2020, dir_output, scenario)
    # elseif onlyMC
    #     do_monte_carlo_runs(numMCruns, dir_output, scenario)
    # else
    #     get_scc_mcs(numMCruns, 2020, dir_output, scenario)
    #     do_monte_carlo_runs(numMCruns, dir_output, scenario)
    # end
end
## compare ICE v ANN v VAR with 3 different selected sets of MC parameters:
## only var:
# scc_stochastic_ICEANNVAR_fullMCoptions(100000, "NDCs", true, false, false, true, false)
## no var, all other uncertainties:
scc_stochastic_ICEANNVAR_fullMCoptions(100000, "NDCs", false, true, false, true, false)
## full set of uncertainties:
scc_stochastic_ICEANNVAR_fullMCoptions(100000, "NDCs", false, false, true, true, false)


###################
# 5)
###################
# MC-violin of *SCC* fot PAGE-VAR for the 4 selected scenarios (no BAU and 8.5, which develop to surreal >6C )
###################
# data done? => Done for 20000 runs. Do for larger sizes later.
# plotting done? => yes. seaborn or matplotlib both okay. Perhaps find different way to show these extremes.
###################
# do Monte Carlo runs for multiple different socioeconomic cenarios
function do_var_scenario_MCs(numMCruns::Int64=100)
    randomdraw = rand(1:1000000000000)
    if use_only_varMC
        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/onlyvarMC/1_5C"
        global scenario = "1.5 degC Target"
        include("getpagefunction.jl")
        include("utils/mctools.jl")
        include("mcs.jl")
        Random.seed!(randomdraw);
        get_scc_mcs(numMCruns, 2020, dir_output, scenario)


        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/onlyvarMC/2_0C"
        global scenario = "2 degC Target"
        include("getpagefunction.jl")
        include("utils/mctools.jl")
        include("mcs.jl")
        Random.seed!(randomdraw);
        get_scc_mcs(numMCruns, 2020, dir_output, scenario)

        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/onlyvarMC/2_5C"
        global scenario = "2.5 degC Target"
        include("getpagefunction.jl")
        include("utils/mctools.jl")
        include("mcs.jl")
        Random.seed!(randomdraw);
        get_scc_mcs(numMCruns, 2020, dir_output, scenario)

        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/onlyvarMC/NDC"
        global scenario = "NDCs"
        include("getpagefunction.jl")
        include("utils/mctools.jl")
        include("mcs.jl")
        Random.seed!(randomdraw);
        get_scc_mcs(numMCruns, 2020, dir_output, scenario)

        ## ELIMINATED BECAUSE OF TEMPERATURE EXTRAPOLATION
        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/onlyvarMC/BAU"
        global scenario = "BAU"
        include("getpagefunction.jl")
        include("utils/mctools.jl")
        include("mcs.jl")
        Random.seed!(randomdraw);
        get_scc_mcs(numMCruns, 2020, dir_output, scenario)

        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/onlyvarMC/RCP2_6_SSP1"
        global scenario = "RCP2.6 & SSP1"
        include("getpagefunction.jl")
        include("utils/mctools.jl")
        include("mcs.jl")
        Random.seed!(randomdraw);
        get_scc_mcs(numMCruns, 2020, dir_output, scenario)

        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/onlyvarMC/RCP4_5_SSP2"
        global scenario = "RCP4.5 & SSP2"
        include("getpagefunction.jl")
        include("utils/mctools.jl")
        include("mcs.jl")
        Random.seed!(randomdraw);
        get_scc_mcs(numMCruns, 2020, dir_output, scenario)

        ## ELIMINATED BECAUSE OF TEMPERATURE EXTRAPOLATION
        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/onlyvarMC/RCP8_5_SSP5"
        global scenario = "RCP8.5 & SSP5"
        include("getpagefunction.jl")
        include("utils/mctools.jl")
        include("mcs.jl")
        Random.seed!(randomdraw);
        get_scc_mcs(numMCruns, 2020, dir_output, scenario)
    else
        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/fullvarMC/1_5C"
        global scenario = "1.5 degC Target"
        include("getpagefunction.jl")
        include("utils/mctools.jl")
        include("mcs.jl")
        Random.seed!(randomdraw);
        get_scc_mcs(numMCruns, 2020, dir_output, scenario)


        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/fullvarMC/2_0C"
        global scenario = "2 degC Target"
        include("getpagefunction.jl")
        include("utils/mctools.jl")
        include("mcs.jl")
        Random.seed!(randomdraw);
        get_scc_mcs(numMCruns, 2020, dir_output, scenario)

        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/fullvarMC/2_5C"
        global scenario = "2.5 degC Target"
        include("getpagefunction.jl")
        include("utils/mctools.jl")
        include("mcs.jl")
        Random.seed!(randomdraw);
        get_scc_mcs(numMCruns, 2020, dir_output, scenario)

        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/fullvarMC/NDC"
        global scenario = "NDCs"
        include("getpagefunction.jl")
        include("utils/mctools.jl")
        include("mcs.jl")
        Random.seed!(randomdraw);
        get_scc_mcs(numMCruns, 2020, dir_output, scenario)

        ## ELIMINATED BECAUSE OF TEMPERATURE EXTRAPOLATION
        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/fullvarMC/BAU"
        global scenario = "BAU"
        include("getpagefunction.jl")
        include("utils/mctools.jl")
        include("mcs.jl")
        Random.seed!(randomdraw);
        get_scc_mcs(numMCruns, 2020, dir_output, scenario)

        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/fullvarMC/RCP2_6_SSP1"
        global scenario = "RCP2.6 & SSP1"
        include("getpagefunction.jl")
        include("utils/mctools.jl")
        include("mcs.jl")
        Random.seed!(randomdraw);
        get_scc_mcs(numMCruns, 2020, dir_output, scenario)

        println("Let's fix RCP4.5")
        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/fullvarMC/RCP4_5_SSP2"
        global scenario = "RCP4.5 & SSP2"
        include("getpagefunction.jl")
        include("utils/mctools.jl")
        include("mcs.jl")
        Random.seed!(randomdraw);
        get_scc_mcs(numMCruns, 2020, dir_output, scenario)

        ## ELIMINATED BECAUSE OF TEMPERATURE EXTRAPOLATION
        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/fullvarMC/RCP8_5_SSP5"
        global scenario = "RCP8.5 & SSP5"
        include("getpagefunction.jl")
        include("utils/mctools.jl")
        include("mcs.jl")
        Random.seed!(randomdraw);
        get_scc_mcs(numMCruns, 2020, dir_output, scenario)
    end
end
# # produce 8 scenarios for PAGE-VAR, with good robustness, for variability only and full MC.
# global use_only_varMC = true
# do_var_scenario_MCs(100000)
# global use_only_varMC = false
# do_var_scenario_MCs(100000)

# Do 5) but then not for PAGE-VAR (which is already running), but for PAGE-ICE and PAGE-ANN, with lower robustness [10,000 runs], full MC
function do_var_scenario_MCs_ICE_ANN(numMCruns::Int64=100)
    randomdraw = rand(1:1000000000000)

    # # ICE
    # global use_annual = false
    # global use_interannvar = false
    #
    #     global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/ICE/1_5C"
    #     global scenario = "1.5 degC Target"
    #     include("getpagefunction.jl")
    #     include("utils/mctools.jl")
    #     include("mcs.jl")
    #     Random.seed!(randomdraw);
    #     get_scc_mcs(numMCruns, 2020, dir_output, scenario)
    #
    #
    #     global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/ICE/2_0C"
    #     global scenario = "2 degC Target"
    #     include("getpagefunction.jl")
    #     include("utils/mctools.jl")
    #     include("mcs.jl")
    #     Random.seed!(randomdraw);
    #     get_scc_mcs(numMCruns, 2020, dir_output, scenario)
    #
    #     global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/ICE/2_5C"
    #     global scenario = "2.5 degC Target"
    #     include("getpagefunction.jl")
    #     include("utils/mctools.jl")
    #     include("mcs.jl")
    #     Random.seed!(randomdraw);
    #     get_scc_mcs(numMCruns, 2020, dir_output, scenario)
    #
    #     global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/ICE/NDC"
    #     global scenario = "NDCs"
    #     include("getpagefunction.jl")
    #     include("utils/mctools.jl")
    #     include("mcs.jl")
    #     Random.seed!(randomdraw);
    #     get_scc_mcs(numMCruns, 2020, dir_output, scenario)
    #
    #     ## ELIMINATED BECAUSE OF TEMPERATURE EXTRAPOLATION
    #     global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/ICE/BAU"
    #     global scenario = "BAU"
    #     include("getpagefunction.jl")
    #     include("utils/mctools.jl")
    #     include("mcs.jl")
    #     Random.seed!(randomdraw);
    #     get_scc_mcs(numMCruns, 2020, dir_output, scenario)
    #
    #     global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/ICE/RCP2_6_SSP1"
    #     global scenario = "RCP2.6 & SSP1"
    #     include("getpagefunction.jl")
    #     include("utils/mctools.jl")
    #     include("mcs.jl")
    #     Random.seed!(randomdraw);
    #     get_scc_mcs(numMCruns, 2020, dir_output, scenario)
    #
    #     global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/ICE/RCP4_5_SSP2"
    #     global scenario = "RCP4.5 & SSP2"
    #     include("getpagefunction.jl")
    #     include("utils/mctools.jl")
    #     include("mcs.jl")
    #     Random.seed!(randomdraw);
    #     get_scc_mcs(numMCruns, 2020, dir_output, scenario)
    #
    #     ## ELIMINATED BECAUSE OF TEMPERATURE EXTRAPOLATION
    #     global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/ICE/RCP8_5_SSP5"
    #     global scenario = "RCP8.5 & SSP5"
    #     include("getpagefunction.jl")
    #     include("utils/mctools.jl")
    #     include("mcs.jl")
    #     Random.seed!(randomdraw);
    #     get_scc_mcs(numMCruns, 2020, dir_output, scenario)

    # ANN
    global use_annual = false
    global use_interannvar = true

        # global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/ANN/1_5C"
        # global scenario = "1.5 degC Target"
        # include("getpagefunction.jl")
        # include("utils/mctools.jl")
        # include("mcs.jl")
        # Random.seed!(randomdraw);
        # get_scc_mcs(numMCruns, 2020, dir_output, scenario)


        # global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/ANN_100k/2_0C"
        # global scenario = "2 degC Target"
        # include("getpagefunction.jl")
        # include("utils/mctools.jl")
        # include("mcs.jl")
        # Random.seed!(randomdraw);
        # get_scc_mcs(numMCruns, 2020, dir_output, scenario)

        # global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/ANN/2_5C"
        # global scenario = "2.5 degC Target"
        # include("getpagefunction.jl")
        # include("utils/mctools.jl")
        # include("mcs.jl")
        # Random.seed!(randomdraw);
        # get_scc_mcs(numMCruns, 2020, dir_output, scenario)

        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/ANN_100k/NDC"
        global scenario = "NDCs"
        include("getpagefunction.jl")
        include("utils/mctools.jl")
        include("mcs.jl")
        Random.seed!(randomdraw);
        get_scc_mcs(numMCruns, 2020, dir_output, scenario)

        # ## ELIMINATED BECAUSE OF TEMPERATURE EXTRAPOLATION
        # global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/ANN/BAU"
        # global scenario = "BAU"
        # include("getpagefunction.jl")
        # include("utils/mctools.jl")
        # include("mcs.jl")
        # Random.seed!(randomdraw);
        # get_scc_mcs(numMCruns, 2020, dir_output, scenario)
        #
        # global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/ANN/RCP2_6_SSP1"
        # global scenario = "RCP2.6 & SSP1"
        # include("getpagefunction.jl")
        # include("utils/mctools.jl")
        # include("mcs.jl")
        # Random.seed!(randomdraw);
        # get_scc_mcs(numMCruns, 2020, dir_output, scenario)

        global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/ANN_100k/RCP4_5_SSP2"
        global scenario = "RCP4.5 & SSP2"
        include("getpagefunction.jl")
        include("utils/mctools.jl")
        include("mcs.jl")
        Random.seed!(randomdraw);
        get_scc_mcs(numMCruns, 2020, dir_output, scenario)

        # ## ELIMINATED BECAUSE OF TEMPERATURE EXTRAPOLATION
        # global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/finalscc/ANN/RCP8_5_SSP5"
        # global scenario = "RCP8.5 & SSP5"
        # include("getpagefunction.jl")
        # include("utils/mctools.jl")
        # include("mcs.jl")
        # Random.seed!(randomdraw);
        # get_scc_mcs(numMCruns, 2020, dir_output, scenario)
end
    # ICE and ANN
# do_var_scenario_MCs_ICE_ANN(100000)

###################
# 6)
###################
# a full MC run in which multiple things are saved.
# i) with full variation:
#    a) MC-violin of discontinuity trigger day (for NDCs for PAGE-ICE, PAGE-ANN, and PAGE-VAR)
#    b) MC-violin of MarketDamagesBurke costs (consumption) (for NDCs for PAGE-ICE, PAGE-ANN, and PAGE-VAR)
#    c) MC-violin of discontinuity costs (consumption) (for NDCs for PAGE-ICE, PAGE-ANN, and PAGE-VAR)
###################
# data done? => yes. for 10000 runs.
# plotting done? => mwah: yes but not fancy yet.
###################
# NB. ALTERNATIVE, UNFINISHED/NOT-CHECKED version
# do Monte Carlo runs for PAGE-ICE, PAGE-ANN, and PAGE-VAR, saving loads of variables in the process for plotting.
# function do_variability_MCs(numMCruns::Int64 = 2000, scenario::String = "NDCs", calc_scc::Bool=true)
#
#     include("getpagefunction.jl")
#     include("utils/mctools.jl")
#     include("mcs.jl")
#     include("compute_scc.jl")
#     randomdraw = rand(1:1000000000000)
#
#
#     global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEICE"
#     global use_annual = false
#     global use_interannvar = false
#
#     Random.seed!(randomdraw);
#     do_monte_carlo_runs(numMCruns, dir_output)
#     global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEICE/scc"
#     if calc_scc
#         get_scc_mcs(numMCruns, 2020, dir_output)
#     end
#
#
#     include("getpagefunction.jl")
#     include("utils/mctools.jl")
#     include("mcs.jl")
#     include("compute_scc.jl")
#
#     global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEANN"
#     global use_annual = true
#     global use_interannvar = false
#
#     Random.seed!(randomdraw);
#     do_monte_carlo_runs(numMCruns, dir_output)
#     global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEANN/scc"
#     if calc_scc
#         get_scc_mcs(numMCruns, 2020, dir_output)
#     end
#
#
#     include("getpagefunction.jl")
#     include("utils/mctools.jl")
#     include("mcs.jl")
#     include("compute_scc.jl")
#
#     global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR"
#     global use_annual = true
#     global use_interannvar = true
#
#     Random.seed!(randomdraw);
#     do_monte_carlo_runs(numMCruns, dir_output)
#     global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/mcPAGEVAR/scc"
#     if calc_scc
#         get_scc_mcs(numMCruns, 2020, dir_output)
#     end
#
# end
# do_variability_MCs(100)
###################
## just 6):
# ## only var:
# scc_stochastic_ICEANNVAR_fullMCoptions(100, "NDCs", true, false, false, false, true)
# ## no var, all other uncertainties:
# scc_stochastic_ICEANNVAR_fullMCoptions(100, "NDCs", false, true, false, false, true)
# ## full set of uncertainties:
# scc_stochastic_ICEANNVAR_fullMCoptions(100, "NDCs", false, false, true, false, true)
# ## NB BOTH 4) & 6):
# ## only var:
# scc_stochastic_ICEANNVAR_fullMCoptions(10000, "NDCs", true, false, false, false, false)
# ## no var, all other uncertainties:
# scc_stochastic_ICEANNVAR_fullMCoptions(10000, "NDCs", false, true, false, false, false)
# ## full set of uncertainties:
# scc_stochastic_ICEANNVAR_fullMCoptions(10000, "NDCs", false, false, true, false, false)


###################
# 7)
###################
# timeseries changes in damages for (PAGE-VAR minus PAGE-ANN) per region
###################
# done? => no.
###################



###################
# 8)
###################
# a plot like 3) but then with just dependence on the var_multiplier; SET random.seed similar for every run (=deterministic???).
###################
# done? => no.
###################
function var_sensitivity_deterministic_seedtests_3(numSteps::Int64 = 16, numRuns::Int64 = 10, scenario::String = "NDCs")
    global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/VarSensitivityTests/deterministic/"
    df_varmultiplier = DataFrame(Multiplier = Float64[], SCC_2020 = Float64[], NonMarketCost = Float64[], MarketBurkeCost = Float64[], DiscontCost = Float64[])

    global use_annual = true
    global use_interannvar = true
    global globallyset_use_interannvar = true

    scc_array = zeros(numSteps, numRuns, 2)

    k=0
    for i = collect(range(0, stop = 3, length = numSteps))
        global v_multiplier = i
        println("var multiplier = ", v_multiplier)
        j=0
        k = k+1
        for ii = collect(range(0, stop = numRuns-1, length = numRuns))
            j = j+1
            include("getpagefunction.jl")
            m_varmultiplier = getpage(scenario)
            global randomdraw = rand(1:1000000000000)
            Random.seed!(randomdraw);
            run(m_varmultiplier)
            scc_varmultiplier = compute_scc(m_varmultiplier, year=2020)

            # do monte carlo runs for every iteration here, to get an idea of the range, rather than just one draw with an arbitrary randseed.
            scc_array[k,j,1] = scc_varmultiplier

        end
    end
    writedlm(string(dir_output, "df_varmultiplier_seedtests_sameseedeverywhere.csv"), scc_array, ',')
end
function var_sensitivity_deterministic_seedtests_2(numSteps::Int64 = 16, numRuns::Int64 = 10, scenario::String = "NDCs")
    global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/VarSensitivityTests/deterministic/"
    df_varmultiplier = DataFrame(Multiplier = Float64[], SCC_2020 = Float64[], NonMarketCost = Float64[], MarketBurkeCost = Float64[], DiscontCost = Float64[])

    global use_annual = true
    global use_interannvar = true
    global globallyset_use_interannvar = true

    scc_array = zeros(numSteps, numRuns, 2)

    k=0
    for i = collect(range(0, stop = 3, length = numSteps))
        global v_multiplier = i
        println("var multiplier = ", v_multiplier)
        j=0
        k = k+1
        for ii = collect(range(0, stop = numRuns-1, length = numRuns))
            j = j+1
            include("getpagefunction.jl")
            m_varmultiplier = getpage(scenario)

            run(m_varmultiplier)
            scc_varmultiplier = compute_scc(m_varmultiplier, year=2020)

            # do monte carlo runs for every iteration here, to get an idea of the range, rather than just one draw with an arbitrary randseed.
            scc_array[k,j,1] = scc_varmultiplier

        end
    end
    writedlm(string(dir_output, "df_varmultiplier_seedtests_sameseedonlymcs.csv"), scc_array, ',')
end
function var_sensitivity_deterministic_seedtests_0(numSteps::Int64 = 16, numRuns::Int64 = 10, scenario::String = "NDCs")
    global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/VarSensitivityTests/deterministic/"
    df_varmultiplier = DataFrame(Multiplier = Float64[], SCC_2020 = Float64[], NonMarketCost = Float64[], MarketBurkeCost = Float64[], DiscontCost = Float64[])

    global use_annual = true
    global use_interannvar = true
    global globallyset_use_interannvar = true

    scc_array = zeros(numSteps, numRuns, 2)

    k=0
    for i = collect(range(0, stop = 3, length = numSteps))
        global v_multiplier = i
        println("var multiplier = ", v_multiplier)
        j=0
        k = k+1
        for ii = collect(range(0, stop = numRuns-1, length = numRuns))
            j = j+1
            include("getpagefunction.jl")
            m_varmultiplier = getpage(scenario)

            run(m_varmultiplier)
            scc_varmultiplier = compute_scc(m_varmultiplier, year=2020)

            # do monte carlo runs for every iteration here, to get an idea of the range, rather than just one draw with an arbitrary randseed.
            scc_array[k,j,1] = scc_varmultiplier

        end
    end
    writedlm(string(dir_output, "df_varmultiplier_seedtests_nosameseed.csv"), scc_array, ',')
end
# var_sensitivity_deterministic_seedtests_3()
# var_sensitivity_deterministic_seedtests_2()
# var_sensitivity_deterministic_seedtests_0()



###################
# 9)
###################
# look into non-market damages.
###################
# done? => no. ==> first go check the data I already have.
###################
