""" application factory """
import logfire
from flask import Flask
from .config import Config
from .routes.catalog import bp as catalog_blueprint
from .routes.orders import bp as orders_blueprint
from .routes.home import bp as home_blueprint


def create_app():
    """application factory"""
    app = Flask(__name__)

    app.config.from_object(Config)
    logfire.configure(token=app.config["LOGFIRE_TOKEN"])
    logfire.instrument_flask(app)

    # app.logger.setLevel(logging.INFO)

    # register blueprints
    app.register_blueprint(home_blueprint)
    app.register_blueprint(catalog_blueprint)
    app.register_blueprint(orders_blueprint)

    return app
