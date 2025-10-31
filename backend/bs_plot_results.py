"""Generates log-log error plots for Black-Scholes Greek validation.

This script reads the output CSV files from the Black-Scholes Greeks
model (e.g., 'bs_fd_vs_complex_scenario1.csv' and 
'..._scenario2.csv') and produces log-log plots comparing 
the absolute errors of different differentiation methods against 
the relative step size (h_rel).

The script creates two plots per scenario:
1.  Delta Errors: Compares err_D_fd and err_D_cs.
2.  Gamma Errors: Compares err_G_fd, err_G_cs_real, and err_G_cs_45.

It then saves these plots to a folder "plots".

These plots are used to analyze the accuracy, stability, and
step-size sensitivity of each method.

Module Functions
----------------
plot_errors(csv_filename, scenario_name)
    Loads a specific CSV file and generates the 
    Delta and Gamma error plots for that scenario.

Usage
-----
Run this script directly from the terminal.
In the root of the directory where the .csv files are e.g.:

	python script/plot_results.py
"""

import pandas as pd
import matplotlib.pyplot as plt
import os

OUTPUT_DIR = "plots"

def plot_errors(csv_filename, scenario_name):
    """
    Args:
        csv_filename (str): The path to the scenario's CSV file.
        scenario_name (str): A descriptive name (e.g., "Scenario 1 (ATM)")
    """
    try:
        # Create the output directory
        os.makedirs(OUTPUT_DIR, exist_ok=True)

        # Load the data from the CSV
        data = pd.read_csv(csv_filename)
        
        # --- Plot 1: Delta Errors ---
        plt.figure(figsize=(10, 6))
        
        # Plot (Delta) errors for fd and cs
        plt.plot(data['h_rel'].values, data['err_D_fd'].values, label='$\Delta_{fwd}$ Error (err_D_fd)', marker='o', markersize=4)
        plt.plot(data['h_rel'].values, data['err_D_cs'].values, label='$\Delta_{cs}$ Error (err_D_cs)', marker='x', markersize=4)
        
        # Set scales to log-log
        plt.xscale('log')
        plt.yscale('log')
        
        # Add labels, title, grid, and legend
        plt.xlabel('Relative Step Size ($h_{rel}$)')
        plt.ylabel('Absolute Error (log scale)')
        plt.title(f'Delta Error vs. Step Size - {scenario_name}')
        plt.grid(True, which="both", ls="--", linewidth=0.5)
        plt.legend()
        
        # Create the path for the output file
        delta_filename = os.path.join(OUTPUT_DIR, f'{scenario_name.replace(" ", "_")}_Delta_Errors.png')

        # Save the plot, uncomment # plt.show() if you want to display
        plt.savefig(delta_filename)
        # plt.show()
        plt.close()

        # Plot 2: Gamma Errors
        plt.figure(figsize=(10, 6))
        
        # Plot (Gamma) errors for fd, cs_real and cs_45
        plt.plot(data['h_rel'].values, data['err_G_fd'].values, label='$\Gamma_{fwd}$ Error (err_G_fd)', marker='o', markersize=4)
        plt.plot(data['h_rel'].values, data['err_G_cs_real'].values, label='$\Gamma_{cs,real}$ Error (err_G_cs_real)', marker='x', markersize=4)
        plt.plot(data['h_rel'].values, data['err_G_cs_45'].values, label='$\Gamma_{45^{\circ}}$ Error (err_G_cs_45)', marker='s', markersize=4)
        
        # Set scales to log-log
        plt.xscale('log')
        plt.yscale('log')
        
        # Add labels, title, grid, and legend
        plt.xlabel('Relative Step Size ($h_{rel}$)')
        plt.ylabel('Absolute Error (log scale)')
        plt.title(f'Gamma Error vs. Step Size - {scenario_name}')
        plt.grid(True, which="both", ls="--", linewidth=0.5)
        plt.legend()
        
        # Create the path for the output file
        gamma_filename = os.path.join(OUTPUT_DIR, f'{scenario_name.replace(" ", "_")}_Gamma_Errors.png')

        # Save the plot, uncomment # plt.show() if you want to display
        plt.savefig(gamma_filename)
        # plt.show()
        plt.close()

        print(f"Plots for {scenario_name} saved to '{OUTPUT_DIR}' folder.")

    except FileNotFoundError:
        print(f"Error: The file {csv_filename} was not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

# Call with <name of the csv file> <'Scenario Name'>
plot_errors('bs_fd_vs_complex_scenario1.csv', 'Scenario 1 (ATM)')
plot_errors('bs_fd_vs_complex_scenario2.csv', 'Scenario 2 (Stress)')
