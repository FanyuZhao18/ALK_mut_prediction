#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:a100:1
#SBATCH --cpus-per-task=1
#SBATCH --time=1-00:00:00
#SBATCH --mem=5GB
#SBATCH --job-name=D1203N_pre
#SBATCH --output=slurm_%j.out

module purge
module load amber/openmpi/intel/22.00

pmemd.cuda -O -i equil.in -p ../../merged_bound.prmtop -c ../prod.rst7 -o equi.out -r equi.rst7
pmemd.cuda -O -i prod.in -p ../../merged_bound.prmtop -c equi.rst7 -o prod.out -r prod.rst7