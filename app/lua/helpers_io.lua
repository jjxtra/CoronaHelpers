local json = require("json");

-- reads an object from as file as JSON
-- file : the file to read from
-- root : the root path (i.e. system.DocumentsDirectory)
function helpers.readJSONFromFile(file, root)

	local path = system.pathForFile(file, root);
	local fh = io.open(path, "r");
 
	if (fh) then
		local contents = fh:read("*a");
		fh:close();
		return json.decode(contents);
	else
		return nil;
	end
end

-- writes an object as JSON to a file
-- data : the object to write
-- file : the file to write to
-- root : the root path (i.e. system.DocumentsDirectory)
function helpers.writeJSONToFile(data, file, root)

	local path = system.pathForFile(file, root);
	os.remove(path);
	local fh = io.open(path, "w");
 
	if (fh) then
		local contents = json.encode(data);
		fh:write(contents);
		fh:close();
	end

end