FROM python:3.10-slim

# Install system dependencies needed to build Python C extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    libpq-dev \
    libxml2-dev \
    libxslt1-dev \
    libffi-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy only requirements first to leverage Docker cache
COPY requirements.txt /app/

# Use a pip version known to work with older packages if necessary
RUN python -m pip install --upgrade "pip<24.1" && \
    pip install --no-cache-dir -r requirements.txt

# Copy the rest of the source
COPY . /app

ENV PYTHONUNBUFFERED=1
ENV DJANGO_SETTINGS_MODULE=newsblur_web.settings.production

EXPOSE 8000

# Collect static files at container start (best-effort)
# Note: You can also run migrations/collectstatic in an init container or as a one-off job
CMD ["/bin/sh", "-c", "python manage.py migrate --noinput && python manage.py collectstatic --noinput || true && gunicorn newsblur_web.wsgi:application --bind 0.0.0.0:8000 --config config/gunicorn_conf.py"]
