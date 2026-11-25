FROM python:3.15-slim-trixie@sha256:65a65fc7b30b06cb6df4930fd4650697cb23f4c2698ab81fc87e4b031bc36928 AS base

ENV PYTHONDONTWRITEBYTECODE=1\
    PYTHONUNBUFFERED=1 

RUN groupadd --gid 10001 app && useradd --uid 10001 --gid 10001 app

WORKDIR /app

COPY requirements.txt  /app/
RUN pip install --no-cache-dir -r requirements.txt

FROM base AS builder
COPY . /app/
RUN tailwindcss_install && \
  tailwindcss -i theme/static_src/src/styles.css -o theme/static/css/dist/styles.css --minify

FROM base AS prod
COPY . /app/
COPY --from=builder /app/theme/static/css/dist/ /app/theme/static/css/dist/

RUN mkdir -p db media staticfiles import export && \
  chown app:app db media staticfiles import export

USER app:app
EXPOSE 8000
CMD ["sh", "-c", \
  "python manage.py migrate && \
  python manage.py collectstatic --noinput && \
  exec gunicorn --bind 0.0.0.0:8000 --workers 5 --worker-tmp-dir /dev/shm chillmatma.wsgi:application"]

FROM base AS dev

COPY requirements-dev.txt /app/

RUN pip install --no-cache-dir -r requirements-dev.txt

RUN tailwindcss_install

EXPOSE 8000

CMD ["sh", "-c", \
  "python manage.py migrate && \
  python manage.py tailwind build && \
  python manage.py collectstatic --noinput && \
  exec gunicorn --bind 0.0.0.0:8000 --reload --workers 1 --timeout 0 --threads 4 chillmatma.wsgi:application"]
