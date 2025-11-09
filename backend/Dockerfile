# backend/Dockerfile

# 1. Use the official AWS Lambda base image for Python 3.10
FROM public.ecr.aws/lambda/python:3.10

# 2. Set the working directory
WORKDIR /var/task

# 3. Install dependencies
RUN yum update -y && \
    yum install -y gcc-c++ make && \
    yum clean all

# 4. Copy and install Python requirements
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 5. Copy ALL backend source files
COPY . .

# 6. Compile C++ executable
RUN make -f /var/task/Makefile

# 7. Run C++ executable (creates *.csv in /var/task)
RUN /var/task/bs_validator

# 8. Run Python plotter (creates 'plots/' dir in /var/task)
RUN python3 /var/task/bs_plot_results.py

# 9. Create the final output directory
RUN mkdir -p /var/task/output

# 10. Move all generated files into the final directory
RUN mv /var/task/*.csv /var/task/output/
RUN mv /var/task/plots/*.png /var/task/output/

# 11. Set the command for Lambda
CMD [ "bs_api_server.handler" ]