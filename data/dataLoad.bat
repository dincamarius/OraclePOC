@echo off
(echo ##################################################### 
echo ###### Start generating data in SABDADM schema ###### 
echo ##################################################### 
echo)


# load DIM_CURRENCY
sqlldr parfile=parameterFiles/dim_currency.par

# load DIM_COUNTRY
sqlldr parfile=parameterFiles/dim_country.par

sqlplus -s SABDADM/SABDADM@orcl @loadData.sql