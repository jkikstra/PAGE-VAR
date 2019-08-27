import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from numpy import genfromtxt
import seaborn as sns

####   FULL VAR   ####
######################
# TAKES A FEW HOURS! #
######################

mcruns = 100000
df_VAR_fullvar = pd.DataFrame()  # x scenarios, y mc runs per scenario
i = 0
## NDCs and RCP45 not run correctly!
scenarios = ["2_0C", "NDC", "RCP4_5_SSP2"]
scenarioslabels = ["2.0C", "NDC", "RCP4.5 & SSP2"]
for sc in scenarios:
    path_VAR_fullvar = "..\\PAGEoutput\\mcPAGEVAR\\finalscc\\fullvarMC\\%s\\scc.csv" % (sc)
    data_VAR_fullvar = genfromtxt(path_VAR_fullvar, delimiter=',')

    for ii in range(mcruns):
        df_VAR_fullvar = df_VAR_fullvar.append({'Scenario': sc, 'USD': data_VAR_fullvar[ii]}, ignore_index=True)

df_VAR_fullvar.to_csv('df_VAR_fullvar.csv', sep=',')

print("I'm done, check whether I have done my work well.")

# plotPoints=2500
# sns.set_palette("muted")
#
#
# fig, ax = plt.subplots()
# fig.set_size_inches(14, 7)
# ax = sns.violinplot(x="Scenario", y="USD", data=df_VAR_fullvar, gridsize=plotPoints, cut=0)
# ax.set_ylim(-100,2000)
# ax.set_xticks(range(len(scenarios)))
# ax.set_xticklabels(scenarioslabels)
#
# plt.show()