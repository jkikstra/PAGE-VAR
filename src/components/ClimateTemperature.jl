function calc_temp(p, v, d, tt, annual_year)
    # for every year, do the same calculations, but then with the new annual_year variables
    yr = annual_year - 2015 + 1 # + 1 because of 1-based indexing in Julia

    # NEW -- interpolation between the years, forward-stepping, up to gettime(tt)
    ## interpolation here is linear for 2015-2020
    if is_first(tt)
        frac = annual_year - 2015
        fraction_timestep = frac/((gettime(tt))-2015)

        v.pt_g_preliminarygmst_ann[yr] = (v.pt_g_preliminarygmst[tt])*(fraction_timestep) + p.rt_g0_baseglobaltemp*(1-fraction_timestep)  # difference_to_next_tt * ratio_to_there
    else
        frac = annual_year - gettime(tt-1)
        fraction_timestep = frac/((gettime(tt))-(gettime(tt-1))) # check if +1 might also need to feature here.

        v.pt_g_preliminarygmst_ann[yr] = (v.pt_g_preliminarygmst[tt] )*(fraction_timestep) + v.pt_g_preliminarygmst[tt-1]*(1-fraction_timestep) # difference_to_next_tt * ratio_to_there
    end
    # Without surface albedo, just equal
    v.rt_g_globaltemperature_ann[yr] = v.pt_g_preliminarygmst_ann[yr] # this feeds into Discontinuity.jl, gets variability through pt_g_preliminarygmst -> pt_g_preliminarygmst_ann

    # Adding adjustment, from Hope (2009)
    for r in d.region
        if use_interannvar
            r_variationtemp = rand(Normal(0.0, max(0., p.rvarsd_regionalvariabilitystandarddeviation[r]))) # NEW - with variation
            if globallyset_use_interannvar
                r_variationtemp = r_variationtemp * v_multiplier # for quick & dirty analysis of variability sensitivity
            else
                r_variationtemp = r_variationtemp * p.var_multiplier # NEW - introduced for sensitivity analysis for variability
            end
        else
            r_variationtemp = 0 # NEW - no variation
        end
        v.rtl_realizedtemperature_ann[yr, r] = v.rt_g_globaltemperature_ann[yr] * p.ampf_amplification[r] + r_variationtemp # NEW - add interannual variability
    end

    # update global temperature with variability --- done after amplification factor leads to pre-variability regional temperatures such as to not "double-count/mulitply" the amplification factors/global variability
    # Normal(μ=0.0, σ=...); introduce a global interannual variability parameter (e.g. El-Nino years).
    if use_interannvar
        g_variationtemp = rand(Normal(0.0, max(0., p.gvarsd_globalvariabilitystandarddeviation))) # NEW - with variation
        if globallyset_use_interannvar
            g_variationtemp = g_variationtemp * v_multiplier  # for quick & dirty analysis of variability sensitivity
        else
            g_variationtemp = g_variationtemp * p.var_multiplier # NEW - introduced for sensitivity analysis for variability
        end
    else
        g_variationtemp = 0 # NEW - no variation
    end
    v.rt_g_globaltemperature_ann[yr] = v.pt_g_preliminarygmst_ann[yr] + g_variationtemp # NEW - add variability only to the annual version
    # this  above feeds into Discontinuity.jl, gets variability through pt_g_preliminarygmst -> pt_g_preliminarygmst_ann

    # Land average temperature
    v.rtl_g_landtemperature_ann[yr] = sum(v.rtl_realizedtemperature_ann[yr, :]' .* p.area') / sum(p.area)

    # Ocean average temperature
    v.rto_g_oceantemperature_ann[yr] = (p.area_e_eartharea * v.rt_g_globaltemperature_ann[yr] - sum(p.area) * v.rtl_g_landtemperature_ann[yr]) / (p.area_e_eartharea - sum(p.area))

end

