local tableView = require("lua.tableview")

function helpers.setupObject(o, params)

	local g = display.newGroup();
	g.object = o;
	local parent = params.parent;
	local x = params.x;
	local y = params.y;
	local color = helpers.valueIfNil(params.color, { 255, 255, 255, 255 });
	local tapRelease = params.tapRelease;
	local tapColor = params.tapColor
	local backgroundColor = helpers.valueIfNil(params.backgroundColor, { 0, 0, 0, 0 });
	local fillColor = helpers.valueIfNil(params.fillColor, { 255, 255, 255, 255 });
	local borderColor = helpers.valueIfNil(params.borderColor, { 255, 255, 255, 255 });
	local borderWidth = helpers.valueIfNil(params.borderWidth, 0);
	
	g.parent = parent;
	o.parent = g;
	g._color = color;
	g._backgroundColor = backgroundColor;
	g._fillColor = fillColor;
	g._borderWidth = borderWidth;
	g._borderColor = borderColor;
	
	if (helpers.isSimulator()) then
		g.ultimoteObject = true;
	end
	
	if (x and type(x) == "string" and (x == "left" or x == "right" or x == "center")) then
		g._anchorX = x;
	end	
	if (y and type(y) == "string" and (y == "top" or y == "bottom" or y == "center")) then
		g._anchorY = y;
	end
	
	g._tapRelease = tapRelease;
	
	if (o.setTextColor) then
		g.setTextColor = function (self, r, g, b, a, noStore)
			if (not noStore) then
				self._color = { r, g, b, a };
			end
			self.object:setTextColor(r, g, b, a);
		end
		function g:getColor()
			return self._color;
		end
		g:setTextColor(g._color[1], g._color[2], g._color[3], g._color[4]);
	end
	
	function g:setBackgroundColor(r, g, b, a, disableUpdate)
		self._backgroundColor = { r, g, b, a };
		self:setBorderWidth(self._borderWidth);
	end
	
	function g:getBackgroundColor()
		return self._backgroundColor;
	end
	
	function g:getBorderWidth()
		return self._borderWidth;
	end
	
	function g:setBorderWidth(newBorderWidth, disableUpdate)
	
		if (self._borderRect ~= nil) then
			self._borderRect:removeSelf();
		end
		
		self._borderWidth = newBorderWidth;
		self:_updateFrame();
		
		local offset = self._borderWidth;
		local width = self.object.contentWidth + offset + offset;
		local height = self.object.contentHeight + offset + offset;

		self._borderRect = display.newRoundedRect(self, 0, 0, width, height, self._borderWidth);
		self._borderRect:setFillColor(self._backgroundColor[1], self._backgroundColor[2], self._backgroundColor[3], self._backgroundColor[4]);
		self._borderRect.strokeWidth = self._borderWidth;
		self._borderRect:setStrokeColor(self._borderColor[1], self._borderColor[2], self._borderColor[3], self._borderColor[4]);
		self:insert(self._borderRect);
		self._borderRect:toBack();

	end
	
	function g:getBorderColor()
		return self._borderColor;
	end
	
	function g:setBorderColor(newBorderColor)
		self._borderColor = newBorderColor;
		self:setBorderWidth(self._borderWidth);
	end
	
	if (o.setFillColor) then
		g.setFillColor = function (self, r, g, b, a, noStore)
			if (not noStore) then
				self._fillColor = {r, g, b, a };
			end
			self.object:setFillColor(r, g, b, a);
		end
		function g:getFillColor()
			return _fillColor;
		end
		g:setFillColor(g._fillColor[1], g._fillColor[2], g._fillColor[3], g._fillColor[4]);
	end
	
	function onTap(event)
		
		if (event.phase == "began") then
			if (event.target._isFocus) then return; end
			event.target._isFocus = true;
			
			-- TODO: Remove translate call once corona bug fixed
			if (event.target.setFillColor) then
				event.target:setFillColor(event.target._tapColor[1], event.target._tapColor[2], event.target._tapColor[3], event.target._tapColor[4], true);
				event.target:translate(1, 0);
				event.target:translate(-1, 0);
			elseif (event.target.setTextColor) then
				event.target:setTextColor(event.target._tapColor[1], event.target._tapColor[2], event.target._tapColor[3], event.target._tapColor[4], true);
			end
			display.getCurrentStage():setFocus(event.target);
		elseif (event.phase == "ended" or event.phase == "cancelled") then
			if (event.target._isFocus) then
				event.target._isFocus = false;
				display.getCurrentStage():setFocus(nil);
				-- TODO: Remove translate call once corona bug fixed
				if (event.target.setFillColor) then
					event.target:setFillColor(event.target._color[1], event.target._color[2], event.target._color[3], event.target._color[4]);
					event.target:translate(1, 0);
					event.target:translate(-1, 0);			
				elseif (event.target.setTextColor) then
					event.target:setTextColor(event.target._color[1], event.target._color[2], event.target._color[3], event.target._color[4]);
				end
				if (event.phase == "ended" and helpers.rectContainsPoint(event.target.contentBounds, { x = event.x, y = event.y })) then
					event.target._tapRelease(event);
				end
			end
		end
	end
	
	function g:_updateFrame()
		local offset = self._borderWidth;
		
		self.contentWidth = self.object.contentWidth + offset + offset;
		self.contentHeight = self.object.contentHeight + offset + offset;
		self.object.x = self.contentWidth / 2;
		self.object.y = self.contentHeight / 2;
		self.xReference = self.contentWidth / 2;
		self.yReference = self.contentHeight / 2;
		
		if (self._anchorX) then
			if (self._anchorX == "left") then
				self.x = (self.contentWidth / 2) + 10;
			elseif (self._anchorX == "right") then
				self.x = self.parent.contentWidth - (self.contentWidth / 2) - 10;
			elseif (self._anchorX == "center") then
				self.x = (self.parent.contentWidth / 2);
			end
		end

		if (self._anchorY) then
			if (self._anchorY == "top") then
				self.y = (self.contentHeight / 2) + 10;
			elseif (self._anchorY == "bottom") then
				self.y = self.parent.contentHeight - (self.contentHeight / 2) - 10;
			elseif (self._anchorY == "center") then
				self.y = (self.parent.contentHeight / 2);
			end
		end
	end
	
	function g:_updateElements()

		if (self._borderWidth ~= 0 or self._backgroundColor[4] ~= 0) then
			self:setBorderWidth(self._borderWidth);
		end
		
	end
	
	function g:_update()

		self:_updateFrame();
		self:_updateElements();
		
	end
	
	g:insert(o);	
	g:_update(true);
	
	if (x and type(x) == "number") then
		g.x = x;
	end
	if (y and type(y) == "number") then
		g.y = y;
	end
	
	if (tapRelease) then
		if (tapColor) then
			g._tapColor = tapColor;
		else
			g._tapColor = { 0, 255, 0, 255 };
		end
		g:addEventListener("touch", onTap);
	end
	
	parent:insert(g);
	--setmetatable(g, { __index = o });
	
	return g;
	
