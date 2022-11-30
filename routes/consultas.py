from flask import Blueprint, render_template, request, url_for, redirect, flash
from utils.db_con import connection

consultas = Blueprint('consultas',__name__)
consultas.secret_key="ScrtKy"

# Variables Globales
inst=''
instancias={
    'sales': 'NEGA-PC',
    'production': 'NEGA-PC',
    'other': 'NEGA-PC'
}

@consultas.route("/") #For default route
def Index():
    return render_template("index.html")

@consultas.route("/listex", methods=['POST'])
def listex():
    global inst, instancias
    if request.method == 'POST':
        
        opt=request.form['Instancia']    
        
        if opt == '01':
            inst=instancias.get('sales')
        elif opt == '02':
            inst=instancias.get('production')
        elif opt == '03':
            inst=instancias.get('other')    
        
        return redirect(url_for('consultas.consulta'))

@consultas.route("/consulta")
def consulta():
    products = []
    global inst
    if inst == '':
        flash('Error en la instancia seleccionada')
        return redirect(url_for('consultas.Index'))
    conn = connection(inst)
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM Production.product")
    for row in cursor.fetchall():
        products.append({"id": row[0], "name": row[1], "lsprice": row[2]})
    conn.close()
    return render_template("resultlist.html", products = products)
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
@consultas.route("/consulta_a")
def consulta_a():
    global instancias
    global inst
    categories = []
    conn = connection(inst)
    cursor = conn.cursor()
    cursor.execute("EXEC dbo.usp_CategoryList ?",instancias.get('production'))
    print(cursor)
    for row in cursor.fetchall():
        categories.append({"id": row[0], "name": row[1]})
    conn.close()
    return render_template('consulta_a.html', categories = categories)

@consultas.route("/consatrr", methods=['POST'])
def consatrr():
    global inst
    global instancias
    if request.method == 'POST':
        opt=request.form['Categoria']
        ventas = []
        if inst == '':
            flash('Error en la instancia seleccionada')
            return redirect(url_for('consultas.Index'))
        conn = connection(inst)
        cursor = conn.cursor()
        cursor.execute("EXEC dbo.usp_ConsATVTerr ?,?,?",opt,instancias.get('sales'),instancias.get('production'))
        
        for row in cursor.fetchall():
            ventas.append({"TerrName": row[0], "VentasTotales": row[1]})
        conn.close()

        return redirect(url_for('consultas.consulta_a'))
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
@consultas.route("/consulta_b")
def consulta_b():
    return "Consulta B"