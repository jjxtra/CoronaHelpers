local scene = helpers.newScene("lua.scene_menu");

function scene:addMenu()

	helpers.newMenu
	{
		parent = self.view,
		textAndSceneNames =
		{
			"Text Example", "lua.scene_text",
			"Button Example", "lua.scene_buttons",
			"Sound Example", "lua.scene_sound",
			"Physics Example", "lua.scene_physics",
			"Animation Example", "lua.scene_animation",
			"GameLoop Example", "lua.scene_loop",
			"Web Example", "lua.scene_web",
			"File Example", "lua.scene_file",
			"Checkbox Example", "lua.scene_checkbox",
			"Picker Example", "lua.scene_picker"
		},
		fontSize = 24,
		color = { 255, 255, 255, 255 },
		tapColor = { 50, 255, 50, 255 },
		useButtons = false,
		buttonImage = "images/buttons/button-blue.png",
		buttonImageOver = "images/buttons/button-blue-over.png",
		x = "center",
		y = "center"
	};

end

function scene:onCreate(event)

	--local scrollview = require("scrollview")

	self:setBackgroundImage("images/other/flame_background.png");
	self:setBackgroundColor(75, 75, 75, 255);
	self:addMenu();
	
	-- Setup a scrollable content group
	--local topBoundary = display.screenOriginY;
	--local bottomBoundary = display.screenOriginY;
	--self.scrollview = scrollview.new{ top=topBoundary, bottom=bottomBoundary };
	
	-- Important! Add a background to the scroll view for a proper hit area
	--local scrollBackground = display.newRect(0, 0, display.contentWidth, display.contentHeight);
	--scrollBackground:setFillColor(150);
	--self.scrollview:insert(1, scrollBackground);
	--self.scrollview:addScrollBar();
		
	--self.view:insert(self.scrollview);
	

	
end

function scene:onDestroy(event)

	--self.scrollview:cleanup();

end

return scene;