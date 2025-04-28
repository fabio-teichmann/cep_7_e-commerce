from flask import Blueprint, request, redirect, url_for

bp = Blueprint("orders", __name__, url_prefix="/order")

@bp.route("/", methods=["POST"])
def place_order():
    product_id = request.form.get("product_id")
    # post to Kinesis Stream
    ...
    print(f"received order for product {product_id}")
    return redirect(url_for("catalog.show_catalog"))