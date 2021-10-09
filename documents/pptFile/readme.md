# README #

### Project components ###
```sh
1) Source code (path <SABD/main/src/database);
2) Automatic deployment (path <SABD/main/deploy/database>);
3) Data load (path <SABD/data>);
4) Test performance scenarios (path <SABD/testResults);
```

### How do I set this up? ###
```sh
 Prerequisites: Make sure that sys password is present in orapwd file;
 Deploy: Run <SABD/main/deploy/database/deployDB.bat> and wait for  message <Deploy process finished!>
 Postrequisites: Check if automatic tests were passed. If not, compile any invalid objects;
 Data load: Run <SABD/data/dataLoad.bat> and wait for  message <Load data process finished!> 
 ```

### How do I run the test scenarios? ###

```sh
 Test1: Run <SABD/testResults/test1.bat> and wait for  message <FINISHED TEST1!>
 Test2: Run <SABD/testResults/test2.bat> and wait for  message <FINISHED TEST2!>
 Test3: Run <SABD/testResults/test3.bat> and wait for  message <FINISHED TEST3!>
 Test4: Run <SABD/testResults/test4.bat> and wait for  message <FINISHED TEST4!>
 ```

All results will be displayed in the console, with information about time of running and PGA consummation.


