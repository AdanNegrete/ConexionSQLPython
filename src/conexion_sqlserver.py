import pyodbc

try:
    conection=pyodbc.connect('DRIVER={Sql Server}; SERVER=NEGA-PC;DATABASE:AdventureWorks2019;UID=sa;PWD:123456')
    print("Conexión Exitosa")
except Exception as ex:
    print(ex)
finally:
    conection.close()