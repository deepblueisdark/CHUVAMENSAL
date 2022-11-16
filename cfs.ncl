load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_inv_string.ncl"

function print_calcbacia_cfs( M , config )
begin

	d=dimsizes(M)
	print(d)
 	num_shapes=d(0)

	shapenames=M@shapenames
	print(shapenames)
	num_pleads=config@cfs_pleads
	num_leads=config@cfs_leads 
	; 
	;
	;

	do j=0,num_shapes-1
		filename="CFSMENSAL_"+shapenames(j)+".dat"
		print(filename+" "+j)
		
		
		
		if (config@temlead0 )
			do i=1,num_pleads-1
				valores=new((/num_leads-1/),"string")
				do t=1,num_leads-1
					linha_data=sprintf("%4.0f",M(j,i,t,9))+" "+sprintf("%2.0f",M(j,i,t,10))+" 01 "	
					valores(t-1)=sprintf("%07.2f ",M(j,i,t,0))
				end do
				linha_valores=str_join(valores," ")
				alist=[/linha_data,linha_valores/] 
				write_table(filename,"a",alist,"%s %s")	 
			end do
		else
		
		
			do i=0,num_pleads-1
				valores=new((/num_leads/),"string")
				do t=0,num_leads-1
					linha_data=sprintf("%4.0f",M(j,i,t,9))+" "+sprintf("%2.0f",M(j,i,t,10))+" 01 "	
					valores(t)=sprintf("%07.2f ",M(j,i,t,0))
				end do
				linha_valores=str_join(valores," ")
				alist=[/linha_data,linha_valores/] 
				write_table(filename,"a",alist,"%s %s")	 
			end do
		end if 
    end do
;;write_table(fname, "a", alist, "%d%16.2f%s%d%ld")
return(0)
end





;----------------------------------------------------------------------
; 	calcula media numa bacia 
;  	 reginaldo.venturadesa@gmail.com  20-09-2022
;  
;    congig@lon360 -> tipo de longitude  
;    config@modelo  -> tipo de origen do dado 
;
;    CPC :  dados do cpc em netcdf           ;;;10-3-2020  
;    GPM :  dados do IMERGE NASA              ;;;; 19-9-2022
;  
;   M=calcbacia( chuva , shapefiles , config) 
;  
;  
; retorna
;   M (  num_tempos, num_shapes, campo-info)
;	M@info="media,soma,seca,umida,num_pontos_dentro do shpe, minlat,minlon,maxlat,maxlon,ano,mes,dia,hora,minuto"
;
;
;---------------------------------------------------------------------------------------------
function calcbacia_cfs( files , shapefiles, config)  

