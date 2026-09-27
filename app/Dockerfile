FROM python:3.12-slim

RUN useradd --create-home --uid 10001 nea
WORKDIR /srv
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY ingest/ ./app/ingest/
RUN touch app/__init__.py

USER nea
ENTRYPOINT ["python", "-m", "app.ingest.pipeline"]
