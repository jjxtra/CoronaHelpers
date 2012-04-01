local scenes = {};
local json = require("json");

-- create a new scene, the name should be the lua file name without the .lua
function helpers.newScene(name)

	print("New scene: " .. name);
	local scene = storyboard.newScene(name);
	scene._name = name;
				
	function scene:setBackgroundColor(r, g, b, a)
	
		local backgroundObject;
		if (self._backgroundImage ~= nil) then
			backgroundObject = self._backgroundImage;
		else
			if (self._backgroundColor == nil) then
				backgroundObject = display.newRect(0, 0, display.contentWidth, display.contentHeight);
			else
				backgroundObject = self._backgroundColor;
			end
			self._backgroundColor = backgroundObject;
			self.view:insert(self._backgroundColor);
			self._backgroundColor.x = display.contentWidth / 2;
			self._backgroundColor.y = display.contentHeight / 2;
		end
		
		backgroundObject:setFillColor(r, g, b, a);
		backgroundObject:toBack();
	
	end
	
	function scene:setBackgroundImage(image)
	
		if (self._backgroundColor ~= nil) then
			self._backgroundColor:removeSelf();
			self._backgroundColor = nil;
		end
		
		if (self._backgroundImage ~= nil) then
			self._backgroundImage:removeSelf();
			self._backgroundImage = nil;
		end
		
		self._backgroundImage = helpers.newImageRect(self.view, image, nil, 380, 570);
		self._backgroundImage.x = display.contentWidth / 2;
		self._backgroundImage.y = display.contentHeight / 2;
		self.view:insert(self._backgroundImage);
		self.view.contentWidth = display.contentWidth;
		self.view.contentHeight = display.contentHeight;
		self._backgroundImage:toBack();
	
	end
	
	function scene:enterFrame(event)
	
		local elapsedMilliseconds = event.time;
		local deltaSeconds = (elapsedMilliseconds - self._lastTime) / 1000.0;
		local totalSeconds = (elapsedMilliseconds / 1000.0);
		self._lastTime = elapsedMilliseconds;
		
		if (self.onLoop) then
			self:onLoop(deltaSeconds, totalSeconds);
		end
		
		if (globalConfig.fpsLabel) then
			globalConfig.frameCount = globalConfig.frameCount + 1;
			globalConfig.frameTime = globalConfig.frameTime + deltaSeconds;
			
			if (globalConfig.frameTime >= 1.0) then
				globalConfig.frameTime = globalConfig.frameTime - 1.0;
				globalConfig.fpsLabel.text = string.format("FPS: %d", globalConfig.frameCount);
				globalConfig.fpsLabel.x = (globalConfig.fpsLabel.contentWidth / 2) + 10;
				globalConfig.fpsLabel.y = (display.contentHeight - (globalConfig.fpsLabel.contentHeight / 2)) - 10;
				globalConfig.frameCount = 0;
			end
		end
		
		if (self.view ~= nil) then
			self.view.contentWidth = display.contentWidth;
			self.view.contentHeight = display.contentHeight;
		end
		
	end

	-- restart the current scene
	function scene:restart()

		print(string.format("Restarting scene %s", self._name));
		while (self.view.numChildren ~= 0) do
			self.view[1]:removeSelf();
		end
		self._backgroundImage = nil;
		self._backgroundColor = nil;
		self:createScene();
		self:enterScene();
	
	end
	
	function scene:createScene(event)

		print("createScene: " .. self._name);
		
		self._lastTime = system.getTimer();
		
		-- force the scene to expand to the display size
		self:setBackgroundColor(0, 0, 0, 0);
		
		if (helpers.sceneInitializer ~= nil) then
		
			helpers.sceneInitializer(scene);
		
		end
		
		if (self.onCreate) then self:onCreate(event); end
		
	end

	function scene:enterScene(event)
	
		print("enterScene: " .. self._name);
		
		if (self.onEnter) then self:onEnter(event); end
		
		Runtime:addEventListener("enterFrame", self);
		
		storyboard.removeAll();
		
	end

	function scene:exitScene(event)

		print("exitScene: " .. self._name);
	
		if (self.onExit) then self:onExit(event); end
		
		Runtime:removeEventListener("enterFrame", self);
	
	end

	function scene:destroyScene(event)

		print("destroyScene: " .. self._name);
		
		while self.view.numChildren > 0 do
			display.remove(self.view[1]);
		end
		
		if (self.onDestroy) then self:onDestroy(event); end
		
	end	
	
	scene:addEventListener("createScene", scene);
	scene:addEventListener("enterScene", scene);
	scene:addEventListener("exitScene", scene);
	scene:addEventListener("destroyScene", scene);

	return scene;
	
end

-- registers a function to run on each scene create event. Signature should be function sceneInitialize(self) ... end
function helpers.registerSceneInitializer(func)

	helpers.sceneInitializer = func;

end

-- removes a previously registered scene initializer
function helpers.unregisterSceneInitializer()

	helpers.sceneInitializer = nil;

end

-- clear out all scens from history except the current scene
function helpers.clearScenes()

	if (#scenes > 0) then
	
		local current = table.remove(scenes);
		scenes = {};
		table.insert(scenes, current);
		
	end

end

-- replace the current scene without maintaining the replaced scene in the history
function helpers.replaceScene(name)

	if (#scenes > 0) then
		local previousSceneName = scenes[#scenes];
		print(string.format("Replacing scene %s from %s", name, previousSceneName));
	end
		
	storyboard.gotoScene(name);--, "fade", 500);
	
	-- get rid of current
	table.remove(scenes);
	
	-- add the new
	table.insert(scenes, name);
	
end

-- pop the current scene and go to the previous scene
function helpers.popScene()

	local currentSceneName = table.remove(scenes);
	
	if (#scenes > 0) then
		local previousSceneName = scenes[#scenes];
		print(string.format("Popping %s to %s", currentSceneName, previousSceneName));
		storyboard.gotoScene(previousSceneName);--, "fade", 500);
	end

end

-- push a new scene on to the stack
function helpers.pushScene(name)

	if (#scenes > 0) then
		local previousSceneName = scenes[#scenes];
		print(string.format("Pushing scene %s from %s", name, previousSceneName));
	end
		
	storyboard.gotoScene(name);--, "fade", 500);
	
	table.insert(scenes, name);

end