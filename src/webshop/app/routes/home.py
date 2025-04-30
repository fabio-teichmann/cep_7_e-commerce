"""home API"""

from flask import Blueprint, render_template

bp = Blueprint("home", __name__)


@bp.route("/")
def index():
    """home page"""
    return render_template("home.html")
