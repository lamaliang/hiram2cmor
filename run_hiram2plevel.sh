#!/bin/sh

# === Module load some libs ===
module purge
module load hdf5_pgi-9.0.4/1.8.10
module load netcdf_hdf5-1.8.10_pgi-9.0.4/4.2.1
module load pgi/pgwc-9.0.4

vnm=$1
var=$2
lev=$3
yr=$4
infile=$5

if [ $lev == plev19 ] ;then
  plevs="100000 92500 85000 70000 60000 50000 40000 30000 25000 20000 15000 10000 7000 5000 3000 2000 1000 500 100"
fi

sday=${yr}0101
eday=${yr}1201

for ((years=$sday; years<=$eday; years=`date +"%Y%m%d" -d"$years 12:00 +1 month"`)) ; do
  ./plevel.sh -i /lfs/archive/HiRAM/raw/$vnm/combined/$years/${infile}_${years}.nc -p "$plevs" -o ${vnm}.${years}.${var}.nc $var
done
