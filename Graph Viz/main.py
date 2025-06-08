# %%
import os
from utils.config import GRAPH_SAVE_FOLDER, DATA_FOLDER
from utils.plotter import plot_line_comparison


# %%
# import pandas as pd

# data_dir = os.path.join(DATA_FOLDER)
# extra_tag = f"Starlink_channel_specs_250MHz_10.5GHz"    
# tagged_folder = os.path.join(GRAPH_SAVE_FOLDER, extra_tag)

# # Ensure the tagged folder exists
# os.makedirs(tagged_folder, exist_ok=True)

# df = pd.read_csv('Satellite_Australia_Simulation_Log.csv')
# df = pd.read_csv('./250mhz_Data_10.5Ghz/Satellite_Australia_Simulation_Log.csv')

# %%
# import pandas as pd

# data_dir = os.path.join(DATA_FOLDER)
# extra_tag = f"Starlink_BGAN"    
# tagged_folder = os.path.join(GRAPH_SAVE_FOLDER, extra_tag)

# # Ensure the tagged folder exists
# os.makedirs(tagged_folder, exist_ok=True)

# df = pd.read_csv('Satellite_Australia_Simulation_Log.csv')
# # df = pd.read_csv('./250mhz_Data_10.5Ghz/Satellite_Australia_Simulation_Log.csv')

# %%
import pandas as pd

data_dir = os.path.join(DATA_FOLDER)
extra_tag = f"starlink_downlink"    
tagged_folder = os.path.join(GRAPH_SAVE_FOLDER, extra_tag)

# Ensure the tagged folder exists
os.makedirs(tagged_folder, exist_ok=True)

df = pd.read_csv('./data/Satellite_Australia_Simulation_Log_starlink_downlink.csv')

# %%
import pandas as pd

data_dir = os.path.join(DATA_FOLDER)
extra_tag = f"starlink_uplink"    
tagged_folder = os.path.join(GRAPH_SAVE_FOLDER, extra_tag)

# Ensure the tagged folder exists
os.makedirs(tagged_folder, exist_ok=True)

df = pd.read_csv('./data/Satellite_Australia_Simulation_Log_starlink_uplink.csv')

# %%
import pandas as pd
import re

# Step 1: Drop columns that are all zeros or all NaN
df = df.drop(columns=[col for col in df.columns if ((df[col] == 0) | (df[col].isna())).all()])

# Step 2: Get max satellite ID from column names
sat_ids = [int(match.group(1)) for col in df.columns if (match := re.match(r'LEO(\d+)_', col))]
max_sat_id = max(sat_ids) if sat_ids else -1

print("Max satellite ID found:", max_sat_id)

# Step 3: Track satellites with access
possible_sat_conn_ids = []

for i in range(max_sat_id + 1):
    sat_id = f'LEO{i}'

    # Check access columns
    sydney_access_col = f'{sat_id}_Sydney_Access'
    melbourne_access_col = f'{sat_id}_Melbourne_Access'

    # Check if access columns exist and have any True values
    # .fillna(False) ensures we treat NaN as False
    # .any() checks if there is at least one True value
    sydney_access_ok = sydney_access_col in df.columns and df[sydney_access_col].fillna(False).any()
    melbourne_access_ok = melbourne_access_col in df.columns and df[melbourne_access_col].fillna(False).any()

    if sydney_access_ok and melbourne_access_ok:
        possible_sat_conn_ids.append(sat_id)
    else:
        # Drop base satellite info if no access
        base_cols = [f'{sat_id}_Name', f'{sat_id}_Lat', f'{sat_id}_Lon', f'{sat_id}_Freq_Hz']
        existing_cols_to_drop = [col for col in base_cols if col in df.columns]
        df = df.drop(columns=existing_cols_to_drop)

print("Satellites with possible connection:", possible_sat_conn_ids)
print("length(Satellites with possible connection):", len(possible_sat_conn_ids))


# %%
# Collect all satellite-related columns NOT in possible_sat_conn_ids to drop
cols_to_drop = []

for col in df.columns:
    # Extract satellite id number from column name if it matches pattern
    match = re.match(r'(LEO\d+)_', col)
    if match:
        sat_id = match.group(1)
        # If satellite not in possible_sat_conn_ids, mark its columns for deletion
        if sat_id not in possible_sat_conn_ids:
            cols_to_drop.append(col)

# Drop those columns
df = df.drop(columns=cols_to_drop)

print("Remaining columns after cleanup:", df.columns.tolist())


