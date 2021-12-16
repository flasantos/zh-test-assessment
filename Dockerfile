FROM python:3.9.5-slim

WORKDIR /opt/api/currency

ADD requirements.txt .
RUN pip install -r requirements.txt

WORKDIR /opt/api/currency/app
ADD app/ .

CMD ["waitress-serve", "--call", "app:create_app"]