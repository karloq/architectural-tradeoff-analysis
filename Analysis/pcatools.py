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
from sklearn.preprocessing import MinMaxScaler
import math
from sklearn.cluster import DBSCAN

def paretoOptimize(df, target_columns, target_objectives, top_optimized_percentage):
    target_df = df[target_columns]

    ct_nonoptimal = target_df.copy()
    df_nonoptimal = df.copy()

    removed_rows = 0
    full_length = len(target_df)

    if(top_optimized_percentage >= 1) :
        raise ValueError("Percentage must be smaller than 100% (1.0)")

    while full_length-removed_rows > (1-top_optimized_percentage)*full_length :
        mask = paretoset(ct_nonoptimal, sense=target_objectives)
        masklist = mask.tolist()
        indices = [index for (index, item) in enumerate(masklist) if item == True]
        removed_rows += len(indices)
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

def printParetoOpt(df, df_5,df_15,df_50,df_75, invert_axles, plot_title): 

    colors = ('firebrick','orangered', 'orange', 'gold','chartreuse')
    legend_elements = [Line2D([0], [0], marker='o', color='w', label='Top 5%',
                          markerfacecolor=colors[4], markersize=14),
                        Line2D([0], [0], marker='o', color='w', label='Top 15%',
                          markerfacecolor=colors[3], markersize=14),
                        Line2D([0], [0], marker='o', color='w', label='Top 50%',
                          markerfacecolor=colors[2], markersize=14),
                        Line2D([0], [0], marker='o', color='w', label='Top 75%',
                          markerfacecolor=colors[1], markersize=14),
                        Line2D([0], [0], marker='o', color='w', label='Non-optimal Samples',
                          markerfacecolor=colors[0], markersize=14)]
    
    plt.scatter(df.Latency, df.Cost, color=colors[0])
    plt.scatter(df_75.Latency, df_75.Cost, color=colors[1])
    plt.scatter(df_50.Latency, df_50.Cost, color=colors[2])
    plt.scatter(df_15.Latency, df_15.Cost, color=colors[3])
    plt.scatter(df_5.Latency, df_5.Cost, color=colors[4])
    plt.ylabel("Cost")
    plt.xlabel("Latency")
    if plot_title != None :
        plt.title(plot_title)
    if invert_axles:
        plt.gca().invert_yaxis()
        plt.gca().invert_xaxis()
    plt.legend(handles=legend_elements, loc='upper right')
    plt.show()

    plt.scatter(df.Complexity, df.Cost, color=colors[0])
    plt.scatter(df_75.Complexity, df_75.Cost, color=colors[1])
    plt.scatter(df_50.Complexity, df_50.Cost, color=colors[2])
    plt.scatter(df_15.Complexity, df_15.Cost, color=colors[3])
    plt.scatter(df_5.Complexity, df_5.Cost, color=colors[4])
    plt.ylabel("Cost")
    plt.xlabel("Complexity")
    if plot_title != None :
        plt.title(plot_title)
    if invert_axles:
        plt.gca().invert_yaxis()
        plt.gca().invert_xaxis()
    plt.legend(handles=legend_elements, loc='upper right')
    plt.show()

    plt.scatter(df["Load Sensitivity"], df.Cost, color=colors[0])
    plt.scatter(df_75["Load Sensitivity"], df_75.Cost, color=colors[1])
    plt.scatter(df_50["Load Sensitivity"], df_50.Cost, color=colors[2])
    plt.scatter(df_15["Load Sensitivity"], df_15.Cost, color=colors[3])
    plt.scatter(df_5["Load Sensitivity"], df_5.Cost, color=colors[4])
    plt.ylabel("Cost")
    plt.xlabel("Load Sensitivity")
    if plot_title != None :
        plt.title(plot_title)
    if invert_axles:
        plt.gca().invert_yaxis()
        plt.gca().invert_xaxis()
    plt.legend(handles=legend_elements, loc='upper right')
    plt.show()

