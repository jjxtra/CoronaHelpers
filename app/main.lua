globalConfig =
{
	showFPS = true,
	multiTouch = false,
	useUltimote = false,
	font = "MarkerFeltWide-Plain",
	fontSize = 34
};

helpers = require("lua.helpers");
helpers.registerSceneInitializer(function(self)

	print("Scene initializer executed");

end);

helpers.pushScene("lua.scene_splash");