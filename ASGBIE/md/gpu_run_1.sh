#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH -p chem
#SBATCH --gres=gpu:1
#SBATCH --time=1-00:00:00
#SBATCH --mem=5GB
#SBATCH --job-name=88TRP
#SBATCH --output=slurm_%j.out

module purge
#module load amber/22gpu
module load singularity amber/22-cuda-11.4.2
#module load singularity amber/22-cuda-11.4.2

pmemd.cuda -O -i min1.in -o min1.out -p ../lig_prep/com_solv.prmtop -c ../lig_prep/com_solv.inpcrd  -r min1.rst -ref ../lig_prep/com_solv.inpcrd
pmemd.cuda -O -i min2.in -o min2.out -p ../lig_prep/com_solv.prmtop -c min1.rst -r min2.rst 
pmemd.cuda -O -i heat.in  -o heat.out  -p ../lig_prep/com_solv.prmtop -c min2.rst -r heat.rst  -ref min2.rst
pmemd.cuda -O -i equil.in  -o equil.out  -p ../lig_prep/com_solv.prmtop -c heat.rst  -r equil.rst -ref heat.rst
pmemd.cuda -O -i prod.in  -o prod.out  -p ../lig_prep/com_solv.prmtop -c equil.rst  -r prod.rst  -x prod.nc