local scene = helpers.newScene("lua.scene_text");

function scene:itemPicked(index)

	self.picker:dispose();
	self.picker:removeSelf();
	
end

function scene:onCreate(event)

	self.picker = helpers.newItemPicker
	{
		parent = self.view,
		data =
		{
			{ title = "Item1 No Sub" },
			{ title = "Item2", subtitle = "Item2 Subtitle" },
			{ title = "Item3", subtitle = "Item3 Subtitle" },
			{ title = "Item4", subtitle = "Item4 Subtitle" },
			{ title = "Item5", subtitle = "Item5 Subtitle" },
			{ title = "Item6", subtitle = "Item6 Subtitle" },
			{ title = "Item7", subtitle = "Item7 Subtitle" },
			{ title = "Item8", subtitle = "Item8 Subtitle" },
			{ title = "Item9", subtitle = "Item9 Subtitle" },
			{ title = "Item10", subtitle = "Item10 Subtitle" },
			{ title = "Item11", subtitle = "Item11 Subtitle" },
			{ title = "Item12", subtitle = "Item12 Subtitle" },
			{ title = "Item13", subtitle = "Item13 Subtitle" },
			{ title = "Item14", subtitle = "Item14 Subtitle" },
			{ title = "Item15", subtitle = "Item15 Subtitle" },
			{ title = "Item16", subtitle = "Item16 Subtitle" }
		},
		selected = function(event)
			print('Selected row ' .. tostring(event.target.id));
			self:itemPicked(event.target.id);
		end
	};
	
end

return scene;

