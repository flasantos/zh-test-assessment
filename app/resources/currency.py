import json
import requests
from flask_restful import Resource

class Currency(Resource):
    def get(self, currency):
        """
        Method to return currency informations about bitcoin
        :param currency:
        :return:
        """
        try:
            url = f'https://api.coinbase.com/v2/prices/spot?currency={currency}'

            headers = {
                'Content-Type': 'application/json'
            }

            response = requests.get(url=url, headers=headers)

            return response.json(), response.status_code
        except json.decoder.JSONDecodeError:
            return {'error': 'Invalid json response!'}, 500
