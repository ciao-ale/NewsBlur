FROM python:3.10-slim

# Install system dependencies needed to build Python C extensions and image libs
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    python3-dev \
    pkg-config \
    autoconf \
    automake \
    libtool \
    libpq-dev \
    libxml2-dev \
    libxslt1-dev \
    libffi-dev \
    libzmq3-dev \
    libjpeg-dev \
    zlib1g-dev \
    libfreetype6-dev \
    liblcms2-dev \
    libopenjp2-7-dev \
    libtiff5-dev \
    libwebp-dev \
    tk-dev \
    tcl-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy only requirements first to leverage Docker cache
COPY requirements.txt /app/

# Use a pip version known to work with older packages if necessary,
# and install Cython early so packages that need it (pyzmq/gevent) can build.
RUN python -m pip install --upgrade "pip<24.1" && \
    python -m pip install --no-cache-dir cython && \
    pip install --no-cache-dir -r requirements.txt

# Copy the rest of the source
COPY . /app

ENV PYTHONUNBUFFERED=1
ENV DJANGO_SETTINGS_MODULE=newsblur_web.settings.production

EXPOSE 8000

# Collect static files at container start (best-effort)
CMD ["/bin/sh", "-c", "python manage.py migrate --noinput && python manage.py collectstatic --noinput || true && gunicorn newsblur_web.wsgi:application --bind 0.0.0.0:8000 --config config/gunicorn_conf.py"]
