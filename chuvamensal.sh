#!/bin/bash 







echo $1 $2 $3 $4 $5 $6 $7


anof=`date +"%Y"`
mesf=`date +"%m"`
diaf=`date +"%d"`

anoi=`date +"%Y" -d"365 days ago"`
mesi=`date +"%m" -d"365 days ago"`
diai=`date +"%d" -d"365 days ago"`



case $1 in 
	opera)
	
		export CPC_ANO_f=$anof
		export CPC_MES_f=$mesf
		export CPC_DIA_f=$diaf
		export CPC_ANO_i=$anoi
		export CPC_MES_i=$mesi
		export CPC_DIA_i=$diai
        ncl cpc.ncl 
		mkdir -p ./OUTPUT/`date +"%Y%m%d"`/
		mv CHUVACPCMENSAL* ./OUTPUT/`date +"%Y%m%d"`/
		ncl cfs.ncl  
		mkdir -p ./OUTPUT/`date +"%Y%m%d"`/
		mv CFSMENSAL* ./OUTPUT/`date +"%Y%m%d"`/
		;;

	cpc)
		export CPC_ANO_f=$anof
		export CPC_MES_f=$mesf
		export CPC_DIA_f=$diaf
		export CPC_ANO_i=$anoi
		export CPC_MES_i=$mesi
		export CPC_DIA_i=$diai
                ncl cpc.ncl
		mkdir -p ./OUTPUT/`date +"%Y%m%d"`/
		mv CHUVACPCMENSAL* ./OUTPUT/`date +"%Y%m%d"`/
		;;

	cfs)
		export CPC_ANO_f=$anof
		export CPC_MES_f=$mesf
		export CPC_DIA_f=$diaf
		export CPC_ANO_i=$anoi
		export CPC_MES_i=$mesi
		export CPC_DIA_i=$diai
                ncl cfs.ncl  
		mkdir -p ./OUTPUT/`date +"%Y%m%d"`/
		mv CFSMENSAL* ./OUTPUT/`date +"%Y%m%d"`/
		;;

esac 		
		
rm *.grb2 
#rm *.RT
rm job* 

#
# processo CPC 
#