begin
	
	;
	;
	;
	num_files=dimsizes(files)
	num_shapes=dimsizes(shapefiles) 
	
	num_pleads=config@cfs_pleads
	num_leads=config@cfs_leads 
	
	;M=new((/num_files,num_shapes,20/),"float",-1)
	MM=new((/num_shapes,num_leads+1,num_pleads+1,11/),"float",-1)
	shapename=new((/num_shapes/),"string") 
	
	print("[ CALCBACIA ] Numero de arquivos de dados  :"+num_files)
	print("[ CALCBACIA ] Numero de arquivos shapefiles:"+num_shapes)
	
	num_dias_mes=(/31,28,31,30,31,30,31,31,30,31,30,31/) 
	
	
	do i=0,num_files-1
		;
		; se  for o CPC 
	
		fi = addfile(files(i),"r")
	
		;print(getfilevarnames(fi))
		vars=getfilevarnames(fi)
		if (config@operacional)
			codigo_chuva=0
		else
			codigo_chuva=15
		end if 	
		lat=fi->lat_0
		lon=fi->lon_0
			
		
			
		data_inicial=str_get_field(files(i),2,".") 
		data_rodada=str_get_field(files(i),3,".")
		data_prev=str_get_field(files(i),4,".")

			
		
		tempos_inicial = tointeger(cd_calendar(cd_inv_string(data_inicial, "%Y%N%D"),0))
		tempos_rodada =  tointeger(cd_calendar(cd_inv_string(data_rodada,  "%Y%N%D%H"),0))
		tempos_prev = tointeger(cd_calendar(cd_inv_string(data_prev, "%Y%N"),0))
			
		
			
			
		units="months from 1981-01-01 00:00:00"
		mesp=cd_inv_calendar(tempos_prev(0,0),tempos_prev(0,1),1,0,0,0,units,0)
		mesr=cd_inv_calendar(tempos_rodada(0,0),tempos_rodada(0,1),1,0,0,0,units,0)
			
			
		units="hours from "+sprinti("%d",tempos_inicial(0,0))+"-"+sprinti("%02d",tempos_inicial(0,1))+"-"+sprinti("%02d",tempos_inicial(0,2))+" 00:00:00"

		mesr0=cd_inv_calendar(tempos_inicial(0,0),tempos_inicial(0,1),tempos_inicial(0,2),0,0,0,units,0)
		mesr1=cd_inv_calendar(tempos_rodada(0,0),tempos_rodada(0,1),tempos_rodada(0,2),tempos_rodada(0,3),0,0,units,0)
		
		
	
		;if (tempos_rodada(0,2) .le. 20 )
				plead=tointeger(abs((mesr0/6)-(mesr1/6)) )
		;else
		;		plead=tointeger(abs((mesr0/6)-(mesr1/6)) )-1
		;end if	
		
			
			
		
		;if (tempos_rodada(0,2) .le. 20 )
			lead=tointeger(mesp-mesr)
		;else
		;	lead=tointeger(mesp-mesr)-1
		;end if	
		print(mesr0+" "+mesr1+" "+plead+" "+lead+" "+files(i))
			
			
			
		data2=fi->$vars(codigo_chuva)$
		data=data2*24*3600*num_dias_mes(tempos_prev(0,1)-1)
		;printMinMax(data,0)
		;printMinMax(data2,0)
		;printVarSummary(data2)
		copy_VarCoords(data,data2)

		
		
		;print("[ CALCBACIA ] Abrindo arquivo CFS  na data de:"+temposx) 


		;
		; dimesnoes 
		;
		nlat=dimsizes(lat)
		nlon=dimsizes(lon) 
		if (plead .le. num_pleads) 
			do j=0,num_shapes-1
				data_mask = new(dimsizes(data),typeof(data),data@_FillValue)
				copy_VarCoords(data,data_mask)
				svar1=str_get_field(shapefiles(j),3,"/")
				svar=str_get_field(svar1,1,".")
				shapename(j)=svar	

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
			    ;;;print(j+" "+lead+" "+plead+" "+sum(data_mask)+" "+num_pontos_inside)
	           
			if (num_pontos_inside .gt. 0 )
			
				MM(j,lead,plead,0)=sum(data_mask)/num_pontos_inside
				MM(j,lead,plead,1)=tempos_inicial(0,0)
				MM(j,lead,plead,2)=tempos_inicial(0,1)
				MM(j,lead,plead,3)=tempos_inicial(0,2)
				MM(j,lead,plead,4)=tempos_inicial(0,3)
				MM(j,lead,plead,5)=tempos_rodada(0,0)
				MM(j,lead,plead,6)=tempos_rodada(0,1)
				MM(j,lead,plead,7)=tempos_rodada(0,2)
				MM(j,lead,plead,8)=tempos_rodada(0,3)
				MM(j,lead,plead,9)=tempos_prev(0,0)
				MM(j,lead,plead,10)=tempos_prev(0,1)
				
			else
				MM(j,plead,lead,0:10)= -1
			end if
			;print(M(i,j,:))
			;limites(j,:,:,:,:)=limites_shp
		    delete(f)
			delete(mrb_lon)
			delete(mrb_lat)
			delete(ilt_mn)
			delete(ilt_mx)
			delete(iln_mn)
			delete(iln_mx)
			delete(data_mask)

		end do	
	end if	
		delete(fi)
		delete(data)
		
    end do
	MM@info="media,soma,seca,umida,num_pontos_dentro do shpe, minlat,minlon,maxlat,maxlon,ano,mes,dia,hora,minuto"
    MM@shapenames=shapename
	
	MM@_FillValue=-1 
	return(MM)
end 





;
;
;
; modo= True ---> OPERACIONAL 
;       False  --> NAO OPERACIONAL (HISTPRY)   

function baixar_cfs( OPERACIONAL, data_base , data_inicial  , num_ens)
begin

  
	num_dias=num_ens/4
	

 
  
  units="days from "+sprinti("%d",data_base(0))+"-"+sprinti("%02d",data_base(1))+"-"+sprinti("%02d",data_base(2))+" 00:00:00"
  t0=tointeger(cd_inv_calendar(data_base(0),data_base(1),data_base(2),data_base(3),data_base(4),data_base(5),units,0))
  t1=tointeger(cd_inv_calendar(data_inicial(0),data_inicial(1),data_inicial(2),data_inicial(3),data_inicial(4),data_inicial(5),units,0))
  
 vetor=ispan(tointeger(t0),tointeger(t1),1)
  vetor@units=units

  yyyymmdd=cd_calendar(vetor(t1-num_dias:t1),-2)
  itime=cd_calendar(vetor(t1-num_dias:t1),-5)

  yyyymm=cd_calendar(vetor(t1-num_dias:t1),-1)


  print(yyyymmdd+" ")
  print(itime+" ")
  print(yyyymm+" ")
  
 

  units="months from "+sprinti("%d",data_inicial(0))+"-"+sprinti("%02d",data_inicial(1))+"-"+sprinti("%02d",data_inicial(2))+" 00:00:00"
  t0=tointeger(cd_inv_calendar(data_inicial(0),data_inicial(1),data_inicial(2),data_inicial(3),data_inicial(4),data_inicial(5),units,0))
  lead=ispan(0,7,1)
  lead@units=units
  yyyymmdd2=cd_calendar(lead,-2)
  data_rodada=max(yyyymmdd)
  yyyymm2=cd_calendar(lead,-1)

