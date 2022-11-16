load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_inv_string.ncl"


;-------------------------------------------------------------------
;
;  imprime tabla com a chuva media baseada na matrix gerada por 
;  calcbacia() 	
;
;  by regis reginaldo.venturadesa@gmail.com 
;
;  criando em 31/10/2021
;
;  O script precisa das seguintes variaveis ambientes  
;
;
;
;;--------------------------------------------------
function print_calcbacia_mes( M , config  )
begin

	d=dimsizes(M)
	
 	num_shapes=d(0)
	num_meses=d(1)
	vetor=ispan(0,num_meses,1)
	
	shapenames=M@shapenames
	periodo=M@periodo
	units="months from "+sprinti("%d",periodo(0))+"-"+sprinti("%02d",periodo(1))+"-"+sprinti("%02d",periodo(2))+" 00:00:00"
	vetor@units=units
	tempos=cd_calendar(vetor,-5) 
	print(tempos)



	; 
	;
	;

	do j=0,num_shapes-1
		filename="CHUVACPCMENSAL_"+shapenames(j)+".dat"
		print(filename+" "+j)
		do i=0,num_meses-1
		   linha_data=sprintf("%4.0f",tempos(i,0))+" "+sprintf("%2.0f",tempos(i,1))+" 01 "	
		   valores=sprintf("%06.2f ",M(j,i,1))
	
			
			alist=[/linha_data,valores/] 
			
		
			write_table(filename,"a",alist,"%s %s")	 
			 
		 end do
		
    end do
;;write_table(fname, "a", alist, "%d%16.2f%s%d%ld")
return(0)
end



;-------------------------------------------------------------------
;
;  calcula chuva mensal 
;
;  by regis reginaldo.venturadesa@gmail.com 
;
;  criando em 31/10/2021
;
;  O script precisa das seguintes variaveis ambientes  
;
;
;
;;--------------------------------------------------
function calcbacia_mensal( files , shapefiles, config)  

