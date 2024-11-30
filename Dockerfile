FROM mcr.microsoft.com/playwright/python:v1.49.0-noble

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file
COPY requirements.txt requirements.txt

# Install the dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY . .

# Define the command to run your application
CMD ["pytest"]