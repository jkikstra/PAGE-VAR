import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from numpy import genfromtxt
import seaborn as sns


####   ONLY VAR   ####
######################
# TAKES A FEW HOURS! #
######################

mcruns = 100000
df_VAR_onlyvar = pd.DataFrame()  # x scenarios, y mc runs per scenario
i = 0

# scenarios = ["1_5C", "2_0C", "2_5C", "NDC", "BAU", "RCP2_6_SSP1", "RCP4_5_SSP2", "RCP8_5_SSP5"]
# scenarioslabels = ["1.5C", "2.0C", "2.5C", "NDC", "BAU", "RCP2.6 & \n SSP1", "RCP4.5 & \n SSP2", "RCP8.5 & \n SSP5"]
scenarios = ["2_0C", "NDC", "RCP4_5_SSP2"]
scenarioslabels = ["2.0C", "NDC", "RCP4.5 & SSP2"]
for sc in scenarios:
    path_VAR_onlyvar = "..\\PAGEoutput\\mcPAGEVAR\\finalscc\\onlyvarMC\\%s\\scc.csv" % (sc)
    data_VAR_onlyvar = genfromtxt(path_VAR_onlyvar, delimiter=',')

    for ii in range(mcruns):
        df_VAR_onlyvar = df_VAR_onlyvar.append({'Scenario': sc, 'USD': data_VAR_onlyvar[ii]}, ignore_index=True)

df_VAR_onlyvar.to_csv('df_VAR_onlyvar.csv', sep=',')

# plotPoints=2500
# sns.set_palette("muted")
#
#
# fig, ax = plt.subplots()
# fig.set_size_inches(14, 7)
# ax = sns.violinplot(x="Scenario", y="USD", data=df_VAR_onlyvar, gridsize=plotPoints, cut=0)
# ax.set_ylim(-100,2000)
# ax.set_xticks(range(len(scenarios)))
# ax.set_xticklabels(scenarioslabels)
#
# plt.show()