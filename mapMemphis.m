% plotMultipolygonCSV.m
% This script reads a CSV file containing a MULTIPOLYGON WKT string,
% extracts the coordinate groups from the "the_geom" column, and plots each polygon.
%
% Adjust the CSV filename and import options if needed.

%% Read the CSV file
filename = 'Jurisdiction_Boundary__Memphis_20250301.csv';  % Replace with your CSV filename

% Detect import options. Adjust the delimiter if your file is tab-delimited.
opts = detectImportOptions(filename);
% If your CSV is tab-delimited, uncomment the following line:
% opts.Delimiter = '\t';

T = readtable(filename, opts);

% Check that the expected column exists
if ~ismember('the_geom', T.Properties.VariableNames)
    error('The CSV file does not contain a "the_geom" column.');
end

% For this example, we use the first row. Modify if you need to process multiple rows.
wktStr = strtrim(T.the_geom{1});

%% Pre-process the WKT string
% Expected format: 
% MULTIPOLYGON (((x1 y1, x2 y2, ...)), ((x3 y3, x4 y4, ...)), ...)
if startsWith(wktStr, 'MULTIPOLYGON')
    wktStr = extractAfter(wktStr, 'MULTIPOLYGON');
end
wktStr = strtrim(wktStr);

% Remove the outermost parentheses.
if wktStr(1)=='(' && wktStr(end)==')'
    wktStr = wktStr(2:end-1);
end

%% Split the text into individual polygons
% Polygons are separated by ")), ((".
polygonStrs = regexp(wktStr, '\)\s*,\s*\(', 'split');

%% Set up the figure for plotting
figure;
hold on;
axis equal;
xlabel('Longitude');
ylabel('Latitude');
title('Multipolygon Plot');

%% Process each polygon and plot
for k = 1:length(polygonStrs)
    % Remove any stray parentheses from the polygon string.
    polyStr = regexprep(polygonStrs{k}, '^[\(\s]+|[\)\s]+$', '');
    
    % Split the polygon string into coordinate pairs (separated by commas)
    coordPairs = strtrim(strsplit(polyStr, ','));
    numPoints = length(coordPairs);
    x = zeros(numPoints,1);
    y = zeros(numPoints,1);
    
    % Convert coordinate pairs from string to numbers
    for j = 1:numPoints
        % Split each coordinate pair by space(s)
        nums = str2num(coordPairs{j});  %#ok<ST2NM>
        if length(nums) < 2
            error('Coordinate parsing error at polygon %d, point %d.', k, j);
        end
        x(j) = nums(1);
        y(j) = nums(2);
    end
    
    % Close the polygon if not already closed
    if x(1) ~= x(end) || y(1) ~= y(end)
        x(end+1) = x(1);
        y(end+1) = y(1);
    end
    
    % Plot the polygon with markers
    plot(x, y, '-o', 'LineWidth', 1.5);
end

hold off;
