import pandas as pd
import numpy as np
from sklearn import preprocessing
import random as rd
from sklearn.decomposition import PCA
import matplotlib.pyplot as plt
from paretoset import paretoset
import plotly.express as px
import pandas as pd
from adjustText import adjust_text
from matplotlib.patches import Patch
from matplotlib.lines import Line2D

def paretoOptimize(df, target_columns, target_objectives, iterations):
    target_df = df[target_columns]

    ct_nonoptimal = target_df.copy()
    df_nonoptimal = df.copy()

    for i in range(iterations):
        mask = paretoset(ct_nonoptimal, sense=target_objectives)
        masklist = mask.tolist()
        indices = [index for (index, item) in enumerate(masklist) if item == True]
        ct_nonoptimal.drop(ct_nonoptimal.index[indices], inplace=True)
        df_nonoptimal.drop(df_nonoptimal.index[indices], inplace=True)
        
    df_pareto= pd.concat([df, df_nonoptimal])
    df_pareto = df_pareto.drop_duplicates(keep=False)
       
    return df_pareto

def printPareto(df, df_pareto, target_columns, invert_axles):
    
    legend_elements = [Line2D([0], [0], marker='o', color='w', label='Non-optimal Sample',
                          markerfacecolor='b', markersize=8),
                   Line2D([0], [0], marker='o', color='w', label='Pareto Optimal Sample',
                          markerfacecolor='g', markersize=8)]
    
    plt.scatter(df[target_columns[0]], df[target_columns[1]], color='b')
    plt.scatter(df_pareto[target_columns[0]], df_pareto[target_columns[1]], color='g')
    plt.xlabel(target_columns[0])
    plt.ylabel(target_columns[1])
    if invert_axles:
        plt.gca().invert_yaxis()
        plt.gca().invert_xaxis()
    plt.legend(handles=legend_elements, loc='lower left')
    plt.show()
    
def printParameterScatter(df, parameter_names, color_variable, plot_title):
    df_scatter = df.copy()
    
    if color_variable != None:
       df_scatter[color_variable] = df_scatter[color_variable].astype(str)
       fig = px.scatter_matrix(df_scatter,
        dimensions=parameter_names,
        color=color_variable,
        title = plot_title)
    else:
        fig = px.scatter_matrix(df_scatter,
        dimensions=parameter_names,
        title = plot_title)
       
    fig.update_traces(diagonal_visible=False)

    fig.update_layout(
        autosize=False,
        width=800,
        height=800,
        margin=dict(
            l=50,
            r=50,
            b=100,
            t=100,
            pad=4
        )
    )  
    fig.show()
    
def scaleData(df):
    scaled_ndarr = preprocessing.scale(df)
    return pd.DataFrame(scaled_ndarr, columns = df.columns)

def createPCA(correlation_matrix):
    corr_arr = correlation_matrix.to_numpy()
    pca = PCA()
    pca.fit(corr_arr)
    pca_data = pca.transform(corr_arr)
    return pca, pca_data
    
def printScree(pca, plot_title):
    # Calculate percentage of variation that each PC (principal component) accounts for
    per_var = np.round(pca.explained_variance_ratio_*100, decimals=1)
    # Create labels
    labels = ['PC' + str(x) for x in range(1, len(per_var)+1)]
    # Plot scree plot
    plt.bar(x=range(1,len(per_var)+1), height=per_var, tick_label=labels)
    plt.ylabel('% of explained variance')
    plt.xlabel('Principal Component')
    plt.title(plot_title)
    plt.show()

def printPCA(pca, pca_data, correlation_matrix, plot_title, categories, colormap):
    per_var = np.round(pca.explained_variance_ratio_*100, decimals=1)
    # Create labels
    labels = ['PC' + str(x) for x in range(1, len(per_var)+1)]
    pca_df = pd.DataFrame(pca_data, index=correlation_matrix.columns, columns=labels)
    plt.scatter(pca_df.PC1, pca_df.PC2,  c=colormap[categories])
    plt.title(plot_title)
    plt.xlabel('PC1 - {0}%'.format(per_var[0]))
    plt.ylabel('PC2 - {0}%'.format(per_var[1]))
    texts = [plt.text(pca_df.PC1[i], pca_df.PC2[i], pca_df.PC1.keys()[i]) for i in range(len(pca_df.PC2))]
    adjust_text(texts)
    plt.show()