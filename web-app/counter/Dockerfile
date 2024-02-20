# Use the official Python base image
FROM python:3.11-slim

# Set the working directory inside the container
WORKDIR /app

# Environment variables
ENV UVICORN_PORT=8000
ENV UVICORN_HOST=0.0.0.0

# Copy the application code to the working directory
COPY static/ static/
COPY requirements.txt *py ./

# Install the Python dependencies
RUN pip install --no-cache-dir --upgrade -r requirements.txt

# Expose the port on which the application will run
EXPOSE 8000

# Run the FastAPI application using uvicorn server
CMD ["uvicorn", "main:app", "--lifespan", "off"]