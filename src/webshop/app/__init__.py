from flask import Flask
from .config import Config
from .routes.catalog import bp as catalog_blueprint 
from .routes.orders import bp as orders_blueprint 

def create_app():
    app = Flask(__name__)

    app.config.from_object(Config)

    # register blueprints
    app.register_blueprint(catalog_blueprint)
    app.register_blueprint(orders_blueprint)

    return app