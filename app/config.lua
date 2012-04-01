-- background image should be 380x570
local model = system.getInfo("model");
print("Model: " .. model);
local iPhone = (string.find(model, "iPhone") ~= nil or string.find(model, "iPod") ~= nil);
local iPad =  (string.find(model, "iPad") ~= nil);

if (iPhone) then -- IPHONE

application =
{
	content =
	{
		width = 380,
		height = 570,
		scale = "letterBox",
		fps = 60,
		imageSuffix =
        {
            ["@2x"] = 1.5,
        },
	};
};

elseif (iPad) then -- IPAD

application =
{
	content =
	{
		width = 380,
		height = 507,
		scale = "letterBox",
		fps = 60,
		imageSuffix =
        {
            ["@2x"] = 1.5,
        },
	};
};

else -- DROID

application =
{
	content =
	{
		width = 320,
		height = 534,
		scale = "zoomStretch",
		fps = 60,
		imageSuffix =
        {
            ["@2x"] = 1.7,
        },
	};
};

end