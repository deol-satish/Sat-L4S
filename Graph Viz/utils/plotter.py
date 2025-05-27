import matplotlib.pyplot as plt
import os
import itertools
from utils.config import colors, markers, linestyles, DPI, SAVE_FORMATS, bar_width as global_bar_width , figsize as global_figsize, title_req

# Function to save the plot in different formats
def save_plot(fig, filename, folder):
    """Save a plot in multiple formats."""
    os.makedirs(folder, exist_ok=True)
    for fmt in SAVE_FORMATS:
        fig.savefig(f"{folder}/{filename}.{fmt}", dpi=DPI, bbox_inches='tight')

# For Train_Test

# Function to plot multiple datasets for comparison
def plot_comparison(dfs, x_column, y_column, labels, title, xlabel, ylabel, filename, folder):
    """Compare multiple datasets on a single plot."""
    fig, ax = plt.subplots(figsize=(6, 4), dpi=DPI)
    
    # Create iterators for cycling through colors, markers, and linestyles
    color_cycle = itertools.cycle(colors)
    marker_cycle = itertools.cycle(markers)
    linestyle_cycle = itertools.cycle(linestyles)
    
    for df, label in zip(dfs, labels):
        # Get the next available color, marker, and linestyle
        color = next(color_cycle)
        marker = next(marker_cycle)
        linestyle = next(linestyle_cycle)
        
        # Plot the line with chosen style and color
        ax.plot(
            df[x_column], df[y_column], 
            label=label, 
            color=color, 
            marker=marker, 
            linestyle=linestyle
        )

    if not title_req:
        title = ""

    # Set plot properties
    ax.set(title=title, xlabel=xlabel, ylabel=ylabel)
    ax.legend()
    ax.grid(True)
    
    # Tight layout and save the plot
    plt.tight_layout()
    print("folder save", folder)
    save_plot(fig, filename, folder)
    plt.close(fig)


# Function to plot metrics with color, marker, and linestyle cycling
def plot_metric(df, x_column, y_columns, labels, title, xlabel, ylabel, filename, folder):
    """Plot one or more metrics."""
    fig, ax = plt.subplots(figsize=(6, 4), dpi=DPI)
    
    # Create iterators for cycling through colors, markers, and linestyles
    color_cycle = itertools.cycle(colors)
    marker_cycle = itertools.cycle(markers)
    linestyle_cycle = itertools.cycle(linestyles)
    
    for y_column, label in zip(y_columns, labels):
        # Get the next available color, marker, and linestyle
        color = next(color_cycle)
        marker = next(marker_cycle)
        linestyle = next(linestyle_cycle)
        
        # Plot the line with chosen style and color
        ax.plot(
            df[x_column], df[y_column], 
            label=label, 
            color=color, 
            marker=marker, 
            linestyle=linestyle
        )
    if not title_req:
        title = ""
    # Set plot properties
    ax.set(title=title, xlabel=xlabel, ylabel=ylabel)
    ax.legend()
    ax.grid(True)
    
    # Tight layout and save the plot
    plt.tight_layout()
    save_plot(fig, filename, folder)
    plt.close(fig)

####################################################################################################################################
# For Evaluate

markers = ['*','p','o', 's', 'D', '^', 'v', 'p', '*', 'x']

def plot_line_comparison(df, columns, labels, xlabel, ylabel, title, filename, folder):
    """
    Plot a line comparison graph for multiple columns and save it.

    Parameters:
        df (pd.DataFrame): The DataFrame containing the data.
        columns (list): List of column names to plot.
        labels (list): List of labels for the legend corresponding to the columns.
        xlabel (str): Label for the X-axis.
        ylabel (str): Label for the Y-axis.
        title (str): Title of the plot.
        filename (str): Name of the file to save the plot.
        folder (str): Folder where the plot will be saved.
        formats (list): List of formats to save the plot.
        dpi (int): DPI resolution for the saved plot.
    """
    # colors = ['b', 'g', 'r', 'c', 'm', 'y', 'k', '#ff6347']  # Add more colors as needed
    # markers = ['o', 's', 'D', '^', 'v', 'p', '*', 'x']       # Add more markers as needed
    # linestyles = ['-', '--', '-.', ':']                      # Add more linestyles as needed

    fig, ax = plt.subplots(figsize=(4, 3))

    for i, (column, label) in enumerate(zip(columns, labels)):
        color = colors[i % len(colors)]
        marker = markers[i % len(markers)]
        linestyle = linestyles[i % len(linestyles)]
        ax.plot(df.index, df[column], color=color, marker=marker, linestyle=linestyle, label=label)

    if not title_req:
        title = ""
        
    ax.set(title=title, xlabel=xlabel, ylabel=ylabel)
    ax.legend()
    ax.grid(True)
    plt.tight_layout()
    save_plot(fig, filename, folder)
    plt.close(fig)

# def cdf_plot_line_comparison(df, index_rows, columns, labels, xlabel, ylabel, title, filename, folder):
#     """
#     Plot a line comparison graph for multiple columns and save it.

