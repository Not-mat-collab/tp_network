FROM python:3.11-slim

WORKDIR /app

RUN pip install Flask pymysql

COPY app.py .

CMD ["python", "app.py"]
