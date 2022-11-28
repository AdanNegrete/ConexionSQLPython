from flask import Flask, render_template

Server = Flask(__name__)

@Server.route("/") #For default route
def main():
    return render_template("resultlist.html")

if(__name__ == "__main__"):
    Server.run()