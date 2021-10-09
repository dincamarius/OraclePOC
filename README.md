# README #

### What is this repository for? ###

This repository contains the code to set up an Oracle Database simulate situations where different scenarios of database performance improvements are tested. 
For example: 
- Oracle partitioning capabilities;
- Query optimization using materialized views;
- Performance improvement using table functions and pipelined table functions;
- Performance of bulk collect, implicit cursor, explicit cursor


### How do I get set up? ###

This repository contains the code for creating the database components(schemas, tablespaces, tables...),
automatic deploy (create all objects, load dimension tables...) and a comparison between different possibilities
of loading and aggregate data on facts tables. 
The comparison is made between pga memory consumed, uga memory consumed and the time.

    Dependencies: Oracle database 12c or higher, running on Windows 64bit
    
    Database configuration used:
    CPU	    cpu_count	            8
    MEMORY	    sga_target	            2432M
    	    pga_aggregate_target    807M
                hash_area_size	    128Kb
                bitmap_merge_area_size  1M
    	    sort_area_size	    64Kb

    
    Deployment: 
    Run "/main/deploy/database/deployDB.bat"
    All database objects will be automatically created. 

    How to run tests: 
    Test1: Run "testResults/test1.bat". It provides a comparasion between bulk collect, implicit cursor and explicit cursor.
    Test2: Run "testResults/test2.bat". It provides a comparasion between table functions and pipelined table functions.
    Test3: Run "testResults/test3.bat". It provides a comparasion between using non partitioned tables and partitioned tables.
    Test4: Run "testResults/test4.bat". It provides a comparasion when using materialized views.
    
A robust documentation can be found under documents directory.


### Contribution guidelines ###

* Writing tests
* Code review
* Other guidelines

### Who do I talk to? ###

    Mailto: dinca.marius.catalin@gmail.com