def scatterPrint(df, x, y, x_uplim, x_lowlim, y_uplim, y_lowlim, invert_axles):
    if x_lowlim != None:
        df = df.loc[df[x] > x_lowlim]
    if x_uplim != None:
        df = df.loc[df[x] < x_uplim]
    if y_lowlim != None:
        df = df.loc[df[y] > y_lowlim]
    if y_uplim != None:
        df = df.loc[df[y] < y_uplim]
    plt.scatter(df[x], df[y], color='b')
    plt.xlabel(x)
    plt.ylabel(y)
    if invert_axles:
        plt.gca().invert_yaxis()
        plt.gca().invert_xaxis()
    plt.show()

def topoScatterPrint(df, x, y, invert_axles):

    df.reindex(df.index)
    topologies = df['Topology'].unique().tolist()

    # Define a colormap that maps each column to a color
    colormap = plt.cm.get_cmap('gist_rainbow', len(topologies))

    # Create the main scatterplot and set the colors
    fig, ax = plt.subplots()
    scatter = ax.scatter(df[x], df[y], c=df['Topology'], cmap=colormap)

    legend_elements = []

    for i in range(len(topologies)):
        legend_elements.append(Line2D([0], [0], marker='o', color='w', label=str(topologies[i]), markerfacecolor=colormap(i), markersize=10))

    ax.legend(handles=legend_elements)

    plt.xlabel(x)
    plt.ylabel(y)
    plt.legend(handles=legend_elements, loc='upper right')
    if invert_axles:
        plt.gca().invert_yaxis()
        plt.gca().invert_xaxis()
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

    per_var = per_var[0:5]
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
    
    # fit and transform the dataframe
    scaler = MinMaxScaler(feature_range=(-1, 1))
    df_scaled = pd.DataFrame(scaler.fit_transform(pca_df), columns=pca_df.columns)
    df_scaled.index = pca_df.index
    
    circle1 = plt.Circle((0, 0), 1, color='none', ec='black', alpha=1)
    plt.gca().add_artist(circle1)

    circle2 = plt.Circle((0, 0), 0.7, color='none', ec='black', alpha=1)
    plt.gca().add_artist(circle2)
    
    plt.gca().set_aspect('equal')
    
    plt.scatter(df_scaled.PC1, df_scaled.PC2,  c=colormap[categories])
    plt.title(plot_title)
    plt.xlabel('PC1 - {0}%'.format(per_var[0]))
    plt.ylabel('PC2 - {0}%'.format(per_var[1]))
    plt.xlim(-1.1, 1.1)
    plt.ylim(-1.1, 1.1)
    texts = [plt.text(df_scaled.PC1[i], df_scaled.PC2[i], df_scaled.PC1.keys()[i]) for i in range(len(df_scaled.PC2))]
    adjust_text(texts)
    plt.show()
    
