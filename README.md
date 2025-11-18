# Jenkins Python Build Agent Image

This directory contains a custom Docker image for a Jenkins Python build agent with all dependencies pre-installed. It can also be used as a base image for other needs requiring Python and AI libs.

## Why This Image?

- **Faster pipelines**: Dependencies are pre-installed, eliminating `pip install` steps
- **Consistent environment**: Same Python version and dependencies across all builds
- **SQLite compatibility**: Uses Python 3.11+ which includes SQLite 3.35.0+ (required by ChromaDB)

## Building the Image

### Automated Build (Recommended)

**Use the Jenkins pipeline** (`Jenkinsfile`):

1. Create a new Jenkins Pipeline job
2. Point it to this repository
3. Set branch: `main`
4. Pipeline script: `Jenkinsfile`

**The pipeline will:**
- Build the Docker image
- Tag it based on branch (`latest` for main/master, `BRANCH-BUILD_NUMBER` for others)
- Push to GAR: `us-east1-docker.pkg.dev/teralivekubernetes/logistics/jenkins-python-ai-agent:TAG`
- Use the same GAR authentication as other pipelines (`jenkins-gar-sa` credential)

### Manual Build (Alternative)

This image is self-contained with its own `requirements.txt`:

```bash
# Set variables
export GCP_PROJECT_ID=teralivekubernetes
export GCP_REGION=us-east1
export GAR_REPOSITORY=logistics
export IMAGE_NAME=jenkins-python-ai-agent
export IMAGE_TAG=latest

# Build the image
docker build -t ${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${GAR_REPOSITORY}/${IMAGE_NAME}:${IMAGE_TAG} -f Dockerfile .

# Authenticate to GAR
gcloud auth configure-docker ${GCP_REGION}-docker.pkg.dev

# Push the image
docker push ${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${GAR_REPOSITORY}/${IMAGE_NAME}:${IMAGE_TAG}
```

## Updating Jenkins Configuration

After building and pushing the image:

1. Go to **Manage Jenkins** → **Configure System** → **Cloud** → **Kubernetes**
2. Add a new pod template with label `python-ai`
3. Add the `builder` container
4. Update the **Container Image** to:
   ```
   us-east1-docker.pkg.dev/teralivekubernetes/logistics/jenkins-python-ai-agent:latest
   ```
5. Save the configuration

**Note**: The image is stored in the `logistics` GAR repository (not `uplifted-mascot`).

## What's Included

- **Python 3.11-slim**: Modern Python with SQLite 3.35.0+
- **All ingestion dependencies**: ChromaDB, Vertex AI, tiktoken, etc.
- **All RAG service dependencies**: FastAPI, Uvicorn, Pydantic, etc.
- **Shared base image**: Used by both Jenkins agents and RAG service for faster builds

## Using as Base Image

The RAG service Dockerfile uses this image as its base:

```dockerfile
FROM us-east1-docker.pkg.dev/teralivekubernetes/logistics/jenkins-python-ai-agent:latest
```

This means:
- RAG service builds are faster (dependencies already installed)
- Consistent Python version (3.11) across all services
- Single source of truth for dependencies

## Updating Dependencies

When you need to update dependencies:

1. Update `requirements.txt` (combines ingestion + RAG dependencies)
2. Rebuild the image via Jenkins pipeline or manually
3. Push to GAR (automated via pipeline)
4. Update Jenkins pod template to use the new image tag (if not using `latest`)
5. Rebuild RAG service (it will pull the updated base image)
6. Test both pipelines

**Note**: Since the RAG service uses this as a base image, updating this image will require rebuilding the RAG service to get the new dependencies. Consider using version tags (e.g., `v1`, `v2`) instead of `latest` for better reproducibility and controlled updates.

