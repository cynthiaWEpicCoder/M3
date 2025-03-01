function [xmin, ymin, xmax, ymax] = myBoundingBox(poly)
% myBoundingBox Returns the minimum and maximum coordinates for a polyshape.
%   [xmin, ymin, xmax, ymax] = myBoundingBox(poly) computes the bounding box
%   for the input polyshape object by using its vertices.
%
%   Note: This function uses the polyshape's Vertices property.

vertices = poly.Vertices;
xmin = min(vertices(:,1));
ymin = min(vertices(:,2));
xmax = max(vertices(:,1));
ymax = max(vertices(:,2));
end