using Test
using Mimi

function page_model()
    Mimi.reset_compdefs()

    include("../src/utils/load_parameters.jl")
    include("../src/utils/mctools.jl")

    m = Model()

    set_dimension!(m, :time, [2020, 2030, 2040, 2050, 2075, 2100, 2150, 2200, 2250, 2300])
    set_dimension!(m, :region, ["EU", "USA", "OECD", "USSR", "China", "SEAsia", "Africa", "LatAmerica"])

    return m
end

function get_scenario(ii)
    Mimi.reset_compdefs()
    if ii == 1
        return "ndcs", "NDCs", true, false
    end
    if ii == 2
        return "2c-saf", "2 degC Target", true, true
    end
end

@testset "mimi-page.jl" begin

##
# Tests not suitable yet for annual version with its own parameters
##
# include("test_climatemodel.jl")
include("test_AbatementCosts.jl")
include("test_AdaptationCosts.jl")
include("test_CH4cycle.jl")
include("test_CH4emissions.jl")
include("test_CH4forcing.jl")
# include("test_ClimateTemperature.jl")
include("test_CO2cycle.jl")
include("test_CO2emissions.jl")
include("test_CO2forcing.jl")
# include("test_Discontinuity.jl")
# include("test_EquityWeighting.jl")
include("test_GDP.jl")
include("test_LGcycle.jl")
include("test_LGemissions.jl")
include("test_LGforcing.jl")
include("test_loadparameters.jl")
# include("test_mainmodel.jl")
# include("test_mainmodel_noperm.jl")
# ##include("test_MarketDamages.jl") # missing data
# include("test_MarketDamagesBurke.jl")
include("test_N2Ocycle.jl")
include("test_N2Oemissions.jl")
include("test_N2Oforcing.jl")
# include("test_NonMarketDamages.jl")
include("test_Population.jl")
include("test_SeaLevelRise.jl")
include("test_SLRDamages.jl")
include("test_SulphateForcing.jl")
include("test_TotalAbatementCosts.jl")
include("test_TotalAdaptationCosts.jl")
include("test_TotalForcing.jl")
include("test_Permafrost.jl")
# #include("test_mcs.jl") # missing data
# include("contrib/test_taxeffect.jl")

end
