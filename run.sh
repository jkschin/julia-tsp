#!/bin/bash
#SBATCH --job-name=18337
#SBATCH -o logs/%j.log
#SBATCH -e logs/%j.err
#SBATCH --cpus-per-task=1
#SBATCH --nodes=2
#SBATCH --tasks-per-node=48
#SBATCH --constraint=xeon-p8
#SBATCH -p normal
####SBATCH --gres=gpu:volta:2

source /etc/profile
module load anaconda/2021a

julia test.jl

