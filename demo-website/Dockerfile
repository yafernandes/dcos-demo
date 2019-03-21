FROM python:alpine
WORKDIR /usr/src/app
RUN pip install --upgrade pip
RUN pip install --no-cache-dir flask flask-api kafka-python ifaddr
COPY demo-website.py ./
CMD [ "python", "demo-website.py"]