begin
	
	;
	;
	;
		
	 
	num_files=dimsizes(files)
	
	num_shapes=dimsizes(shapefiles)

	
	
	
	num_dias_mes=(/31,28,31,30,31,30,31,31,30,31,30,31/) 
	
	fi=addfiles(files,"r")

	chuva=fi[:]->chuva_cpc
	lat=fi[0]->lat
	lon=fi[0]->lon
			;
		; dimesnoes 
		;
		nlat=dimsizes(lat)
		nlon=dimsizes(lon) 
	tempos=tointeger((cd_calendar(cd_inv_string(fi[:]->date,"%Y%N%D"),0)))
	temposx=(cd_calendar(cd_inv_string(fi[:]->date,"%Y%N%D"),3))
			
	anoi=tointeger(tempos(0,0))
	anof=tointeger(tempos(num_files-1,0))
	mesi=tointeger(tempos(0,1))
	mesf=tointeger(tempos(num_files-1,1))
	diai=tointeger(tempos(0,2))
	diaf=tointeger(tempos(num_files-1,2))
	
	periodo=((/anoi,mesi,diai,anof,mesf,diaf/)) 


	
	
	units="months from "+sprinti("%d",anoi)+"-"+sprinti("%02d",mesi)+"-"+sprinti("%02d",diai)+" 00:00:00"
	indice=tointeger(cd_inv_calendar(tempos(:,0),tempos(:,1),tempos(:,2),tempos(:,3),tempos(:,4),tempos(:,5),units,0))


	units="months from "+sprinti("%d",config@anoi)+"-"+sprinti("%02d",config@mesi)+"-"+sprinti("%02d",config@diai)+" 00:00:00"
	indice_inicial=cd_inv_calendar(anoi,mesi,diai,0,0,0,units,0)
	indice_final=cd_inv_calendar(anof,mesf,diaf,0,0,0,units,0)
    num_meses=tointeger(abs((indice_final-indice_inicial)))+1


	 
	chuva_mensal=new((/num_meses,nlat,nlon/),"float",-9999) 
	chuva_mensal!0="months"
	chuva_mensal!1="lat"
	chuva_mensal!2="lon"
	chuva_mensal&lat=lat
	chuva_mensal&lon=lon
	
	
	do m=0,num_meses-1
		chuva_mensal(m,:,:)=dim_avg_n(chuva(ind(indice.eq.m),:,:),0) 
	end do 
	printVarSummary(chuva_mensal)

  




	shapename=new((/num_shapes/),"string") 
	MM=new((/num_shapes,num_meses,2/),"float",-9999)
    
	do i=0,num_meses-1
		data=chuva_mensal(i,:,:)
		print("Calculando mes "+i)

	
		do j=0,num_shapes-1
			svar1=str_get_field(shapefiles(j),3,"/")
			svar=str_get_field(svar1,1,".")
			shapename(j)=svar	
			data_mask = new(dimsizes(data),typeof(data),data@_FillValue)
			copy_VarCoords(data,data_mask)
			f=addfile(shapefiles(j), "r")
			if (config@lon360)
				mrb_lon = f->x
			else
				mrb_lon = f->x+360
			end if
			mrb_lat = f->y
			
			
			nmrb    = dimsizes(mrb_lon)
			min_mrb_lat = min(mrb_lat)
			max_mrb_lat = max(mrb_lat)
			min_mrb_lon = min(mrb_lon)
			max_mrb_lon = max(mrb_lon)
			limites_shp=((/min_mrb_lat,min_mrb_lon,max_mrb_lat,max_mrb_lon/))
	
			if (config@modelo .eq. "CFS" .or. config@modelo .eq. "GFS")
				;print(" GFS lat invertida encontrada ") 
				ilt_mn = ind(min_mrb_lat.lt.lat)
				ilt_mx = ind(max_mrb_lat.gt.lat)
				iln_mn = ind(min_mrb_lon.gt.lon)
				iln_mx = ind(max_mrb_lon.lt.lon)
				ilt2 = ilt_mn(dimsizes(ilt_mn)-1)    ; Start of lat box
				iln1   = iln_mn(dimsizes(iln_mn)-1)    ; Start of lon box
				ilt1   = ilt_mx(0)                     ; End of lat box
				iln2   = iln_mx(0)                     ; End of lon box
				;print(ilt1 +" "+iln1 +" "+ilt2 +" "+iln2) 
			else
				ilt_mn = ind(min_mrb_lat.gt.lat)
				ilt_mx = ind(max_mrb_lat.lt.lat)
				iln_mn = ind(min_mrb_lon.gt.lon)
				iln_mx = ind(max_mrb_lon.lt.lon)
				ilt1   = ilt_mn(dimsizes(ilt_mn)-1)    ; Start of lat box
				iln1   = iln_mn(dimsizes(iln_mn)-1)    ; Start of lon box
				ilt2   = ilt_mx(0)                     ; End of lat box
				iln2   = iln_mx(0)                     ; End of lon box
				;print(ilt1 +" "+iln1 +" "+ilt2 +" "+iln2) 
			end if
			;
			;  
			; 
			;
			do ilt=ilt1,ilt2
				do iln=iln1,iln2

					if	(gc_inout(lat(ilt),lon(iln),mrb_lat,mrb_lon)) then
						data_mask(ilt,iln) = data(ilt,iln)
					
					end if
				end do
			end do
			num_pontos_inside=num(.not.ismissing(data_mask)) 
			var=where(data_mask .le. 0.2,1,0)
            seca=sum(var)		
			var:=where(data_mask .gt. 0.2,1,0)
            umida=sum(var)		
			soma = sum(data_mask)
	         
			if (num_pontos_inside .gt. 0 )
	
			
				MM(j,i,0)=(sum(data_mask)/num_pontos_inside)
				MM(j,i,1)=sum(data_mask)
			
				
				
			
			
			end if
			
		    delete(f)
			delete(mrb_lon)
			delete(mrb_lat)
			delete(ilt_mn)
			delete(ilt_mx)
			delete(iln_mn)
			delete(iln_mx)
			delete(data_mask)

		end do	
		
		
    end do

	MM@info="media,soma,seca,umida,num_pontos_dentro do shpe, minlat,minlon,maxlat,maxlon,ano,mes,dia,hora,minuto"
    MM@shapenames=shapename
	MM@periodo=periodo
	MM@_FillValue=-1
	return(MM)
end 