def printRadarPlots(df_mean, topo_names, fill_color,rows,columns, lbl_correction, figsize, plot_title) :
    angles = [0.0, 1.5707963267948966, 3.141592653589793, 4.71238898038469, 0.0]
    # Create a figure with a 2x2 grid of subplots
    fig, axs = plt.subplots(rows, columns, subplot_kw=dict(projection='polar'), figsize=figsize)

    if plot_title != None :
        fig.suptitle(plot_title, fontsize=16)

    if rows > 1 :
        idx = 0
        for x in range(rows) :
            for y in range(columns):
                if (x*columns + y) >= len(df_mean) :
                    break
                mean_list = df_mean.iloc[idx].to_list()
                mean_list.append(mean_list[0])
                axs[x,y].plot(angles, mean_list, linewidth=2, linestyle='solid', c=fill_color[idx])
                axs[x,y].fill(angles, mean_list, c=fill_color[idx], alpha=0.4)
                axs[x,y].set_thetagrids(np.degrees(angles[:-1]), df_mean.columns)
                axs[x,y].set_title(topo_names[idx], fontsize=12)
                axs[x,y].grid(True)
                axs[x,y].set_yticklabels([])
                idx += 1
    elif len(df_mean) == 1 :
            mean_list = df_mean.iloc[0].to_list()
            mean_list.append(mean_list[0])
            axs.plot(angles, mean_list, linewidth=2, linestyle='solid', c=fill_color[0])
            axs.fill(angles, mean_list, c=fill_color[0], alpha=0.4)
            axs.set_thetagrids(np.degrees(angles[:-1]), df_mean.columns)
            axs.set_title(topo_names[idx], fontsize=12)
            axs.grid(True)
            axs.set_yticklabels([])
    else:
        idx = 0
        for y in range(columns):
            mean_list = df_mean.iloc[idx].to_list()
            mean_list.append(mean_list[0])
            axs[y].plot(angles, mean_list, linewidth=2, linestyle='solid', c=fill_color[idx])
            axs[y].fill(angles, mean_list, c=fill_color[idx], alpha=0.4)
            axs[y].set_thetagrids(np.degrees(angles[:-1]), df_mean.columns)
            axs[y].set_title(topo_names[idx], fontsize=12)
            axs[y].grid(True)
            axs[y].set_yticklabels([])
            idx += 1

    # Hide the empty subplots
    if len(df_mean) < columns*rows :
        for i in range(rows):
            for j in range(columns):
                if i == rows-1 and j >= (columns)-((columns*rows)-len(df_mean)):
                    axs[i, j].axis('off')

    if len(df_mean) > 1 :
        for i, ax in enumerate(axs.flat):
            idx = 0
            for label in ax.xaxis.get_ticklabels():
                if idx == 0 :
                    label.set_position((label.get_position()[0], label.get_position()[1]+lbl_correction[0]))
                if idx == 1 :
                    label.set_position((label.get_position()[0], label.get_position()[1]+lbl_correction[1]))
                if idx == 2 :
                    label.set_position((label.get_position()[0], label.get_position()[1]+lbl_correction[2]))
                if idx == 3 :
                    label.set_position((label.get_position()[0], label.get_position()[1]+lbl_correction[3]))

                idx += 1
        # Set the ylim for all subplots to be the same
        for ax in axs.flat:
            ax.set_ylim(0, math.ceil(df_mean.max().max()))
    else :
        idx = 0
        for label in axs.xaxis.get_ticklabels():
                if idx == 0 :
                    label.set_position((label.get_position()[0], label.get_position()[1]+lbl_correction[0]))
                if idx == 1 :
                    label.set_position((label.get_position()[0], label.get_position()[1]+lbl_correction[1]))
                if idx == 2 :
                    label.set_position((label.get_position()[0], label.get_position()[1]+lbl_correction[2]))
                if idx == 3 :
                    label.set_position((label.get_position()[0], label.get_position()[1]+lbl_correction[3]))

                idx += 1


    fig.subplots_adjust(left=0.1, bottom=0.1, right=0.9, top=0.9, wspace=1.2, hspace=0.2)

    # Show the plot
    plt.show()

def filterData(df,topologies, latency_uplims,latency_lowlims,cost_uplims,cost_lowlims,complexity_uplims, complexity_lowlims, scalability_uplims, scalability_lowlims) :
    for i, topo in enumerate(topologies):
        if latency_uplims[i] is None:
            latency_uplims[i] = df[(df.Topology == topo)].Latency.max()
        if latency_lowlims[i] is None:
            latency_lowlims[i] = df[(df.Topology == topo)].Latency.min()
        if cost_uplims[i] is None:
            cost_uplims[i] = df[(df.Topology == topo)].Cost.max()
        if cost_lowlims[i] is None:
            cost_lowlims[i] = df[(df.Topology == topo)].Cost.min()
        if complexity_uplims[i] is None:
            complexity_uplims[i] = df[(df.Topology == topo)].Complexity.max()
        if complexity_lowlims[i] is None:
            complexity_lowlims[i] = df[(df.Topology == topo)].Complexity.min()
        if scalability_uplims[i] is None:
            scalability_uplims[i] = df[(df.Topology == topo)]["Load Sensitivity"].max()
        if scalability_lowlims[i] is None:
            scalability_lowlims[i] = df[(df.Topology == topo)]["Load Sensitivity"].min()

    df_filtered = pd.DataFrame()

    for i, topo in enumerate(topologies) :
        df1 = df[(df.Topology == topo) &
            (df.Latency <= latency_uplims[i]) & (df.Latency >= latency_lowlims[i]) &
            (df.Cost <= cost_uplims[i]) & (df.Cost >= cost_lowlims[i]) & 
            (df.Complexity <= complexity_uplims[i])& (df.Complexity >= complexity_lowlims[i]) &
            (df["Load Sensitivity"] <= scalability_uplims[i])& (df["Load Sensitivity"] >= scalability_lowlims[i])]

        df_filtered = pd.concat([df_filtered, df1])

    removed_rows = len(df) - len(df_filtered)
    print("Filtered out {} rows of data".format(removed_rows))

    return df_filtered

