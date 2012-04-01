local scene = helpers.newScene("lua.scene_web");

function scene:onCreate(event)

end

function scene:onEnter(event)

	helpers.newWebPopup("web/test.html", system.ResourceDirectory, true);
	
end

return scene;