# Shared Python AI base image with all dependencies pre-installed
# Used by both Jenkins build agents and RAG service
# We use the official Playwright image to ensure all browser dependencies are present
FROM mcr.microsoft.com/playwright/python:v1.40.0-jammy

# Install system dependencies that may be needed (git, curl)
# Playwright image is based on Ubuntu, so apt-get works
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip and install Python dependencies
RUN python -m pip install --upgrade pip setuptools wheel

# Install all Python dependencies (ingestion + RAG service + Vordu tests)
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Verify installations
RUN python -c "import chromadb; import vertexai; import fastapi; import uvicorn; print('✓ All dependencies installed successfully')" && \
    python -c "import sqlite3; print(f'✓ SQLite version: {sqlite3.sqlite_version}')"

# Set working directory
WORKDIR /workspace

# Default command (will be overridden by consumers)
CMD ["/bin/bash"]
