from flask import Blueprint

consultas = Blueprint('consultas',__name__)

@consultas.route("/consulta_a")
def consulta_a():
    return "Consulta A"

@consultas.route("/consulta_b")
def consulta_b():
    return "Consulta B"