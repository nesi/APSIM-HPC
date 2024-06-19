# -*- coding: utf-8 -*-
"""
Created on Wed May  8 13:33:22 2024

@author: hartvigssono
"""

import sqlite3
import shutil
import glob
import pandas

###TODO:
##Open up the _Messages table, look at last row, if grepl(normally) then good, else bad. 
##If bad, dont add to db AND create list of bad simulations. 
##If good, add to MasterDB and remove individual file. 


#List all DBs, will later be a supplied csv file with DB names
DBFiles = glob.glob('C:/R_projects/ApsimAutomation/*.db')
DBfiles = pandas.read_csv('C:/R_projects/ApsimAutomation/DBNames.csv')
DBfiles = list(DBfiles.values.flatten())
#Path and Name of new DB to be created. 
MasterDB = 'C:/R_projects/ApsimAutomation/MasterDB.db'

TableNames = 'SummReport', 'Report2Test'

#Create Master DB by copying the first DB file and renaming it to desired name and place 
shutil.copyfile(DBfiles[0], MasterDB)

#Set up connection to the Master DB
conn1 = sqlite3.connect(MasterDB) 
cursor1 = conn1.cursor() 

#Loop where DBs are opened 1 by 1 (starting from no 2) and appended to the Master DB
for i in range(1,len(DBfiles)):
    conn2 = sqlite3.connect(DBfiles[i]) 
    cursor2 = conn2.cursor()
    
    if type(TableNames) == str:
        data2 = cursor2.execute('SELECT * FROM ' + TableNames).fetchall()
        cursor1.executemany('INSERT INTO ' + TableNames + ' VALUES (?' + ', ?'*(len(data2[1])-1) + ')', data2)
    elif type(TableNames == tuple):
        for j in range(0, len(TableNames)):
            data2 = cursor2.execute('SELECT * FROM ' + TableNames[j]).fetchall()
            cursor1.executemany('INSERT INTO ' + TableNames[j] + ' VALUES (?' + ', ?'*(len(data2[1])-1) + ')', data2)
    else:
        print('Invalid TableName')
    conn1.commit()
    conn2.close()


conn1.close() 


