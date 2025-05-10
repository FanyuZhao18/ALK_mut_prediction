#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=11
#SBATCH --time=01:00:00
#SBATCH --mem=50GB
#SBATCH --job-name=pb
#SBATCH --output=GB.out

module purge
module load amber/openmpi/intel/20.11
module load gcc/10.2.0
export LD_LIBRARY_PATH=/share/apps/gcc/10.2.0/lib64:/scratch/fz2113/g16/bsd:/scratch/fz2113/g16:/scratch/fz2113/g16/bsd:/scratch/fz2113/g16:/scratch/fz2113/g16/bsd:/scratch/fz2113/g16::/share/apps/centos/8/usr/lib:/share/apps/centos/8/usr/lib64:/share/apps/centos/8/lib64:/scratch/fz2113/gv/lib:/share/apps/centos/8/usr/lib:/share/apps/centos/8/usr/lib64:/share/apps/centos/8/lib64:/scratch/fz2113/gv/lib:/share/apps/centos/8/usr/lib:/share/apps/centos/8/usr/lib64:/share/apps/centos/8/lib64:/scratch/fz2113/gv/lib:/home/fz2113/asgbie/lib


###copy and Run Alanine Scanning
cp ../lig_prep/lig.pdb ./ASGB/prepare
cp ../lig_prep/lig.pdb ./ASIE/prepare
cp ../lig_prep/pro.pdb ./ASGB/prepare
cp ../lig_prep/pro.pdb ./ASIE/prepare
cp ../lig_prep/com.pdb ./ASGB/prepare
cp ../lig_prep/com.pdb ./ASIE/prepare
cp ../lig_prep/lig.frcmod ./ASGB/prepare
cp ../lig_prep/lig.frcmod ./ASIE/prepare
cp ../lig_prep/lig.mol2 ./ASGB/prepare
cp ../lig_prep/lig.mol2 ./ASIE/prepare
ln -sf ../md/prod.nc ./md.nc


cd ./ASGB/prepare/
ln -sf ../../md.nc md.nc
bash ./Step1_RunWildtype_GB.sh
bash ./Step2_RunPrepare_GB.sh
bash ./Step3_RunCalculate_GB.sh
bash ./Step4_GetResult_GB.sh


cd ../../ASIE/prepare/
ln -sf ../../md.nc md.nc
bash ./Step1_RunPrepare_IE.sh
bash ./Step2_RunCalculate_IE.sh
bash ./Step3_GetResult_IE.sh
