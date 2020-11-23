#!/bin/sh

# === module list ===
module purge
module load json-c_gcc-7.5.0/0.13.1
module load netcdf_hdf5-1.10.5_gcc-7.5.0/4.7.3
module load cmor_gcc-7.5.0/3.5
module load gcc/7.5.0
module load cdo_gcc-7.5.0/1.9.8
module load openmpi_gcc-7.5.0/4.0.2
module load nco_gcc-4.4.7_netcdf4/4.7.5
#==================================================
# --- Setting ---
isy=1950
iey=1950
vnm=$1
table=$2
#file=HiRAM-SIT_HighResMIP_output.txt
map=mapping_table_hiram-${table}.txt
indir=/lfs/archive/HiRAM/raw/$vnm/combined
exp_id=highresSST-present

if [ `echo $vnm | cut -c 1-4` == c192 ] ; then sour_id=HiRAM-SIT-LR ;fi
if [ `echo $vnm | cut -c 1-4` == c384 ] ; then sour_id=HiRAM-SIT-HR ;fi

outdir=/lfs/archive/taiesm_ppost/$sour_id/$exp_id/$table
tmpdir=/lfs/archive/taiesm_ppost/$sour_id/$exp_id/${table}.raw
if [ ! -d $outdir ] ; then mkdir -p $outdir ; fi 
if [ ! -d $tmpdir ] ; then mkdir -p $tmpdir ; fi 


if [ -z "$1" ] || [ -z "$2" ] ;then
  echo "error : Please Input CMIP6 Table Name or Experiment Name "
  exit
else
# Model file list check
  if [ $table == Amon ] ; then infile=atmos_month ; fi

# Post-Processing 
  iStrt=`cat $map | grep -n "Amon" |awk -F: '{print $1}' |head -n1`
  iLast=`cat $map | grep -n "Amon" |awk -F: '{print $1}' |tail -n1`

  for yr in `seq $isy $iey` ; do
  for nm in `seq $iStrt $iLast` ; do
    cvar=`sed -n ${nm}p $map | awk '{print $2}' | cut -d "=" -f 2`
    hvar=`sed -n ${nm}p $map | awk '{print $3}' | cut -d "=" -f 2 |cut -d \" -f 2` 

    if [ ! -f $outdir/${cvar}_${table}_${sour_id}_${exp_id}_r1i1p1f1_gn_${yr}*.nc ] ; then
    if `ncdump -h $indir/${yr}*/${infile}_${yr}0101.nc | grep -q "float $hvar("` ;then

      if `sed -n ${nm}p $map | grep -q "plev"` ; then
        echo "Processing 3Dvar = $cvar | hiram var = $hvar "
        lev=`sed -n ${nm}p $map | awk '{print $6}' | cut -d "=" -f 2 |cut -d \" -f 2` 
        sh run_hiram2plevel.sh $vnm $hvar $lev $yr $infile

        input=hiram_${vnm}_${yr}_${hvar}_${table}.nc
        ncrcat -h ${vnm}.${yr}????.${hvar}.nc $input 
        rm -rf ${vnm}.${yr}????.${hvar}.nc
      else
        echo "Processing 2Dvar = $cvar | hiram var = $hvar "
        echo "Combined $yr $infile data = "$hvar
        input=hiram_${vnm}_${yr}_${hvar}_${table}.nc
        cdo -select,name=$hvar $indir/${yr}*/${infile}_*.nc $input
      fi

       ncrename -h -v grid_xt,lon -v grid_yt,lat -d grid_xt,lon -d grid_yt,lat $input 
       ncrename -h -v grid_xt_bnds,lon_bnds -v grid_yt_bnds,lat_bnds $input
       ncatted -h -O -a bounds,lon,o,c,"lon_bnds" $input 
       ncatted -h -O -a bounds,lat,o,c,"lat_bnds" $input 
       cdo -v cmor,cmip6-cmor-tables/CMIP6_${table}.json,cn=${cvar},om=r,info=${sour_id}.${exp_id}.r1i1p1f1.nml,mt=$map,drs=n,dr=$outdir $input
    
       mv $input $tmpdir

    fi
    fi
  done # nvar
  done # nyr 
fi
