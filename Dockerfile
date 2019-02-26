FROM python:2.7

RUN apt-get update && apt-get install
RUN pip install --upgrade pip

RUN mkdir /opt/script
ADD ./criar-ssl.sh /opt/script

ENV PYTHONPATH $PYTHONPATH:/opt
WORKDIR /opt/letsencrypt