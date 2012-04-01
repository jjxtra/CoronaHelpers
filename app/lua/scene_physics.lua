local scene = helpers.newScene("lua.scene_physics");
local sprite = require("sprite");
local physics = require("physics");

--physics.setDrawMode( "debug" ) -- shows collision engine outlines only
--physics.setDrawMode( "hybrid" ) -- overlays collision outlines on normal Corona objects
physics.setDrawMode( "normal" ) -- the default Corona renderer, with no collision outlines

local function onCollision( event )
        if ( event.phase == "began" ) then
 
                --print( "began: " .. event.object1.description .. " & " .. event.object2.description );
 
        elseif ( event.phase == "ended" ) then
 
                --print( "ended: " .. event.object1.description .. " & " .. event.object2.description );
 
        end
end

function scene:createMarble()

	self.marble = helpers.physicsGetObject
	{
		parent = self.view,
		displayObject = "images/other/marble1.png",
		physicsObject = { density = 1.0, friction = 0.2, bounce = 0.2, radius = "auto" },
		x = 50,
		y = 50
	};
	self.marble:applyLinearImpulse(10, 15, self.marble.x, self.marble.y);
	self.marble.onFlicked = function (event)
		self.marble:applyLinearImpulse(event.force.x, event.force.y, event.x, event.y);
		return true;
	end;
	helpers.physicsEnableFlicking(self.marble, self.marble.onFlicked);
	self.marble.description = "Marble";
	
end

function scene:createShip()

	self.ship = helpers.physicsGetObject
	{
		parent = self.view,
		displayObject = "images/other/ship1.png",
		physicsObject = "lua.physics_ship",
		physicsObjectName = "ship1",
		x = 200,
		y = 300
	};
	self.ship.description = "Ship";
	
end

function scene:createFood()

	self.food = helpers.physicsGetObject
	{
		parent = self.view,
		displayObject = "images/other/food1.png",
		physicsObject = { density = 1.0, friction = 1.0, bouncs = 0.1, radius = "auto" },
		x = 100,
		y = 300
	};
	helpers.physicsEnableDragging(self.food);
	self.food:addEventListener("collision", self.food)
	self.food.description = "Food";
	
end

function scene:createDragLabel()

	self.dragLabel = helpers.newLabel
	{
		parent = self.view,
		text = "Disable drag",
		fontSize = 32,
		color = { 255, 255, 255, 255 },
		x = "right",
		y = "top",
		tapRelease = function (event)
			if (self.dragLabel:getText() == "Disable drag") then
				self.dragLabel:setText("Enable drag");
				helpers.physicsDisableDragging(self.food);
			else
				self.dragLabel:setText("Disable drag");
				helpers.physicsEnableDragging(self.food);
			end
		end,
		tapColor = nil
	};
	
end

function scene:createFlickLabel()

	self.flickLabel = helpers.newLabel
	{
		parent = self.view,
		text = "Disable flick",
		fontSize = 32,
		color = { 255, 255, 255, 255 },
		x = "right",
		y = 75,
		tapRelease = function (event)
			if (self.flickLabel:getText() == "Disable flick") then
				self.flickLabel:setText("Enable flick");
				helpers.physicsDisableFlicking(self.marble);
			else
				self.flickLabel:setText("Disable flick");
				helpers.physicsEnableFlicking(self.marble, self.marble.onFlicked);
			end
		end,
		tapColor = nil
	};
	
end

function scene:onCreate(event)

	physics.start();
	physics.setGravity(0, 0);
	helpers.physicsAddBorder(self.view, 0.2, 1.0);

	helpers.newBackButton(self.view, "images/buttons/back_button.png");
	self:createMarble();
	self:createShip();
	self:createFood();
	self:createDragLabel();
	self:createFlickLabel();
	
	Runtime:addEventListener("collision", onCollision);
	
end

function scene:onDestroy(event)

	physics.stop();
	Runtime:removeEventListener("collision");
	
end

return scene;