;-------------------------------------------------------------------
;
; cria o netcdf do arquivo binario do CPC
;
;  by regis reginaldo.venturadesa@gmail.com 
;
;  criando em 31/10/2021
;
;  O script precisa das seguintes variaveis ambientes  
;
;
;
;;--------------------------------------------------
function cria_cpc_netcdf( filename ,config )
begin
	;print(" INPUT:"+filename) 
 	setfileoption("nc","Format","Classic")       
   
	
	scale     = 0.1                      ; see documentation or GrADS ctl
	ntim      = 1                        ; added for netCDF purposes only
	nlat      = 360   
	mlon      = 720 
	lat       = -89.75 + ispan(0,nlat-1,1)*0.50  
	lon       =   0.25 + ispan(0,mlon-1,1)*0.50 
	lat!0     = "lat"             ;latitude
	lat&lat   =  lat
	lat@long_name = "latitude"
	lat@units     = "degrees_north"     
	lon!0     = "lon"                   ;longitude
	lon&lon   =  lon
	lon@long_name = "longitude"
	lon@units     = "degrees_east"
    ;
	setfileoption("bin","ReadByteOrder","LittleEndian")
    ;
    cpc      = fbindirread(filename,0, (/ntim,nlat,mlon/),"float")
	cpc@_FillValue = -999.0                           ; GrADS ctl: undef -999.0

    date_str = str_get_field(filename, 5, ".")        ; yyyymmdd as a string

     if (scale.ne.1.0) then
         cpc = cpc*scale                               ; scale (if appropriate)
     end if

     cpc@_FillValue  = -999.0
     cpc@units       = "mm/day"
     cpc@long_name   = "CPC_UNI_precip"
	 
  
     print(filename+": min="+sprintf("%6.3f", min(cpc)) \
                   +"  max="+sprintf("%6.3f", max(cpc)) )
  
     cpc!0    = "time"                  ; netCDF purposes only
     cpc!1    = "lat"                   ; name the dimensions
     cpc!2    = "lon"
     cpc&lat  =  lat                    ; create coordinate variable
     cpc&lon  =  lon                    ; create coordinate variable

   
	   	;-------------------------------------------------------------------
		;
		;    RECORTE
		;
		;
		if (config@recorte)
			cpc_out=cpc(:,{config@lat0:config@lat1},{config@lon0:config@lon1})
			cpc_out@long_name   = "CPC_UNI_precip "+config@descricao 
		else 
			cpc_out=cpc 
	   
		end if 
	
	
         yyyy     = toint(str_get_cols(date_str,  0, 3))    ; yyyymmdd as integer 
         mm       = toint(str_get_cols(date_str,  4, 5))    ; mm
         dd       = toint(str_get_cols(date_str,  6, 7))    ; dd
         hh       = 12             ; center of 'mass' for the day
         mn       = 0

         tunits   = "hours since 1979-01-01 00:00:0.0"   ; arbitrary start time
         time    := cd_inv_calendar(yyyy,mm,dd,hh,mn,0d0,tunits, 0)
         time!0   = "time"
         cpc_out&time = time           ; associate 'time' with the variable
  
         date    := yyyy*10000 + mm*100 + dd
         date@units = "yyyymmdd"
         date!0   = "time"
         date&time=  time
  
         datesec := hh*3600                              ; match model 
         datesec@units = "current seconds of current date"
         datesec!0     = "time"
         datesec&time  =  time
         
         nline  = inttochar(10)
  
         globeAtt              = True
         globeAtt@title        = "CPC Unified 0.50 Daily"    
		 globeAtt@netCDF  	   = "netCDF-3"
         globeAtt@ftp          = nline + \
         "http://ftp.cpc.ncep.noaa.gov/precip/CPC_UNI_PRCP/"
  
         globeAtt@description  = nline + \
         "https://climatedataguide.ucar.edu/guidance/cpc-unified-gauge-based-analysis-global-daily-precipitation"
  
         globeAtt@references   = "A list of references is at: " + nline + \
         "http://ftp.cpc.ncep.noaa.gov/precip/CPC_UNI_PRCP/GAUGE_GLB/DOCU/"
       
         globeAtt@creation_date= systemfunc ("date" )
       
	   
	   
	   

	   
	   
	   
	   
	   
	   
         NCPATH = config@prefixo+"_"+date_str+ ".nc"
		 ncdf   = addfile(NCPATH,"c")     
		
         fileattdef(ncdf, globeAtt )         ; create the global [file] attributes
         filedimdef(ncdf,"time",-1,True)     ; make time and UNLIMITED dimension 
                                             ; recommended  for most applications
         ncdf->date    = date
         ncdf->datesec = datesec
         ncdf->chuva_cpc = cpc_out
		 return(cpc_out)
