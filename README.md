# tarantool-sql
The sql wrapper on the NoSQL datastore tarantool (www.tarantool.org)

# initialize
   
    require('sql')
    
# SELECT
    
    local test = box.schema.create_space('test')                        -- in project: CREATE SHEMA 'test'
    test:create_index('id', {type='tree', {parts = {1, 'unsigned'}})    -- in project: CREATE PRIMARY INDEX 'id' ON (1 unsigned)
    test:create_index('type',{unique = false, parts={2,'unsigned'}  }   -- in project: CREATE TREE INDEX 'id' ON (2 unsigned)
    
    sql('insert into test values(1,2,3)')
    sql('insert into test values(2,2,4)')
    sql('insert into test values(3,2,5)')
    sql('insert into test values(5,1,4)')
    sql('insert into test values(6,1,5)')
    sql('insert into test values(7,1,8)')
    sql('insert into test values(9,1,9)')
    
    sql ('select * from test where type=2')
    ---
    - - [3, 2, 5]
      - [2, 2, 4]
      - [1, 2, 3]
     ...

    sql ('select * from test where id=2')
    ---
    - - [2, 2, 4]
    ...
    
    sql ('select * from test where id > 5')
    ---
    - - [6, 1, 5]
      - [7, 1, 8]
      - [9, 1, 9]
    ...
    
    sql ('select * from test where id > 5')
    - 3
    
    sql ('select * from test')          --- show all records
    
    delete from test where id =1        --- delete only by primary key
    
    
    