end

-- creates a new label
-- params contains:
-- parent : the owner of the label
-- x : x position
-- y : y position
-- width : the width of the label (optional)
-- text : the text for the label
-- fontSize : the font size
-- font : optional font name, if not specified, globalConfig.font is used
-- color : the label color (array of 4 numbers rgba)
-- backgroundColor : the label background color (array of 4 numbers rgba)
-- borderColor : optional border color
-- borderWidth : optional border width
-- tapRelease : event for tap release event
-- tapColor : color for when label is tapped
-- return value has function setText for changing the text, and getText for getting the text
function helpers.newLabel(params)

	params.width = helpers.valueIfNil(params.width, 0);
	params.font = helpers.valueIfNil(params.font, globalConfig.font);
	params.fontSize = helpers.valueIfNil(params.fontSize, globalConfig.fontSize);
	
	local l = display.newText(params.parent, params.text, 0, 0, params.width, 0, params.font, params.fontSize);
	l.contentWidth = l.contentWidth + 8;
	l.contentHeight = l.contentHeight + 8;
	if (params.color) then
		l:setTextColor(params.color[1], params.color[2], params.color[3], params.color[4]);
	end
	local wrapper = helpers.setupObject(l, params);
	
	function wrapper:setText(newText)
		if (newText) then
			self.object:removeSelf();
			self.object = display.newText(self, newText, 0, 0, params.width, 0, params.font, params.fontSize);
			self.object.contentWidth = self.object.contentWidth + 8;
			self.object.contentHeight = self.object.contentHeight + 8;
			self:insert(self.object);
			self:_update();
		end
	end
	
	function wrapper:getText()
		return self.object.text;
	end
	
	return wrapper;

