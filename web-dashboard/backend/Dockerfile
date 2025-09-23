# Multi-stage build for Python FastAPI application

# --- Estágio Builder: Instala as dependências ---
FROM python:3.11-slim AS builder

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONHASHSEED=random \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Instala dependências de build do sistema
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copia apenas os arquivos de dependência para aproveitar o cache
WORKDIR /app
COPY requirements-dev.txt ./
# Copia o requirements.txt da raiz do projeto para o contexto de build
COPY ../../requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt -r requirements-dev.txt

# Production stage
FROM python:3.11-slim AS production

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    curl \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Set working directory
WORKDIR /app

# Copia o código da aplicação como uma das últimas etapas para otimizar o cache
COPY . .

# Ajusta permissões e cria diretórios necessários
RUN mkdir -p logs && chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

# Start application
ENTRYPOINT ["uvicorn", "main_fixed:app"]
CMD ["--host", "0.0.0.0", "--port", "8000"]
