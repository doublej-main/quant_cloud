#!/bin/bash
#
# This script builds and runs the entire C++/Python workflow.
# It then moves all generated files (.png and .csv into /outputs)
# Finally it starts up the API server, AWS App Runner expects port 8000 by default
# It will stop immediately if any command fails.
#

set -e

echo "--- 1. Building C++ executable ---"
make

echo "--- 2. Running C++ executable to generate CSVs ---"
./bs_validator 

echo "--- 3. Running Python plotter ---"
python3 bs_plot_results.py

echo "--- 4. Organizing output files... ---"
OUTPUT_DIR="/quant_cloud/output"
mkdir -p $OUTPUT_DIR
mv *.csv $OUTPUT_DIR/
mv plots/*.png $OUTPUT_DIR/
echo "All files moved to $OUTPUT_DIR"

echo "--- 5. Starting FastAPI server... ---"
uvicorn bs_api_server:app --host 0.0.0.0 --port 8000

echo "--- Workflow complete. ---"