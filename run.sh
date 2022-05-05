#!/bin/bash
 
# Initialize and Load Modules
source /etc/profile

module load julia/1.6.1

echo "My task ID: " $LLSUB_RANK
echo "Number of Tasks: " $LLSUB_SIZE
 
# Don't forget to change the -p here before running a job. This changes the number of voters.
julia -p 48 src/julia/test.jl $LLSUB_RANK $LLSUB_SIZE

# #!/bin/bash
# #SBATCH --job-name=18337
# #SBATCH -o logs/%j.log
# #SBATCH -e logs/%j.err
# #SBATCH --cpus-per-task=1
# #SBATCH --nodes=2
# #SBATCH --tasks-per-node=48
# #SBATCH --constraint=xeon-p8
# #SBATCH -p normal
# ####SBATCH --gres=gpu:volta:2

# source /etc/profile
# module load anaconda/2021a

# julia testsupercloud.jl