end

-- creates a checkbox
-- params contains:
-- parent : the owner of the checkbox
-- x : the x position of the checkbox
-- y : the y position of the checkbox
-- width : the width of the checkbox
-- height : the height of the checkbox
-- checkedImage : image for check state (optional, if nil default of images/buttons/checkbox-checked.png is used)
-- uncheckedImage : image for uncheck state (optional, if nil default of images/buttons/checkbox-unchecked.png is used)
-- baseDirectory : baseDirectory for images (i.e. system.ResourceDirectory)
-- text : string containing text to display to the right of the checkbox
-- fontSize : font size for the text
-- font : optional font for the title, if nil globalConfig.font is used
-- color : color for text
-- checkChanging : return false to disallow changing the check box, signature is function(self) ... end -- self is the checkbox about to change check
-- checkedChanged : event that can execute when checked property changes, signature is function(self) ... end -- self is the checkbox
-- returns : the checkbox, contains checked property (bool), and setChecked(self, bool)
function helpers.newCheckBox(params)

	local checkBoxGroup = display.newGroup();
	
	params.checkedImage = helpers.valueIfNil(params.checkedImage, "images/buttons/checkbox-checked.png");
	params.uncheckedImage = helpers.valueIfNil(params.uncheckedImage, "images/buttons/checkbox-unchecked.png");
	
	function checkBoxGroup:setChecked(checked)
		if (self.checked ~= nil and self.checked ~= checked) then
			if (self.currentImage ~= nil) then
				self.currentImage:removeSelf();
			end
			local image;
			if (checked) then
				image = checkBoxGroup.checkedImage;
			else
				image = checkBoxGroup.uncheckedImage;
			end
		
			self.checked = checked;
			self.currentImage = helpers.newImageRect(self, image, checkBoxGroup.baseDirectory, params.width, params.height);
			self:insert(self.currentImage);
		
			if (self.checkedChanged ~= nil) then
				self:checkedChanged();
			end
		end
	end
	
	local titleLabel = nil;
	checkBoxGroup.baseDirectory = params.baseDirectory;
	checkBoxGroup.checkedImage = params.checkedImage;
	checkBoxGroup.uncheckedImage = params.uncheckedImage;
	checkBoxGroup.checkedChanged = params.checkedChanged;
	checkBoxGroup.currentImage = helpers.newImageRect(checkBoxGroup, params.uncheckedImage, params.baseDirectory, params.width, params.height);
	checkBoxGroup.contentWidth = checkBoxGroup.currentImage.contentWidth;
	checkBoxGroup.contentHeight = checkBoxGroup.currentImage.contentHeight;
	checkBoxGroup:insert(checkBoxGroup.currentImage);
	checkBoxGroup.checked = false;
	
	if (params.title) then
		titleLabel = helpers.newLabel
		{
			parent = checkBoxGroup,
			text = params.title,
			color = params.titleColor,
			size = params.titleSize,
			x = "right",
			y = "center"
		};
	end

	checkBoxGroup:addEventListener("touch", function(event)
		if (event.phase == "ended") then
			event.target:setChecked(not event.target.checked);
		end
	end);
	
	helpers.setupObject(checkBoxGroup, params);
	
	if (titleLabel) then
		checkBoxGroup.contentWidth = checkBoxGroup.contentWidth + 20 + titleLabel.contentWidth;
		checkBoxGroup.contentHeight = checkBoxGroup.currentImage.contentHeight;
		titleLabel:_update();
	end
	
	 return checkBoxGroup;
