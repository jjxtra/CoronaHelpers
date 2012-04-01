local scene = helpers.newScene("lua.scene_buttons");

function scene:onCreate(event)

	self.backButton = helpers.newBackButton(self.view, "images/buttons/back_button.png");
	
	self.listButton = helpers.newButton(
	{
		parent = self.view,
		x = display.contentWidth / 2,
		y = 150,
		default = "images/buttons/button-blue.png",
		over = "images/buttons/button-blue-over.png",
		onEvent = function (event)
			self:showDropDownList();
		end,
		id = "btnPlay",
		text = "New Game",
		font = system.defaultFont,
		fontSize = 28,
		emboss = true,
		onRelease = nil
	});
	self.imageButton = helpers.newImage(
	{
		parent = self.view,
		file = "images/buttons/button-blue.png",
		x = 200,
		y = 400,
		tapRelease = function (event) end,
		tapColor = { 125, 25, 255, 255 }
	});
	
end

return scene;
