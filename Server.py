from flask import Flask, flash
from routes.consultas import consultas

Server = Flask(__name__)
Server.register_blueprint(consultas)
Server.secret_key="ScrtKy"

if(__name__ == "__main__"):
    Server.run(debug=True)