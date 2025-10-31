import pandas as pd
import matplotlib.pyplot as plt
import os
from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles

# --- CORS Imports ---
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# --- CORS SECURITY FIX ---
# This tells the browser that it's safe for your
# frontend to make requests to this backend.

# You should restrict this in production!
# For this project, allowing all origins is ok.
# For a real project, you'd put your S3 URL in origins.
origins = [
    "*",  # Allows all origins
    # "http://your-s3-website-url.s3-website-us-east-1.amazonaws.com" # Example
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods (GET, POST, etc.)
    allow_headers=["*"],  # Allows all headers
)
# --- END CORS FIX ---


# This is the directory where run_script.sh places the files
OUTPUT_DIR = "/quant_cloud/output"

# Mount the static directory to serve files
# This creates a "/files" endpoint
app.mount("/files", StaticFiles(directory=OUTPUT_DIR), name="files")

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
        
        # We prefix with '/files/' because that's our StaticFiles mount point
        return {
            "csv": [f"/files/{f}" for f in csv_files],
            "plots": [f"/files/{f}" for f in png_files]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# This allows users to download a specific file
@app.get("/files/{file_name}")
def get_file(file_name: str):
    file_path = os.path.join(OUTPUT_DIR, file_name)
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="File not found")
    return FileResponse(file_path)
