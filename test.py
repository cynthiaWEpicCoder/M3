import pandas as pd
import gurobipy as gp
from gurobipy import GRB
import re
import math

# ----------------------------
# 1. Read and Process Center Data
# ----------------------------
centersDF = pd.read_csv('unpack_out.csv', header=None, names=['geometry'])

def extract_xy(point_str):
    # Regular expression to extract coordinates from a POINT string.
    match = re.search(r"POINT\s*\(\s*([-\d\.]+)\s+([-\d\.]+)\s*\)", point_str)
    if match:
        x = float(match.group(1))
        y = float(match.group(2))
        return pd.Series({'x': x, 'y': y})
    else:
        return pd.Series({'x': None, 'y': None})

centersDF[['x', 'y']] = centersDF['geometry'].apply(extract_xy)
centersDF = centersDF.dropna(subset=['x', 'y'])
centersDF.reset_index(drop=True, inplace=True)

print("Centers Data:")
print(centersDF)

# ----------------------------
# 2. Read and Process Point Data
# ----------------------------
points_df = pd.read_csv('output_grid.csv')  # Assumes columns: GSI_x, GSI_y, value
points_df = points_df.dropna(subset=['GSI_x', 'GSI_y', 'value'])
points_df.reset_index(drop=True, inplace=True)

print("Points Data:")
print(points_df)

# ----------------------------
# 3. Define Helper Function for Distance
# ----------------------------
def dist(x1, y1, x2, y2):
    """Euclidean distance."""
    return math.sqrt((x2 - x1)**2 + (y2 - y1)**2)

# ----------------------------
# 4. Create the Gurobi Model
# ----------------------------
model = gp.Model('center_selection')

# Create binary decision variables for each center.
c = {}
for idx, row in centersDF.iterrows():
    x = row['x']
    y = row['y']
    c[(x, y)] = model.addVar(vtype=GRB.BINARY, name=f"c_{x}_{y}")

# ----------------------------
# 5. Create Parameter Dictionary for Points
# ----------------------------
# a: mapping point coordinates to its associated value.
a = {}
for idx, row in points_df.iterrows():
    x = row['GSI_x']
    y = row['GSI_y']
    a[(x, y)] = row['value']

# ----------------------------
# 6. Precompute Weights for Each Center
# ----------------------------
# Weight for a center: sum_over_points [ a(point) * (1 - exp(-distance(center, point)) ]
weight = {}
for (i, j) in c.keys():
    w = 0.0
    for (x, y), a_val in a.items():
        d = dist(i, j, x, y)
        t2 = 1 - math.exp(-d)
        w += a_val * t2
    weight[(i, j)] = w

# Optional: Print weights for debugging.
print("\nCenter Weights:")
for key, w in weight.items():
    print(f"Center {key}: weight = {w}")

# ----------------------------
# 7. Set the Objective Function
# ----------------------------
# Objective: minimize the sum of selected center weights.
obj = gp.quicksum(c[(i, j)] * weight[(i, j)] for (i, j) in c.keys())
model.setObjective(obj, GRB.MINIMIZE)

# ----------------------------
# 8. Add Constraints
# ----------------------------
# Force exactly k centers to be selected.
k = 5
model.addConstr(gp.quicksum(c[(i, j)] for (i, j) in c.keys()) == k, "exactly_k_centers")

# ----------------------------
# 9. Optimize the Model
# ----------------------------
model.optimize()

# ----------------------------
# 10. Print the Results
# ----------------------------
if model.status == GRB.OPTIMAL:
    print("\nOptimal objective value:", model.ObjVal)
    selected_centers = []
    for (i, j), var in c.items():
        if var.X > 0.5:
            selected_centers.append((i, j))
    print("Selected centers:", selected_centers)
else:
    print("No optimal solution found.")
