"""Backend API server for Black-Scholes Greek Validator.
This module implements a FastAPI server that serves the results
of the Black-Scholes Greek validation computations.
It provides endpoints to list available CSV results and
plots, as well as to download specific files.

Module Functions
----------------
read_root()
    Health check endpoint.
get_results()
    Lists available CSV and PNG files in the output directory.
get_file(file_name)
    Downloads a specific file from the output directory.
"""
import os
import logging
from mangum import Mangum
from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware

# --- Logging Configuration ---
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# --- FastAPI App Definition ---
app = FastAPI()

# --- CORS Middleware ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods (GET, POST, etc.)
    allow_headers=["*"],  # Allows all headers
)

# --- THE FILES ARE NOW PRE-BUILT ---
# The Dockerfile created this directory with all our files.
OUTPUT_DIR = "/var/task/output"

# --- API Endpoints ---
@app.get("/")
def read_root():
    """
    Health check endpoint.
    """
    return {"message": "Black-Scholes Greek Validator API is running."}

@app.get("/api/results")
def get_results():
    """
    API endpoint that lists all available .csv and .png files.
    """
    try:
        files = os.listdir(OUTPUT_DIR)
        csv_files = [f for f in files if f.endswith('.csv')]
        png_files = [f for f in files if f.endswith('.png')]
        
        # Return only the filenames. The frontend adds the "/files/" prefix.
        return {
            "csv": csv_files,
            "plots": png_files
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/files/{file_name}")
def get_file(file_name: str):
    """
    Downloads a specific file from the output directory.
    """
    try:
        if ".." in file_name or file_name.startswith("/"):
             raise HTTPException(status_code=400, detail="Invalid filename")

        file_path = os.path.join(OUTPUT_DIR, file_name)
        
        if not os.path.exists(file_path):
            logger.error(f"File not found: {file_path}")
            raise HTTPException(status_code=404, detail="File not found")
        
        return FileResponse(file_path)
    
    except Exception as e:
        logger.error(f"Failed to get file {file_name}: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

# --- Mangum Handler ---
handler = Mangum(app)