from flask_restful import Resource

class Health(Resource):
    def get(self):
        return {'message': 'The application health status is OK!'}