from flask import Blueprint, render_template, request, url_for, redirect, flash
from utils.db_con import connection

consultas = Blueprint('consultas',__name__)
consultas.secret_key="ScrtKy"

# ~~~~~~~~~~~~~~~~ Variables Globales ~~~~~~~~~~~~~~~~
inst=''
instancias={
    'sales': 'NEGA-PC',
    'production': 'NEGA-PC',
    'other': 'NEGA-PC'
}

# ~~~~~~~~~~~~~~~~ Métodos Auxiliares (Listas) ~~~~~~~~~~~~~~~~
def complete_SelCat():
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
    return categories

def complete_SelProd():
    global instancias
    global inst
    products = []
    conn = connection(inst)
    cursor = conn.cursor()
    cursor.execute("EXEC dbo.usp_ProductList ?",instancias.get('production'))
    print(cursor)
    for row in cursor.fetchall():
        products.append({"id": row[0], "name": row[1]})
    conn.close()
    return products

def complete_SelReg():
    global instancias
    global inst
    regions = []
    conn = connection(inst)
    cursor = conn.cursor()
    cursor.execute("EXEC dbo.usp_RegionList ?",instancias.get('sales'))
    print(cursor)
    for row in cursor.fetchall():
        regions.append({"group": row[0]})
    conn.close()
    return regions

def complete_SelLoc():
    global instancias
    global inst
    locations = []
    conn = connection(inst)
    cursor = conn.cursor()
    cursor.execute("EXEC dbo.usp_LocationList ?",instancias.get('production'))
    print(cursor)
    for row in cursor.fetchall():
        locations.append({"id": row[0], "name": row[1]})
    conn.close()
    return locations

def complete_SelMet():
    global instancias
    global inst
    methods_u = []
    conn = connection(inst)
    cursor = conn.cursor()
    cursor.execute("EXEC dbo.usp_MethodList ?",instancias.get('other'))
    
    for row in cursor.fetchall():
        methods_u.append({"id": row[0], "name": row[1]})
    conn.close()
    return methods_u

def complete_SelTerr():
    global instancias
    global inst
    territories = []
    conn = connection(inst)
    cursor = conn.cursor()
    cursor.execute("EXEC dbo.usp_TerritoryList ?",instancias.get('other'))
    
    for row in cursor.fetchall():
        territories.append({"id": row[0], "name": row[1], "group": row[2]})
    conn.close()
    return territories


# ~~~~~~~~~~~~~~~~ Métodos Principales (render y controlers) ~~~~~~~~~~~~~~~~

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
# Consulta A
@consultas.route("/consulta_a")
def consulta_a():
    categories = complete_SelCat()
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
        categories = complete_SelCat()
        return render_template('consulta_a.html', ventas = ventas, categories = categories)
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Consulta B
@consultas.route("/consulta_b")
def consulta_b():
    regions=complete_SelReg()
    return render_template('consulta_b.html', regions=regions)

@consultas.route("/consb", methods=['POST'])
def consb():
    global inst
    global instancias
    if request.method == 'POST':
        opt=request.form['Region']
        productos = []
        rowx=''
        if inst == '':
            flash('Error en la instancia seleccionada')
            return redirect(url_for('consultas.Index'))
        conn = connection(inst)
        cursor = conn.cursor()
        
        #Se obtiene el producto con el primer procedimiento
        cursor.execute("EXEC dbo.usp_ConsBProdSol ?,?,?",opt,instancias.get('sales'),instancias.get('production'))
        row=cursor.fetchone()
        rowx=str(row[2])
        print(rowx)
        #Se ejecuta otro query para obtener el valor del segundo procedimiento
        cursor.execute("EXEC dbo.usp_ConsBTerr ?,?,?",opt,str(rowx),instancias.get('sales'))
        row_f = cursor.fetchone()
        productos.append({"TVentas": row[0], "Name": row[1], "Id": row[2], "Region": opt, "Territory": row_f[0]})
        
        conn.close()
        regions=complete_SelReg()

        return render_template('consulta_b.html', productos = productos, regions = regions)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Consulta C
@consultas.route("/consulta_c")
def consulta_c():
    locations = complete_SelLoc()
    categories = complete_SelCat()
    return render_template('consulta_c.html', locations = locations, categories = categories)

@consultas.route("/consc", methods=['POST'])
def consc():
    global inst
    global instancias
    if request.method == 'POST':
        opt_cat=request.form['Categoria']
        opt_loc=request.form['Localidad']
        print(opt_cat+'   '+opt_loc)
        if not(opt_cat != '' and opt_loc != ''):
            flash('Formulario incompleto')
            return redirect(url_for('consultas.consulta_c'))
        conn = connection(inst)
        cursor = conn.cursor()
        cursor.execute("EXEC dbo.usp_ConsCUpdtProd ?,?,?",opt_loc,opt_cat,instancias.get('production'))
        row=cursor.fetchone()
        respuesta = row[0];
        conn.commit()
        conn.close()
        
        if respuesta == 'Success':
            flash('Valor Actualizado Correctamente')
            return redirect(url_for('consultas.consulta_c'))
        elif respuesta == 'NoProducts':
            flash('No hay Productos de esa Categoría en la Localidad.')
            return redirect(url_for('consultas.consulta_c'))
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Consulta E
@consultas.route("/consulta_e")
def consulta_e():
    products = complete_SelProd()
    return render_template('consulta_e.html', products = products)