rodada=(/"00","06","12","18"/) 

	;num_dias=dimsizes(yyyymmdd)
	num_ciclos=dimsizes(rodada)
	num_prev=dimsizes(yyyymm2)
	linha="#!/bin/bash"
	alist=[/linha/]
	write_table("job.sh","w",alist,"%s")
	linha:="#  criado pelo baixar_cfs.ncl"
	alist=[/linha/]
	write_table("job.sh","a",alist,"%s")
	
	

	
	if ( OPERACIONAL) 
		do dia=0,num_dias-1
			do ciclo=0,num_ciclos-1
				do prev=0,num_prev-1
					filecfs="flxf.01."+sprinti("%d",yyyymmdd(dia))+rodada(ciclo)+"."+sprinti("%d",yyyymm2(prev))+".avrg.grib.grb2"
					fileout="CFS."+sprinti("%d",data_rodada)+"."+sprinti("%d",yyyymmdd(dia))+rodada(ciclo)+"."+sprinti("%d",yyyymm2(prev))+".grb2"					
					link="https://nomads.ncep.noaa.gov/pub/data/nccf/com/cfs/prod/cfs."+sprinti("%d",yyyymmdd(dia))+"/"+rodada(ciclo)+"/monthly_grib_01/"+filecfs
					inv="https://nomads.ncep.noaa.gov/pub/data/nccf/com/cfs/prod/cfs."+sprinti("%d",yyyymmdd(dia))+"/"+rodada(ciclo)+"/monthly_grib_01/"+filecfs+".idx"
					linha:="./get_inv.pl "+inv+"| grep ':PRATE:' | ./get_grib.pl "+link+" "+fileout
					alist=[/linha/]
					write_table("job.sh","a",alist,"%s")
					
					
				end do
			end do
		end do
		dia=num_dias
		ciclo=0
		do prev=0,num_prev-1
				filecfs="flxf.01."+sprinti("%d",yyyymmdd(dia))+rodada(ciclo)+"."+sprinti("%d",yyyymm2(prev))+".avrg.grib.grb2"
				fileout="CFS."+sprinti("%d",data_rodada)+"."+sprinti("%d",yyyymmdd(dia))+rodada(ciclo)+"."+sprinti("%d",yyyymm2(prev))+".grb2"					
				link="https://nomads.ncep.noaa.gov/pub/data/nccf/com/cfs/prod/cfs."+sprinti("%d",yyyymmdd(dia))+"/"+rodada(ciclo)+"/monthly_grib_01/"+filecfs
				inv="https://nomads.ncep.noaa.gov/pub/data/nccf/com/cfs/prod/cfs."+sprinti("%d",yyyymmdd(dia))+"/"+rodada(ciclo)+"/monthly_grib_01/"+filecfs+".idx"
				linha:="./get_inv.pl "+inv+"| grep ':PRATE:' | ./get_grib.pl "+link+" "+fileout
				alist=[/linha/]
				write_table("job.sh","a",alist,"%s")
		end do
	else
		print("nao pperacional")
		do dia=0,num_dias-1
			do ciclo=0,num_ciclos-1
				do prev=0,num_prev-1
					print(dia+" "+ciclo+" "+prev)  
					filecfs="flxf.01."+sprinti("%d",yyyymmdd(dia))+rodada(ciclo)+"."+sprinti("%d",yyyymm2(prev))+".avrg.grib.grb2"
					filecfsinv="flxf.01."+sprinti("%d",yyyymmdd(dia))+rodada(ciclo)+"."+sprinti("%d",yyyymm2(prev))+".avrg.grib.inv"
					
					print(filecfs)
					print(filecfsinv)
					fileout="CFS."+sprinti("%d",data_rodada)+"."+sprinti("%d",yyyymmdd(dia))+rodada(ciclo)+"."+sprinti("%d",yyyymm2(prev))+".grb2"					
					print(fileout)
					link="https://www.ncei.noaa.gov/data/climate-forecast-system/access/operational-9-month-forecast/monthly-means/"+sprinti("%d",itime(dia,0))+"/"+sprinti("%d",yyyymm(dia))+"/"+sprinti("%d",yyyymmdd(dia))+"/"+sprinti("%d",yyyymmdd(dia))+rodada(ciclo)+"/"+filecfs
					inv="https://www.ncei.noaa.gov/data/climate-forecast-system/access/operational-9-month-forecast/monthly-means/"+sprinti("%d",itime(dia,0))+"/"+sprinti("%d",yyyymm(dia))+"/"+sprinti("%d",yyyymmdd(dia))+"/"+sprinti("%d",yyyymmdd(dia))+rodada(ciclo)+"/"+filecfsinv
									
				
				
					;linha:="./get_inv.pl "+inv+"| grep ':PRATE:' | ./get_grib.pl "+link+" "+fileout
					linha:="wget -O "+fileout+" "+link
					
					alist=[/linha/]
					write_table("job.sh","a",alist,"%s")
				
				
				end do
			end do
		end do
		dia=num_dias
		ciclo=0
		do prev=0,num_prev-1
				filecfs="flxf.01."+sprinti("%d",yyyymmdd(dia))+rodada(ciclo)+"."+sprinti("%d",yyyymm2(prev))+".avrg.grib.grb2"
				fileout="CFS."+sprinti("%d",data_rodada)+"."+sprinti("%d",yyyymmdd(dia))+rodada(ciclo)+"."+sprinti("%d",yyyymm2(prev))+".grb2"					
				link="https://www.ncei.noaa.gov/data/climate-forecast-system/access/operational-9-month-forecast/monthly-means/"+sprinti("%d",itime(dia,0))+"/"+sprinti("%d",yyyymm(dia))+"/"+sprinti("%d",yyyymmdd(dia))+"/"+sprinti("%d",yyyymmdd(dia))+rodada(ciclo)+"/"+filecfs
				inv="https://www.ncei.noaa.gov/data/climate-forecast-system/access/operational-9-month-forecast/monthly-means/"+sprinti("%d",itime(dia,0))+"/"+sprinti("%d",yyyymm(dia))+"/"+sprinti("%d",yyyymmdd(dia))+"/"+sprinti("%d",yyyymmdd(dia))+rodada(ciclo)+"/"+filecfsinv
			
		        linha:="wget -O "+fileout+" "+link
				alist=[/linha/]
				write_table("job.sh","a",alist,"%s")
		end do
	end if

	system("./job.sh") 


