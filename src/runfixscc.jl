using Mimi
using Distributions
using DataFrames
using CSV
using Random

# standard output folder:
global dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/FixSCC"
global scenario = "NDCs"

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

# # Run.
# # with variability
# numMCruns = 20000
# include("getpagefunction.jl")
# include("utils/mctools.jl")
# include("mcs_scc_dist.jl")
#
# get_pre_scc_mcs(numMCruns, 2020, dir_output, scenario)


# Run.
# without variability
global use_interannvar = false
dir_output = "C:/Users/jarmo/Documents/GitHub/PAGEoutput/FixSCC/Novar"

numMCruns = 30000
include("getpagefunction.jl")
include("utils/mctools.jl")
include("mcs_scc_dist.jl")

get_pre_scc_mcs(numMCruns, 2020, dir_output, scenario)
