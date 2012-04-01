local scene = helpers.newScene("lua.scene_file");
local json = require("json");

function scene:onCreate()

	local backButton = helpers.newBackButton(self.view, "images/buttons/back_button.png");
	local levelData = helpers.readJSONFromFile("data/level1.json", system.ResourceDirectory);
	local levelDataString = json.encode(levelData);
	
	local label1 = helpers.newLabel
	{
		parent = self.view,
		text = "Level data json: " .. levelDataString,
		fontSize = 32,
		color = { 255, 255, 255, 255 },
		x = "center",
		y = 250,
		width = 300
	};
	
	levelData.customProperty = "Boo";
	levelData.jeremyTest = "Jeremy J.";
	helpers.writeJSONToFile(levelData, "data/level2.json", system.ResourceDirectory);
	
end

return scene;