end

-- creates a radio group
-- params contains:
-- parent : the owner of the radio group
-- x : the x position of the radio group
-- y : the y position of the radio group
-- items : array of strings for captions, i.e. { "item1", "item2", "item3" }
-- titleSize : font size for titles
-- titleColor : font color for titles
-- checkedChanged : event that can execute when checked property changes, signature is function(self) ... end -- self is the radio group
-- checkedImage : image for check state (optional, if nil default of images/buttons/radiobutton-checked.png is used)
-- uncheckedImage : image for uncheck state (optional, if nil default of images/buttons/radiobutton-unchecked.png is used)
-- returns : the radio group, contains selectedIndex property, will be -1 if no item selected yet and setSelectedIndex(index)
function helpers.newRadioGroup(params)

	local radioGroup = display.newGroup();
	local y = 0;
	radioGroup.selectedIndex = -1;
	radioGroup.checkedChanged = params.checkedChanged;
	
	function radioGroup:setSelectedIndex(idx)
		if (idx == -1) then
			for i = 1, self.numChildren, 1 do
				self[i][1]._disableClearing = true;
				self[i][1]:setChecked(false);
				self[i][1]._disableClearing = false;
			end
		else
			self[idx][1]:setChecked(true);
		end
		
		self.selectedIndex = idx;
	end
	
	if (params.titleSize == nil) then
		params.titleSize = 24;
	end
	if (params.titleColor == nil) then
		params.titleColor = { 255, 255, 255, 255 };
	end
	if (params.checkedImage == nil) then
		params.checkedImage = "images/buttons/radiobutton-checked.png";
	end
	if (params.uncheckedImage == nil) then
		params.uncheckedImage = "images/buttons/radiobutton-unchecked.png";
	end
	
	for i = 1, #params.items, 1 do
		local checkbox = helpers.newCheckBox
		{
			parent = radioGroup,
			x = 0,
			y = y,
			title = params.items[i],
			titleSize = params.titleSize,
			titleColor = params.titleColor,
			checkedImage = params.checkedImage,
			uncheckedImage = params.uncheckedImage,
			checkedChanged = function(self)
				local tmp = 1;
				if (not self.checked) then tmp = 0; end
				--print(string.format("CHECK CHANGE, IDX: %d, Checked: %d", self._index, tmp));
				if (self._disableClearing) then
					--print("Disable clearing for index " .. tostring(self._index));
				else
					--print("Checking " .. tostring(self.parent.parent.numChildren) .. " radio children...");
					for j = 1, self.parent.parent.numChildren, 1 do
						if (self.parent.parent[j][1] ~= self) then
							self.parent.parent[j][1]._disableClearing = true;
							self.parent.parent[j][1]:setChecked(false);
							self.parent.parent[j][1]._disableClearing = false;
							--print("Unchecked index " .. tostring(j));
						else
							--print("Skipped index " .. tostring(j));
						end
					end
					
					local newSelectedIndex;
					
					if (self.checked) then
						newSelectedIndex = self._index;
					else
						newSelectedIndex = -1;
					end
					
					if (newSelectedIndex ~= self.parent.parent.selectedIndex) then
						self.parent.parent.selectedIndex = newSelectedIndex;
						if (self.parent.parent.checkedChanged ~= nil) then
							self.parent.parent:checkedChanged();
						end
					end
				end
			end
		};
		y = y + checkbox.contentHeight + 10;
		checkbox._index = i;
	end
	
	helpers.setupObject(radioGroup, params);
			
	return radioGroup;
	
end

-- creates an image
-- params contains:
-- parent : the owner of the image
-- x : x position of the image (center)
-- y : y position of the image (center)
-- width : width of the image
-- height : height of the image
-- file : the image file
-- baseDirectory : the base directory (i.e. system.ResourceDirectory)
-- tapRelease : callback for tapRelease event
-- tapColor : color to change to when tapped
function helpers.newImage(params)

	local img = helpers.newImageRect(params.parent, params.file, params.baseDirectory, params.width, params.height);
	
	return helpers.setupObject(img, params);
	
