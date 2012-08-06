require "LevelHelper.Helpers.LHHelpers"


--notifications
LHPathMovementHasEndedGlobalNotification = "LHPathMovementHasEndedGlobalNotification"
LHPathMovementHasEndedPerSpriteNotification = "LHPathMovementHasEndedPerSpriteNotification"

LHPathMovementHasChangedPointGlobalNotification ="LHPathMovementHasChangedPointGlobalNotification"
LHPathMovementHasChangedPointPerSpriteNotification ="LHPathMovementHasChangedPointPerSpriteNotification"


LHPathNode = {}
function LHPathNode:initWithPoints(points, spriteObj)

	if (nil == points) then
		print("Invalid LHPathNode initialization!")
	end
		
	local object = {coronaSprite = spriteObj,
					speed = 0.2,
					interval = 0.01,
					paused = false,
					startAtEndPoint = false,
					isCyclic = false,
					restartOtherEnd = false,
					axisOrientation = 0, -- 1 is x 2 is y
					flipX = false,
					flipY = false,
					pathPoints = lh_deepcopy(points),
					currentPoint = 1,
					elapsed = 0.0,					
					isLine = true,										
					initialAngle = spriteObj.rotation,
					prevPathPosition = {x = 0, y = 0},										
					time = os.clock(),
					moveWithDelta = false,					
					firstTime = true
					}

	setmetatable(object, { __index = LHPathNode })  -- Inheritance	
		
	if(#object.pathPoints > 0)then
        object.prevPathPosition =  object.pathPoints[1];
    end
    
	Runtime:addEventListener( "enterFrame", object )

	return object
end
--------------------------------------------------------------------------------
function LHPathNode:removeSelf()

	--print("path node remove self");

	Runtime:removeEventListener("enterFrame", self);	
	self.coronaSprite = nil;	
	self.pathPoints = nil	
	self.speed = nil
	self.interval = nil
	self.startAtEndPoint = nil
	self.isCyclic = nil
	self.restartOtherEnd = nil
	self.axisOrientation = nil
	self.currentPoint = nil
	self.elapsed = nil
	self.initialAngle = nil
	self.time = nil
	self.isLine = nil
	self.paused = nil
	self.pathNotifierId = nil
	self.pathNotifierSel= nil
	self.firstTime = nil
	
	self = nil;
end
--------------------------------------------------------------------------------
function LHPathNode:restart()
	self.currentPoint = 1
	self.elapsed = 0.0
end
--------------------------------------------------------------------------------
function LHPathNode:setSpeed(val)
	self.speed = val;
	self.interval = self.speed/(#self.pathPoints-1);	
end
--------------------------------------------------------------------------------
function LHPathNode:setStartAtEndPoint(val)
	
	if(self.startAtEndPoint == val)then
		--we do this so that we dont reverse point over and over if 1 is given multiple times
		return
	end
	
	self.startAtEndPoint = val;
    
    if(self.startAtEndPoint == 1)then
    	self.pathPoints = self:inversePoints(self.pathPoints)
    end
end
--------------------------------------------------------------------------------
function LHPathNode:setMoveUsingDelta(moveWithDelta)

	if(false == moveWithDelta)then
		self.moveWithDelta = moveWithDelta
		local startPosition = self.pathPoints[1];
		self.coronaSprite.x = startPosition.x;
		self.coronaSprite.y = startPosition.y;
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--PRIVATE METHODS
--------------------------------------------------------------------------------
function LHPathNode:inversePoints(points)

	local invertedPoints = {}
	for i = #points,1,-1 do
		invertedPoints[#invertedPoints+1] = points[i]
	end
	
	points = nil;
	return invertedPoints
end
--------------------------------------------------------------------------------
function LHPathNode:rotationDegreeFromPoint ( srcObj, dstObj )
 
	local xDist = dstObj.x-srcObj.x
   	local yDist = dstObj.y-srcObj.y
    local angleBetween = math.deg( math.atan( yDist/xDist ) )
        
    if ( srcObj.x < dstObj.x ) then 
        angleBetween = angleBetween+90
    else 
        angleBetween = angleBetween-90 
    end
        
    return angleBetween
end
--------------------------------------------------------------------------------
function LHPathNode:MIN(A, B)

	if(A < B)then
		return A;
	else
		return B;
	end
	
	return A;
end
--------------------------------------------------------------------------------
function LHPathNode:enterFrame( event )
        
     --print("path enterFrame");
      
    if(self == nil)then
	    return;
    end
    
    local callPathNotification = false;
    
	if(self.firstTime)then
		self.time = event.time/1000
		self.firstTime = false
	end

	if(nil == self.coronaSprite)then
		return;
	end
	
	if(self.paused)then 
		self.time 	  = event.time/1000 
		return;
	end
	
	if(nil == self.pathPoints)then
		return;
	end
    
	local startPosition = self.pathPoints[self.currentPoint];
	local previousPoint = self.currentPoint -1;
	if(previousPoint < 1)then
		previousPoint = 1;
	end
	
	local prevPosition = self.pathPoints[previousPoint];
	local endPosition = startPosition;
		
	local startAngle = self:rotationDegreeFromPoint(startPosition,prevPosition)
	if(self.currentPoint == 1)then
		startAngle = self.initialAngle-90;
	end
	
	local endAngle = startAngle;
	
	if( (self.currentPoint + 1) <= #self.pathPoints)then
		endPosition = self.pathPoints[self.currentPoint+1]
		endAngle = self:rotationDegreeFromPoint(endPosition,startPosition);		
	else 
		if(self.isCyclic)then
	
			if(false == self.restartOtherEnd)then
				self.pathPoints = self:inversePoints(self.pathPoints)
			end
			
			if(self.flipX)then
				self.coronaSprite.xScale = -1*self.coronaSprite.xScale;
			end
			
			if(self.flipY)then
				self.coronaSprite.yScale = -1*self.coronaSprite.yScale;
			end
			
			self.currentPoint = 0;
		end
        
        callPathNotification = true;
	end
	
	if(self.axisOrientation == 1)then
		startAngle =startAngle+ 90.0;
	end
	if(self.axisOrientation == 1)then
		endAngle = endAngle + 90.0;
	end
	
	if(startAngle > 360)then
		startAngle = startAngle - 360;
	end
	if(endAngle > 360)then
		endAngle = endAngle - 360;
	end
		
	local t = self:MIN(1.0, self.elapsed/self.interval);
	
	local deltaP = lh_Sub( endPosition, startPosition );

	local newPos = {x = startPosition.x + deltaP.x * t, 
					y = startPosition.y + deltaP.y * t};
            
	if(startAngle > 270 and startAngle < 360 and
	   endAngle > 0 and endAngle < 90)then
		startAngle = startAngle - 360;
	end
	
	
	if(startAngle > 0 and startAngle < 90 and
	   endAngle < 360 and endAngle > 270)then
		startAngle = startAngle + 360;
	end
	
	local deltaA = endAngle - startAngle;
	local newAngle = startAngle + deltaA*t;

	if(newAngle > 360)then
		newAngle = newAngle - 360;
	end
	
	if(nil ~= self.coronaSprite)then
		local sprPos = {x = self.coronaSprite.x, y = self.coronaSprite.y};
		local sprDelta={ x = newPos.x - self.prevPathPosition.x, y = newPos.y - self.prevPathPosition.y};
		
		self.coronaSprite.x = sprPos.x + sprDelta.x;
		self.coronaSprite.y = sprPos.y + sprDelta.y;
		
		if(moveWithDelta == false)then
			self.coronaSprite.x = newPos.x;
			self.coronaSprite.y = newPos.y;
		end
		
		self.prevPathPosition = newPos;		
	end


	if(self.axisOrientation ~= 0)then
		self.coronaSprite.rotation = newAngle;
	end
	
	if(self.isLine)then
		if(self.axisOrientation ~= 0)then
			self.coronaSprite.rotation = endAngle;
		end
	end
	
	local dist = lh_Distance(self.prevPathPosition, endPosition);
		
	if(0.001 > dist)then
		if(self.currentPoint + 1 <= #self.pathPoints)then
			self.elapsed = 0;
			self.currentPoint =self.currentPoint+ 1;     
			
			local changedEvent = { name=LHPathMovementHasChangedPointGlobalNotification, 
								  object = self.coronaSprite } 
			Runtime:dispatchEvent(changedEvent);
			
			local changedEvent = { name=LHPathMovementHasChangedPointPerSpriteNotification, 
								  object = self.coronaSprite } 
			self.coronaSprite:dispatchEvent(changedEvent);

		end
	end
    
	self.elapsed  = self.elapsed + (event.time/1000 - self.time)
	self.time 	  = event.time/1000 

	if(callPathNotification)then
	
			local endedEvent = { name=LHPathMovementHasEndedGlobalNotification, 
								 object = self.coronaSprite } 
			Runtime:dispatchEvent(endedEvent);

			local endedEvent = { name=LHPathMovementHasEndedPerSpriteNotification, 
								 object = self.coronaSprite } 
			self.coronaSprite:dispatchEvent(endedEvent);

		if(false == self.isCyclic)then
			self.paused = true;
        end
	end
end
--------------------------------------------------------------------------------