import pandas as pd
import gurobipy as gp
from gurobipy import GRB
import re
from haversine import haversine, Unit
import sys
import itertools
import math
centersDF = pd.read_csv('unpack_out.csv', header=None, names=['geometry'])

import copy

# Define a function to extract x and y from a POINT string.
def extract_xy(point_str):
    # Regular expression to match a POINT string like: POINT (-89.95277208199995 35.08684412200006)
    match = re.search(r"POINT\s*\(\s*([-\d\.]+)\s+([-\d\.]+)\s*\)", point_str)
    if match:
        x = float(match.group(1))
        y = float(match.group(2))
        return pd.Series({'x': x, 'y': y})
    else:
        # Return NaN values if no match is found.
        return pd.Series({'x': None, 'y': None})

# Apply the function to the geometry column.
centersDF[['x', 'y']] = centersDF['geometry'].apply(extract_xy)

# Reset the index to have an explicit index column if desired.
centersDF.reset_index(inplace=True)
centersDF.rename(columns={'index': 'number'}, inplace=True)

print(centersDF)

points_df = pd.read_csv('output_grid.csv')

print(points_df)

def dist(x1,y1,x2,y2):
    return math.sqrt((x2-x1)**2 + (y2 - y1)**2)


#centersDF = pd.read_csv('C:\\Users\\yesle\\OneDrive\\Documents\\MATLAB\\M3\\unpack_out.csv')
model = gp.Model('model name')

#deciison variables
c = {}

for idx, row in centersDF.iterrows():
    i = row['x']
    j = row['y']
    c[(i, j)] = model.addVar(vtype=GRB.BINARY, name=f"c_{i}_{j}")

#parameters

a = {}

for idx, row in points_df.iterrows():
    x = row['GSI_x']
    y = row['GSI_y']
    a[(x, y)] = row['value']

b = copy.deepcopy(a)


def objectivizer():
    for (i,j),val1 in c.items():
        sumit = 0
        for (x, y), val2 in b.items():
            t1 = c[(i,j)]
            d = dist(i,j,x,y)
            t2 = 1 - math.exp(-d)
            sumit = sumit + t1*t2*b[(x,y)]
        b[(x,y)] = sumit
    return gp.quicksum(b[(i,j)] for i, j in b)
'''
def objectivizer():
    # Build the objective expression without modifying the original b.
    obj_expr = gp.LinExpr()
    for (i, j) in c.keys():
        # For each center, accumulate the contribution from all points.
        center_term = 0
        for (x, y), b_val in b.items():
            d = dist(i, j, x, y)
            t2 = 1 - math.exp(-d)
            center_term += t2 * b_val  # b_val is assumed to be a constant
        # Multiply the center term by the decision variable for that center.
        val = c[(i, j)].X
        if math.isnan(val):
            continue
        obj_expr += c[(i, j)] * center_term
    return obj_expr
'''
objective = objectivizer()
model.setObjective(objective, GRB.MINIMIZE)

#Constraints:
k =7
model.addConstr(gp.quicksum(c[i, j] for i, j in c) <= k)


model.optimize()


print("Optimal objective value:", model.ObjVal)