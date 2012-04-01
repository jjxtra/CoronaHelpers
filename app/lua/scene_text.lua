local scene = helpers.newScene("lua.scene_text");

function scene:onCreate(event)

	local label1 = helpers.newLabel(
	{
		parent = self.view,
		text = "Im in the top left",
		fontSize = 32,
		color = { 255, 255, 255, 255 },
		x = "left",
		y = "top",
		tapRelease = nil,
		tapColor = nil
	});
	local label2 = helpers.newLabel(
	{
		parent = self.view,
		text = "-CENTER CLICK ME-",
		fontSize = 16,
		color = { 255, 255, 255, 255 },
		x = "center",
		y = "center",
		backgroundColor = { 0, 0, 255, 255 },
		borderColor = { 255, 0, 0, 255 },
		borderWidth = 5,
		tapRelease = function (event) end,
		tapColor = { 0, 255, 0, 255 }
	});
	print("CS: " .. label2.contentWidth);
	local label3 = helpers.newLabel(
	{
		parent = self.view,
		text = "Go Back",
		fontSize = 32,
		color = { 255, 255, 255, 255 },
		x = "right",
		y = "bottom",
		tapRelease = function (event)
			event.target.disabled = true;
			helpers.popScene();
		end,
		tapColor = nil
	});
	
end

return scene;

