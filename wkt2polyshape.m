function poly = wkt2polyshape(wkt_str)
% wkt2polyshape Converts a WKT POLYGON or MULTIPOLYGON string into a polyshape.
%   poly = wkt2polyshape(wkt_str) returns a polyshape object.
%
%   Supports WKT strings of the form:
%      POLYGON ((x1 y1, x2 y2, ..., xn yn))
%      MULTIPOLYGON (((x1 y1, x2 y2, ..., xn yn)), ((...)), ...)
%
%   This is a basic parser and may need extension for complex WKT files.

% Remove any leading or trailing whitespace
wkt_str = strtrim(wkt_str);

if startsWith(wkt_str, 'MULTIPOLYGON')
    % Remove the "MULTIPOLYGON" keyword and outer parentheses.
    % Example: MULTIPOLYGON (((...)), ((...)), ... )
    % First, remove the keyword:
    polyStr = strrep(wkt_str, 'MULTIPOLYGON', '');
    polyStr = strtrim(polyStr);
    
    % Remove the first two and last two parentheses.
    if polyStr(1)=='(' && polyStr(2)=='('
        polyStr = polyStr(3:end-2);
    else
        error('Unexpected format in MULTIPOLYGON WKT.');
    end
    
    % Now split individual polygons on the delimiter ")), ((".
    polyStrings = strsplit(polyStr, ')), ((');
    
    % Initialize an empty polyshape.
    poly = polyshape();
    for i = 1:length(polyStrings)
        % Remove any extra parentheses.
        stri = strrep(polyStrings{i}, '(', '');
        stri = strrep(stri, ')', '');
        % Split coordinate pairs by comma.
        coordPairs = strsplit(stri, ',');
        x = [];
        y = [];
        for j = 1:length(coordPairs)
            pointStr = strtrim(coordPairs{j});
            nums = sscanf(pointStr, '%f %f');
            if numel(nums)==2
                x(end+1) = nums(1); %#ok<AGROW>
                y(end+1) = nums(2); %#ok<AGROW>
            end
        end
        % Add the extracted boundary to the polyshape.
        if ~isempty(x) && ~isempty(y)
            poly = addboundary(poly, x, y);
        end
    end

elseif startsWith(wkt_str, 'POLYGON')
    % Remove the "POLYGON" keyword.
    polyStr = strrep(wkt_str, 'POLYGON', '');
    polyStr = strtrim(polyStr);
    
    % Remove the first two and last two parentheses.
    if polyStr(1)=='(' && polyStr(2)=='('
        polyStr = polyStr(3:end-2);
    else
        error('Unexpected format in POLYGON WKT.');
    end
    
    % Split coordinate pairs by comma.
    coordPairs = strsplit(polyStr, ',');
    x = [];
    y = [];
    for j = 1:length(coordPairs)
        pointStr = strtrim(coordPairs{j});
        nums = sscanf(pointStr, '%f %f');
        if numel(nums)==2
            x(end+1) = nums(1); %#ok<AGROW>
            y(end+1) = nums(2); %#ok<AGROW>
        end
    end
    poly = polyshape(x, y);
    
else
    error('Unsupported WKT type. Only POLYGON and MULTIPOLYGON are supported.');
end

end