@defcomp ClimateTemperature begin

    region = Index()
    year = Index() # NEW - for annual version

    gvarsd_globalvariabilitystandarddeviation = Parameter(unit = "unitless", default = set_gvarsd)
    rvarsd_regionalvariabilitystandarddeviation = Parameter(index=[region], unit = "unitless")
    var_multiplier = Parameter(unit = "unitless", default = 1)

    # Basic parameters
    area = Parameter(index=[region], unit="km2")
    y_year_ann =  Parameter(index=[year], unit="year") # NEW
    y_year_0 = Parameter(unit="year")
    y_year = Parameter(index=[time], unit="year")
    area_e_eartharea = Parameter(unit="km2", default=5.1e8)
    use_seaice::Bool = Parameter()

    # Initial temperature outputs
    rt_g0_baseglobaltemp = Parameter(unit="degreeC", default=0.9461666666666667) #needed for feedback in CO2 cycle component
    rtl_0_baselandtemp = Variable(index=[region], unit="degreeC")
    rtl_g0_baselandtemp = Variable(unit="degreeC") #needed for feedback in CH4 and N2O cycles

    # Rate of change of forcing
    fant_anthroforcing = Parameter(index=[time], unit="W/m2")
    ft_0_totalforcing0 = Parameter(unit="W/m2", default=3.202)
    fsd_g_0_directsulphate0 = Parameter(unit="W/m2", default=-0.46666666666666673)
    fsi_g_0_indirectsulphate0 = Parameter(unit="W/m2", default=-0.17529148701061475)

    # Climate sensitivity calculations
    tcr_transientresponse = Parameter(unit="degreeC", default=1.7666666666666668)
    frt_warminghalflife = Parameter(unit="year", default=28.333333333333332)

    ecs_climatesensitivity = Variable(unit="degreeC")

    # Unadjusted temperature calculations
    fslope_CO2forcingslope = Parameter(unit="W/m2", default=5.5)
    pt_g_preliminarygmst = Variable(index=[time], unit="degreeC")
    pt_g_preliminarygmst_ann = Variable(index=[year], unit="degreeC") # NEW - for annual version

    # Surface albedo parameters
    alb_t_switch = Parameter(default=10.0)
    alb_saf_quadr_mean_t2_coeff = Parameter(default=-0.001955963673212411)
    alb_saf_quadr_mean_t1_coeff = Parameter(default=-0.006407351323331157)
    alb_saf_quadr_mean_t0_coeff = Parameter(default=0.36372124028281877)
    alb_saf_quadr_std = Parameter(default=0.10908771841232413)
    alb_saf_lin_mean = Parameter(default=0.0636051293985324)
    alb_saf_lin_std = Parameter(default=0.02907749205894582)
    alb_emulator_rand = Parameter(default=0)

    # Surface albedo internal variables
    alb_fsaf_y0 = Variable(unit="W/m2")
    alb_saf_y0 = Variable(unit="W/m2/degC")
    alb_fsaf_ecs = Variable(unit="W/m2")
    alb_saf_ecs = Variable(unit="W/m2/degC")
    alb_fsaf_t_switch = Variable(unit="W/m2")

    # Global outputs
    rt_g_globaltemperature = Variable(index=[time], unit="degreeC")
    rto_g_oceantemperature = Variable(index=[time], unit="degreeC")
    rtl_g_landtemperature = Variable(index=[time], unit="degreeC")

    rt_g_globaltemperature_ann = Variable(index=[year], unit="degreeC") # NEW - for annual version
    rto_g_oceantemperature_ann = Variable(index=[year], unit="degreeC") # NEW - for annual version
    rtl_g_landtemperature_ann = Variable(index=[year], unit="degreeC") # NEW - for annual version

    # Regional outputs
    ampf_amplification = Parameter(index=[region])
    rtl_realizedtemperature = Variable(index=[time, region], unit="degreeC")
    rtl_realizedtemperature_ann = Variable(index=[year, region], unit="degreeC") # NEW - for annual version


    function init(p, v, d)

        for rr in d.region
            v.rtl_0_baselandtemp[rr] = p.rt_g0_baseglobaltemp * p.ampf_amplification[rr]
        end

        # Equation 21 from Hope (2006): initial global land temperature
        v.rtl_g0_baselandtemp = sum(v.rtl_0_baselandtemp .* p.area) / sum(p.area)

        # Inclusion of transient climate response from Hope (2009)
        v.ecs_climatesensitivity = p.tcr_transientresponse / (1. - (p.frt_warminghalflife / 70.) * (1. - exp(-70. / p.frt_warminghalflife)))

        ## Surface albedo internal variables
        v.alb_fsaf_y0 = ((p.alb_saf_quadr_mean_t2_coeff*(p.rt_g0_baseglobaltemp^3)/3 + p.alb_saf_quadr_mean_t1_coeff*(p.rt_g0_baseglobaltemp^2)/2 + p.alb_saf_quadr_mean_t0_coeff*p.rt_g0_baseglobaltemp) + (p.alb_saf_quadr_std*p.rt_g0_baseglobaltemp) * p.alb_emulator_rand)
        v.alb_saf_y0 = (p.alb_saf_quadr_mean_t2_coeff*(p.rt_g0_baseglobaltemp^2)/2 + p.alb_saf_quadr_mean_t1_coeff*p.rt_g0_baseglobaltemp + p.alb_saf_quadr_mean_t0_coeff) + p.alb_saf_quadr_std * p.alb_emulator_rand

        if v.ecs_climatesensitivity <= p.alb_t_switch
            v.alb_fsaf_ecs = (p.alb_saf_quadr_mean_t2_coeff*(v.ecs_climatesensitivity^3)/3 + p.alb_saf_quadr_mean_t1_coeff*(v.ecs_climatesensitivity^2)/2 + p.alb_saf_quadr_mean_t0_coeff*v.ecs_climatesensitivity) + (p.alb_saf_quadr_std*v.ecs_climatesensitivity) * p.alb_emulator_rand
        else
            v.alb_fsaf_ecs = (p.alb_saf_quadr_mean_t2_coeff*( p.alb_t_switch^3)/3 + p.alb_saf_quadr_mean_t1_coeff*( p.alb_t_switch^2)/2 + p.alb_saf_quadr_mean_t0_coeff*p.alb_t_switch + p.alb_saf_lin_mean*(v.ecs_climatesensitivity - p.alb_t_switch)) + (p.alb_saf_quadr_std*p.alb_t_switch + p.alb_saf_lin_std*(v.ecs_climatesensitivity - p.alb_t_switch)) * p.alb_emulator_rand
        end
        v.alb_saf_ecs = v.alb_fsaf_ecs / v.ecs_climatesensitivity
        v.alb_fsaf_t_switch = (p.alb_saf_quadr_mean_t2_coeff*(p.alb_t_switch^3)/3 + p.alb_saf_quadr_mean_t1_coeff*(p.alb_t_switch^2)/2 + p.alb_saf_quadr_mean_t0_coeff*p.alb_t_switch) + (p.alb_saf_quadr_std*p.alb_t_switch) * p.alb_emulator_rand
    end

    function run_timestep(p, v, d, tt)
        # Rate of change of grand total forcing
        if is_first(tt)
            fant0 = p.ft_0_totalforcing0 + p.fsd_g_0_directsulphate0 + p.fsi_g_0_indirectsulphate0
            rate_fant = 0 # inferred from spreadsheet
            deltat = p.y_year[tt] - p.y_year_0
        elseif is_timestep(tt, 2)
            fant0 = p.ft_0_totalforcing0 + p.fsd_g_0_directsulphate0 + p.fsi_g_0_indirectsulphate0
            rate_fant = (p.fant_anthroforcing[tt-1] - fant0) / (p.y_year[tt-1] - p.y_year_0)
            deltat = p.y_year[tt] - p.y_year[tt-1]
        else
            rate_fant = (p.fant_anthroforcing[tt-1] - p.fant_anthroforcing[tt-2]) / (p.y_year[tt-1] - p.y_year[tt-2])
            deltat = p.y_year[tt] - p.y_year[tt-1]
        end

        BB = v.ecs_climatesensitivity / (p.fslope_CO2forcingslope * log(2.0)) * rate_fant
        EXPT = exp(-deltat / p.frt_warminghalflife)

        if is_first(tt)
            fant0 = p.ft_0_totalforcing0 + p.fsd_g_0_directsulphate0 + p.fsi_g_0_indirectsulphate0
            AA = v.ecs_climatesensitivity / (p.fslope_CO2forcingslope * log(2.0)) * fant0
            v.pt_g_preliminarygmst[tt] = p.rt_g0_baseglobaltemp + (AA - p.rt_g0_baseglobaltemp) * (1 - EXPT) # Drop BB because 0
        else
            AA = v.ecs_climatesensitivity / (p.fslope_CO2forcingslope * log(2.0)) * p.fant_anthroforcing[tt-1]
            v.pt_g_preliminarygmst[tt] = v.pt_g_preliminarygmst[tt-1] + (AA - p.frt_warminghalflife*BB - v.pt_g_preliminarygmst[tt-1]) * (1 - EXPT) + deltat * BB
        end

        if !p.use_seaice
            # Without surface albedo, just equal
            v.rt_g_globaltemperature[tt] = v.pt_g_preliminarygmst[tt]
        else
            alb_saf_approx = (((p.alb_saf_quadr_mean_t2_coeff*(v.pt_g_preliminarygmst[tt]^3)/3 + p.alb_saf_quadr_mean_t1_coeff*(v.pt_g_preliminarygmst[tt]^2)/2 + p.alb_saf_quadr_mean_t0_coeff*v.pt_g_preliminarygmst[tt]) + (p.alb_saf_quadr_std*v.pt_g_preliminarygmst[tt]) * p.alb_emulator_rand) - v.alb_fsaf_y0) / (v.pt_g_preliminarygmst[tt] - p.rt_g0_baseglobaltemp)
            alb_saf_adjust = alb_saf_approx - v.alb_saf_ecs
            ecs_alb_adj = v.ecs_climatesensitivity / (1 - v.ecs_climatesensitivity * alb_saf_adjust / (log(2)*p.fslope_CO2forcingslope))
            frt_alb_adj = p.frt_warminghalflife / (1 - v.ecs_climatesensitivity * alb_saf_adjust / (log(2)*p.fslope_CO2forcingslope))
            if is_first(tt)
                alb_fsaf_adjust = ((p.alb_saf_quadr_mean_t2_coeff*(p.rt_g0_baseglobaltemp^3)/3 + p.alb_saf_quadr_mean_t1_coeff*(p.rt_g0_baseglobaltemp^2)/2 + p.alb_saf_quadr_mean_t0_coeff*p.rt_g0_baseglobaltemp) + (p.alb_saf_quadr_std*p.rt_g0_baseglobaltemp) * p.alb_emulator_rand) - alb_saf_approx*p.rt_g0_baseglobaltemp
                v.rt_g_globaltemperature[tt] = p.rt_g0_baseglobaltemp + (ecs_alb_adj * (fant0 + alb_fsaf_adjust) / (log(2) * p.fslope_CO2forcingslope) - p.rt_g0_baseglobaltemp) * (1 - exp(-deltat/frt_alb_adj))
            else
                if v.rt_g_globaltemperature[tt-1] <= p.alb_t_switch
                    alb_fsaf_adjust = ((p.alb_saf_quadr_mean_t2_coeff*(v.rt_g_globaltemperature[tt-1]^3)/3 + p.alb_saf_quadr_mean_t1_coeff*(v.rt_g_globaltemperature[tt-1]^2)/2 + p.alb_saf_quadr_mean_t0_coeff*v.rt_g_globaltemperature[tt-1]) + (p.alb_saf_quadr_std*v.rt_g_globaltemperature[tt-1]) * p.alb_emulator_rand) - alb_saf_approx * v.rt_g_globaltemperature[tt-1]
                else
                    alb_fasf_adjust = p.alb_fsaf_t_switch + p.alb_saf_lin_mean*(v.rt_g_globaltemperature[tt-1] - p.alb_t_switch) + (p.alb_saf_lin_std*(v.rt_g_globaltemperature[tt-1] - p.alb_t_switch)) * p.alb_emulator_rand - alb_saf_approx * v.rt_g_globaltemperature[tt-1]
                end
                v.rt_g_globaltemperature[tt] = v.rt_g_globaltemperature[tt-1] + (ecs_alb_adj * (p.fant_anthroforcing[tt-1] - rate_fant*frt_alb_adj + alb_fsaf_adjust) / (log(2)*p.fslope_CO2forcingslope) - v.rt_g_globaltemperature[tt-1]) * (1 - exp(-deltat/frt_alb_adj)) + ecs_alb_adj * (rate_fant*deltat) / (log(2)*p.fslope_CO2forcingslope)
            end
        end

        # Adding adjustment, from Hope (2009)
        for rr in d.region
            v.rtl_realizedtemperature[tt, rr] = v.rt_g_globaltemperature[tt] * p.ampf_amplification[rr]
        end

        # Land average temperature
        v.rtl_g_landtemperature[tt] = sum(v.rtl_realizedtemperature[tt, :]' .* p.area') / sum(p.area)

        # Ocean average temperature
        v.rto_g_oceantemperature[tt] = (p.area_e_eartharea * v.rt_g_globaltemperature[tt] - sum(p.area) * v.rtl_g_landtemperature[tt]) / (p.area_e_eartharea - sum(p.area))


        # annual interpolation of the timestep-calculated variables.
        if is_first(tt)
            for annual_year = 2015:gettime(tt) # because p["y_year_0"] does not exist (globally)
                calc_temp(p, v, d, tt, annual_year) # NEW -- introduce function for calulating temperature
            end
        else
            for annual_year = (gettime(tt-1)+1):gettime(tt)
                calc_temp(p, v, d, tt, annual_year) # NEW -- use  function for calulating temperature

                # # save results.
                # if annual_year == 2300
                #     if use_interannvar
                #         writedlm("RegionalTemperature.csv", v.rtl_realizedtemperature_ann, ',')
                #     else
                #         writedlm("RegionalTemperature_novar.csv", v.rtl_realizedtemperature_ann, ',')
                #     end
                # end
                # if annual_year == 2300
                #     println(v.rt_g_globaltemperature_ann[annual_year-2015])
                # end
            end
        end

    end
end

function addclimatetemperature(model::Model, use_seaice::Bool)
    climtemp = add_comp!(model, ClimateTemperature)

    climtemp[:use_seaice] = use_seaice

    return climtemp
end
