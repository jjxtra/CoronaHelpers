local physics = require("physics");

-- add static border to edges of screen
function helpers.physicsAddBorder(parent, bounce, friction)

	local borderGroup = display.newGroup();
	local borderBodyElement = { density = 1.0, bounce = bounce, friction = friction }
	local r = 255;
	local g = 255;
	local b = 255;
	local a = 0;

	 -- TOP (x, y, width, height)
	local borderTop = display.newRect(0, 0, parent.contentWidth, 1);
	borderTop:setFillColor(r, g, b, a);
	physics.addBody(borderTop, "static", borderBodyElement);
	borderTop.description = "BorderTop";

	 -- BOTTOM (x, y, width, height)
	local borderBottom = display.newRect(0, parent.contentHeight - 1, parent.contentWidth, 1);
	borderBottom:setFillColor(r, g, b, a);
	physics.addBody(borderBottom, "static", borderBodyElement);
	borderBottom.description = "BorderBottom";

	-- LEFT (x, y, width, height)
	local borderLeft = display.newRect(0, 0, 1, parent.contentHeight);
	borderLeft:setFillColor(r, g, b, a);
	physics.addBody(borderLeft, "static", borderBodyElement);
	borderLeft.description = "BorderLeft";								   
	
	-- RIGHT (x, y, width, height)
	local borderRight = display.newRect(parent.contentWidth - 1, 0, 1, parent.contentHeight);
	borderRight:setFillColor(r, g, b, a);
	physics.addBody(borderRight, "static", borderBodyElement);
	borderRight.description = "BorderRight";
	
	borderGroup:insert(borderTop);
	borderGroup:insert(borderBottom);
	borderGroup:insert(borderLeft);
	borderGroup:insert(borderRight);
        
	parent:insert(borderGroup);
		
	return borderGroup;
	
end

-- params.parent : parent view to add object to
-- params.displayObject : image file to use OR a display object
-- params.physicsObject : lua file (no extension) with polygon OR a physics structure with density, friction, bounce and radius (radius can be "auto" to use contentWidth / 2)
-- params.physicsObjectName : if lua file, specifies the key in the file representing the polygon
-- params.x : starting x point
-- params.y : starting y point
-- params.width : width
-- params.height : height
function helpers.physicsGetObject(params)

	local shape;	
	if (type(params.displayObject) == "string") then
		shape = helpers.newImageRect(params.parent, params.displayObject, nil, params.width, params.height);
		params.parent:insert(shape);
	else
		shape = params.displayObject;
	end
	
	if (type(params.x) == "number" and type(params.y) == "number") then
		shape.x = params.x;
		shape.y = params.y;
	end
	
	if (type(params.physicsObject) == "string") then
		local shapedefs = require(params.physicsObject);
		local physicsData = shapedefs.physicsData(1.0);
		physics.addBody(shape, physicsData:get(params.physicsObjectName));
	else
		if (type(params.physicsObject.radius) == "string" and params.physicsObject.radius == "auto") then
			params.physicsObject.radius = shape.contentWidth / 2;
		end
		physics.addBody(shape, params.physicsObject);
	end
	
	if (helpers.isSimulator()) then
		shape.ultimoteObject = true;
	end
	
	return shape;

end

-- creates a physics object backed by a sprite object
-- params contains:
-- parent : the container for the object
-- spriteSheet : the sprite sheet to use for the sprite
-- physicsObject : the physics properties (i.e. { density = 1.0, friction = 1.0, bouncs = 0.1, radius = "auto" })
-- onTouched : callback for touch events
-- linearDamping : linear damping
-- angularDamping : angular damping
function helpers.physicsGetSpriteObject(params)

	local obj = helpers.newSprite
	{
		parent = params.parent,
		spriteSheet = params.spriteSheet,
		x = params.x,
		y = params.y
	};
	
	obj = helpers.physicsGetObject
	{
		parent = params.parent,
		displayObject = obj,
		physicsObject = params.physicsObject
	};
	
	if (params.onTouch ~= nil) then
		obj:addEventListener("touch", params.onTouch);
	end
	
	if (params.linearDamping) then
		obj.linearDamping = params.linearDamping;
	end
	if (params.angularDamping) then
		obj.angularDamping = params.angularDamping;
	end
	
	return obj;

end

