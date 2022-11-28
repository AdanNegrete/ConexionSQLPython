from flask import Flask, render_template
import pyodbc

Server = Flask(__name__)

def connection():
    s = 'NEGA-PC' #Your server name 
    d = 'AdventureWorks' 
    u = 'sa' #Your login
    p = '123456' #Your login password
    cstr = 'DRIVER={ODBC Driver 17 for SQL Server};SERVER='+s+';DATABASE='+d+';UID='+u+';PWD='+ p
    conn = pyodbc.connect(cstr)
    return conn

@Server.route("/") #For default route

def main():
    products = []
    conn = connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM Production.product")
    for row in cursor.fetchall():
        products.append({"id": row[0], "name": row[1], "lsprice": row[2]})
    conn.close()
    return render_template("resultlist.html", products = products)

def main():
    return render_template("resultlist.html")

if(__name__ == "__main__"):
    Server.run()