# %%
import pandas as pd
import numpy as np

# Assuming your DataFrame is loaded into 'df'

# Identify unique satellite IDs
satellite_ids = sorted(list(set([col.split('_')[0] for col in df.columns if col.startswith('LEO') and '_' in col])))

results = []

# Iterate through each row (representing a time index)
for index, row in df.iterrows():
    best_sydney = {'SAT_ID': None, 'BEST_SNR': -np.inf, 'BEST_RSSI': -np.inf, 'BEST_Thrpt': -np.inf,
                   'BEST_BER_MQAM': np.inf, 'BEST_BER_QPSK': np.inf, 'BEST_Latency': np.inf}
    best_melbourne = {'SAT_ID': None, 'BEST_SNR': -np.inf, 'BEST_RSSI': -np.inf, 'BEST_Thrpt': -np.inf,
                     'BEST_BER_MQAM': np.inf, 'BEST_BER_QPSK': np.inf, 'BEST_Latency': np.inf}

    for sat_id in satellite_ids:
        # Sydney data
        sydney_snr = row.get(f'{sat_id}_Sydney_SNR_dB')
        sydney_rssi = row.get(f'{sat_id}_Sydney_RSSI_dBm')
        sydney_thrpt = row.get(f'{sat_id}_Sydney_Throughput')
        sydney_ber_mqam = row.get(f'{sat_id}_Sydney_BER_MQAM')
        sydney_ber_qpsk = row.get(f'{sat_id}_Sydney_BER_QPSK')
        sydney_latency = row.get(f'{sat_id}_Sydney_Latency')

        if pd.notna(sydney_snr) and sydney_snr > best_sydney['BEST_SNR']:
            best_sydney['SAT_ID'] = sat_id
            best_sydney['BEST_SNR'] = sydney_snr
            best_sydney['BEST_RSSI'] = sydney_rssi
            best_sydney['BEST_Thrpt'] = sydney_thrpt
            best_sydney['BEST_BER_MQAM'] = sydney_ber_mqam
            best_sydney['BEST_BER_QPSK'] = sydney_ber_qpsk
            best_sydney['BEST_Latency'] = sydney_latency
        elif pd.notna(sydney_snr) and sydney_snr == best_sydney['BEST_SNR']:
            # Handle ties - you might want a specific tie-breaking logic
            pass

        # Melbourne data
        melbourne_snr = row.get(f'{sat_id}_Melbourne_SNR_dB')
        melbourne_rssi = row.get(f'{sat_id}_Melbourne_RSSI_dBm')
        melbourne_thrpt = row.get(f'{sat_id}_Melbourne_Throughput')
        melbourne_ber_mqam = row.get(f'{sat_id}_Melbourne_BER_MQAM')
        melbourne_ber_qpsk = row.get(f'{sat_id}_Melbourne_BER_QPSK')
        melbourne_latency = row.get(f'{sat_id}_Melbourne_Latency')

        if pd.notna(melbourne_snr) and melbourne_snr > best_melbourne['BEST_SNR']:
            best_melbourne['SAT_ID'] = sat_id
            best_melbourne['BEST_SNR'] = melbourne_snr
            best_melbourne['BEST_RSSI'] = melbourne_rssi
            best_melbourne['BEST_Thrpt'] = melbourne_thrpt
            best_melbourne['BEST_BER_MQAM'] = melbourne_ber_mqam
            best_melbourne['BEST_BER_QPSK'] = melbourne_ber_qpsk
            best_melbourne['BEST_Latency'] = melbourne_latency
        elif pd.notna(melbourne_snr) and melbourne_snr == best_melbourne['BEST_SNR']:
            # Handle ties - you might want a specific tie-breaking logic
            pass

    results.append({
        'Time': row['Time'],
        'Sydney_Best_SAT_ID': best_sydney['SAT_ID'],
        'Sydney_BEST_SNR': best_sydney['BEST_SNR'],
        'Sydney_BEST_RSSI': best_sydney['BEST_RSSI'],
        'Sydney_BEST_Thrpt': best_sydney['BEST_Thrpt'] / (1024 * 1024),  # Convert to Mbps
        'Sydney_BEST_BER_MQAM': best_sydney['BEST_BER_MQAM'],
        'Sydney_BEST_BER_QPSK': best_sydney['BEST_BER_QPSK'],
        'Sydney_BEST_Latency': best_sydney['BEST_Latency'] * 1000,  # Convert to ms,
        'Melbourne_Best_SAT_ID': best_melbourne['SAT_ID'],
        'Melbourne_BEST_SNR': best_melbourne['BEST_SNR'],
        'Melbourne_BEST_RSSI': best_melbourne['BEST_RSSI'],
        'Melbourne_BEST_Thrpt': best_melbourne['BEST_Thrpt'] / (1024 * 1024),  # Convert to Mbps
        'Melbourne_BEST_BER_MQAM': best_melbourne['BEST_BER_MQAM'],
        'Melbourne_BEST_BER_QPSK': best_melbourne['BEST_BER_QPSK'],
        'Melbourne_BEST_Latency': best_melbourne['BEST_Latency'] * 1000,  # Convert to ms
    })