def printTopologyClusters(data, colors) :
    legend_elements = [Line2D([0], [0], marker='o', color='w', label='Simple_1',
                            markerfacecolor=colors[0], markersize=14),
                            Line2D([0], [0], marker='o', color='w', label='Simple_2',
                            markerfacecolor=colors[1], markersize=14),
                            Line2D([0], [0], marker='o', color='w', label='Simple_3',
                            markerfacecolor=colors[2], markersize=14),
                            Line2D([0], [0], marker='o', color='w', label='Simple_4',
                            markerfacecolor=colors[3], markersize=14),
                            Line2D([0], [0], marker='o', color='w', label='Stream_1',
                            markerfacecolor=colors[4], markersize=14),
                            Line2D([0], [0], marker='o', color='w', label='Stream_2',
                            markerfacecolor=colors[5], markersize=14),
                            Line2D([0], [0], marker='o', color='w', label='Sophisticated_1',
                            markerfacecolor=colors[6], markersize=14)]
        

    fig, axs = plt.subplots(2, 5, figsize=(4, 6), sharey=True)

    idx = 0
    for i, ax in enumerate(axs.flat):
        col = data.columns[i]
        counts = data[col]
        samples = counts.index

        bottom = None
        for j in range(len(counts)):
            if counts[j] > 0:
                ax.bar(col, counts[j], bottom=bottom, label=samples[j],color=colors[j])
                if bottom is None:
                    bottom = counts[j]
                else:
                    bottom += counts[j]
        idx += 1
        ax.xaxis.set_visible(False)

        # display y-axis
        ax.yaxis.set_visible(False)
        ax.set_title(col)

    fig.legend(handles=legend_elements, loc='upper right', bbox_to_anchor=(1.35, 0.88), borderaxespad=0)
    plt.text(1.6,1.4,"La  =  Latency", ha = 'left',va='center', transform = plt.gca().transAxes)
    plt.text(1.6,1.3,"Co  =  Cost", ha = 'left',va='center', transform = plt.gca().transAxes)
    plt.text(1.6,1.2,"Cx  =  Complexity", ha = 'left',va='center', transform = plt.gca().transAxes)
    plt.text(1.6,1.1,"LS  =  Load Sensitivity", ha = 'left',va='center', transform = plt.gca().transAxes)
    # show plot
    plt.show()

