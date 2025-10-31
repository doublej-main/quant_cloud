import os
from fastapi import FastAPI
from fastapi.responses import FileResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import mimetypes

# --- Configuration ---
# Use the absolute path based on the Dockerfile WORKDIR
OUTPUT_DIR = "/quant_cloud/output"

# --- FastAPI App Initialization ---
app = FastAPI()

# --- CORS Middleware ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins (restrict in production)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- API Endpoints ---

@app.get("/")
def read_root():
    return {"message": "Black-Scholes Greek Validator API is running."}

@app.get("/api/results")
async def get_results_manifest():
    """
    Scans the output directory and returns a list of available files.
    """
    try:
        files = os.listdir(OUTPUT_DIR)
        # Filter for only .csv and .png files
        result_files = [f for f in files if f.endswith('.csv') or f.endswith('.png')]
        return {"files": result_files}
    except FileNotFoundError:
        return JSONResponse(status_code=404, content={"error": f"Output directory not found at {OUTPUT_DIR}. Did the startup script run?"})
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})


@app.get("/api/files/{filename:path}")
async def get_file(filename: str):
    """
    Serves a specific file from the output directory.
    """
    try:
        file_path = os.path.join(OUTPUT_DIR, filename)
        
        # Basic security: prevent directory traversal
        if ".." in filename or not os.path.exists(file_path) or not os.path.isfile(file_path):
            return JSONResponse(status_code=404, content={"error": "File not found"})

        # Guess MIME type
        mimetype, _ = mimetypes.guess_type(file_path)
        if mimetype is None:
            mimetype = "application/octet-stream"

        return FileResponse(file_path, media_type=mimetype, filename=filename)
    
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})