end 



;-------------------------------------------------------------------
;
;  cria um script em bash que baixa os arquivos necessarios
;
;  by regis reginaldo.venturadesa@gmail.com 
;
;  criando em 31/10/2021
;
;  O script precisa das seguintes variaveis ambientes  
;
;
;
;;--------------------------------------------------
function baixa_cpc( data_inicial , data_final , config)
begin 


  data_base=(/1979,1,1,0,0,0/)
  units="days from "+sprinti("%d",data_base(0))+"-"+sprinti("%02d",data_base(1))+"-"+sprinti("%02d",data_base(2))+" 00:00:00"
  t0=tointeger(cd_inv_calendar(data_base(0),data_base(1),data_base(2),data_base(3),data_base(4),data_base(5),units,0))
  t1=tointeger(cd_inv_calendar(data_inicial(0),data_inicial(1),data_inicial(2),data_inicial(3),data_inicial(4),data_inicial(5),units,0))
  tf=tointeger(cd_inv_calendar(data_final(0),data_final(1),data_final(2),data_final(3),data_final(4),data_final(5),units,0))
  
  vetor=ispan(tointeger(t1),tointeger(tf),1)
  vetor@units=units

  yyyymmdd=cd_calendar(vetor,-2)
  itime=cd_calendar(vetor,-5)
  ano=sprinti("%d",itime(:,0)) 	
  yyyymm=cd_calendar(vetor,-1)

 print(yyyymmdd+" "+ano)
	linha="#!/bin/bash"
	alist=[/linha/]
	write_table("jobcpc.sh","w",alist,"%s")
	linha:="#  criado pelo baixar_cfs.ncl"
	alist=[/linha/]
	write_table("jobcpc.sh","a",alist,"%s")



		filebin="PRCP_CU_GAUGE_V1.0GLB_0.50deg.lnx."+sprinti("%d",yyyymmdd)+".RT"
		filenc="CPC_GAUGE_AMS_"+sprinti("%d",yyyymmdd)+".nc"
        
		path="./CPC/"+filenc
		a=fileexists(path)
		
		flag=where(a.eq.True,"#","")
		
		
		link="wget   ftp://ftp.cpc.ncep.noaa.gov/precip/CPC_UNI_PRCP/GAUGE_GLB/RT/"+ano+"/"+filebin 
				alist=[/flag,link/]
				write_table("jobcpc.sh","a",alist,"%s%s")
		
		
		
;		edir=$2"/"$filenc
;		if test -e $edir ;then
;			let a=1
;			###
;		else
;			echo "[ CPC_GAUGE ] BAIXANDO ARQUIVO:"$file" para gerar o arquivo:"$filenc 
;			wget -nc ftp://ftp.cpc.ncep.noaa.gov/precip/CPC_UNI_PRCP/GAUGE_GLB/RT/$ano/$file  > /dev/null 2>&1
;			export FILE_CPC=$file
;			#
;			#
;			#  codigo em ncl para criar o netcdf 
;;			#
;			ncl ncl_cria_netcdf_cpc.ncl  > /dev/null 2>&1
;			#
;
return(0)

end







