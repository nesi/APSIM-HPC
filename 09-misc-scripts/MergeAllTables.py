
import sqlite3
import shutil
import glob


#List all DBs, will later be a supplied csv file with DB names
DBfiles = glob.glob('./PASSED_DB/*.db')
#Path and Name of new DB to be created. 
MasterDB = './MasterDB.db'

TableNames = 'SummReport'#, 'OtherTableName

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


