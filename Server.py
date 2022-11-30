from flask import Flask
from routes.consultas import consultas
from routes.principal import principal

Server = Flask(__name__)
Server.register_blueprint(consultas)

if(__name__ == "__main__"):
    Server.run(debug=True)