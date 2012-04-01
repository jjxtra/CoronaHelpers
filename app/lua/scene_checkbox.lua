local scene = helpers.newScene("lua.scene_checkbox");

function scene:onCreate(event)

	helpers.newBackButton(self.view);
	self.checkbox1 = helpers.newCheckBox
	{
		parent = self.view,
		x = 50,
		y = 100,
		text = "Check Me",
		fontSize = 24,
		color = { 255, 255, 255, 255 },
		checkedChanged = function(self)
			print("Check changed, new value = " .. tostring(self.checked));
		end
	};
	-- scene.checkbox1.checked contains true or false
	
	self.radiogroup1 = helpers.newRadioGroup
	{
		parent = self.view,
		x = 50,
		y = 175,
		items = { "item1", "item2", "item3" },
		checkedChanged = function(self)
			print("Radio check changed, selected index = " .. tostring(self.selectedIndex));
		end
	};
	-- scene.radiogroup1 contains selectedIndex property, -1 if none
	
	self.textBox = helpers.newTextBox{ parent = self.view, x = 50, y = 375, width = 200, height = 75, size = 34 };
	
end

return scene;