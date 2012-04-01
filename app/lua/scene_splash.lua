local scene = helpers.newScene("lua.scene_splash");

function scene:loadAssets()

	-- TODO: Load assets, such as audio files, images, data files, etc.

end

function scene:onCreate(event)

	self:setBackgroundColor(0, 0, 0, 255);
	
end

function scene:onEnter(event)

	local loadingLabel = helpers.newLabel
	{
		parent = self.view,
		text = "Loading...",
		fontSize = 40,
		x = "center",
		y = "center"
	};
	timer.performWithDelay(1, function()
		self:loadAssets();
		helpers.pushScene("lua.scene_menu");
	end);

end

return scene;