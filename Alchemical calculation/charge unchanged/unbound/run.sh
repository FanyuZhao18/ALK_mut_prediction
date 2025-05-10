#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:a100:1
#SBATCH --time=1-00:00:00
#SBATCH --mem=10GB
#SBATCH --job-name=V88W_pre
#SBATCH --output=slurm_%j.out

module purge
module load amber/openmpi/intel/22.00

#module load amber/22gpu
pmemd.cuda -O -i pre_min1.in -p ../merged_unbound.prmtop -c ../merged_unbound.inpcrd -ref ../merged_unbound.inpcrd -o min1.out -r min1.rst7
pmemd.cuda -O -i pre_min2.in -p ../merged_unbound.prmtop -c min1.rst7 -o min2.out -r min2.rst7
pmemd.cuda -O -i pre_heat.in -p ../merged_unbound.prmtop -c min2.rst7 -ref min2.rst7 -o heat.out -r heat.rst7
pmemd.cuda -O -i pre_equil.in -p ../merged_unbound.prmtop -c heat.rst7 -o equi.out -r equi.rst7
pmemd.cuda -O -i pre_prod.in -p ../merged_unbound.prmtop -c equi.rst7 -o prod.out -r prod.rst7