def specialPCA(pca, pca_data, corr_topo) :
    per_var = np.round(pca.explained_variance_ratio_*100, decimals=1)
    # Create labels
    labels = ['PC' + str(x) for x in range(1, len(per_var)+1)]
    pca_df = pd.DataFrame(pca_data, index=corr_topo.columns, columns=labels)
        
    # fit and transform the dataframe
    scaler = MinMaxScaler(feature_range=(-1, 1))
    df_scaled = pd.DataFrame(scaler.fit_transform(pca_df), columns=pca_df.columns)
    df_scaled.index = pca_df.index

    # generate some example data
    x_filtered = df_scaled.loc[['Latency','Cost', 'Complexity', 'Load Sensitivity']].PC1
    y_filtered = df_scaled.loc[['Latency','Cost', 'Complexity', 'Load Sensitivity']].PC2
    x = df_scaled.drop(['Latency','Cost', 'Complexity', 'Load Sensitivity']).PC1
    y = df_scaled.drop(['Latency','Cost', 'Complexity', 'Load Sensitivity']).PC2
    labels = x.keys()


    # plot the data as a scatter plot
    fig, ax = plt.subplots(figsize=(8, 8))
    #ax.scatter(x_filtered, y_filtered, c='green', s = 75 )

    circle1 = plt.Circle((0, 0), 1, color='none', ec='black', alpha=0.4)
    plt.gca().add_artist(circle1)

    circle2 = plt.Circle((0, 0), 0.7, color='none', ec='black', alpha=0.4)
    plt.gca().add_artist(circle2)

    # use dbscan to cluster the data
    clustering = DBSCAN(eps=0.1, min_samples=1).fit(np.column_stack((x, y)))
    # loop over each cluster and plot it as a single point with a label
    for label in np.unique(clustering.labels_):
        if label == -1:
            # plot noise points as red crosses
            ax.scatter(x[clustering.labels_ == label], y[clustering.labels_ == label], c='r', marker='x')
        else:
            # plot cluster points as a single blue point
            x_mean = np.mean(x[clustering.labels_ == label])
            y_mean = np.mean(y[clustering.labels_ == label])
            ax.scatter(x_mean, y_mean, c='royalblue', s=75)
            
            # add a label next to the point listing the samples in the cluster
            cluster_samples = labels[clustering.labels_ == label]
            cluster_label = "\n".join(cluster_samples)

            if(len(cluster_samples) == 1) :
                ax.text(x_mean+0.058, y_mean, cluster_label, fontsize=10, verticalalignment='center')
            elif(len(cluster_samples) == 7) :
                ax.annotate(cluster_label, (x_mean, y_mean), xytext=(-56, -110), textcoords='offset points',
                        arrowprops=dict(facecolor='black', arrowstyle='->'))
            elif(len(cluster_samples) == 3) :
                ax.annotate(cluster_label, (x_mean, y_mean), xytext=(-44, -50), textcoords='offset points',
                        arrowprops=dict(facecolor='black', arrowstyle='->'))
            elif 'fargate_vcpus' in cluster_samples :
                ax.annotate(cluster_label, (x_mean, y_mean), xytext=(-54, -40), textcoords='offset points',
                        arrowprops=dict(facecolor='black', arrowstyle='->'))
            elif 'kinesis_efos' in cluster_samples :
                ax.annotate(cluster_label, (x_mean, y_mean), xytext=(-90, -30), textcoords='offset points',
                        arrowprops=dict(facecolor='black', arrowstyle='->'))
            elif 'kinesis_peak' in cluster_samples :
                ax.annotate(cluster_label, (x_mean, y_mean), xytext=(-40, -40), textcoords='offset points',
                        arrowprops=dict(facecolor='black', arrowstyle='->'))
            else :
                ax.text(x_mean+0.058, y_mean, cluster_label, fontsize=10, verticalalignment='center')
        
            #ax.text(x_mean+0.058, y_mean, cluster_label, fontsize=10, verticalalignment='center')
        

    clustering = DBSCAN(eps=0.1, min_samples=1).fit(np.column_stack((x_filtered, y_filtered)))
    labels = x_filtered.keys()

    for label in np.unique(clustering.labels_):
        if label == -1:
            # plot noise points as red crosses
            ax.scatter(x_filtered[clustering.labels_ == label], y_filtered[clustering.labels_ == label], c='r', marker='x')
        else:
            x_mean = np.mean(x_filtered[clustering.labels_ == label])
            y_mean = np.mean(y_filtered[clustering.labels_ == label])
            ax.scatter(x_mean-0.05, y_mean, c='green', s=75)
            
            # add a label next to the point listing the samples in the cluster
            cluster_samples = labels[clustering.labels_ == label]
            cluster_label = "\n".join(cluster_samples)
            ax.text(x_mean-0.1, y_mean, cluster_label, fontsize=10, verticalalignment='center', horizontalalignment='right')



    # set axis labels and show the plot
    ax.set_xlabel('PC1 - {0}%'.format(per_var[0]))
    ax.set_ylabel('PC2 - {0}%'.format(per_var[1]))
    ax.set_xlim([-1.45, 1.45])
    ax.set_ylim([-1.3, 1.3])
    ax.set_aspect('equal')
    plt.show()