-- enable dragging of a physics object
-- obj : the physics object to allow dragging by touch
function helpers.physicsEnableDragging(obj)

	if (not obj._isDraggable) then
		obj._isDraggable = true;
		obj._dragFunction =  function(event)
			helpers.physicsDragBody(event, { maxForce = 10000, frequency = 10, dampingRatio = 0.5 });
		end;
		obj:addEventListener("touch", obj._dragFunction);
		obj.linearDamping = 999;
		obj.angularDamping = 999;
	end
	
end

-- disable dragging of a physics object
-- obj : the physics object to turn off dragging by touch
function helpers.physicsDisableDragging(obj)
	if (obj._isDraggable) then
		obj._isDraggable = false;
		obj:removeEventListener("touch", obj._dragFunction);
		obj._dragFunction = nil;
	end
end

-- enable a physics object to be flicked by touching
-- obj : the physics obj to enable flicking by touch
-- callback : calls back with details on a flick (contains normal touch event which has a force property, i.e. function(event) ... end)
function helpers.physicsEnableFlicking(obj, callback)

	if (not obj._isFlickable) then
		obj._isFlickable = true;
		obj._flickFunction = function(event)
			local flickedObj = event.target;
	
			if (event.phase == "began" or event.phase == "moved") then
				if (flickedObj._prevTouchLocation == nil) then
					print(event.phase);
					display.getCurrentStage():setFocus(flickedObj);
					flickedObj._prevTouchLocation = { x = event.x, y = event.y };
				elseif (not flickedObj._flicked) then	
					flickedObj._flicked = true;
					if (callback ~= nil) then
						local force = { x = (event.x - flickedObj._prevTouchLocation.x) * 2.0, y = (event.y - flickedObj._prevTouchLocation.y) * 2.0 };
						event.force = force;
						callback(event);
					end
				end
			else
				print(event.phase);
				flickedObj._prevTouchLocation = nil;
				flickedObj._flicked = false;
				display.getCurrentStage():setFocus(nil);
			end
		end;

		obj:addEventListener("touch", obj._flickFunction);
	end

end

-- disable flicking a physics object by touch
-- obj : the physics object to disable flicking by touch for
function helpers.physicsDisableFlicking(obj)
	
	if (obj._isFlickable) then
		obj._isFlickable = false;
		obj._prevTouchLocation = nil;
		obj._flicked = false;
		obj:removeEventListener("touch", obj._flickFunction);
		obj._flickFunction = nil;
		display.getCurrentStage():setFocus(nil);
	end
	
end

-- maxForce (float)
-- frequency (float, higher numbers = less lag/bounce)
-- dampingRation (float, 0 (no damping) to 1.0 (critical damping))
-- center (bool, drag from center point or touch point)
function helpers.physicsDragBody(event, params)
	local body = event.target;
	local phase = event.phase;
	local stage = display.getCurrentStage();

	if "began" == phase then
		stage:setFocus(body);
		body.isFocus = true;

		-- Create a temporary touch joint and store it in the object for later reference
		if params and params.center then
			-- drag the body from its center point
			body.tempJoint = physics.newJoint( "touch", body, body.x, body.y );
		else
			-- drag the body from the point where it was touched
			body.tempJoint = physics.newJoint( "touch", body, event.x, event.y );
		end

		-- Apply optional joint parameters
		if params then
			local maxForce, frequency, dampingRatio;

			if params.maxForce then
				-- Internal default is (1000 * mass), so set this fairly high if setting manually
				body.tempJoint.maxForce = params.maxForce;
			end
			
			if params.frequency then
				-- This is the response speed of the elastic joint: higher numbers = less lag/bounce
				body.tempJoint.frequency = params.frequency;
			end
			
			if params.dampingRatio then
				-- Possible values: 0 (no damping) to 1.0 (critical damping)
				body.tempJoint.dampingRatio = params.dampingRatio;
			end
		end
	
	elseif body.isFocus then
		if "moved" == phase then
		
			-- Update the joint to track the touch
			body.tempJoint:setTarget( event.x, event.y );

		elseif "ended" == phase or "cancelled" == phase then
			stage:setFocus(nil);
			body.isFocus = false;
			
			-- Remove the joint when the touch ends			
			body.tempJoint:removeSelf();
			
		end
	end

	-- Stop further propagation of touch event
	return true;
end