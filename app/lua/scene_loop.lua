local scene = helpers.newScene("lua.scene_loop");
scene.timePast = 0;

function scene:onLoop(deltaSeconds, totalSeconds)

	self.timePast = self.timePast + deltaSeconds;
	
	if (self.timePast > 2) then
		self:setBackgroundColor(math.random(1, 256), math.random(1, 256), math.random(1, 256), 255);
		self.timePast = 0;
	end

end

function scene:onCreate(event)

	helpers.newBackButton(self.view, "images/buttons/back_button.png");

end

return scene;