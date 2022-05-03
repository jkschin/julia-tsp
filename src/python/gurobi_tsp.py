#!/usr/bin/env python3.7

# Copyright 2022, Gurobi Optimization, LLC

# Solve a traveling salesman problem on a randomly generated set of
# points using lazy constraints.   The base MIP model only includes
# 'degree-2' constraints, requiring each node to have exactly
# two incident edges.  Solutions to this model may contain subtours -
# tours that don't visit every city.  The lazy constraint callback
# adds new constraints to cut them off.

import sys
import math
import random
from itertools import combinations
import gurobipy as gp
from gurobipy import GRB
import parser
import os
import time
import pickle


# points: a list of points
def optimize(filename, timelimit=3600 * 12, MIPGap = 0):
    print("Solving %s..." %filename)
    print("Time Limit: ", timelimit)
    print("Stop at Gap: ", MIPGap)
    points = parser.tsp_instance_parser(os.path.join("tsp_instances", filename))

    # Callback 1 - use lazy constraints to eliminate sub-tours
    # Callback 2 - log bunch of stuff
    def custom_callback(model, where):
        if where == gp.GRB.Callback.MIP:
            cur_obj = model.cbGet(gp.GRB.Callback.MIP_OBJBST)
            cur_bd = model.cbGet(gp.GRB.Callback.MIP_OBJBND)

            # Did objective value or best bound change?
            if model._obj != cur_obj or model._bd != cur_bd:
                model._obj = cur_obj
                model._bd = cur_bd
                model._data.append([time.time() - model._start, cur_obj, cur_bd])
            with open(os.path.join("results/%s.pkl" %filename), "wb") as f:
                pickle.dump(model._data, f, protocol=2)

        if where == GRB.Callback.MIPSOL:
            vals = model.cbGetSolution(model._vars)
            # find the shortest cycle in the selected edge list
            tour = subtour(vals)
            if len(tour) < n:
                # add subtour elimination constr. for every pair of cities in tour
                model.cbLazy(gp.quicksum(model._vars[i, j]
                                        for i, j in combinations(tour, 2))
                            <= len(tour)-1)


    # Given a tuplelist of edges, find the shortest subtour

    def subtour(vals):
        # make a list of edges selected in the solution
        edges = gp.tuplelist((i, j) for i, j in vals.keys()
                            if vals[i, j] > 0.5)
        unvisited = list(range(n))
        cycle = range(n+1)  # initial length has 1 more city
        while unvisited:  # true if list is non-empty
            thiscycle = []
            neighbors = unvisited
            while neighbors:
                current = neighbors[0]
                thiscycle.append(current)
                unvisited.remove(current)
                neighbors = [j for i, j in edges.select(current, '*')
                            if j in unvisited]
            if len(cycle) > len(thiscycle):
                cycle = thiscycle
        return cycle    
    
    n = len(points)

    # Dictionary of Euclidean distance between each pair of points

    dist = {(i, j):
            math.sqrt(sum((points[i][k]-points[j][k])**2 for k in range(2)))
            for i in range(n) for j in range(i)}

    m = gp.Model()

    # Create variables

    vars = m.addVars(dist.keys(), obj=dist, vtype=GRB.BINARY, name='e')
    for i, j in vars.keys():
        vars[j, i] = vars[i, j]  # edge in opposite direction

    # You could use Python looping constructs and m.addVar() to create
    # these decision variables instead.  The following would be equivalent
    # to the preceding m.addVars() call...
    #
    # vars = tupledict()
    # for i,j in dist.keys():
    #   vars[i,j] = m.addVar(obj=dist[i,j], vtype=GRB.BINARY,
    #                        name='e[%d,%d]'%(i,j))


    # Add degree-2 constraint

    m.addConstrs(vars.sum(i, '*') == 2 for i in range(n))

    # Using Python looping constructs, the preceding would be...
    #
    # for i in range(n):
    #   m.addConstr(sum(vars[i,j] for j in range(n)) == 2)


    # Optimize model

    m._vars = vars

    # Variables required for logging
    m._obj = None
    m._bd = None
    m._data = []
    m._start = time.time()

    m.Params.LazyConstraints = 1
    m.Params.timelimit = timelimit
    m.Params.MIPGap = MIPGap
    # m.Params.Threads = 48
    m.optimize(callback=custom_callback)

    vals = m.getAttr('X', vars)
    tour = subtour(vals)
    assert len(tour) == n

    print('')
    print('Optimal tour: %s' % str(tour))
    print('Optimal cost: %g' % m.ObjVal)
    print('')
    return m


if __name__ == "__main__":
    coords = parser.tsp_instance_parser("tsp_instances/lin318.tsp")
    optimize(coords)