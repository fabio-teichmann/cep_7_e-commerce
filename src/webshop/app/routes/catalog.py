from flask import Blueprint, render_template

bp = Blueprint("catalog", __name__, url_prefix="/catalog")

@bp.route("/")
def show_catalog():
    products = [
        {"id": 1, "name": "Laptop", "price": 999, "description": "The laptop of your dreams"},
        {"id": 2, "name": "Keyboard", "price": 49, "description": "Basic keyboard for everyday use"}
    ]
    return render_template("catalog.html", products=products)