end

-- creates a full screen web popup
-- url -  the url to load
-- baseUrl - if a file, the path of the data (i.e. system.DocumentsDirectory or system.ResourcesDirectory) (optional)
-- popOnClose - whether to call helpers.popScene if a close event is called
-- url click - function to callback when urls are clicked, event contains event.url indicating the clicked url and callback returns true to load the url, false to cancel (optional but recommended)
-- remarks: use <a href="corona:close">...</a> to close the browser
-- remarks: DO NOT pope the scene in the url click function, instead use popOnClose = true
function helpers.newWebPopup(url, baseUrl, popOnClose, urlClick)

	native.showWebPopup(url, { baseUrl = baseUrl, urlRequest = function (event)
		if (event.url == "corona:close") then
			timer.performWithDelay(1, function(_event)
				helpers.closeWebPopup();
				if (popOnClose) then
					timer.performWithDelay(1, function(__event) helpers.popScene(); end);
				end
			end);			

			return false;
		end
		
		if (urlClick ~= nil) then
			return urlClick(event);
		end
		
		return true;
	end });
end

-- closes any existing web popup
function helpers.closeWebPopup()

	native.cancelWebPopup();
	
end

-- Creates a back button that pops the scene when tapped
-- parent - the owner for the image
-- imageFile - the file to load and display, if nil default is used (images/buttons/back_button.png)
-- baseDirectory - base directory for image (i.e. system.ResourceDirectory)
-- width - back button width
-- height - back button height
function helpers.newBackButton(parent, imageFile, baseDirectory, width, height)

	if (imageFile == nil) then
		imageFile = "images/buttons/back_button.png";
	end
	
	local img = helpers.newImageRect(parent, imageFile, baseDirectory, width, height);
	local params =
	{
		parent = parent,
		x = "left",
		y = "top",
		tapRelease = function (event)
			helpers.popScene();
		end,
		tapColor = { 50, 255, 50, 255 };
	};
	return helpers.setupObject(img, params);

end

-- Create a menu
-- params contains:
-- parent : the container for the menu
-- textAndSceneNames : an array of text, scene names to navigate to when menu item is clicked (i.e. { "Play", "scene_play", "Help", "scene_help" })
-- useButtons : boolean
-- fontSize : the font size of the text
-- font : the font for the text
-- color : the color of the text
-- tapColor : the color of the text when tapped
-- buttonImage : image (if useButtons is true)
-- buttonImageOver : image for tap (if useButtons is true)
-- baseDirectory : base directory for images (i.e. system.ResourceDirectory)
-- returns : the menu container
function helpers.newMenu(params)

	local y = 0;
	local totalHeight = 0;
	local increment;
	local count = #params.textAndSceneNames;
	local menuGroup = display.newGroup();
	local font = params.font;
	
	if (font == nil) then
		font = globalConfig.font;
	end
	
	menuGroup.contentWidth = params.parent.contentWidth;
	
	for i = 1, count, 2 do
	
		if (i ~= 1) then
			totalHeight = totalHeight + 10;
		end
		
		if (params.useButtons) then
			local button1 = helpers.newButton
			{
				parent = menuGroup,
				x = menuGroup.contentWidth / 2,
				y = 0,
				default = params.buttonImage,
				over = params.buttonImageOver,
				text = params.textAndSceneNames[i],
				baseDirectory = params.baseDirectory,
				font = font,
				fontSize = params.fontSize,
				emboss = true,
				onRelease =  function (event)
					helpers.pushScene(params.textAndSceneNames[i + 1]);
				end
			};
			totalHeight = totalHeight + button1.contentHeight;
		else
			local label1 = helpers.newLabel
			{
				parent = menuGroup,
				text = params.textAndSceneNames[i],
				fontSize = params.fontSize,
				color = params.color,
				x = "center",
				y = 0,
				tapRelease = function (event)
					helpers.pushScene(params.textAndSceneNames[i + 1]);
				end,
				tapColor = params.tapColor
			};
			totalHeight = totalHeight + label1.contentHeight;
		end
	end

	-- reposition everything now that we know the total height...
	menuGroup.contentHeight = totalHeight;
	y = menuGroup[1].contentHeight / 2;
	for i = 1, menuGroup.numChildren, 1 do
		menuGroup[i].y = y;
		y = y + menuGroup[i].contentHeight + 10;
	end
			
	if (params.x and params.y) then
		if (type(params.x) == "string" and params.x == "center") then
			menuGroup.x = (params.parent.contentWidth - menuGroup.contentWidth) / 2;
		elseif (type(params.x) == "number") then
			menuGroup.x = params.x;
		end
		
		if (type(params.y) == "string" and params.y == "center") then
			menuGroup.y = (params.parent.contentHeight - menuGroup.contentHeight) / 2;
		elseif (type(params.y) == "number") then
			menuGroup.y = params.y;
		end		
	end
	
	params.parent:insert(menuGroup);
	
	return menuGroup;

