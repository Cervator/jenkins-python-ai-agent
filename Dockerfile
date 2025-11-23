# Shared Python AI base image with all dependencies pre-installed
# Used by both Jenkins build agents and RAG service
# This speeds up pipelines and deployments by avoiding dependency installation
FROM python:3.11-slim

# Install system dependencies that may be needed
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    libglib2.0-0 \
    libnspr4 \
    libnss3 \
    libdbus-1-3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libatspi0 \
    libx11-6 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libxcb1 \
    libxkbcommon0 \
    libasound2 \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip and install Python dependencies
RUN python -m pip install --upgrade pip setuptools wheel

# Install all Python dependencies (ingestion + RAG service + Vordu tests)
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt && \
    playwright install --with-deps chromium

# Verify installations
RUN python -c "import chromadb; import vertexai; import fastapi; import uvicorn; print('✓ All dependencies installed successfully')" && \
    python -c "import sqlite3; print(f'✓ SQLite version: {sqlite3.sqlite_version}')"

# Set working directory
WORKDIR /workspace

# Default command (will be overridden by consumers)
CMD ["/bin/bash"]