begin 
	;-------------------------------------------------------------------
	;
	;
	;          Baixa dados do CPC
	;          cria versao netcdf 
	;          calcula media mensal  
	;
	;  by regis reginaldo.venturadesa@gmail.com 
	;
	;  criando em 31/10/2021
	;
	;  O script precisa das seguintes variaveis ambientes  
	; 
	;   CPC_ANO_i  : Ano inicial 
	;   CPC_MES_i  : Mes inicial
	;   CPC_DIA_i  : dia inicial 
	;   CPC_ANO_f  : Ano final  
	;   CPC_MES_f  : Mes final 
	;   CPC_DIA_f  : dia final 
	;
	;  Data inicial é a data mais antiga
	;  Data final é a data mais recente 
	;  Isso por que no operacional estamos pegando sempre o dia atual - dias atrás
	;---------------------------------------------------------------------
	;
	; opções
	;
	config=True
	;
	; recorte para AMS 
	;
	; se config@recorte=False pega todo o globo
	;
	config@recorte=True
	config@lat0=-40
	config@lat1=10
	config@lon0=280
	config@lon1=330
	config@descricao=" Recorte para America do Sul"
	;
	; prefixo do arquivo netcdf
	;
	config@prefixo="CPC_GAUGE_AMS"
	;----------------------------------------------------------------------------
	;
	; data base (não mudar)
	; O CPC tem duas versões . versão 1.0 de 1979 a 2017 e a versao 2 de 2017 em diante
	; Esta versão só se aplica a versão 2.0  
	;
	;---------------------------------------------------------------------------- 
	data_base=(/2017,1,1,0,0,0/)
	;----------------------------------------------------------------------------------
	;
	;
	;  faz inspesção d rgumentos externos 
	;   os dados vem de variaveis externa ambientais  
	;
	;----------------------------------------------------------------------------------
	if (.not. ismissing(getenv("CPC_ANO_i")))
		anoi=tointeger(getenv("CPC_ANO_i"))
		
	else
	         print("erro . definir ano inicial")
			 exit
	end if
	if (.not.ismissing(getenv("CPC_MES_i")))
		mesi=tointeger(getenv("CPC_MES_i"))
	else
	         print("erro . definir mes inicial")
			 exit
	end if
	if (.not.ismissing(getenv("CPC_DIA_i")))
		diai=tointeger(getenv("CPC_DIA_i"))
	else
	         print("erro . definir dia inicial")
			 exit
	end if
	
	if (.not.ismissing(getenv("CPC_ANO_f")))
		anof=tointeger(getenv("CPC_ANO_f"))
	else
	         print("erro . definir ano final")
			 exit
	end if
	if (.not.ismissing(getenv("CPC_MES_f")))
		mesf=tointeger(getenv("CPC_MES_f"))
	else
	         print("erro . definir dia final")
			 exit
	end if
	if (.not.ismissing(getenv("CPC_DIA_f")))
		diaf=tointeger(getenv("CPC_DIA_f"))
	else
	         print("erro . definir dia final")
			 exit
	end if
	;
	; cria matriz de datas
	;
	data_inicial=(/anoi,mesi,diai,0,0,0/)
	data_final=(/anof,mesf,diaf,0,0,0/)
	;---------------------------------------------------------------------
	;
	;
	; baixa os arquivos cpc via  script bash file 
	;
	;------------------------------------------------------------------------
	k=baixa_cpc(data_inicial,data_final,config) 
	system("./jobcpc.sh")
	;
	; lista os arquivos baixados 
	;
	files=systemfunc("ls -1 PRCP_CU_GAUGE_V1.0GLB_0.50deg.lnx.*") 
	flag=ismissing(files)
    print(flag)	
	if(.not.ismissing(files(0)))
		;
		;
		; transforma arquivos bin em netcdf com rrecorte 
		;
		num_files=dimsizes(files)
		do i=0,num_files-1
			d=cria_cpc_netcdf( files(i) ,config )
		end do 	
		system("mv "+config@prefixo+"* CPC/")
		system("rm PRCP_CU_GAUGE_V1.0GLB_0.50deg.lnx*") 
	else
		exit
	end if 	
	
	;
	; calcula chuva mensal 
	;
	config=True
    config@modelo="CPC"
	config@lon360=False
	shapes=systemfunc("ls -1 ./SHAPES/*.shp") 
	
	;
	;  pega os ultimos 365 arquivos se existirem 
	;
	files:=systemfunc("ls -1 ./CPC/CPC_GAUGE_AMS_*.nc | tail -365")
	;
	;
	;
	config@anoi=anoi
	config@mesi=mesi
	config@diai=diai
	config@anof=anof
	config@mesf=mesf
	config@diaf=diaf
	;
	; calcula chuva mensal
	;
	M=calcbacia_mensal( files ,shapes ,config)
	;
	; imprime as chuvas mensais por shape file 
	;
	k=print_calcbacia_mes( M , config )
    ;
    ;	
	
		
end
 

 
 

