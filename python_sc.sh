#!/bin/bash
 
# Initialize and Load Modules
source /etc/profile
module load anaconda/2021a
 
echo "My task ID: " $LLSUB_RANK
echo "Number of Tasks: " $LLSUB_SIZE
 
python python/supercloud.py $LLSUB_RANK $LLSUB_SIZE