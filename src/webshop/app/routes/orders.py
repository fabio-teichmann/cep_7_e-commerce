from flask import Blueprint, request, redirect, url_for, render_template
from random import randint
import logging

bp = Blueprint("orders", __name__, url_prefix="/order")

@bp.route("/", methods=["POST"])
def place_order():
    product_id = request.form.get("product_id")
    product_name = request.form.get("product_name")
    product = request.form.get("product")
    # simulate occasionally failing orders
    failed_order = randint(1, 10) > 5
    if failed_order:
        logging.error(f"order failed: {product_id}")
        return render_template("order_error.html", message="We are currently unable to serve your request, please try again.")
    # post to Kinesis Stream
    ...
    print(f"received order for product {product_id}")
    return render_template("order_confirmation.html", product=product)
    return redirect(url_for("catalog.show_catalog"))