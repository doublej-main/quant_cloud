# 1. Use an official Python runtime as a parent image
FROM python:3.10-slim

# 2. Set the working directory in the container to /quant_cloud
WORKDIR /quant_cloud

# 3. Install dependencies
# We need 'g++' and 'make' to compile the C++ code
RUN apt-get update && \
    apt-get install -y g++ make && \
    rm -rf /var/lib/apt/lists/*

# 4. Copy and install Python requirements
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 5. Copy all backend source files into /quant_cloud
COPY . .

# 6. Make the entrypoint script executable
RUN chmod +x run_script.sh

# 7. Set the entrypoint to run our script
# This script will compile, run C++/Python, and then start the API server
CMD ["./run_script.sh"]