@consultas.route("/conse", methods=['POST'])
def conse():
    global inst
    global instancias
    if request.method == 'POST':
        opt_ord=request.form['Orden']
        opt_pro=request.form['Producto']
        opt_can=request.form['Cantidad']
        if not(opt_can != '' and opt_ord != ''):
            flash('Formulario incompleto')
            return redirect(url_for('consultas.consulta_e'))
        conn = connection(inst)
        cursor = conn.cursor()
        cursor.execute("EXEC dbo.usp_ConsEUpdtSales ?,?,?,?,?",opt_can,opt_ord,opt_pro,instancias.get('sales'),instancias.get('production'))
        row=cursor.fetchone()
        respuesta = row[0];
        conn.commit()
        conn.close()
        print (opt_can+'  '+respuesta)
        if respuesta == 'Success':
            flash('Valor Actualizado Correctamente')
            return redirect(url_for('consultas.consulta_e'))
        elif respuesta == 'NoProducts':
            flash('No hay Suficientes Productos en Existencia.')
            return redirect(url_for('consultas.consulta_e'))
        elif respuesta == 'NoOrder':
            flash('El Producto No se Encuentra en la Orden.')
            return redirect(url_for('consultas.consulta_e'))
        elif respuesta == 'Fail':
            flash('Error al actualizar datos')
            return redirect(url_for('consultas.consulta_e'))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Consulta F
@consultas.route("/consulta_f")
def consulta_f():
    methods_u = complete_SelMet()
    return render_template('consulta_f.html', methods_u = methods_u)

@consultas.route("/consf", methods=['POST'])
def consf():
    global inst
    global instancias
    if request.method == 'POST':
        opt_ord=request.form['Orden']
        opt_met=request.form['Metodo']
        if not(opt_met != '' and opt_ord != ''):
            flash('Formulario incompleto')
            return redirect(url_for('consultas.consulta_f'))
        conn = connection(inst)
        cursor = conn.cursor()
        cursor.execute("EXEC dbo.usp_ConsFUpdtMet ?,?,?,?",opt_met,opt_ord,instancias.get('sales'),instancias.get('other'))
        row=cursor.fetchone()
        respuesta = row[0];
        conn.commit()
        conn.close()
        
        if respuesta == 'Success':
            flash('Valor Actualizado Correctamente')
            return redirect(url_for('consultas.consulta_f'))
        elif respuesta == 'NotOrder':
            flash('No se encontró la orden solicitada')
            return redirect(url_for('consultas.consulta_f'))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Consulta G
@consultas.route("/consulta_g")
def consulta_g():
    return render_template('consulta_g.html')

@consultas.route("/consg", methods=['POST'])
def consg():
    global inst
    global instancias
    if request.method == 'POST':
        opt_ctm=request.form['Customer']
        opt_eml=request.form['Email']
        if not(opt_ctm != '' and opt_eml != ''):
            flash('Formulario incompleto')
            return redirect(url_for('consultas.consulta_g'))
        conn = connection(inst)
        cursor = conn.cursor()
        cursor.execute("EXEC dbo.usp_ConsGUpdtEml ?,?,?,?",opt_ctm,opt_eml,instancias.get('sales'),instancias.get('other'))
        row=cursor.fetchone()
        respuesta = row[0];
        conn.commit()
        conn.close()
        
        if respuesta == 'Success':
            flash('Valor Actualizado Correctamente')
            return redirect(url_for('consultas.consulta_g'))
        elif respuesta == 'NoCustomer':
            flash('No se ha encontrado un cliente con la id ingresada')
            return redirect(url_for('consultas.consulta_g'))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Consulta H
@consultas.route("/consulta_h")
def consulta_h():
    territories = complete_SelTerr()
    return render_template('consulta_h.html', territories=territories)


@consultas.route("/consh", methods=['POST'])
def consh():
    global inst
    global instancias
    if request.method == 'POST':
        opt=request.form['Territorio']
        personas = []
        if inst == '':
            flash('Error en la instancia seleccionada')
            return redirect(url_for('consultas.Index'))
        conn = connection(inst)
        cursor = conn.cursor()
        cursor.execute("EXEC dbo.usp_ConsHMejEmp ?,?,?",opt,instancias.get('sales'),instancias.get('other'))
        
        for row in cursor.fetchall():
            personas.append({"ID": row[0], "nombre": row[1], "apellido": row[2], "pedidos": row[3], "territorio": row[4], "region": row[5]})
        conn.close()
        territories = complete_SelTerr()
        return render_template('consulta_h.html', territories = territories, personas = personas)
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Consulta I
@consultas.route("/consulta_i")
def consulta_i():
    return render_template('consulta_i.html')

@consultas.route("/consi", methods=['POST'])
def consi():
    global inst
    global instancias
    if request.method == 'POST':
        ventas=[]
        opt=request.form['daterange']
        if opt == '':
            flash('No se han seleccionado fechas')
            return redirect(url_for('consultas.consulta_i'))
        
        fechas = opt.split(" - ")
        
        fechaini=fechas[0].split("/")
        fecha_i=fechaini[2]+'-'+fechaini[0]+'-'+fechaini[1]
        
        fechafin=fechas[1].split("/")
        fecha_f=fechafin[2]+'-'+fechafin[0]+'-'+fechafin[1]

        conn = connection(inst)
        cursor = conn.cursor()
        cursor.execute("EXEC usp_ConsITotVen ?,?,?",fecha_i,fecha_f,instancias.get('sales'))
        for row in cursor.fetchall():
            ventas.append({"Region": row[0], "VentasTotales": row[1]})
        conn.close()
        return render_template('consulta_i.html', ventas = ventas)
