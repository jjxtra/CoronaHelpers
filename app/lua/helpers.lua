helpers = {};

math.randomseed(os.time());
math.random(); math.random(); math.random();
local isAndroid = (system.getInfo("platformName") == "Android");
local isIOS = (system.getInfo("platformName") == "iPhone OS");
local isSimulator = (system.getInfo("environment") == "simulator");

display.setStatusBar(display.HiddenStatusBar);
helpers.deviceWidth = math.ceil((display.contentWidth - (display.screenOriginX * 2)) / display.contentScaleX);
helpers.deviceHeight = math.ceil((display.contentHeight - (display.screenOriginY * 2)) / display.contentScaleY);

print(string.format("Device width: %d, height: %d", helpers.deviceWidth, helpers.deviceHeight));
print(string.format("Platform: %s", system.getInfo("platformName")));

--print("Registered fonts:");
--local sysFonts = native.getFontNames();
--for k,v in pairs(sysFonts) do print(v) end

storyboard = require("storyboard");
require("lua.helpers_ui");
require("lua.helpers_scene");
require("lua.helpers_physics");
require("lua.helpers_animation");
require("lua.helpers_audio");
require("lua.helpers_io");

if (globalConfig.multiTouch) then
	system.activate("multitouch");
end

if (globalConfig.showFPS) then
	globalConfig.fpsLabel = display.newText("FPS:", 30, display.contentHeight - 50, native.systemFontBold, 32);
	local g = graphics.newGradient( { 255, 255, 255 }, { 100, 100, 100 }, "down" );
	globalConfig.fpsLabel:setTextColor(g);
	globalConfig.frameCount = 0;
	globalConfig.frameTime = 0.0;
end

function helpers.rectContainsPoint(rect, point)

	return point.x >= rect.xMin and point.y >= rect.yMin and point.x <= rect.xMax and point.y <= rect.yMax;
	
end

function helpers.newImageRect(parent, image, baseDirectory, width, height)

	baseDirectory = helpers.valueIfNil(baseDirectory, system.ResourceDirectory);
	
	if (width == nil or height == nil) then
		return display.newImage(parent, image, baseDirectory);
	end
		
	return display.newImageRect(parent, image, baseDirectory, width, height);
	
end

function helpers.valueIfNil(_value, _valueIfNil)

	if (_value == nil) then
		return _valueIfNil;
	end
	
	return _value;

end

function helpers.isAndroid()

	return isAndroid;
	
end

function helpers.isIOS()

	return isIOS;
	
end

function helpers.isSimulator()

	return isSimulator;
	
end

-- turn on ultimote remote if we asked for it and we are in the sim
if (helpers.isSimulator() and globalConfig.useUltimote) then
	print("Connecting ultimote...");
	ultimote = require("lua.ultimote");
	ultimote.setOption{ noDebug = true };
	ultimote.connect();
end

return helpers;