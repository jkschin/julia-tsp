import sys
import os
import gurobi_tsp
import pickle


# Grab the arguments that are passed in
my_task_id = int(sys.argv[1])
num_tasks = int(sys.argv[2])
 
values = os.listdir("tsp_instances")
values = [i for i in values if i.endswith(".tsp")]

# Assign indices to this process/task
my_values = values[my_task_id:len(values):num_tasks]
 
for v in my_values:
    instance_name = v.split(".")[0]
    m = gurobi_tsp.optimize(v)
    data = m._data
    with open(os.path.join("results/%s.pkl" %instance_name), "wb") as f:
        pickle.dump(data, f, protocol=2)