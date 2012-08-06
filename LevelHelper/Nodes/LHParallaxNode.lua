

--notifications
LHParallaxSpriteMovedBackNotification = "LHParallaxSpriteMovedBackNotification"


LHParallaxNode = {}
LHParallaxPointObject = {} --Should not be used by user
--------------------------------------------------------------------------------
function LHParallaxNode:parallaxWithDictionary(properties, parentLoader)

	if (nil == properties) then
		print("ERROR: Invalid LHParallaxNode initialization!")
		return nil;
	end
	
	local object = {isContinuous = properties:boolForKey("ContinuousScrolling"),
					lhParentLoader = parentLoader,
					direction = properties:intForKey("Direction"),
					speed = properties:floatForKey("Speed"),
					lhUniqueName = properties:stringForKey("UniqueName"),
					position = { x = 0, y = 0},
					paused = false,
					time = 0,
					lastPosition = { x = -100, y = -100},
					winSize ={width = display.contentWidth, height = display.contentHeight},
					screenNumberOnTheRight = 1,
					screenNumberOnTheLeft = 0,
					screenNumberOnTheTop = 0,
					screenNumberOnTheBottom = 0,
					sprites = {}
					}
	setmetatable(object, { __index = LHParallaxNode })  -- Inheritance	
		
	if(false == object.isContinuous)then
		object.speed = 1.0;
	end
		
	local spritesInParallaxInfo = properties:arrayForKey("Sprites");
	for i = 1, spritesInParallaxInfo:count() do
	
		local sprInfo = spritesInParallaxInfo:dictAtIndex(i);
		
		local ratioX = sprInfo:floatForKey("RatioX");
		local ratioY = sprInfo:floatForKey("RatioY");
		local cSprite= parentLoader:spriteWithUniqueName(sprInfo:stringForKey("SpriteName"));
		if(cSprite~= nil)then
			object:addChild(cSprite, {x = ratioX, y = ratioY});
		end
	end		
		
	Runtime:addEventListener( "enterFrame", object )

	return object
end
--------------------------------------------------------------------------------
function LHParallaxPointObject:initWithRatio(ratioValue) --not for the user
		
	local object = {position = {x = 0,y = 0},
					ratio = ratioValue,
					offset = {x = 0, y = 0},
					initialPosition = {x = 0, y = 0},
					coronaSprite = nil
					}
	setmetatable(object, { __index = LHParallaxPointObject })  -- Inheritance	
		
	return object
end
--------------------------------------------------------------------------------
function LHParallaxNode:removeSelf()
	
	--print("Parallax removeSelf");
	
	Runtime:removeEventListener( "enterFrame", self )
	
	self.isContinuous = nil;
	self.speed = nil;
	self.lhUniqueName = nil;
	self.position = nil;
	self.paused = nil;
	self.lastPosition = nil;
	self.direction = nil;
	self.winSize = nil;	
	self.screenNumberOnTheRight = nil;	
	self.screenNumberOnTheLeft = nil;	
	self.screenNumberOnTheTop = nil;	
	self.screenNumberOnTheBottom = nil;	
	self.sprites = nil;
	self.movedEndListenerSEL = nil;
					
	self = nil;
end
--------------------------------------------------------------------------------
function LHParallaxNode:setSpeed(newSpeed)

	if(self.isContinuous)then
		self.speed = newSpeed;
		if(self.speed < 0)then
			self.speed = 0
		end
	end
end
--------------------------------------------------------------------------------
function LHParallaxNode:setPaused(value)
	self.paused = value;
end
--------------------------------------------------------------------------------
function LHParallaxNode:isPaused()
	return self.paused;
end
--------------------------------------------------------------------------------
function LHParallaxNode:setPosition(x, y)

	if(self.isContinuous)then
		return
	end

	self.position.x = x;
	self.position.y = y;	
