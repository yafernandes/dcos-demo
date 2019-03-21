FROM python:alpine
WORKDIR /usr/src/app
RUN apk add --no-cache git
RUN git clone https://github.com/dpkp/kafka-python
RUN pip install ./kafka-python
COPY kafka-producer.py ./
CMD [ "python", "./kafka-producer.py" ]