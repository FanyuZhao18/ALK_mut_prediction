#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:1
#SBATCH -p sci
#SBATCH --cpus-per-task=1
#SBATCH --time=2-00:00:00
#SBATCH --mem=10GB
#SBATCH --job-name=M49G_pre

module purge
module load amber/22gpu

pmemd.cuda -O -i min1.in -p pep_1.top -c pep_1.crd -ref pep_1.crd -o min1_1.out -r min1_1.rst7
pmemd.cuda -O -i min2.in -p pep_1.top -c min1_1.rst7 -o min2_1.out -r min2_1.rst7
pmemd.cuda -O -i heat.in -p pep_1.top -c min2_1.rst7 -ref min2_1.rst7 -o heat_1.out -r heat_1.rst7
pmemd.cuda -O -i equil.in -p pep_1.top -c heat_1.rst7 -ref heat_1.rst7 -o equi_1.out -r equi_1.rst7
pmemd.cuda -O -i prod.in -p pep_1.top -c equi_1.rst7 -o prod_1.out -r prod_1.rst7 -x prod_1.netcrd