end
--------------------------------------------------------------------------------
function LHParallaxNode:addChild(lhSprite, ratioPoint)

	if(nil == lhSprite)then
		print("Argument must not be nil")
		return
	end

	local obj = LHParallaxPointObject:initWithRatio(ratioPoint);
	obj.coronaSprite = lhSprite;
	obj.position = {x = lhSprite.x, y = lhSprite.y};
	obj.offset = {x = lhSprite.x, y = lhSprite.y};
	obj.initialPosition = {x = lhSprite.x, y = lhSprite.y};
	self.sprites[#self.sprites+1] = obj;
	lhSprite.lhParallaxNode = self;

	local scrRight = lh_toInt(obj.initialPosition.x/self.winSize.width);
	
	if(self.screenNumberOnTheRight <= scrRight)then
		self.screenNumberOnTheRight = scrRight+1;
	end
		
	local scrLeft = lh_toInt(obj.initialPosition.x/self.winSize.width);
	
	if(self.screenNumberOnTheLeft >= scrLeft)then
		self.screenNumberOnTheLeft = scrLeft-1;
	end
		
	local scrTop = lh_toInt(obj.initialPosition.y/self.winSize.height);
	
	if(self.screenNumberOnTheTop <= scrTop)then
		self.screenNumberOnTheTop = scrTop + 1;
	end
	
	local scrBottom = lh_toInt(obj.initialPosition.y/self.winSize.height);

	if(self.screenNumberOnTheBottom >= scrBottom)then
		self.screenNumberOnTheBottom = scrBottom-1;
	end
		
end
--------------------------------------------------------------------------------
function LHParallaxNode:removeChild(lhSprite)

	for i = 1, #self.sprites do
		point = self.sprites[i];
    	if(point.coronaSprite == lhSprite)then
	    	table.remove(self.sprites,i)
    		return
    	end
    end
    
end
--------------------------------------------------------------------------------
function LHParallaxNode:spritesInNode()
	local spritesInNode = {};
	for i =1, #self.sprites do
		spritesInNode[#spritesInNode+1] = self.sprites[i].coronaSprite;
	end
	
	return spritesInNode;
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--PRIVATE METHODS
--------------------------------------------------------------------------------
function LHParallaxNode:setPositionOnPointNode(pos, point, offset)

	if(point.coronaSprite ~= nil)then
		if(true == self.isContinuous)then
	
			local newPos = {x = point.coronaSprite.x - offset.x,
            	            y = point.coronaSprite.y - offset.y};
          
			point.coronaSprite.x = newPos.x;
			point.coronaSprite.y = newPos.y;
		else	
			point.coronaSprite.x = pos.x;
			point.coronaSprite.y = pos.y;
		end
	end
end
--------------------------------------------------------------------------------
function LHParallaxNode:getBounds(rw, rh, radians)

	local x1 = -rw/2;
    local x2 = rw/2;
    local x3 = rw/2;
    local x4 = -rw/2;
    local y1 = rh/2;
    local y2 = rh/2;
    local y3 = -rh/2;
    local y4 = -rh/2;
    
    local x11 = x1 * math.cos(radians) + y1 * math.sin(radians);
    local y11 = -x1 * math.sin(radians) + y1 * math.cos(radians);
    local x21 = x2 * math.cos(radians) + y2 * math.sin(radians);
    local y21 = -x2 * math.sin(radians) + y2 * math.cos(radians);
    local x31 = x3 * math.cos(radians) + y3 * math.sin(radians);
    local y31 = -x3 * math.sin(radians) + y3 * math.cos(radians);
    local x41 = x4 * math.cos(radians) + y4 * math.sin(radians);
    local y41 = -x4 * math.sin(radians) + y4 * math.cos(radians);

	local minX12 = math.min(x11,x21);
	local minX34 = math.min(x31,x41);
    local x_min = math.min(minX12,minX34);
    local x_max = math.max(math.max(x11,x21),math.max(x31,x41));
    
  	local y_min = math.min(math.min(y11,y21),math.min(y31,y41));
    local y_max = math.max(math.max(y11,y21),math.max(y31,y41));
    
 
    return {width = x_max-x_min, height = y_max-y_min}
end
--------------------------------------------------------------------------------
function LHParallaxNode:repositionPoint(point)

	local spriteContentSize =  {width = point.coronaSprite.contentWidth,
	    						 height= point.coronaSprite.contentHeight}
    
	local rotation =  point.coronaSprite.rotation *  math.pi / 180;
    
	local contentSize = self:getBounds(spriteContentSize.width, spriteContentSize.height, rotation);
		
	if(nil == contentSize.width or nil == contentSize.height)then
		return
	end
	--contentSize in corona is also affected by scale so dont use scale here
		
	if(self.direction == 1) then --right to left
		
		if(point.coronaSprite.x + contentSize.width/2.0 <= 0)then

			if(nil ~= point.coronaSprite)then
			
				local difX = point.coronaSprite.x;
			
				point.coronaSprite.x = self.winSize.width*self.screenNumberOnTheRight + difX;
                        
            	local movedToBackEvent = { name=LHParallaxSpriteMovedBackNotification, object = self, movedSprite = point.coronaSprite } 
				Runtime:dispatchEvent(movedToBackEvent);

			end
		end
	
	elseif (self.direction == 0) then -- left to right
	
		if(point.coronaSprite.x - contentSize.width/2.0 >= self.winSize.width)then
		
			if(nil ~= point.coronaSprite)then
			
				local difX = point.coronaSprite.x - self.winSize.width;
				
				point.coronaSprite.x = self.winSize.width*self.screenNumberOnTheLeft + difX;
            
				local movedToBackEvent = { name=LHParallaxSpriteMovedBackNotification, object = self, movedSprite = point.coronaSprite } 
				Runtime:dispatchEvent(movedToBackEvent);
				
			end

		end
		
	elseif (self.direction == 2) then -- up to bottom
	
		if(point.coronaSprite.y - contentSize.height/2.0 >= self.winSize.height)then
						
			if(nil ~= point.coronaSprite)then
			
				local difY = point.coronaSprite.y - self.winSize.height;
			
				point.coronaSprite.y = self.winSize.height*self.screenNumberOnTheBottom + difY
             	
             		local movedToBackEvent = { name=LHParallaxSpriteMovedBackNotification, object = self, movedSprite = point.coronaSprite } 
				Runtime:dispatchEvent(movedToBackEvent);
			end
		end

	elseif (self.direction == 3) then -- bottom to top
	
		if(point.coronaSprite.y + contentSize.height/2.0 <= 0)then
		
			if(nil ~= point.coronaSprite)then
			
				local difY = point.coronaSprite.y; 
				
				point.coronaSprite.y = self.winSize.height*self.screenNumberOnTheTop + difY;
				
				local movedToBackEvent = { name=LHParallaxSpriteMovedBackNotification, object = self, movedSprite = point.coronaSprite } 
				Runtime:dispatchEvent(movedToBackEvent);				
			end
		end
	end
	
end--------------------------------------------------------------------------------
function LHParallaxNode:enterFrame( event )
            
   -- print("parallax enterFrame");
        
    if(self.paused)then
    	self.time 	  = event.time
    	return
    end
    
    local pos = self.position;
    
    local deltaX = self.position.x - self.lastPosition.x;
    local deltaY = self.position.y - self.lastPosition.y;
                

	local frameTime = event.time - self.time;
    frameTime = frameTime/1000.0;
        
   	for i = 1, #self.sprites do
   	    
   	    local point = self.sprites[i];
    
    	if(point ~= nil)then

           	oldPosX = point.coronaSprite.x;
           	oldPosY = point.coronaSprite.y;
    	
    		 if(self.isContinuous)then
    		
    			local i = -1.0; --direction left to right -- up to bottom
	   			if(self.direction == 1 or self.direction == 3) then --right to left -- bottom to top
					i = 1.0;
				end
    	 
    			point.coronaSprite.x = oldPosX - i*point.ratio.x*self.speed*frameTime;
				point.coronaSprite.y = oldPosY - i*point.ratio.y*self.speed*frameTime;
            
            	self:repositionPoint(point)         
            else 
                
                point.coronaSprite.x = oldPosX + point.ratio.x*deltaX;
                point.coronaSprite.y = oldPosY + point.ratio.y*deltaY;
                
            end
    	end
	end 
	
	self.lastPosition = {x = pos.x, y = pos.y}; --very important or else you will equalize with a pointer
	self.time = event.time;
end
--------------------------------------------------------------------------------