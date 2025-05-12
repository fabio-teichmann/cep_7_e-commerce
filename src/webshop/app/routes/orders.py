"""orders API"""

import time
from datetime import datetime
import random
import json
import logfire
from flask import Blueprint, request, render_template, redirect, url_for, current_app
from .catalog import get_products
import boto3

bp = Blueprint("orders", __name__, url_prefix="/order", template_folder="routes")
AUTO_ORDER_FLAG = {"active": False}

kinesis_client = boto3.client("kinesis", region_name="us-east-1")

def process_order(product, user_id=0, quantity=1, notes="auto ordered"):
    """Processes the order and posts it to a Kinesis Stream.
    Simulates order failure for ~20% of cases."""
    
    if random.random() < 0.2:
        logfire.error(f"Order failed: {product.get('id')}")
        return False

    order = {
        "customer_id": user_id,
        "product_id": int(product["id"]),
        "product_name": product["name"],
        "product_description": product["description"],
        "price": product["price"],
        "quantity": quantity,
        "timestamp": datetime.now().isoformat(),
        "category": product["category"]
    }

    stream_name = current_app.config.get("KINESIS_STREAM_NAME")
    if not stream_name:
        logfire.error("Kinesis stream name not configured")
        return False

    try:
        logfire.info(f"Posting order to Kinesis stream: {stream_name}")
        response = kinesis_client.put_record(
            StreamName=stream_name,
            Data=f"{json.dumps(order)}\n".encode("utf-8"),
            PartitionKey=str(product["id"])
        )
        logfire.info(f"Kinesis response: {response}")
        return True
    except Exception as e:
        logfire.error(f"Kinesis put_record failed: {e}")
        return False


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
        user_id = random.randint(1, 10)
        process_order(product, user_id=user_id)

        time.sleep(1)

    return redirect(url_for("orders.auto_order_page"))


@bp.route("/auto_order/stop", methods=["POST"])
def stop_auto_order():
    """interrupt auto ordering process"""
    AUTO_ORDER_FLAG["active"] = False

    return redirect(url_for("orders.auto_order_page"))
