import pyodbc

def connection(inst):
    s = inst #Your server name
    d = 'AW_Equipo6' #Your db name
    u = 'sa' #Your login
    p = '123456' #Your login password
    cstr = 'DRIVER={ODBC Driver 17 for SQL Server};SERVER='+s+';DATABASE='+d+';UID='+u+';PWD='+ p
    conn = pyodbc.connect(cstr)
    print("Conexión Exitosa")
    return conn

