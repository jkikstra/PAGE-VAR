import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from numpy import genfromtxt
import seaborn as sns

####  ANN (FULL)  ####
######################
# TAKES A FEW HOURS! #
######################

mcruns = 100000
df_ANN_fullvar = pd.DataFrame()  # x scenarios, y mc runs per scenario
i = 0

scenarios = ["2_0C", "NDC", "RCP4_5_SSP2"]
scenarioslabels = ["2.0C", "NDC", "RCP4.5 & SSP2"]
for sc in scenarios:
    path_VAR_fullvar = "..\\PAGEoutput\\mcPAGEVAR\\finalscc\\ANN_100k\\%s\\scc.csv" % (sc)
    data_VAR_fullvar = genfromtxt(path_VAR_fullvar, delimiter=',')

    for ii in range(mcruns):
        df_ANN_fullvar = df_ANN_fullvar.append({'Scenario': sc, 'USD': data_VAR_fullvar[ii]}, ignore_index=True)

df_ANN_fullvar.to_csv('df_ANN_fullvar.csv', sep=',')

print("I'm done, check whether I have done my work well.")