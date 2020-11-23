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
file=HiRAM-SIT_HighResMIP_output.txt
mapping=mapping_table_hiram-${table}.txt
indir=/lfs/archive/HiRAM/raw/$vnm/combined

if [ -f $mapping ] ; then rm -rf $mapping ; fi
if [ -z "$1" ] || [ -z "$2" ] ;then
  echo "error : Please Input CMIP6 Table Name or Experiment Name "
  exit
else
# Model file list check
  if [ $table == Amon ] ; then infile=atmos_month ; fi

# Post-Processing 
  cat $file | grep -n "#" > tmp 
  iStrt=$((`cat tmp | grep "$table" |awk -F: '{print $1}'`+2))
  iLast=`grep -n "$table" tmp |awk -F: '{print $1+2}' | xargs -I {} sed -n '{}p' tmp |awk -F: '{print $1-1}'`
  rm -f tmp

  for nm in `seq $iStrt $iLast` ; do
    cvar=`sed -n ${nm}p $file | awk -F= '{print $1}'` 
    hvar=`sed -n ${nm}p $file | awk -F= '{print $2}'` 

    # create mapping file 
    if [ ! -z "$cvar" ] && [ ! -z "$hvar" ] ; then
      printf "%-10s %-23s %-21s %-26s %-15s %-1s\n" \&parameter cmor_name=$cvar name=\"$hvar\" project_mip_table=\"$table\" cell_methods=\"m\" \/ >> $mapping 
    fi

  done # nvar
fi
