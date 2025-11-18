# Shared Python AI base image with all dependencies pre-installed
# Used by both Jenkins build agents and RAG service
# This speeds up pipelines and deployments by avoiding dependency installation
FROM python:3.11-slim

# Install system dependencies that may be needed
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip and install Python dependencies
RUN python -m pip install --upgrade pip setuptools wheel

# Install all Python dependencies (ingestion + RAG service)
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Verify installations
RUN python -c "import chromadb; import vertexai; import fastapi; import uvicorn; print('✓ All dependencies installed successfully')" && \
    python -c "import sqlite3; print(f'✓ SQLite version: {sqlite3.sqlite_version}')"

# Set working directory
WORKDIR /workspace

# Default command (will be overridden by consumers)
CMD ["/bin/bash"]

