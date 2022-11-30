from flask import Blueprint, render_template, request, url_for, redirect

principal = Blueprint('principal',__name__)

@principal.route("/") #For default route
def Index():
    return render_template("index.html")

@principal.route("/listex", methods=['POST'])
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
        
        return redirect(url_for('consulta'))