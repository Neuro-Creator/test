from app import app
from flask import render_template, make_response, request, jsonify, redirect, url_for
from werkzeug.exceptions import NotFound, ServiceUnavailable
from werkzeug.security   import generate_password_hash

from pymongo import MongoClient
import json
from bson.objectid import ObjectId
import pg8000

from flask_jwt_extended.config import config
from flask_jwt_extended import (
    JWTManager, jwt_required, jwt_optional, create_access_token,
    get_jwt_identity, set_access_cookies, unset_jwt_cookies
)

from .cfgs import ( cfg_key, get_pwd, get_key )
from .user import ( User )
from protor import ww


def get_XCsrf_Token(rq):
    if 'X-Csrf-Token' in rq.headers:
        return rq.headers['X-Csrf-Token']
    return ''


@app.after_request
def add_header(r):
    """
    Add headers to both force latest IE rendering engine or Chrome Frame,
    and also to cache the rendered page for 10 minutes.
    """
    r.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    r.headers["Pragma"] = "no-cache"
    r.headers["Expires"] = "0"

    r.headers['Cache-Control'] = 'public, max-age=0'
    return r


@app.route('/')
@app.route('/index')
def index():
    resp = make_response(render_template('index.html', user='Docker', cfg=cfg_key(32)))
    return resp, 200


@app.route('/login', methods = ['POST'])
def todo_login():
    j = request.json

    username  = j['uname']
    pwd = get_pwd(j['sid'])

    u = User(username, client)
    check = u.check_password_hash(generate_password_hash(pwd))
    data = {'result': 'okk' if check is True else 'wrong identity'}
    # Create the tokens we will be sending back to the user
    tdata = {'name': username, 'key':get_key(j['sid'])}
    access_token = create_access_token(identity=tdata)
    resp = jsonify(data)
    set_access_cookies(resp, access_token)
    return resp, 200


@app.route('/todo', methods = ['PUT'])
def todo_put():
    content = request.json
    result = db.todo.update_one({ '_id': ObjectId(content['id']) },
                                { '$set': { 'completed': content['completed'] } })
    data = {'modified_count': result.modified_count}
    return  jsonify(data) #str(result.inserted_id)


@app.route('/linkster', methods = ['PUT'])
def linkster_put():
    content = request.json
    cursor = psql_conn.cursor()
    wl   = content['weblink']
    desc = content['description']
    rate = content['rate']
    done = content['done']
    cursor.execute(('INSERT INTO linkster (weblink, description, rate, done) '
                    'VALUES (%s, %s, %s, %s) RETURNING id'), (wl, desc, rate, done))
    results = cursor.fetchall()
    data = {'modified_count': len(results)}
    psql_conn.commit()
    cursor.close()
    return jsonify(data)


@app.route('/proto', methods = ['GET'])
def proto_get():
    data = next(ww)
    return jsonify(data), 200


@app.route('/logout')
def logout():
    return redirect(url_for('index'))