end

-- create a new native text box for input
-- params contains:
-- parent : the parent for the textbox
-- x : the x position (top left) of the text box
-- y : the y position (top left) of the text box
-- width : the width of the text box
-- height : the height of the text box
-- font : font name for text box
-- fontSize : font size for text box
-- callback : callback for text box, signature is function(event) ... end, contains following event.phase:
	-- began : the keyboard appeared, the user is about to type
	-- ended : the keyboard was dismissed or the user went to another text field
	-- submitted : the user pressed the "return", "done" or "submit" button on the keyboard
-- returns : an object with a getText method and setText method
function helpers.newTextBox(params)
	local textBoxWrapper = display.newRect(params.parent, params.x, params.y, params.width, params.height);
	
	if (helpers.isSimulator()) then
		local g = graphics.newGradient( { 200, 200, 200, 255 }, { 100, 100, 100, 255 }, "down" );
		textBoxWrapper:setFillColor(g);
	end
	
	textBoxWrapper._removeSelf = textBoxWrapper.removeSelf;
	textBoxWrapper.removeSelf = function(self)
		self:_removeSelf();
		self.textBox:removeSelf();
		self.textBox = nil;
	end;
	
	textBoxWrapper.getText = function(self)
		return self.textBox.text;
	end
	
	textBoxWrapper.setText = function(self, text)
		self.textBox.text = text;
	end
	
	local textBox = native.newTextField(params.x, params.y, params.width, params.height);
	if (params.font ~= nil) then
		textBox.font = params.font;
	end
	if (params.fontSize ~= nil) then
		textBox.fontSize = params.fontSize;
	end
	textBox:addEventListener("userInput",
		function(event)
			
			if (event.phase == "submitted") then
				native.setKeyboardFocus(nil);
			end
			
			if (params.callback ~= nil) then
				event.target = textBox;
				params.callback(event);
			end
			
		end
	);
	
	textBoxWrapper.textBox = textBox;
	params.parent:insert(textBoxWrapper);
	
	return textBoxWrapper;
end