return(0)

end









begin 

    config=True
    config@modelo="CFS"
	config@lon360=False
	config@cfs_leads=8
	config@cfs_pleads=7
	config@operacional=True
	config@temlead0=True
	
	shapes=systemfunc("ls -1 ./SHAPES/*.shp") 
	
	
	
	data_base=(/2011,4,1,0,0,0/)
		;
	;  faz inspesção d rgumentos externos 
	;
	if (.not. ismissing(getenv("CPC_ANO_i")))
		anoi=tointeger(getenv("CPC_ANO_i"))
		
	else
	         print("erro . definir ano inicial")
	end if
	if (.not.ismissing(getenv("CPC_MES_i")))
		mesi=tointeger(getenv("CPC_MES_i"))
	else
	         print("erro . definir ano inicial")
	end if
	if (.not.ismissing(getenv("CPC_DIA_i")))
		diai=tointeger(getenv("CPC_DIA_i"))
	else
	         print("erro . definir ano inicial")
	end if
	
	if (.not.ismissing(getenv("CPC_ANO_f")))
		anof=tointeger(getenv("CPC_ANO_f"))
	else
	         print("erro . definir ano inicial")
	end if
	if (.not.ismissing(getenv("CPC_MES_f")))
		mesf=tointeger(getenv("CPC_MES_f"))
	else
	         print("erro . definir ano inicial")
	end if
	if (.not.ismissing(getenv("CPC_DIA_f")))
		diaf=tointeger(getenv("CPC_DIA_f"))
	else
	         print("erro . definir ano inicial")
	end if
	;
	; cria matriz de datas
	;
	;;;data_inicial=(/anoi,mesi,diai,0,0,0/)
	data_inicial=(/anof,mesf,diaf,0,0,0/)

	
	h=baixar_cfs(config@operacional , data_base,data_inicial, 8) 
	
	files=systemfunc("ls -1r CFS*.grb2")
	
	M=calcbacia_cfs( files, shapes,config) 
	print(M)
	k=print_calcbacia_cfs(M,config)
	
	
end
	