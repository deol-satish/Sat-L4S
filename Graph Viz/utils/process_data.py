import os
from utils.config import GRAPH_SAVE_FOLDER, DATA_FOLDER
from utils.plotter import plot_line_comparison


import pandas as pd
import re


def process_data(df: pd.DataFrame) -> pd.DataFrame:

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

    all_rssi_cols = [col for col in df.columns if re.search(r'_RSSI_dBm$', col)]
    all_snr_cols = [col for col in df.columns if re.search(r'_SNR_dB$', col)]
    all_thrpt_cols = [col for col in df.columns if re.search(r'_Throughput$', col)]
    all_BER_QPSK_cols = [col for col in df.columns if re.search(r'_BER_QPSK$', col)]
    all_BER_MQAM_cols = [col for col in df.columns if re.search(r'_BER_MQAM$', col)]
    all_Latency_cols = [col for col in df.columns if re.search(r'Latency$', col)]
    all_TimeOut_cols = [col for col in df.columns if re.search(r'TimeOut$', col)]

    df[all_thrpt_cols] = df[all_thrpt_cols] / (1024 * 1024) # Convert to Mbps

    df[all_Latency_cols] = df[all_Latency_cols] * 1000 # Convert to Mbps
    
    return df, possible_sat_conn_ids




import re

def return_sat_col_dict(df):
    # Initialize the nested dictionary
    organized_cols = {}

    # Regex to capture the LEO number, Location, and Metric from column names
    # Pattern: LEO<digits>_<LocationAlphanumeric>_<MetricAnythingElse>
    pattern = re.compile(r'LEO(\d+)_([a-zA-Z0-9]+)_(.+)$')

    for col_name in df.columns:
        match = pattern.match(col_name)
        if match:
            leo_num_str = "LEO" + match.group(1)  # e.g., "LEO20"
            location = match.group(2)             # e.g., "Sydney"
            metric = match.group(3)               # e.g., "Access", "SNR_dB"

            # Ensure LEO number exists in the main dictionary
            if leo_num_str not in organized_cols:
                organized_cols[leo_num_str] = {}

            # Ensure location exists under the LEO number
            if location not in organized_cols[leo_num_str]:
                organized_cols[leo_num_str][location] = {}

            # Ensure metric list exists under the location
            if metric not in organized_cols[leo_num_str][location]:
                organized_cols[leo_num_str][location][metric] = []

            # Add the column name to the list
            organized_cols[leo_num_str][location][metric].append(col_name)

    return organized_cols


# def return_sat_col_dict(df):
#     # Initialize the nested dictionary
#     organized_cols = {}

#     # Regex to capture the LEO number, Location, and Metric from column names
#     # Pattern: LEO<digits>_<LocationAlphanumeric>_<MetricAnythingElse>
#     pattern = re.compile(r'LEO(\d+)_([a-zA-Z0-9]+)_(.+)$')

#     for col_name in df.columns:
#         match = pattern.match(col_name)
#         if match:
#             leo_num_str = match.group(1) # LEO number as string e.g., "20"
#             location = match.group(2)    # Location e.g., "Sydney"
#             metric = match.group(3)      # Metric e.g., "Access", "SNR_dB"

#             leo_num_str = "LEO"+leo_num_str

#             # Ensure location exists in the main dictionary
#             if location not in organized_cols:
#                 organized_cols[location] = {}

#             # Ensure LEO number exists for that location
#             if leo_num_str not in organized_cols[location]:
#                 organized_cols[location][leo_num_str] = {}

#             # Ensure metric list exists for that LEO number and location
#             if metric not in organized_cols[location][leo_num_str]:
#                 organized_cols[location][leo_num_str][metric] = []

#             # Add the column name to the list
#             organized_cols[location][leo_num_str][metric].append(col_name)

#     # # To view the result:
#     # import json
#     # print(json.dumps(organized_cols, indent=4))

#     return organized_cols
