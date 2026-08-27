# ============================================================
# Project PARAKH — Production Dockerfile
# Multi-stage build with non-root security execution (§47)
# ============================================================

# --- Stage 1: Build & Dependencies ---
FROM python:3.11-slim AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# --- Stage 2: Runtime ---
FROM python:3.11-slim AS runtime

WORKDIR /app

# Install runtime shared libraries for OpenCV and PostgreSQL
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    libgl1 \
    libglib2.0-0 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root system user
RUN groupadd -r parakh && useradd -r -g parakh -d /app -s /sbin/nologin parakh

# Copy installed python packages from builder
COPY --from=builder /root/.local /home/parakh/.local
ENV PATH=/home/parakh/.local/bin:$PATH
ENV PYTHONPATH=/app

# Copy application source code
COPY --chown=parakh:parakh . /app

USER parakh

EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