# Create the new DataFrame
best_sinr_df = pd.DataFrame(results)

print(best_sinr_df)

best_sinr_df.to_csv(f"{extra_tag}_Best_Satellite_Australia_Simulation_Log_cleaned.csv")

# %%
plot_line_comparison(
    best_sinr_df,
    columns=['Sydney_BEST_Thrpt', 'Melbourne_BEST_Thrpt'],
    labels=['Sydney_BEST_Thrpt', 'Melbourne_BEST_Thrpt'],
    xlabel='Time (m) ',
    ylabel='Latency (ms)',
    title=f'Latency for Starlink Satellites',
    filename=f"{extra_tag}_{sat_id}_Melbourne_latency",
    folder=f"./graphs/{extra_tag}_best"  # Adjust the folder path as needed
)

# %%
best_sinr_df['Sydney_BEST_Thrpt'].describe()

# %%
best_sinr_df['Melbourne_BEST_Thrpt'].describe()

# %%
best_sinr_df['Sydney_BEST_BER_QPSK'].describe()

# %%
best_sinr_df['Melbourne_BEST_BER_QPSK'].describe()

# %%
for col in best_sinr_df.columns:
    print("-" * 20)
    print(f"{col}: {best_sinr_df[col].describe()}")
    print("-" * 20)

# %%
best_sinr_df

# %%


# %%
for sat_id in possible_sat_conn_ids:
    print(f"Processing satellite ID: {sat_id}")
    sat_col = [s for s in df.columns.to_list() if sat_id in s]
    print("sat_col:", sat_col)
    print(df[sat_col])
    break


# %%
all_rssi_cols = [col for col in df.columns if re.search(r'_RSSI_dBm$', col)]
all_snr_cols = [col for col in df.columns if re.search(r'_SNR_dB$', col)]
all_thrpt_cols = [col for col in df.columns if re.search(r'_Throughput$', col)]
all_BER_QPSK_cols = [col for col in df.columns if re.search(r'_BER_QPSK$', col)]
all_BER_MQAM_cols = [col for col in df.columns if re.search(r'_BER_MQAM$', col)]
all_Latency_cols = [col for col in df.columns if re.search(r'Latency$', col)]
all_TimeOut_cols = [col for col in df.columns if re.search(r'TimeOut$', col)]

# %%
# df[all_thrpt_cols] = df[all_thrpt_cols] / (1024 * 1024) # Convert to Mbps
# df[all_Latency_cols] = df[all_Latency_cols] * 1000 # Convert to Mbps

# %%
# Loop over each satellite in possible_sat_conn_ids
for sat_id in possible_sat_conn_ids:
    # Build Latency column names
    sydney_Latency_col = f'{sat_id}_Sydney_Latency'
    melbourne_Latency_col = f'{sat_id}_Melbourne_Latency'

    # Check which Latency columns exist
    sydney_exists = sydney_Latency_col in df.columns
    melbourne_exists = melbourne_Latency_col in df.columns

    # Skip if neither exists
    if not sydney_exists and not melbourne_exists:
        continue
    temp_tagged_folder = os.path.join(tagged_folder, "Latency")
    # Plot 
    if sydney_exists:
        plot_line_comparison(
            df,
            columns=[sydney_Latency_col],
            labels=[sydney_Latency_col],
            xlabel='Time (m)',
            ylabel='Latency (ms)',
            title=f'Latency for Starlink Satellites',
            filename=f"{extra_tag}_{sat_id}_Sydney_latency",
            folder=temp_tagged_folder
        )
    if melbourne_exists:
        plot_line_comparison(
            df,
            columns=[melbourne_Latency_col],
            labels=[melbourne_Latency_col],
            xlabel='Time (m) ',
            ylabel='Latency (ms)',
            title=f'Latency for Starlink Satellites',
            filename=f"{extra_tag}_{sat_id}_Melbourne_latency",
            folder=temp_tagged_folder
        )

