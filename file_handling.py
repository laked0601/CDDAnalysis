import re
import os
import sqlite3
from contextlib import contextmanager


def create_sqlite_connection():
    if not os.path.exists("CDDAnalysis.db"):
        open("CDDAnalysis.db").close()
    return sqlite3.connect("CDDAnalysis.db")


@contextmanager
def sql_cnxn():
    cnxn = create_sqlite_connection()
    yield cnxn
    cnxn.close()


class ContentType:
    def __init__(self, pk, name, extension):
        self.pk = pk
        self.name = name
        self.extension = extension


with sql_cnxn() as cnxn:
    crsr = cnxn.cursor()
    crsr.execute("select `PK`, `Name`, `File Extension` from `Content Types`")
    CONTENT_TYPES = [ContentType(row[0], row[1], row[2]) for row in crsr.fetchall()]

FILEPATH_SAFE_RE = re.compile(r"([\[#%&{}\\<>\*\?\/ \$!'\":@\+`\|=\]])")


def filepath_safe_string(stringobj):
    # Directory traversal prevention, modify at your own risk. For more info, visit:
    # https://owasp.org/www-community/attacks/Path_Traversal
    stringobj = stringobj.replace('\\', '/')
    while stringobj.find('../') != -1:
        stringobj = stringobj.replace('../', '/')
    while stringobj.find('./') != -1:
        stringobj = stringobj.replace('./', '/')
    while stringobj.find('//') != -1:
        stringobj = stringobj.replace('//', '/')
    directories = stringobj.split('/')
    for i, dirstr in enumerate(directories):
        directories[i] = FILEPATH_SAFE_RE.sub('_', dirstr)
    new_file_path = '/'.join(directories)
    if new_file_path[0:1] == '/':
        new_file_path = new_file_path[1:]
    return new_file_path


def get_content_type(from_header=None, from_extension=None):
    if from_header is not None:
        for content_type_obj in CONTENT_TYPES:
            if from_header.find(content_type_obj.name) != -1:
                return content_type_obj
    elif from_extension is not None:
        for content_type_obj in CONTENT_TYPES:
            if from_extension == content_type_obj.extension:
                return content_type_obj
    else:
        raise Exception("Cannot determine content type without any indicators!")


def create_new_filepath(from_dir, raw_filepath):
    base_from_dir = filepath_safe_string(from_dir)
    if not os.path.exists(base_from_dir):
        os.mkdir(base_from_dir)
    new_filepath = filepath_safe_string(raw_filepath)
    last_forward_slash = new_filepath.rfind('/')
    if last_forward_slash != -1:
        dirpath = new_filepath[0:last_forward_slash]
        dirpath_str = base_from_dir
        for dirname in dirpath.split('/'):
            dirpath_str += dirname
            if not os.path.exists(dirpath_str):
                os.mkdir(dirpath_str)
            dirpath_str += '/'
    return base_from_dir + new_filepath
