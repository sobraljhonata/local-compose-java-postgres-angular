FROM python:3.12-slim
WORKDIR /app
RUN pip install --no-cache-dir "pyjwt[crypto]==2.10.1" cryptography==44.0.2
COPY server.py /app/server.py
ENV PORT=8080 \
    LOCAL_KEY_DIR=/var/lib/autua-local-keys
RUN mkdir -p /var/lib/autua-local-keys && chmod 700 /var/lib/autua-local-keys
EXPOSE 8080
HEALTHCHECK --interval=5s --timeout=5s --retries=15 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/health')"
CMD ["python", "-u", "/app/server.py"]
