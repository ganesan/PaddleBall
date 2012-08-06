require "LevelHelper.Helpers.LHHelpers"
--------------------------------------------------------------------------------

--notifications
LHAnimationHasEndedGlobalNotification = "LHAnimationHasEndedGlobalNotification"
LHAnimationFrameGlobalNotification = "LHAnimationFrameGlobalNotification"

LHAnimationHasEndedPerSpriteNotification = "LHAnimationHasEndedPerSpriteNotification"
LHAnimationFramePerSpriteNotification = "LHAnimationFramePerSpriteNotification"


LHAnimationFrameInfo = {}
function LHAnimationFrameInfo:frameWithDictionary(frmInfo)

	if(frmInfo == nil)then
		print("ERROR: Frame info is nil.");
		return nil;
	end
		
	local object = {lhDelayPerUnit = frmInfo:floatForKey("delayPerUnit"),
					lhOffset = frmInfo:pointForKey("offset"),
					lhNotifications = LHDictionary:initWithDictionary(frmInfo:dictForKey("notifications")),
					lhFrameName = frmInfo:stringForKey("spriteframe"),
					lhRect = frmInfo:rectForKey("Frame"),
					lhFrameOffset = frmInfo:pointForKey("TextureOffset"),
					lhRectIsRotated= frmInfo:boolForKey("IsRotated"),
					lhFrameSize = frmInfo:sizeForKey("SpriteSize")
					}
					
	setmetatable(object, { __index = LHAnimationFrameInfo })  -- Inheritance	
	return object
end

function LHAnimationFrameInfo:removeSelf()
	
	--print("LHAnimationFrameInfo removeSelf");
	
	self.lhDelayPerUnit = nil;
	self.lhOffset = nil;
	self.lhNotifications:removeSelf();
	self.lhNotification = nil;
	self.lhRect = nil;
	self.lhFrameOffset = nil;
	self.lhRectIsRotated = nil;
	self.lhFrameSize = nil;
	self = nil;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