# %%
# Loop over each satellite in possible_sat_conn_ids
for sat_id in possible_sat_conn_ids:
    # Build Thrpt column names
    sydney_Thrpt_col = f'{sat_id}_Sydney_Throughput'
    melbourne_Thrpt_col = f'{sat_id}_Melbourne_Throughput'

    # Check which Thrpt columns exist
    sydney_exists = sydney_Thrpt_col in df.columns
    melbourne_exists = melbourne_Thrpt_col in df.columns

    # Skip if neither exists
    if not sydney_exists and not melbourne_exists:
        continue
    temp_tagged_folder = os.path.join(tagged_folder, "thrpt")
    # Plot 
    if sydney_exists:
        plot_line_comparison(
            df,
            columns=[sydney_Thrpt_col],
            labels=[sydney_Thrpt_col],
            xlabel='Time (m)',
            ylabel='Thrpt (Mbps)',
            title=f'Thrpt for Starlink Satellites',
            filename=f"{extra_tag}_{sat_id}_Sydney_thrpt",
            folder=temp_tagged_folder
        )
    if melbourne_exists:
        plot_line_comparison(
            df,
            columns=[melbourne_Thrpt_col],
            labels=[melbourne_Thrpt_col],
            xlabel='Time (m) ',
            ylabel='Thrpt (Mbps)',
            title=f'Thrpt for Starlink Satellites',
            filename=f"{extra_tag}_{sat_id}_Melbourne_thrpt",
            folder=temp_tagged_folder
        )

# %%
# Loop over each satellite in possible_sat_conn_ids
for sat_id in possible_sat_conn_ids:
    # Build SNR column names
    sydney_SNR_col = f'{sat_id}_Sydney_SNR_dB'
    melbourne_SNR_col = f'{sat_id}_Melbourne_SNR_dB'

    # Check which SNR columns exist
    sydney_exists = sydney_SNR_col in df.columns
    melbourne_exists = melbourne_SNR_col in df.columns

    # Skip if neither exists
    if not sydney_exists and not melbourne_exists:
        continue
    # Plot 
    temp_tagged_folder = os.path.join(tagged_folder, "SNR")
    if sydney_exists:
        plot_line_comparison(
            df,
            columns=[sydney_SNR_col],
            labels=[sydney_SNR_col],
            xlabel='Time (m)',
            ylabel='SNR (dBm)',
            title=f'SNR for Starlink Satellites',
            filename=f"{extra_tag}_{sat_id}_Sydney_SNR",
            folder=temp_tagged_folder
        )
    if melbourne_exists:
        plot_line_comparison(
            df,
            columns=[melbourne_SNR_col],
            labels=[melbourne_SNR_col],
            xlabel='Time (m) ',
            ylabel='SNR (dBm)',
            title=f'SNR for Starlink Satellites',
            filename=f"{extra_tag}_{sat_id}_Melbourne_SNR",
            folder=temp_tagged_folder
        )

# %%
# Loop over each satellite in possible_sat_conn_ids
for sat_id in possible_sat_conn_ids:
    # Build BER_QPSK column names
    sydney_BER_QPSK_col = f'{sat_id}_Sydney_BER_QPSK'
    melbourne_BER_QPSK_col = f'{sat_id}_Melbourne_BER_QPSK'

    # Check which BER_QPSK columns exist
    sydney_exists = sydney_BER_QPSK_col in df.columns
    melbourne_exists = melbourne_BER_QPSK_col in df.columns

    # Skip if neither exists
    if not sydney_exists and not melbourne_exists:
        continue
    # Plot 
    temp_tagged_folder = os.path.join(tagged_folder, "BER_QPSK")
    if sydney_exists:
        plot_line_comparison(
            df,
            columns=[sydney_BER_QPSK_col],
            labels=[sydney_BER_QPSK_col],
            xlabel='Time (m)',
            ylabel='BER_QPSK',
            title=f'BER_QPSK for Starlink Satellites',
            filename=f"{extra_tag}_{sat_id}_Sydney_BER_QPSK",
            folder=temp_tagged_folder
        )
    if melbourne_exists:
        plot_line_comparison(
            df,
            columns=[melbourne_BER_QPSK_col],
            labels=[melbourne_BER_QPSK_col],
            xlabel='Time (m) ',
            ylabel='BER_QPSK',
            title=f'BER_QPSK for Starlink Satellites',
            filename=f"{extra_tag}_{sat_id}_Melbourne_BER_QPSK",
            folder=temp_tagged_folder
        )

