
%% Step 1: Read CSV files and convert WKT strings to polyshape objects

% Read Memphis boundary CSV. Assumes one row representing the full multipolygon.
memTable = readtable('Jurisdiction_Boundary__Memphis_20250301.csv');
% Convert the WKT string (assume column name is 'the_geom') into a polyshape.
% You will need to implement or obtain a helper function 'wkt2polyshape'
memPoly = wkt2polyshape(memTable.the_geom{1});

% Read zipcode boundaries CSV. Each row should have a WKT multipolygon and a zipcode identifier.
zipTable = readtable('Zip_Codes__City_of_Memphis_20250301.csv');
nZip = height(zipTable);
zipPolys = cell(nZip,1);
for i = 1:nZip
    zipPolys{i} = wkt2polyshape(zipTable.the_geom{i});
end

% Read CSV with zipcode sadness values.
sadnessData = readtable('entropy_out.csv');  % with fields 'zipcode' and 'sadness'

%% Step 2: Create a 100x100 grid over the Memphis bounding box
[xmin, ymin, xmax, ymax] = myBoundingBox(memPoly);  % you can use polyshape's boundingbox
xvec = linspace(xmin, xmax, 100);
yvec = linspace(ymin, ymax, 100);
[X, Y] = meshgrid(xvec, yvec);
gridPoints = [X(:), Y(:)];
nPoints = size(gridPoints,1);

% Initialize values to 0 (points outside Memphis will remain 0)
values = zeros(nPoints,1);

%% Step 3: Filter grid points inside Memphis
inMemphis = isinterior(memPoly, gridPoints(:,1), gridPoints(:,2));

%% Step 4: For each zipcode polygon, assign the corresponding sadness value
for i = 1:nZip
    % Find grid points within this zipcode polygon
    inZip = isinterior(zipPolys{i}, gridPoints(:,1), gridPoints(:,2));
    
    % Only update points that are also inside Memphis
    idx = inZip & inMemphis;
    
    % Get zipcode identifier (adjust field name if necessary)
    zc = zipTable.ZipCode(i);  
    % Look up sadness value from the sadnessData table
    row = sadnessData(strcmp(string(sadnessData.ZipCodes), string(zc)), :);
    if ~isempty(row)
        sadnessVal = row.VulnerabilityScore;
        values(idx) = sadnessVal;
    end
end

%% Step 5: Export the grid as CSV
% Prepare table with columns: GSI_x, GSI_y, and value.
outputTable = table(gridPoints(:,1), gridPoints(:,2), values, 'VariableNames', {'GSI_x','GSI_y','value'});
writetable(outputTable, 'output_grid.csv');

%% (Optional) Plot for visualization
figure;
plot(memPoly, 'FaceAlpha', 0.1); hold on;
scatter(gridPoints(:,1), gridPoints(:,2), 15, values, 'filled');
colorbar;
title('Grid with Zipcode Sadness Values');