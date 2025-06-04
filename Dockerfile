# Python image
FROM python:3.11-slim

WORKDIR /app

COPY demoapp/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python", "demoapp/app.py"]
