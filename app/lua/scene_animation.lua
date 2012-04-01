local scene = helpers.newScene("lua.scene_animation");
local sprite = require("sprite");
local physics = require("physics");

function scene:addAnimation(name, y)

	local button1 = helpers.newButton(
	{
		parent = self.view,
		x = display.contentWidth / 2,
		y = y,
		default = "images/buttons/button-blue.png",
		over = "images/buttons/button-blue-over.png",
		onEvent = nil,
		id = "btnPlay",
		text = name,
		font = system.defaultFont,
		size = 28,
		emboss = true,
		onRelease = function(event)
			self.creature:playAnimation(name);
		end
	});
	
end

function scene.creatureTouched(event)

	helpers.physicsDragBody(event, { maxForce = 10000, frequency = 10, dampingRatio = 0.5 });

end

function scene:createCreature()

	self.creature = helpers.physicsGetSpriteObject
	{
		parent = self.view,
		spriteSheet = self.spriteSheet,
		x = 100,
		y = 100,
		physicsObject = { density = 1.0, friction = 1.0, bouncs = 0.1, radius = "auto" },
		onTouch = self.creatureTouched,
		linearDamping = 999,
		angularDamping = 999
	};
	
	self.creature.description = "Creature";
	
end

function scene:onCreate(event)

	physics.start();
	physics.setGravity(0, 0);
	
	helpers.newBackButton(self.view, "images/buttons/back_button.png");
	
	self.spriteSheet = helpers.newSpriteSheet
	{
		spriteData = "lua.sprite_creature",
		imageObject = "images/sprites/sprite_creature.png",
		duration = 200 -- 200 milliseconds per frame
	};
	
	self:createCreature();
	
	self:addAnimation("NormalToAngry", 150);
	self:addAnimation("NormalToHappy", 200);
	self:addAnimation("NormalToHungry", 250);
	self:addAnimation("NormalToAngry-Reverse", 300);
	self:addAnimation("NormalToHappy-Reverse", 350);
	self:addAnimation("NormalToHungry-Reverse", 400);

end

function scene:onExit(event)

	self.spriteSheet:dispose();
	physics.stop();

end

return scene;