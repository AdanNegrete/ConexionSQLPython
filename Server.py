from flask import Flask, render_template, request, redirect, url_for, flash
from routes.consultas import consultas
from routes.principal import principal
import pyodbc

Server = Flask(__name__)
Server.register_blueprint(consultas)
principal.register_blueprint(principal)
Server.secret_key="ScrtKy"

inst=''
instancias={
    'sales': 'NEGA-PC',
    'production': 'NEGA-PC',
    'other': 'NEGA-PC'
}

def connection():
    s = inst #Your server name
    d = 'AdventureWorks' #Your db name
    u = 'sa' #Your login
    p = '123456' #Your login password
    cstr = 'DRIVER={ODBC Driver 17 for SQL Server};SERVER='+s+';DATABASE='+d+';UID='+u+';PWD='+ p
    conn = pyodbc.connect(cstr)
    return conn

@Server.route("/consulta")
def consulta():
    products = []
    global inst
    if inst == '':
        flash('Error en la instancia seleccionada')
        return redirect(url_for('Index'))
    conn = connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM Production.product")
    for row in cursor.fetchall():
        products.append({"id": row[0], "name": row[1], "lsprice": row[2]})
    conn.close()
    return render_template("resultlist.html", products = products)

if(__name__ == "__main__"):
    Server.run(debug=True)