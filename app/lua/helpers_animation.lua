local sprite = require("sprite");

-- params.parent = parent to add to
-- params.spriteSheet = the createSpriteSheet object to use
-- params.x = start x
-- params.y = start.y 
function helpers.newSprite(params)

	local _sprite = sprite.newSprite(params.spriteSheet.spriteSet);
	
	if (type(params.x) == "number" and type(params.y) == "number") then
		_sprite.x = params.x;
		_sprite.y = params.y;
	end
	
	if (globalConfig.animationScale ~= nil) then
	--if (display.contentScaleX <= 0.75 or display.contentScaleY <= 0.75) then
		_sprite.xScale = globalConfig.animationScale;
		_sprite.yScale = globalConfig.animationScale;
	end
	
	_sprite:prepare("default");
	
	params.parent:insert(_sprite);
	
	function _sprite:playAnimation(name)

		self:pause();
		
		-- HACK: Work around corona bug switching animations
        timer.performWithDelay(33, function()
			print("Playing animation " .. name);
			self:prepare(name);
			self:play();
		end);

	end
	
	function _sprite:stopAnimation(name)
		self:pause();	
	end
	
	return _sprite;
	
end

-- params.spriteData = lua file (no extension) with the exported sprite sheet. The names of the files should be AnimationName_FrameName, text before the underscore denotes the animation name
-- params.imageObject = path to image file
-- params.array = if multiple sprite data files and images are needed, use this instead of spriteData and imageObject. Each object in the array should be { spriteData = ..., imageObject = ... }
-- params.duration = duration for each frame (in milliseconds)
-- return { spriteSet, sheetsAndFrames } object !!! IMPORTANT !!! call obj:dispose() when done!
-- Notes: Each AnimationName gets an AnimationName-Reverse, AnimationName-Loop, AnimationName-Bounce, AnimationName-BounceLoop added as well automagically
function helpers.newSpriteSheet(params)

	if (params.array == nil) then
		params.array = { { spriteData = params.spriteData, imageObject = params.imageObject } };
	end
	if (params.duration == nil) then
		params.duration = 33;
	end
	
	local result =
	{
		spriteSet = nil,
		sheetsAndFrames = {},
		dispose = function(self)
			for i = 1, #self.sheetsAndFrames, 1 do
				self.sheetsAndFrames[i].sheet:dispose();
			end
		end
	};
	
	print('Processing ' .. tostring(#params.array) .. ' sprite datas...');
	for s = 1, #params.array, 1 do
	
		--print('Loading animation data ' .. params.array[s].spriteData);
		local sheetData = require(params.array[s].spriteData).getSpriteSheetData();
		
		--print('Loading animation image ' .. params.array[s].imageObject);
		local spriteSheet = sprite.newSpriteSheetFromData(params.array[s].imageObject, sheetData);
		
		-- parse out all the animations
		local previousName = nil;
		local startIndex = 1;
		local frameIndexes = {};
		local frames = {};
		local count = 0;
		
		--print("Processing " .. tostring(#sheetData.frames) .. " animation frames");
		
		for i = 1, #sheetData.frames, 1 do
			--print("i: " .. tostring(i));
			local frame = sheetData.frames[i];
			local underscorePos = string.find(frame.name, "_", 1, true);
			local currentName = frame.name;

			-- find the animation name by taking everything before the first underscore
			if (underscorePos ~= nil and underscorePos > 1) then
				currentName = string.sub(currentName, 1, underscorePos - 1);
			else
				-- no underscore or it's the first character, make a single image animation with everything before the first period
				underscorePos = string.find(currentName, ".", 1, true);
				if (underscorePos ~= nil) then
					currentName = string.sub(currentName, 1, underscorePos - 1);
				end
			end
				
			-- did we change animation names? if so we need to build the animation for all the previous images
			while (previousName ~= nil and (currentName ~= previousName or i == #sheetData.frames)) do
			
				if (i == #sheetData.frames and currentName == previousName) then
					count = count + 1; -- we need one more count if we are on the very last frame and the name still matches
				end
				
				-- total duration is number of images * duration per frame
				local duration = count * params.duration;
				--print("Start index: " .. tostring(startIndex));
				-- add in the frame indexes for the animation
				for j = 0, count - 1, 1 do
					--print("FWD: " .. previousName .. ": " .. tostring(startIndex + j));
					table.insert(frameIndexes, startIndex + j);
				end
				
				table.insert(frames, { name = previousName, startIndex = (#frameIndexes - count) + 1, count = count, duration = duration, loop = 1 });
				
				if (count > 1) then
					table.insert(frames, { name = previousName .. "-Loop", startIndex = (#frameIndexes - count) + 1, count = count, duration = duration, loop = 0 });
					table.insert(frames, { name = previousName .. "-Bounce", startIndex = (#frameIndexes - count) + 1, count = count, duration = duration, loop = -1 });
					table.insert(frames, { name = previousName .. "-BounceLoop", startIndex = (#frameIndexes - count) + 1, count = count, duration = duration, loop = -2 });
				
					-- add in reverse animation frame indexes
					for j = (startIndex + count) - 1, startIndex, -1 do
						--print("REV: " .. previousName .. ": " .. tostring(j));
						table.insert(frameIndexes, j);
					end
				
					-- add additional frames for a reverse animation
					table.insert(frames, { name = previousName .. "-Reverse", startIndex = (#frameIndexes - count) + 1, count = count, duration = duration, loop = 1 });
				end
				
				startIndex = i;
				
				if (i == #sheetData.frames and previousName ~= nil and currentName ~= previousName) then
					-- we are on the very last image and it should be it's very own animation, so run through this loop one more time
					--print('Last sheet');
					previousName = currentName;
				else
					-- break out of the loop
					previousName = nil;
				end
				
				count = 0;
			end
			
			previousName = currentName;			
			count = count + 1;
		end
		
		table.insert(result.sheetsAndFrames, { sheet = spriteSheet, frames = frameIndexes, frameNames = frames });
	end
	
	-- create a multie sprite set
	print('Creating sprite set with ' .. tostring(#result.sheetsAndFrames) .. ' sprite sheets');
	result.spriteSet = sprite.newSpriteMultiSet(result.sheetsAndFrames);
	
	-- add the animations to the sprite set
	local currentIndex = 0;
	for i, sheetsAndFrames in ipairs(result.sheetsAndFrames) do
		for j, frame in ipairs(sheetsAndFrames.frameNames) do
			print(string.format("Loading animation %s, index = %d (%d), count = %d, duration = %d, loop = %d", frame.name, frame.startIndex, frame.startIndex + currentIndex, frame.count, frame.duration, frame.loop));
			sprite.add(result.spriteSet, frame.name, frame.startIndex + currentIndex, frame.count, frame.duration, frame.loop);
		end
		
		currentIndex = currentIndex + #sheetsAndFrames.frames;
	end
		
	return result;
	
end