---------------
-- Button class
function helpers.newButton(params)

	-----------------
	-- Helper function for newButton utility function below
	local function newButtonHandler( self, event )

		if (self.disabled) then return false; end
		
		local result = true

		local default = self[1]
		local over = self[2]
		
		-- General "onEvent" function overrides onPress and onRelease, if present
		local onEvent = self._onEvent
		
		local onPress = self._onPress
		local onRelease = self._onRelease

		local buttonEvent = {}
		if (self._id) then
			buttonEvent.id = self._id
		end

		local phase = event.phase
		if "began" == phase then
			if over then 
				default.isVisible = false
				over.isVisible = true
			end

			if onEvent then
				buttonEvent.phase = "press"
				result = onEvent( buttonEvent )
			elseif onPress then
				result = onPress( event )
			end

			-- Subsequent touch events will target button even if they are outside the stageBounds of button
			display.getCurrentStage():setFocus(event.target)
			self.isFocus = true
			
		elseif self.isFocus then
			local bounds = self.stageBounds
			local x,y = event.x,event.y
			local isWithinBounds = 
				bounds.xMin <= x and bounds.xMax >= x and bounds.yMin <= y and bounds.yMax >= y

			if "moved" == phase then
				if over then
					-- The rollover image should only be visible while the finger is within button's stageBounds
					default.isVisible = not isWithinBounds
					over.isVisible = isWithinBounds
				end
				
			elseif "ended" == phase or "cancelled" == phase then 
				if over then 
					default.isVisible = true
					over.isVisible = false
				end
				
				if "ended" == phase then
					-- Only consider this a "click" if the user lifts their finger inside button's stageBounds
					if isWithinBounds then
						if onEvent then
							buttonEvent.phase = "release"
							result = onEvent( buttonEvent )
						elseif onRelease then
							result = onRelease( event )
						end
					end
				end
				
				-- Allow touch events to be sent normally to the objects they "hit"
				display.getCurrentStage():setFocus(nil)
				self.isFocus = false
			end
		end

		return result
	end

	local button, default, over, size, font, textColor, offset
	
	if params.default then
		button = display.newGroup()
		if (params.width and params.height) then
			default = helpers.newImageRect(button, params.default, params.baseDirectory, params.width, params.height )
		else
			default = display.newImage(params.default, params.baseDirectory)
		end
		
		button:insert( default, true )
	end
	
	if params.over then
		if (params.width and params.height) then
			over = helpers.newImageRect(button, params.over, params.baseDirectory, params.width, params.height )
		else
			over = display.newImage(params.over, params.baseDirectory)
		end
		over.isVisible = false
		button:insert( over, true )
	end
	
	-- Public methods
	function button:setText( newText )
	
		local labelText = self.text
		if ( labelText ) then
			labelText:removeSelf()
			self.text = nil
		end

		local labelShadow = self.shadow
		if ( labelShadow ) then
			labelShadow:removeSelf()
			self.shadow = nil
		end

		local labelHighlight = self.highlight
		if ( labelHighlight ) then
			labelHighlight:removeSelf()
			self.highlight = nil
		end
		
		if ( params.fontSize and type(params.fontSize) == "number" ) then size=params.fontSize else size=20 end
		if ( params.font ) then font=params.font else font=globalConfig.font end
		if ( params.textColor ) then textColor=params.textColor else textColor={ 255, 255, 255, 255 } end
		
		-- Optional vertical correction for fonts with unusual baselines (I'm looking at you, Zapfino)
		if ( params.offset and type(params.offset) == "number" ) then offset=params.offset else offset = 0 end
		
		if ( params.emboss ) then
			-- Make the label text look "embossed" (also adjusts effect for textColor brightness)
			local textBrightness = ( textColor[1] + textColor[2] + textColor[3] ) / 3
			
			labelHighlight = display.newText( newText, 0, 0, font, size )
			if ( textBrightness > 127) then
				labelHighlight:setTextColor( 255, 255, 255, 20 )
			else
				labelHighlight:setTextColor( 255, 255, 255, 140 )
			end
			button:insert( labelHighlight, true )
			labelHighlight.x = labelHighlight.x + 1.5; labelHighlight.y = labelHighlight.y + 1.5 + offset
			self.highlight = labelHighlight

			labelShadow = display.newText( newText, 0, 0, font, size )
			if ( textBrightness > 127) then
				labelShadow:setTextColor( 0, 0, 0, 128 )
			else
				labelShadow:setTextColor( 0, 0, 0, 20 )
			end
			button:insert( labelShadow, true )
			labelShadow.x = labelShadow.x - 1; labelShadow.y = labelShadow.y - 1 + offset
			self.shadow = labelShadow
		end
		
		labelText = display.newText( newText, 0, 0, font, size )
		labelText:setTextColor( textColor[1], textColor[2], textColor[3], textColor[4] )
		button:insert( labelText, true )
		labelText.y = labelText.y + offset
		self.text = labelText
	end
	
	if params.text then
		button:setText( params.text )
	end
	
	if ( params.onPress and ( type(params.onPress) == "function" ) ) then
		button._onPress = params.onPress
	end
	if ( params.onRelease and ( type(params.onRelease) == "function" ) ) then
		button._onRelease = params.onRelease
	end
	
	if (params.onEvent and ( type(params.onEvent) == "function" ) ) then
		button._onEvent = params.onEvent
	end
		
	-- Set button as a table listener by setting a table method and adding the button as its own table listener for "touch" events
	button.touch = newButtonHandler
	button:addEventListener( "touch", button )

	if params.x then
		button.x = params.x
	end
	
	if params.y then
		button.y = params.y
	end
	
	if params.id then
		button._id = params.id
	end
	
	params.parent:insert(button);
	
	if (helpers.isSimulator()) then
		button.ultimoteObject = true;
	end
	
	return button
end

-- show a new item picker, parameters include:
-- parent = parent to add table view to
-- top = y coordinate for the top of the picker
-- data = array of items containing title, subtitle and image
-- cell_background = background image for each table cell OPTIONAL
-- cell_background_selected = background image for a selected cell OPTIONAL
-- cellHeight = height for each cell OPTIONAL
-- color = text color
-- font = font
-- fontSize = font size
-- backgroundColor = background color (i.e. { 255, 255, 255 }) OPTIONAL
-- render = fired when a row needs to be rendered, OPTIONAL, there is default render behavior
-- selected = fired when a row is selected, signature is callback(event), event.target is the table view and contains an id property which can index back into array
function helpers.newItemPicker(params)

	params.cell_background = helpers.valueIfNil(params.cell_background, "images/buttons/table_cell.png");
	params.cell_background_selected = helpers.valueIfNil(params.cell_background_selected, "images/buttons/table_cell_selected.png");
	params.backgroundColor = helpers.valueIfNil(params.backgroundColor, { 255, 255, 255 });
	params.color = helpers.valueIfNil(params.color, { 0, 0, 0 });
	params.top = helpers.valueIfNil(params.top, 0);
	params.cellHeight = helpers.valueIfNil(params.cellHeight, 93);
	params.font = helpers.valueIfNil(params.font, globalConfig.font);
	params.fontSize = helpers.valueIfNil(params.fontSize, globalConfig.fontSize);
	
	local topBoundary = display.screenOriginY + params.top;
	local bottomBoundary = display.screenOriginY + 0;

	myList = tableView.newList
	{
		data = params.data,
		default = params.cell_background,
		over = params.cell_background_selected,
		onRelease = params.selected,
		cellHeight = params.cellHeight,
		top = topBoundary,
		bottom = bottomBoundary,
		callback = function(row)
			local g = display.newGroup();

			if (row.image ~= nil) then
				local img = display.newImage(row.image);
				g:insert(img);
				img.x = math.floor(img.width*0.5 + 6);
				img.y = math.floor(img.height*0.5);
			end

			if (row.title ~= nil) then
				local title =  display.newText( row.title, 0, 0, params.font, params.fontSize );
				title:setTextColor(params.color[1], params.color[2], params.color[3]);
				g:insert(title);
				
				if (img == nil) then
					title.x = params.parent.contentWidth / 2;
				else
					title.x = title.width / 2 + img.width + 6;
				end
				
				if (row.subtitle == nil) then
					title.y =  params.cellHeight / 2;
				else
					title.y = 30;
				end
				
				if (row.subtitle ~= nil) then
					local subtitle =  display.newText( row.subtitle, 0, 0, params.font, params.fontSize - 4);
					subtitle:setTextColor(params.color[1], params.color[2], params.color[3]);
					g:insert(subtitle);
					
					if (img == nil) then
						subtitle.x = params.parent.contentWidth / 2;
					else
						subtitle.x = subtitle.width / 2 + img.width + 6;
					end
					
					subtitle.y = title.y + title.height + 6;
				end
			end

			return g;
		end 
	}
	
	local listBackground = display.newRect(0, 0, myList.width, myList.height);
	listBackground:setFillColor(params.backgroundColor[1], params.backgroundColor[2], params.backgroundColor[3]);
	myList:insert(1, listBackground);
	
	params.parent:insert(myList);
	
	return myList;

end