import sqlite3
open("CDDAnalysis.db", 'w').close()
cnxn = sqlite3.connect("CDDAnalysis.db")
crsr = cnxn.cursor()
with open("CreateStructure.sql", 'r', encoding="utf-8") as rf:
    content = rf.read()
    x = 0
    next_pos = content.find(';') + 1
    line = content[x:next_pos]
    while line != '':
        line = content[x:next_pos]
        crsr.execute(line)
        x = next_pos
        next_pos = content.find(';', x) + 1
        line = content[x:next_pos]
cnxn.commit()
cnxn.close()