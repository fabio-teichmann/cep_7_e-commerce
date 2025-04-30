"""orders API"""

import time
import random
import logfire
from flask import Blueprint, request, render_template, redirect, url_for, current_app
from .catalog import get_products


bp = Blueprint("orders", __name__, url_prefix="/order", template_folder="routes")
AUTO_ORDER_FLAG = {"active": False}


def process_order(product, user_id="auto_user", quantity=1, notes="auto ordered"):
    """processes the order and posts it to Kinesis Stream.
    Simulates order failure for 20% of cases"""
    # simulate occasionally failing orders
    failed_order = random.randint(1, 10) > 8
    if failed_order:
        logfire.error(f"order failed: {product['id']}")
        return False

    # post to Kinesis Stream
    logfire.info(f"post order to kinesis {current_app.config['KINESIS_TOPIC']}")
    order = [user_id, quantity, notes]
    print(order)
    return True


@bp.route("/", methods=["POST"])
def place_order():
    """places an order, triggered by a user (manual order)"""
    # product_id = request.form.get("product_id")
    # product_name = request.form.get("product_name")
    product = request.form.get("product")
    user_id = request.form.get("user_id")
    # print(f"id: {product_id} -- name: {product_name} -- product: {product}")

    order_processed = process_order(product, user_id, notes="manual order")
    if order_processed:
        return render_template("order_confirmation.html", product=product)
    return render_template(
        "order_error.html",
        message="We are currently unable to serve your request, please try again.",
    )


@bp.route("/auto-order/home", methods=["GET"])
def auto_order_page():
    """auto order page"""
    logs_url = current_app.config["LOGFIRE_URL"]
    return render_template("auto_order.html", logs_url=logs_url)


@bp.route("/auto_order/start", methods=["POST"])
def start_auto_order():
    """Automatically orders a product every 1 second to simulate order activity."""
    AUTO_ORDER_FLAG["active"] = True
    products = get_products()
    logfire.info("started auto ordering process...")
    for _ in range(10):
        if not AUTO_ORDER_FLAG["active"]:
            break
        # Simulate order logic
        product = random.choice(products)
        logfire.info(f"auto-order: {product}")
        process_order(product)

        time.sleep(1)

    return redirect(url_for("orders.auto_order_page"))


@bp.route("/auto_order/stop", methods=["POST"])
def stop_auto_order():
    """interrupt auto ordering process"""
    AUTO_ORDER_FLAG["active"] = False

    return redirect(url_for("orders.auto_order_page"))
