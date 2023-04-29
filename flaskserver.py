from flask import Flask, redirect, render_template, request, send_file
from file_handling import sql_cnxn
from flask_wtf.csrf import CSRFProtect
from wtforms import Form, StringField, IntegerField, SelectField
from wtforms.validators import number_range
import json
import os
import csv


app = Flask(__name__)
csrf = CSRFProtect()
SECRET_KEY = os.urandom(32)
app.config['SECRET_KEY'] = SECRET_KEY

if os.path.exists("DataSources.txt"):
    with open("DataSources.txt", 'r', encoding="utf-8") as rf:
        DataSources = [x.strip() for x in rf.read().split('\n')]
else:
    with sql_cnxn() as cnxn:
        crsr = cnxn.cursor()
        crsr.execute("select distinct DataSource from Individuals")
        DataSources = [x[0] for x in crsr.fetchall()]
        crsr.execute("select * from Individuals")
        with open("Individuals.csv", 'w', encoding="utf-8", newline="") as wf:
            writer = csv.writer(wf, delimiter=",", quotechar='"')
            writer.writerow([x[0] for x in crsr.description])
            res = crsr.fetchone()
            while res is not None:
                writer.writerow(['' if x is None else str(x) for x in res])
                res = crsr.fetchone()
    with open("DataSources.txt", 'w', encoding="utf-8") as wf:
        wf.write('\n'.join(DataSources))


@app.route("/")
def hello_world():
    return redirect("/ind/index.html")


@app.route("/ind/index.html")
def cdd_html():
    return render_template("cdd.html", datasources=DataSources)


@app.route("/ind/Individuals.zip")
def cdd_csv():
    return send_file("Individuals.zip", mimetype="application/zip")


class CDDForm(Form):
    name = StringField("name")
    nationality = StringField("nationality")
    sanctions = StringField("sanctions")
    notes = StringField("notes")
    dob = StringField("dob")
    page = IntegerField("page", [number_range(min=1, max=999999)])
    datasource = SelectField("datasource", choices=[(x, x) for x in DataSources + ['']])


@app.route("/resources/loading.gif")
def loading_gif():
    return send_file("loading.gif", mimetype="image/gif")


@app.route("/ind/api", methods=["GET"])
def cdd_api():
    form = CDDForm(request.args)
    res = form.validate()
    if res:
        with sql_cnxn() as cnxn:
            crsr = cnxn.cursor()
            page_int = int(form.page.data)
            parameters = [form.name.data, "%" + form.name.data.lower().strip().replace(' ', '%') + "%",
                          form.nationality.data, "%" + form.nationality.data.lower().strip().replace(' ', '%') + "%",
                          form.sanctions.data, "%" + form.sanctions.data.lower().strip().replace(' ', '%') + "%",
                          form.dob.data, "%" + form.dob.data.lower().strip().replace(' ', '%') + "%",
                          form.notes.data, "%" + form.notes.data.lower().strip().replace(' ', '%') + "%",
                          form.datasource.data, form.datasource.data, ]
            select_filter = (
                "from Individuals "
                "where (? = '' or FullName like ?) "
                "and (? = '' or Nationality like ?) "
                "and (? = '' or Sanctions like ?) "
                "and (? = '' or DOB like ?) "
                "and (? = '' or Notes like ?) "
                "and (? = '' or DataSource = ?) "
                "order by DataSource, DataSourceID "
            )
            crsr.execute(
                "select "
                "   DataSource, DataSourceID, FullName, NameType, Sanctions, Notes, Gender, Nationality, "
                "   substr(DOB, 0, 10) as `DateOfBirth` "
                "%s limit ?, 200" % (select_filter,),
                parameters + [(page_int - 1) * 200]
            )
            headers = [x[0] for x in crsr.description]
            result = {"rows": []}
            for row in crsr.fetchall():
                result["rows"].append({head: val for head, val in zip(headers, row)})
            crsr.execute(
                "select count(DataSource) "
                "%s" % (select_filter,),
                parameters
            )
            res = crsr.fetchone()
            result["totalrows"] = res[0]
        return app.response_class(
            response=json.dumps(result),
            status=200,
            mimetype="application/json"
        )
    else:
        return app.response_class(
            response=json.dumps(form.errors),
            status=400,
            mimetype="application/json"
        )
