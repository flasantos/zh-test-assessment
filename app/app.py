from flask import Flask
from flask_restful import Api
from prometheus_flask_exporter import PrometheusMetrics
from resources.currency import Currency
from resources.health import Health

app = Flask(__name__)
api = Api(app)
metrics = PrometheusMetrics(app)
metrics.info("app_info", "Zero Hash Spot Price Web Application", version="1.0.0")

api.add_resource(Currency, '/<string:currency>')
api.add_resource(Health, '/health')

def create_app():
    return app