LHAnimationNode = {}
function LHAnimationNode:animationWithDictionary(animInfo) --returns a display object
	
	if(animInfo == nil)then
		print("ERROR: Animation info is nil. Probably animation could not be found.");
		print("ERROR: Probably SpriteHelper document where this animation was created is in older format. Open it with latest version of SpriteHelper and re-save it.");
		return nil;
	end
	
	local object = {lhUniqueName = animInfo:stringForKey("UniqueName"),
					lhSheetName = animInfo:stringForKey("SheetName"),
					lhSheetImage= animInfo:stringForKey("SheetImage");
					lhRestoreOriginalFrame = animInfo:boolForKey("RestoreOriginalFrame"),
					lhRepetitions = animInfo:intForKey("Repetitions"),
					lhDelayPerUnit = animInfo:floatForKey("DelayPerUnit"),
					lhLoop = animInfo:boolForKey("Loop");
					lhAnimAtStart = animInfo:boolForKey("StartAtLaunch");
					coronaSprite = nil, --this needs to be assigned after we create the sprite
					repetitionsPerformed = 0,
					time = 0.0,
					currentFrame = 1,
					paused = true,
					elapsedFrameTime = 0.0,
					lastEventTime = -1,
					lhFrames = {},
					}

	local framesInfo = animInfo:arrayForKey("Frames");
	for i=1, framesInfo:count() do
		
		local frmInfo = framesInfo:dictAtIndex(i);
		object.lhFrames[#object.lhFrames+1] = LHAnimationFrameInfo:frameWithDictionary(frmInfo);
	
	end
	
	setmetatable(object, { __index = LHAnimationNode })  -- Inheritance	
	
	return object
end
--------------------------------------------------------------------------------
function LHAnimationNode:removeSelf()

	--print("LHAnimationNode removeSelf");

	--Runtime:removeEventListener( "enterFrame", self )

	self.lhUniqueName = nil;
	self.lhSheetName = nil;
	self.lhSheetImage= nil;
	self.lhRestoreOriginalFrame = nil;
	self.lhRepetitions = nil;
	self.lhDelayPerUnit = nil;
	self.lhLoop = nil;
	self.lhAnimAtStart = nil;
	self.repetitionsPerformed = nil;
	self.time = nil;
	self.currentFrame = nil;
	self.paused = nil;
	self.elapsedFrameTime = nil;
	self.lastEventTime = nil;

	for i = 1, #self.lhFrames do
		self.lhFrames[i]:removeSelf();
		self.lhFrames[i] = nil;
	end
	self.lhFrames = nil;


	self = nil
end
--------------------------------------------------------------------------------
function LHAnimationNode:animationTime()

	local totalTime = 0.0
	for i=1, #self.lhFrames do
		local frmInfo = self.lhFrames[i];
		totalTime = totalTime + frmInfo.lhDelayPerUnit*self.lhDelayPerUnit;
	end
	return totalTime
end
--------------------------------------------------------------------------------
function LHAnimationNode:enterFrame( event )
        
--    print("enter frame " .. self.lhUniqueName .. " time " .. tostring(event.time));
    if(self == nil)then
	    return;
    end
       
    if(self.paused)then
    	return;
    end 	
        	
    if(self.coronaSprite == nil)then
    	print("ERROR: animation node is not valid as it does not have an associated sprite");
	    return;
    end
    if(self.lastEventTime == -1)then
    	self.lastEventTime = event.time/1000;
    	return;
    end
    	
    local dT = event.time/1000 - self.lastEventTime;
    self.lastEventTime = event.time/1000;
	self.elapsedFrameTime = self.elapsedFrameTime + dT;
    
	local frmObject = self.lhFrames[self.currentFrame];
	
	if(frmObject == nil)then
		return;
	end
	
	if(frmObject.lhDelayPerUnit*self.lhDelayPerUnit <= self.elapsedFrameTime)then
		self.elapsedFrameTime = 0.0;
		self.currentFrame = self.currentFrame + 1;
		
		if(self.currentFrame > #self.lhFrames)then
		
			--we should trigger a notification that the animation has ended
			local endedEvent = { name=LHAnimationHasEndedGlobalNotification, object = self.coronaSprite } 
			Runtime:dispatchEvent(endedEvent);

			local endedPerSprEvent = { name=LHAnimationHasEndedPerSpriteNotification, object = self.coronaSprite } 
			self.coronaSprite:dispatchEvent(endedPerSprEvent);

			if(self.lhLoop)then
				self.currentFrame = 1
			else
				self.repetitionsPerformed = self.repetitionsPerformed +1
				
				if(self.repetitionsPerformed >= self.lhRepetitions)then
				
					self.paused = true;
					self.currentFrame = #self.lhFrames
					
					--restore original frame is handled by stopAnimation
					--we should remove the animation object from the sprite
					self:stopAnimation();
					return;
				else
					self.currentFrame = 1
				end
			end			
		end
		
		
		local activeFrame = self.lhFrames[self.currentFrame];

		self.coronaSprite:setFrame(self.currentFrame);
		--check if this frame has any info and trigger a notification if it has
		--		if([[[activeFrame notifications] allKeys] count] > 0){
		local endedEvent = { name=LHAnimationFrameGlobalNotification, 
							 object = self.coronaSprite, 
							 userInfo = activeFrame.lhNotifications:tableWithKeysAndObjects() } 
		Runtime:dispatchEvent(endedEvent);

		local endedEventPerSpr = { name=LHAnimationFramePerSpriteNotification, 
							 object = self.coronaSprite, 
							 userInfo = activeFrame.lhNotifications:tableWithKeysAndObjects() } 
		self.coronaSprite:dispatchEvent(endedEventPerSpr);
					
	end      
end
--------------------------------------------------------------------------------
function LHAnimationNode:setCurrentFrame(frmNo)

	if(frmNo > 0 and frmNo <=  #self.lhFrames)then
		self.currentFrame = frmNo;
	end
	self.coronaSprite:setFrame(self.currentFrame);
end
--------------------------------------------------------------------------------
function LHAnimationNode:stopAnimation()
	self.paused = true;
	
	-- check for restore original frame and restore it
	self.currentFrame = 1;
	if(self.lhRestoreOriginalFrame)then
		self.coronaSprite:setFrame(1);
	end
	
	--on corona we dont remove the animations because maybe the player wants 
	--to play it later - we remove anim when sprite is removed
	--self:removeSelf();
end
function LHAnimationNode:prepare()
	self.currentFrame = 1;
	self.coronaSprite:setFrame(self.currentFrame);
end