# %%
# Loop over each satellite in possible_sat_conn_ids
for sat_id in possible_sat_conn_ids:
    # Build BER_MQAM column names
    sydney_BER_MQAM_col = f'{sat_id}_Sydney_BER_MQAM'
    melbourne_BER_MQAM_col = f'{sat_id}_Melbourne_BER_MQAM'

    # Check which BER_MQAM columns exist
    sydney_exists = sydney_BER_MQAM_col in df.columns
    melbourne_exists = melbourne_BER_MQAM_col in df.columns

    # Skip if neither exists
    if not sydney_exists and not melbourne_exists:
        continue
    # Plot 
    temp_tagged_folder = os.path.join(tagged_folder, "BER_MQAM")
    if sydney_exists:
        plot_line_comparison(
            df,
            columns=[sydney_BER_MQAM_col],
            labels=[sydney_BER_MQAM_col],
            xlabel='Time (m)',
            ylabel='BER_MQAM ',
            title=f'BER_MQAM for Starlink Satellites',
            filename=f"{extra_tag}_{sat_id}_Sydney_BER_MQAM",
            folder=temp_tagged_folder
        )
    if melbourne_exists:
        plot_line_comparison(
            df,
            columns=[melbourne_BER_MQAM_col],
            labels=[melbourne_BER_MQAM_col],
            xlabel='Time (m) ',
            ylabel='BER_MQAM ',
            title=f'BER_MQAM for Starlink Satellites',
            filename=f"{extra_tag}_{sat_id}_Melbourne_BER_MQAM",
            folder=temp_tagged_folder
        )

# %%
# Loop over each satellite in possible_sat_conn_ids
for sat_id in possible_sat_conn_ids:
    # Build RSSI column names
    sydney_RSSI_col = f'{sat_id}_Sydney_RSSI_dBm'
    melbourne_RSSI_col = f'{sat_id}_Melbourne_RSSI_dBm'

    # Check which RSSI columns exist
    sydney_exists = sydney_RSSI_col in df.columns
    melbourne_exists = melbourne_RSSI_col in df.columns

    # Skip if neither exists
    if not sydney_exists and not melbourne_exists:
        continue
    # Plot 
    temp_tagged_folder = os.path.join(tagged_folder, "RSSI")
    if sydney_exists:
        plot_line_comparison(
            df,
            columns=[sydney_RSSI_col],
            labels=[sydney_RSSI_col],
            xlabel='Time (m)',
            ylabel='RSSI(dBm)',
            title=f'RSSI for Starlink Satellites',
            filename=f"{extra_tag}_{sat_id}_Sydney_RSSI",
            folder=temp_tagged_folder
        )
    if melbourne_exists:
        plot_line_comparison(
            df,
            columns=[melbourne_RSSI_col],
            labels=[melbourne_RSSI_col],
            xlabel='Time (m) ',
            ylabel='RSSI(dBm)',
            title=f'RSSI for Starlink Satellites',
            filename=f"{extra_tag}_{sat_id}_Melbourne_RSSI",
            folder=temp_tagged_folder
        )

# %%
df.head(2)

# %%
for i, row in df.iterrows():
    # Get the highest value across all RSSI columns at the `i-th` row
    highest_rssi_at_i = df[all_rssi_cols].iloc[i].max()

    # Get the column name that has the highest RSSI value at the `i-th` index
    column_with_highest_rssi = df[all_rssi_cols].iloc[i].idxmax()

    print(f"Highest RSSI value at index {i}: {highest_rssi_at_i}")
    print(f"Column with the highest RSSI value at index {i}: {column_with_highest_rssi}")

# %%
stats = df[all_rssi_cols].fillna(0).describe().T
stats.to_csv(os.path.join('./', 'rssi_stats.csv'))

# %%
stats = df[all_rssi_cols].describe().T
stats.to_csv(os.path.join('./', 'rssi_stats.csv'))

# %%
stats = df[all_snr_cols].describe().T
stats.to_csv(os.path.join('./', 'snr_stats.csv'))

# %%

# Highest value per column
max_per_column = df[all_rssi_cols].max()

# Highest value among all columns
overall_max = df[all_rssi_cols].max().max()

# Displaying results
print("\nHighest Value per Column:\n", max_per_column)
print("\nHighest Value Among All Columns:", overall_max)