#     Parameters:
#         df (pd.DataFrame): The DataFrame containing the data.
#         columns (list): List of column names to plot.
#         labels (list): List of labels for the legend corresponding to the columns.
#         xlabel (str): Label for the X-axis.
#         ylabel (str): Label for the Y-axis.
#         title (str): Title of the plot.
#         filename (str): Name of the file to save the plot.
#         folder (str): Folder where the plot will be saved.
#         formats (list): List of formats to save the plot.
#         dpi (int): DPI resolution for the saved plot.
#     """
#     # colors = ['b', 'g', 'r', 'c', 'm', 'y', 'k', '#ff6347']  # Add more colors as needed
#     # markers = ['o', 's', 'D', '^', 'v', 'p', '*', 'x']       # Add more markers as needed
#     # linestyles = ['-', '--', '-.', ':']                      # Add more linestyles as needed

#     fig, ax = plt.subplots(figsize=(4, 3))

#     for i, (column, label) in enumerate(zip(columns, labels)):
#         color = colors[i % len(colors)]
#         marker = markers[i % len(markers)]
#         linestyle = linestyles[i % len(linestyles)]
#         ax.plot(df[index_rows], df[column], color=color, marker=marker, linestyle=linestyle, label=label)

#     if not title_req:
#         title = ""
        
#     ax.set(title=title, xlabel=xlabel, ylabel=ylabel)
#     ax.legend()
#     ax.grid(True)
#     plt.tight_layout()
#     save_plot(fig, filename, folder)
#     plt.close(fig)


# def plot_box_comparison(df, columns, labels, ylabel, title, filename, folder):
#     """
#     Plot a box comparison graph and save it, with custom colors for each box.

#     Parameters:
#         df (pd.DataFrame): The DataFrame containing the data.
#         columns (list): List of column names to include in the box plot.
#         labels (list): List of labels corresponding to the columns.
#         ylabel (str): Label for the Y-axis.
#         title (str): Title of the plot.
#         filename (str): Name of the file to save the plot.
#         folder (str): Folder where the plot will be saved.
#         formats (list): List of formats to save the plot.
#         dpi (int): DPI resolution for the saved plot.
#     """
#     # colors = ['b', 'g', 'r', 'c', 'm', 'y', 'k', '#ff6347']  # Add more colors as needed
    
#     fig, ax = plt.subplots(figsize=(4, 3))

#     # Boxplot
#     box = ax.boxplot(
#         [df[col] for col in columns], 
#         positions=range(1, len(columns) + 1), 
#         widths=0.3, 
#         patch_artist=True
#     )

#     # Apply colors to each box
#     for patch, color in zip(box['boxes'], colors[:len(columns)]):
#         patch.set_facecolor(color)
#         patch.set_edgecolor('black')
    
#     if not title_req:
#         title = ""

#     ax.set(
#         title=title, 
#         ylabel=ylabel, 
#         xticks=range(1, len(labels) + 1), 
#         xticklabels=labels
#     )
#     ax.grid(True)

#     plt.tight_layout()
#     save_plot(fig, filename, folder)
#     plt.close(fig)


# #######################################################################################################################

# # FOr More Graphs ipynb


# import numpy as np
# # Function to create bar plots
# def plot_bar_adjust(data, labels, ylabel, title, filename, folder, colors=colors, bar_width=global_bar_width, figsize=global_figsize):
#     """Create a bar plot for given labels and data."""
#     positions = np.arange(len(labels))

#     # Split labels into multiple lines if they are too long
#     max_label_length = 20  # Set a threshold for label length
#     wrapped_labels = []
#     for label in labels:
#         if len(label) > max_label_length:
#             # Wrap the label into multiple lines
#             words = label.split(' ')
#             wrapped_label = ''
#             current_line = ''
#             for word in words:
#                 # If the current line plus the new word exceeds max length, start a new line
#                 if len(current_line + word) > max_label_length:
#                     wrapped_label += current_line + '\n'
#                     current_line = word + ' '
#                 else:
#                     current_line += word + ' '
#             wrapped_label += current_line  # Add the remaining part of the label
#             wrapped_labels.append(wrapped_label.strip())
#         else:
#             wrapped_labels.append(label)

#     # Initialize the plot
#     fig, ax = plt.subplots(figsize=figsize, dpi=DPI)

#     # Create the bars
#     bars = ax.bar(positions, data, width=bar_width, color=colors or 'blue')

#     # Add value annotations
#     for bar in bars:
#         yval = bar.get_height()
#         ax.text(bar.get_x() + bar.get_width() / 2, yval + 0.005 * max(data), f"{yval:.4f}", 
#                 ha='center', va='bottom')
        
#     if not title_req:
#         title = ""

#     # Set labels and ticks
#     ax.set_ylabel(ylabel)
#     ax.set_xticks(positions)
#     ax.set_xticklabels(wrapped_labels, rotation=15)
#     ax.set_title(title)
#     ax.grid(True)

#     # Remove unnecessary spines
#     ax.spines['top'].set_visible(False)
#     ax.spines['right'].set_visible(False)

#     # Adjust layout and save plot
#     plt.tight_layout()
#     save_plot(fig, filename, folder)
#     plt.close(fig)

