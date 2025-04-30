from flask import Blueprint, render_template
# import json

bp = Blueprint("catalog", __name__, url_prefix="/catalog")


def get_products():
    """abstraction to retrieve product catalog"""
    return [
        {
            "id": 1,
            "name": "Laptop",
            "price": 999,
            "description": "The laptop of your dreams",
        },
        {
            "id": 2,
            "name": "Keyboard",
            "price": 49,
            "description": "Basic keyboard for everyday use",
        },
    ]


@bp.route("/")
def show_catalog():
    """display catalog on UI"""
    # with open("mock_data.json", "r") as f:
    #     products = json.load(f)
    # for product in products:
    #     print(product)
    products = get_products()
    return render_template("catalog.html", products=products)
