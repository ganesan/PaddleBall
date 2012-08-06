require "LevelHelper.Helpers.LHHelpers"
require "LevelHelper.Nodes.LHPathNode"
require "LevelHelper.Nodes.LHSettings"
require "LevelHelper.Nodes.LHAnimationNode"
require "LevelHelper.Nodes.SHDocumentLoader"
require "LevelHelper.Nodes.LHFixture"

require "LevelHelper.Nodes.LHAnimationNode"
--------------------------------------------------------------------------------
--forward declaration of local functions
local createAnimatedSpriteFromDictioary; 
local createSingleSpriteFromTextureDictionary;
local createPhysicObjectForSprite;
local recreatePhysicObjectForSprite; --in case scale is issued
local setTexturePropertiesOnSprite;
local setUserClassPropertiesOnSprite;
local loadPathMovementFromDictionary;

local untitledSpritesCount = 0;

local LHSprite = {}
function LHSprite.spriteWithDictionary(selfSprite, spriteInfo) --returns a display object

	texDict = spriteInfo:dictForKey("TextureProperties");	
	
	local coronaSprite = createAnimatedSpriteFromDictioary(spriteInfo)
	
	if(coronaSprite == nil) then
		coronaSprite = createSingleSpriteFromTextureDictionary(texDict, spriteInfo);
	end
	if(coronaSprite == nil)then
		return nil;
	end
	
	setTexturePropertiesOnSprite(coronaSprite, texDict);	
	
	--LevelHelper sprite properties assigned to a Corona sprite
	----------------------------------------------------------------------------
	
	if(spriteInfo:objectForKey("SHSceneName"))then	
		coronaSprite.shSceneName = spriteInfo:stringForKey("SHSceneName")
	end
	
	if(spriteInfo:objectForKey("SHSheetName"))then	
		coronaSprite.shSheetName = spriteInfo:stringForKey("SHSheetName");
	end
	if(spriteInfo:objectForKey("SHSpriteName"))then
		coronaSprite.shSpriteName= spriteInfo:stringForKey("SHSpriteName");	
	end
	
	if(spriteInfo:objectForKey("UniqueName"))then
		coronaSprite.lhUniqueName = spriteInfo:stringForKey("UniqueName");		
	else
		coronaSprite.lhUniqueName = "UntitledSprite_" .. tostring(untitledSpritesCount);
		untitledSpritesCount = untitledSpritesCount + 1;
	end
	
	coronaSprite.lhZOrder = texDict:intForKey("ZOrder");
	coronaSprite.lhTag = texDict:intForKey("Tag");
	coronaSprite.lhAttachedJoint = {}
	coronaSprite.lhFixtures = nil
	coronaSprite.lhNodeType = "LHSprite"

	--overloaded functions
	----------------------------------------------------------------------------
	coronaSprite.originalCoronaRemoveSelf 	= coronaSprite.removeSelf;
	coronaSprite.removeSelf 				= sprite_removeSelf;
	----------------------------------------------------------------------------
	
	--LevelHelper functions - transformations
	----------------------------------------------------------------------------
	coronaSprite.transformScaleX 		= transformScaleX;
	coronaSprite.transformScaleY 		= transformScaleY;
	coronaSprite.transformScale 		= transformScale;
	
	
	--LevelHelper functions	- animations
	----------------------------------------------------------------------------
	coronaSprite.prepareAnimationNamed 	= prepareAnimationNamed;
	coronaSprite.playAnimation 			= playAnimation;
	coronaSprite.pauseAnimation 		= pauseAnimation;
	coronaSprite.currentAnimationFrame 	= currentAnimationFrame;
	coronaSprite.setAnimationFrame 		= setAnimationFrame;
	coronaSprite.restartAnimation 		= restartAnimation;
	coronaSprite.isAnimationPaused		= isAnimationPaused
	coronaSprite.animationName			= animationName
	coronaSprite.numberOfFrames			= numberOfFrames
	coronaSprite.setNextFrame			= setNextFrame
	coronaSprite.setPreviousFrame 		= setPreviousFrame
	coronaSprite.setNextFrameAndLoop 	= setNextFrameAndLoop
	coronaSprite.setPreviousFrameAndLoop= setPreviousFrameAndLoop
	coronaSprite.isAnimationAtLastFrame = isAnimationAtLastFrame;
	
	
	--LevelHelper functions	- path movement
	----------------------------------------------------------------------------
	coronaSprite.prepareMovementOnPathWithUniqueName = prepareMovementOnPathWithUniqueName
	coronaSprite.pathUniqueName						 = pathUniqueName
	coronaSprite.startPathMovement					 = startPathMovement
	coronaSprite.pausePathMovement					 = pausePathMovement
	coronaSprite.isPathMovementPaused				 = isPathMovementPaused
	coronaSprite.restartPathMovement 				 = restartPathMovement
	coronaSprite.stopPathMovement					 = stopPathMovement
	coronaSprite.setPathMovementSpeed				 = setPathMovementSpeed
	coronaSprite.pathMovementSpeed					 = pathMovementSpeed
	coronaSprite.setPathMovementStartPoint			 = setPathMovementStartPoint
	coronaSprite.pathMovementStartPoint				 = pathMovementStartPoint
	coronaSprite.setPathMovementIsCyclic			 = setPathMovementIsCyclic
	coronaSprite.pathMovementIsCyclic				 = pathMovementIsCyclic
	coronaSprite.setPathMovementRestartsAtOtherEnd	 = setPathMovementRestartsAtOtherEnd
	coronaSprite.pathMovementRestartsAtOtherEnd		 = pathMovementRestartsAtOtherEnd
	coronaSprite.setPathMovementOrientation			 = setPathMovementOrientation
	coronaSprite.pathMovementOrientation			 = pathMovementOrientation
	coronaSprite.setPathMovementFlipXAtEnd			 = setPathMovementFlipXAtEnd
	coronaSprite.pathMovementFlipXAtEnd				 = pathMovementFlipXAtEnd
	coronaSprite.setPathMovementFlipYAtEnd			 = setPathMovementFlipYAtEnd
	coronaSprite.pathMovementFlipYAtEnd				 = pathMovementFlipYAtEnd
	coronaSprite.setPathMovementRelative			 = setPathMovementRelative
	coronaSprite.pathMovementRelative				 = pathMovementRelative
	coronaSprite.pathMovementCurrentPoint			 = pathMovementCurrentPoint;
	
	--LevelHelper functions - joints
	----------------------------------------------------------------------------
	coronaSprite.jointsList = jointsList
	coronaSprite.jointWithUniqueName = jointWithUniqueName
	coronaSprite.removeAllAttachedJoints = removeAllAttachedJoints
	coronaSprite.removeJoint = removeJoint
	
	----------------------------------------------------------------------------
	----------------------------------------------------------------------------
	createPhysicObjectForSprite(coronaSprite, spriteInfo);
	
	setUserClassPropertiesOnSprite(coronaSprite, spriteInfo);
	
	loadPathMovementFromDictionary(coronaSprite, spriteInfo);

	if(coronaSprite.lhActiveAnimNode) then	
		Runtime:addEventListener( "enterFrame", coronaSprite )		
		coronaSprite.oldEnterFrame = coronaSprite.enterFrame;
		coronaSprite.enterFrame = lhSpriteEnterFrame
	end
	
	if(coronaSprite.lhActiveAnimNode and coronaSprite.lhActiveAnimNode.lhAnimAtStart)then
		coronaSprite:playAnimation();
	end
	

	return coronaSprite;
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function lhSpriteEnterFrame(selfSprite, event )
	if(selfSprite.lhActiveAnimNode)then
		selfSprite.lhActiveAnimNode:enterFrame(event)
	end

	if(selfSprite.oldEnterFrame)then
		selfSprite.oldEnterFrame()
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function sprite_removeSelf(selfSprite)
	--print("calling LHSprite removeSelf " .. selfSprite.lhUniqueName .. " parent " .. selfSprite.parent.lhUniqueName);
	--remove all properties of this sprite here
	
	Runtime:removeEventListener( "enterFrame", self )
	
	if(selfSprite.lhAnimationNodes)then --maybe the sprite does not have animations
		for i=1, #selfSprite.lhAnimationNodes do
			local node = selfSprite.lhAnimationNodes[i];
			if(node ~= nil)then
				node:removeSelf();
			end
			node = nil
			selfSprite.lhAnimationNodes[i] = nil
		end
	end
	selfSprite.lhAnimationNodes = nil;


	selfSprite:stopPathMovement()
	selfSprite:removeAllAttachedJoints()
		
	selfSprite.lhScaleHeight = nil
	selfSprite.lhScaleWidth = nil;
	selfSprite.lhUniqueName = nil;
	selfSprite.shSceneName = nil;
	selfSprite.shSheetName = nil;
	selfSprite.lhNodeType = nil;
	selfSprite.shSpriteName = nil;

	if(selfSprite.lhFixtures)then --it may be that sprite has no physics 
		for i = 1, #selfSprite.lhFixtures do
			selfSprite.lhFixtures[i]:removeSelf()
			selfSprite.lhFixtures[i] = nil;
		end
		selfSprite.lhFixtures = nil;
	end
		
	selfSprite:originalCoronaRemoveSelf();
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--Tranformation methods
function transformScaleX(selfSprite, newScaleX)
	selfSprite.xScale = newScaleX;
	recreatePhysicObjectForSprite(selfSprite, selfSprite.lhPhysicalInfo);
end
function transformScaleY(selfSprite, newScaleY)
	selfSprite.yScale = newScaleY;
	recreatePhysicObjectForSprite(selfSprite, selfSprite.lhPhysicalInfo);
end
function transformScale(selfSprite, newScale)
	selfSprite.xScale = newScale;
	selfSprite.yScale = newScale;
	recreatePhysicObjectForSprite(selfSprite, selfSprite.lhPhysicalInfo);
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--ANIMATION METHODS
function prepareAnimationNamed(selfSprite, animName) --this overloads setSequence()

	selfSprite.lhActiveAnimNode = nil;
	if(selfSprite.lhAnimationNodes)then
		for i=1, #selfSprite.lhAnimationNodes do
			local node = selfSprite.lhAnimationNodes[i];
			if(node.lhUniqueName == animName)then
				selfSprite.lhActiveAnimNode = selfSprite.lhAnimationNodes[i];
				selfSprite:setSequence(animName);
				return;
			end
		end
	end
end
--------------------------------------------------------------------------------
function playAnimation(selfSprite) --this overloads play()
	if(selfSprite.lhActiveAnimNode)then
		selfSprite.lhActiveAnimNode:prepare()
		selfSprite.lhActiveAnimNode.paused = false;
	end
end
--------------------------------------------------------------------------------
function pauseAnimation(selfSprite) --this overloads pause()
	if(selfSprite.lhActiveAnimNode)then
		selfSprite:pause();
		selfSprite.lhActiveAnimNode.paused = true;
	end
end
--------------------------------------------------------------------------------
function currentAnimationFrame(selfSprite) --this overloads currentFrame()
	if(selfSprite.lhActiveAnimNode)then
		return selfSprite.lhActiveAnimNode.currentFrame;
	end
	return -1;
end
--------------------------------------------------------------------------------
function restartAnimation(selfSprite)
	selfSprite:setAnimationFrame(1);
	selfSprite:playAnimation();
end
--------------------------------------------------------------------------------
function isAnimationPaused(selfSprite)
	if(selfSprite.lhActiveAnimNode)then
		return selfSprite.lhActiveAnimNode.paused;
	end
	return true;
end
--------------------------------------------------------------------------------
function animationName(selfSprite)
	if(selfSprite.lhActiveAnimNode)then
		return selfSprite.lhActiveAnimNode.lhUniqueName;
	end
	return ""
end
--------------------------------------------------------------------------------
function numberOfFrames(selfSprite)
	if(selfSprite.lhActiveAnimNode)then
		return #selfSprite.lhActiveAnimNode.lhFrames;
	end
	return 0;
end
--------------------------------------------------------------------------------
function setAnimationFrame(selfSprite, frmNo)
	
	if(selfSprite.lhActiveAnimNode)then
		selfSprite.lhActiveAnimNode:setCurrentFrame(frmNo);
	end
end
--------------------------------------------------------------------------------
function setNextFrame(selfSprite)
	selfSprite:setAnimationFrame(selfSprite:currentAnimationFrame()+1)
end
--------------------------------------------------------------------------------
function setPreviousFrame(selfSprite)
	selfSprite:setAnimationFrame(selfSprite:currentAnimationFrame()-1)
end
--------------------------------------------------------------------------------
function setNextFrameAndLoop(selfSprite)
	
	if(selfSprite.lhActiveAnimNode)then
		local nextFrm = selfSprite:currentAnimationFrame()+1;
		
		if(nextFrm > selfSprite:numberOfFrames())then
			nextFrm = 1;
		end
		selfSprite:setAnimationFrame(nextFrm);
	end
end
--------------------------------------------------------------------------------
function setPreviousFrameAndLoop(selfSprite)

	if(selfSprite.lhActiveAnimNode)then
		local prevFrm = selfSprite:currentAnimationFrame()-1;
		
		if(prevFrm <= 0)then
			prevFrm = selfSprite:numberOfFrames();
		end
		selfSprite:setAnimationFrame(prevFrm);
	end
end
--------------------------------------------------------------------------------
function isAnimationAtLastFrame(selfSprite)
	if(selfSprite:numberOfFrames() == selfSprite:currentAnimationFrame())then
		return true;
	end
	return false;
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--PATH METHODS
--for notifications please consult the api documentation or LHPathNode.lua
--------------------------------------------------------------------------------
function prepareMovementOnPathWithUniqueName(selfSprite, pathName)

	if(pathName == nil)then
		print("Invalid argument in prepareMovementOnPathWithUniqueName");
		return
	end
				
	local allLayers = LHSettings:sharedInstance().allLHMainLayers
		
    local bezier = nil;
    for i = 1, #allLayers do
	    local layer = allLayers[i];
	    if(layer)then
			bezier = layer:bezierWithUniqueName(pathName);
			if(bezier)then
				break;
			end
		end
	end
    
    if(bezier)then
    
    	selfSprite.lhPathNode = LHPathNode:initWithPoints(bezier.lhPathPoints, selfSprite)
		local path = selfSprite.lhPathNode;
		
		selfSprite.lhPathUniqueName = pathName;
		path.flipX 			= selfSprite.pathDefaultFlipX;
		path.flipY 			= selfSprite.pathDefaultFlipY;
		path.isCyclic		= selfSprite.pathDefaultIsCyclic;
		path:setMoveUsingDelta(selfSprite.pathDefaultRelativeMove);
		path.axisOrientation= selfSprite.pathDefaultOrientation;
		path.restartOtherEnd= selfSprite.pathDefaultRestartOtherEnd;
		path:setSpeed(selfSprite.pathDefaultSpeed)
		path:setStartAtEndPoint(selfSprite.pathDefaultStartPoint);
		selfSprite:pausePathMovement()
  	else
	  	print("UniqueName " .. pathName .. " for path is not valid. Path movement is ignored on sprite " .. selfSprite.lhUniqueName);
  	end
end
--------------------------------------------------------------------------------
function pathUniqueName(selfSprite)
	if(selfSprite.lhPathNode)then
		return selfSprite.lhPathUniqueName;
	end
	return ""
end
--------------------------------------------------------------------------------
function startPathMovement(selfSprite)
	if(selfSprite.lhPathNode)then
		selfSprite.lhPathNode.paused = false;
	end
end
--------------------------------------------------------------------------------
function pausePathMovement(selfSprite)
	if(selfSprite.lhPathNode)then
		selfSprite.lhPathNode.paused = true;
	end
end
--------------------------------------------------------------------------------
function isPathMovementPaused(selfSprite)
	if(selfSprite.lhPathNode)then
		return selfSprite.lhPathNode.paused;
	end
	return true;
end
--------------------------------------------------------------------------------
function restartPathMovement(selfSprite)
	if(selfSprite.lhPathNode)then
		selfSprite.lhPathNode:restart();
	end
end
--------------------------------------------------------------------------------
function stopPathMovement(selfSprite) --removes the path movement;
	if(selfSprite.lhPathNode)then
		selfSprite.lhPathNode.paused = true;
		selfSprite.lhPathNode:removeSelf();
		selfSprite.lhPathNode = nil
	end
end
--------------------------------------------------------------------------------
function setPathMovementSpeed(selfSprite, value)
	if(selfSprite.lhPathNode)then
		selfSprite.lhPathNode:setSpeed(value);
	end
end
--------------------------------------------------------------------------------
function pathMovementSpeed(selfSprite)
	if(selfSprite.lhPathNode)then
		return selfSprite.lhPathNode.speed;
	end
	return 0;
end
--------------------------------------------------------------------------------
function setPathMovementStartPoint(selfSprite, point) --0 first point 1 last point
	if(point ~= 0 and point ~= 1)then
		print("Valid start path movement points are 0 and 1");
		return
	end
	if(selfSprite.lhPathNode)then
		selfSprite.lhPathNode:setStartAtEndPoint(point);
	end
end
--------------------------------------------------------------------------------
function pathMovementStartPoint(selfSprite)
	if(selfSprite.lhPathNode)then
		return selfSprite.lhPathNode.startAtEndPoint;
	end
	return -1;
end
--------------------------------------------------------------------------------
function setPathMovementIsCyclic(selfSprite, isCyclic)
	if(selfSprite.lhPathNode)then
		selfSprite.lhPathNode.isCyclic = isCyclic;
	end
end
--------------------------------------------------------------------------------
function pathMovementIsCyclic(selfSprite)
	if(selfSprite.lhPathNode)then
		return selfSprite.lhPathNode.isCyclic;
	end
	return false;
end
--------------------------------------------------------------------------------
function setPathMovementRestartsAtOtherEnd(selfSprite, otherEnd)
	if(selfSprite.lhPathNode)then
		selfSprite.lhPathNode.restartOtherEnd = otherEnd;
	end
end
--------------------------------------------------------------------------------
function pathMovementRestartsAtOtherEnd(selfSprite)
	if(selfSprite.lhPathNode)then
		return selfSprite.lhPathNode.restartOtherEnd
	end
	return false;
end
--------------------------------------------------------------------------------
function setPathMovementOrientation(selfSprite, point) --0 no orientation 1 - x 2 - y

	if(point ~= 0 or point ~= 1 or point ~= 2)then
		print("ERROR: Path movement orientation can only be 0 - no orientation 1 - x orientation, 2 - y orientation")
		return
	end

	if(selfSprite.lhPathNode)then
		selfSprite.lhPathNode.axisOrientation= point;
	end
end
--------------------------------------------------------------------------------
function pathMovementOrientation(selfSprite)
	if(selfSprite.lhPathNode)then
		return selfSprite.lhPathNode.axisOrientation;
	end
	return -1;
end
--------------------------------------------------------------------------------
function setPathMovementFlipXAtEnd(selfSprite, shouldFlipX)
	if(selfSprite.lhPathNode)then
		selfSprite.lhPathNode.flipX = shouldFlipX;
	end
end
--------------------------------------------------------------------------------
function pathMovementFlipXAtEnd(selfSprite)
	if(selfSprite.lhPathNode)then
		return selfSprite.lhPathNode.flipX;
	end
	return false;
end
--------------------------------------------------------------------------------
function setPathMovementFlipYAtEnd(selfSprite, shouldFlipY)
	if(selfSprite.lhPathNode)then
		selfSprite.lhPathNode.flipY = shouldFlipX;
	end
end
--------------------------------------------------------------------------------
function pathMovementFlipYAtEnd(selfSprite)
	if(selfSprite.lhPathNode)then
		return selfSprite.lhPathNode.flipY;
	end
end
--------------------------------------------------------------------------------
function setPathMovementRelative(selfSprite, rel)
	if(selfSprite.lhPathNode)then
		selfSprite.lhPathNode:setMoveUsingDelta(rel);
	end
end
--------------------------------------------------------------------------------
function pathMovementRelative(selfSprite)
	if(selfSprite.lhPathNode)then
		return selfSprite.lhPathNode.moveWithDelta;
	end
	return false;
end
--------------------------------------------------------------------------------
function pathMovementCurrentPoint(selfSprite)
	if(selfSprite.lhPathNode)then
		return selfSprite.lhPathNode.currentPoint;
	end
	return -1;
end
--JOINTS METHODS
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--returns the LHJoint objects attached to the sprite
function jointsList(selfSprite) --table contains LHJoint objects
	return selfSprite.lhAttachedJoint;
end 
--------------------------------------------------------------------------------
function jointWithUniqueName(selfSprite, jointName)
	for i = 1, #selfSprite.lhAttachedJoint do
		local jt = selfSprite.lhAttachedJoint[i];
		if(jt)then
			if(jt.lhUniqueName == jointName)then
				return jt;
			end
		end
	end
	return nil;
end
--------------------------------------------------------------------------------
--remove all joints attached to this sprite
function removeAllAttachedJoints(selfSprite)
	for i = 1, #selfSprite.lhAttachedJoint do
		local jt = selfSprite.lhAttachedJoint[i];
		if(jt)then
			selfSprite:removeJoint(jt);
			jt = nil
		end
	end
end
--------------------------------------------------------------------------------
function removeJoint(selfSprite, lhJointObject)

	if(lhJointObject == nil)then
		return
	end

	local foundJointObjectAttachedToSprite = false;
	
	for i = 1, #selfSprite.lhAttachedJoint do
		local jt = selfSprite.lhAttachedJoint[i];
		if(jt)then
			if(jt == lhJointObject)then
				foundJointObjectAttachedToSprite = true;
			end
		end
	end

	if(false == foundJointObjectAttachedToSprite)then
		print("ERROR: Trying to remove joint " .. lhJointObject.lhUniqueName .. " from sprite " .. selfSprite.lhUniqueName .. " but this joint is not attached to this sprite.");
		return
	end

	lhJointObject:removeSelf();
	lhJointObject = nil;
end
--------------------------------------------------------------------------------
--PRIVATE METHODS - USER SHOULD NOT CARE ABOUT THIS METHODS
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
createSingleSpriteFromTextureDictionary = function(texDict, spriteInfo)

	local spr_uvRect = texDict:rectForKey("Frame");
	
	local shTexDict = texDict;
    if(nil == spriteInfo:objectForKey("IsSHSprite"))then--we may be loading directly from a sh dictionary
    
        local shDict = SHDocumentLoader:sharedInstance():dictionaryForSpriteNamed(spriteInfo:stringForKey("SHSpriteName"),
        																		spriteInfo:stringForKey("SHSheetName"),
        																		spriteInfo:stringForKey("SHSceneName"))
        
        if(shDict)then
       		shTexDict = shDict:dictForKey("TextureProperties");
       		
       		spr_uvRect = shTexDict:rectForKey("Frame");
        end
    end
    
    

	local imageFile = imageFileWithFolder(spriteInfo:stringForKey("SheetImage"));
	
	local lhSettings = LHSettings:sharedInstance();
	local batch = lhSettings:sizeForImageFile(imageFile);

	local options = { 
			frames = {
				{ 
					x = spr_uvRect.origin.x,
					y = spr_uvRect.origin.y,
					width = spr_uvRect.size.width,
					height = spr_uvRect.size.height
				}	
    		},
    		
    	sheetContentWidth = batch.width,
    	sheetContentHeight = batch.height
	}
	
	local imageSheet = graphics.newImageSheet( imageFile, options )		
	return display.newImage( imageSheet, 1)
end
--------------------------------------------------------------------------------
createAnimatedSpriteFromDictioary = function(spriteInfo)

	if(spriteInfo == nil)then
		return nil
	end

	local sprAnimInfo = spriteInfo:dictForKey("AnimationsProperties");

	if(sprAnimInfo == nil)then
		return nil;
	end
	
	local otherAnimationsInfo =	nil;
	
	if(sprAnimInfo:objectForKey("OtherAnimations"))then
		otherAnimationsInfo = sprAnimInfo:arrayForKey("OtherAnimations");
	end

	local animName = sprAnimInfo:objectForKey("AnimName")
	if(nil == animName)then 
		animName = sprAnimInfo:objectForKey("UniqueName") --in case we are loading from SH doc
		if(nil == animName)then
			return nil;
		end
	end
    
    
    local animDict = SHDocumentLoader:sharedInstance():dictionaryForAnimationNamed(animName:stringValue(),--sprAnimInfo:stringForKey("AnimName"), 
																				   spriteInfo:stringForKey("SHSceneName"));

	local animNode = LHAnimationNode:animationWithDictionary(animDict);
	if(animNode == nil)then
	return nil
	end
	
	--now set anim properties from the settings inside the level file
	if(sprAnimInfo:objectForKey("AnimRepetitions"))then
		animNode.lhRepetitions = sprAnimInfo:intForKey("AnimRepetitions")
	else
		animNode.lhRepetitions = sprAnimInfo:intForKey("Repetitions") --from SH
	end
	if(sprAnimInfo:objectForKey("AnimLoop"))then
		animNode.lhLoop = sprAnimInfo:boolForKey("AnimLoop")
	else
		animNode.lhLoop = sprAnimInfo:boolForKey("Loop")--from SH
	end
	
	if(sprAnimInfo:objectForKey("AnimRestoreOriginalFrame"))then
		animNode.lhRestoreOriginalFrame = sprAnimInfo:boolForKey("AnimRestoreOriginalFrame")
	else
		animNode.lhRestoreOriginalFrame = sprAnimInfo:boolForKey("RestoreOriginalFrame")
	end
	
	if(sprAnimInfo:objectForKey("AnimSpeed"))then
		animNode.lhDelayPerUnit = sprAnimInfo:floatForKey("AnimSpeed")
	else
		animNode.lhDelayPerUnit = sprAnimInfo:floatForKey("DelayPerUnit")
	end
	
	if(sprAnimInfo:objectForKey("AnimAtStart"))then
		animNode.lhAnimAtStart = sprAnimInfo:boolForKey("AnimAtStart")
	else
		animNode.lhAnimAtStart = sprAnimInfo:boolForKey("StartAtLaunch")
	end

	local imageFile = imageFileWithFolder(animNode.lhSheetImage);
		
	local lhSettings = LHSettings:sharedInstance();
	local batch = lhSettings:sizeForImageFile(imageFile);

	local options = { 
			frames = {	
    		},
    		
    	sheetContentWidth = batch.width,
    	sheetContentHeight = batch.height
	}

	for i = 1, #animNode.lhFrames do
	
		frmInfo = animNode.lhFrames[i];
		
		options.frames[#options.frames + 1] = {	x = frmInfo.lhRect.origin.x, 
												y = frmInfo.lhRect.origin.y,
												width = frmInfo.lhRect.size.width,
												height= frmInfo.lhRect.size.height};
	end
	

	
	----------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------
	
	
	local otherOptions = {};
	
	for a = 1, otherAnimationsInfo:count() do

		local otherInfo = otherAnimationsInfo:dictAtIndex(a);
	
		local otherAnimName = otherInfo:objectForKey("AnimName")
	
		local otherSceneName = otherInfo:objectForKey("SHScene");
	
		local otherAnimDict = SHDocumentLoader:sharedInstance():dictionaryForAnimationNamed(otherAnimName:stringValue(), 
																							otherSceneName:stringValue());

		local otherAnimNode = LHAnimationNode:animationWithDictionary(otherAnimDict);
		if(otherAnimNode == nil)then
			return nil
		end
			
		--now set anim properties from the settings inside the level file
		if(otherInfo:objectForKey("AnimRepetitions"))then
			otherAnimNode.lhRepetitions = otherInfo:intForKey("AnimRepetitions")
		else
			otherAnimNode.lhRepetitions = otherInfo:intForKey("Repetitions") --from SH
		end
		
		if(otherInfo:objectForKey("AnimLoop"))then
			otherAnimNode.lhLoop = otherInfo:boolForKey("AnimLoop")
		else
			otherAnimNode.lhLoop = otherInfo:boolForKey("Loop")--from SH
		end
			
		if(otherInfo:objectForKey("AnimRestoreOriginalFrame"))then
			otherAnimNode.lhRestoreOriginalFrame = otherInfo:boolForKey("AnimRestoreOriginalFrame")
		else
			otherAnimNode.lhRestoreOriginalFrame = otherInfo:boolForKey("RestoreOriginalFrame")
		end
			
		if(otherInfo:objectForKey("AnimSpeed"))then
			otherAnimNode.lhDelayPerUnit = otherInfo:floatForKey("AnimSpeed")
		else
			otherAnimNode.lhDelayPerUnit = otherInfo:floatForKey("DelayPerUnit")
		end
			
		if(otherInfo:objectForKey("AnimAtStart"))then
			otherAnimNode.lhAnimAtStart = otherInfo:boolForKey("AnimAtStart")
		else
			otherAnimNode.lhAnimAtStart = otherInfo:boolForKey("StartAtLaunch")
		end
				
		
		local otherImageFile = imageFileWithFolder(otherAnimNode.lhSheetImage);
		local otherBatch = lhSettings:sizeForImageFile(otherImageFile);
			
		local OtherOpt = { 
				frames = {	
		   		},
			   		
		   	sheetContentWidth = otherBatch.width,
		   	sheetContentHeight = otherBatch.height
		}
			
		for i = 1, #otherAnimNode.lhFrames do
			
			otherFrmInfo = otherAnimNode.lhFrames[i];
				
			OtherOpt.frames[#OtherOpt.frames + 1] = {	x = otherFrmInfo.lhRect.origin.x, 
														y = otherFrmInfo.lhRect.origin.y,
														width = otherFrmInfo.lhRect.size.width,
														height= otherFrmInfo.lhRect.size.height};
		end

		local otherImageSheet = graphics.newImageSheet( otherImageFile, OtherOpt )				
		
		otherOptions[#otherOptions + 1] = {	imageSheet = otherImageSheet, 
											animNode = otherAnimNode};
	end
	

	----------------------------------------------------------------------------------------------
	----------------------------------------------------------------------------------------------
	----------------------------------------------------------------------------------------------
	
	local loop = 0;
	if false == animNode.lhLoop then
		loop = animNode.lhRepetitions
	end
			
	local speed = animNode:animationTime();
	if(speed < 0.001)then
		speed = 0.001
	end
	speed = speed*1000;

	
	local imageSheet = graphics.newImageSheet( imageFile, options )			

	local sequenceData = {
	    
	    {
	    name=#animNode.lhUniqueName,
    	start=1,
	    count=#animNode.lhFrames,
    	time=speed,       
	    loopCount = loop,
	    sheet = imageSheet
	    }
	}
	
	for i = 1, #otherOptions do
		
		local otherOptions = otherOptions[i];
		
		local otherAnimNode = otherOptions.animNode;
		
		local otherLoop = 0;
		if false == otherAnimNode.lhLoop then
			otherLoop = otherAnimNode.lhRepetitions
		end
			
		local otherSpeed = otherAnimNode:animationTime();
		if(otherSpeed < 0.001)then
			otherSpeed = 0.001
		end
		otherSpeed = otherSpeed*1000;
	
		sequenceData[#sequenceData+1] = {name = otherAnimNode.lhUniqueName,
										start = 1,
										count = #otherAnimNode.lhFrames,
										time  = otherSpeed,
										loopCount = otherLoop,
										sheet = otherOptions.imageSheet
										}
	end
	

	local animSprite = display.newSprite( imageSheet, sequenceData )
		
	animSprite.lhAnimationNodes = {};
	
	
	for i = 1, #otherOptions do
		local otherOptions = otherOptions[i];
		local otherAnimNode = otherOptions.animNode;
		otherAnimNode.coronaSprite = animSprite;
		animSprite.lhAnimationNodes[#animSprite.lhAnimationNodes + 1] = otherAnimNode;										
	end
	
	animSprite.lhAnimationNodes[#animSprite.lhAnimationNodes + 1] = animNode;
	animSprite.lhActiveAnimNode = animNode;
	animNode.coronaSprite = animSprite;
	
	return animSprite;
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
setTexturePropertiesOnSprite = function(coronaSprite, texDict)
	
	local scale = texDict:sizeForKey("Scale");
	local flipX = texDict:boolForKey("FlipX")
	local flipY = texDict:boolForKey("FlipY");

	coronaSprite.xScale = coronaSprite.xScale*scale.width
	coronaSprite.yScale = coronaSprite.yScale*scale.height
	coronaSprite.lhScaleWidth = scale.width;
	coronaSprite.lhScaleHeight= scale.height;
	
	if(flipX)then
		coronaSprite.xScale = -1.0*coronaSprite.xScale;
		coronaSprite.lhScaleWidth = -1.0*coronaSprite.lhScaleWidth
	end
	
	if(flipY)then
		coronaSprite.yScale = -1.0*coronaSprite.yScale;
		coronaSprite.lhScaleHeight= -1.0*coronaSprite.lhScaleHeight;
	end
						

	coronaSprite.rotation = texDict:intForKey("Angle")
	coronaSprite.alpha 	  = texDict:floatForKey("Opacity")
	coronaSprite.isVisible = texDict:boolForKey("IsDrawable")

	local position = texDict:pointForKey("Position");
	coronaSprite.x = position.x
	coronaSprite.y = position.y
		
	local color = texDict:rectForKey("Color");
	coronaSprite:setFillColor(color.origin.x*255,color.origin.y*255,color.size.width*255)	
	
end
--------------------------------------------------------------------------------
setUserClassPropertiesOnSprite = function(coronaSprite, spriteInfo)

	local classInfo = spriteInfo:dictForKey("CustomClassInfo");

	if(nil == classInfo)then
		return
	end
	
    local className = classInfo:stringForKey("ClassName");
    
    if(className == nil)then
	    return
    end
    
    require("LevelHelper.CustomClasses.LHCustomClasses");
    coronaSprite.lhUserCustomInfo = lh_customClassInstanceWithName(className);

	if(coronaSprite.lhUserCustomInfo == nil)then
		return
	end
	
	local classRep = classInfo:dictForKey("ClassRepresentation");
	
	coronaSprite.lhUserCustomInfo:setPropertiesFromDictionary(classRep);
end
--------------------------------------------------------------------------------
loadPathMovementFromDictionary = function(coronaSprite, spriteInfo)

	local dictionary = spriteInfo:dictForKey("PathProperties");
	
	
	if(dictionary == nil or dictionary:isEmpty())then
		return;
	end

--    //at this point we may not have a LHBezier in the level 
--    //so we create the path after the level is fully loaded
--    //but we save the path properties here

	local pathName = dictionary:stringForKey("PathName");
	
	if(nil == pathName)then
		return
	end
	
	coronaSprite.pathDefaultFlipX 			= dictionary:boolForKey("PathFlipX");
	coronaSprite.pathDefaultFlipY 			= dictionary:boolForKey("PathFlipY");
    coronaSprite.pathDefaultIsCyclic 		= dictionary:boolForKey("PathIsCyclic");
	coronaSprite.pathDefaultRelativeMove 	= dictionary:boolForKey("PathMoveDelta");
	coronaSprite.lhPathUniqueName 			= pathName;
	coronaSprite.pathDefaultOrientation 	= dictionary:intForKey("PathOrientation");
	coronaSprite.pathDefaultRestartOtherEnd = dictionary:boolForKey("PathOtherEnd");
	coronaSprite.pathDefaultSpeed 			= dictionary:floatForKey("PathSpeed");
	coronaSprite.pathDefaultStartAtLaunch	= dictionary:boolForKey("PathStartAtLaunch");
	coronaSprite.pathDefaultStartPoint 		= dictionary:intForKey("PathStartPoint");
	
end
--------------------------------------------------------------------------------
recreatePhysicObjectForSprite = function(coronaSprite, phyDict)

--first remove the previously created body - if any
 	
	if(coronaSprite.lhFixtures~= nil)then --it may be that sprite has no physics 
		physics.removeBody(coronaSprite);
		for i = 1, #coronaSprite.lhFixtures do
			coronaSprite.lhFixtures[i]:removeSelf()
			coronaSprite.lhFixtures[i] = nil;
		end
		coronaSprite.lhFixtures = nil;
	end



	local pType = phyDict:intForKey("Type");							
	if(pType == 3) then
		return
	end

	local physicType = "static"	
	if(pType == 1)then
		physicType = "kinematic";
	elseif(pType == 2)then
		physicType = "dynamic";
	end

	local fixturesInfo = phyDict:arrayForKey("SH_ComplexShapes");
	
	if(nil == fixturesInfo)then
		return
	end
	
	local completeBodyFixtures = {};
	
	coronaSprite.lhFixtures = {};
	
 	for i=1, fixturesInfo:count() do
 		local fixInfo = fixturesInfo:dictAtIndex(i);
		local previousFixSize = #completeBodyFixtures
 		local fixture = LHFixture:fixtureWithDictionary(fixInfo, coronaSprite, physics, completeBodyFixtures);

		fixture.coronaMinFixtureIdForThisObject = previousFixSize +1;
 		fixture.coronaMaxFixtureIdForThisObject = #completeBodyFixtures;
 		 		
		coronaSprite.lhFixtures[#coronaSprite.lhFixtures +1] = fixture;		
 	end
 	 	
 	physics.addBody(coronaSprite, 
					physicType,
					unpack(completeBodyFixtures))

	coronaSprite.isFixedRotation = phyDict:boolForKey("FixedRot")	
	coronaSprite.isBullet = phyDict:boolForKey("IsBullet")
	coronaSprite.isSleepingAllowed = phyDict:boolForKey("CanSleep")
	coronaSprite.linearDamping = phyDict:floatForKey("LinearDamping")
	coronaSprite.angularDamping = phyDict:floatForKey("AngularDamping");
	coronaSprite.angularVelocity =  phyDict:floatForKey("AngularVelocity")
	
	local velocity = phyDict:pointForKey("LinearVelocity")
	coronaSprite:setLinearVelocity( velocity.x, velocity.y)

end
--------------------------------------------------------------------------------
createPhysicObjectForSprite = function(coronaSprite, spriteInfo)

	local physics = require("physics")
	
	if(nil == physics)then
		return
	end

	phyDict = spriteInfo:dictForKey("PhysicProperties");

	if(phyDict:boolForKey("HandledBySH")) then
		local sprDict = SHDocumentLoader:sharedInstance():dictionaryForSpriteNamed(	coronaSprite.shSpriteName, 
																					coronaSprite.shSheetName, 
																					coronaSprite.shSceneName);
																					
																					
		if(sprDict)then
	        phyDict = sprDict:dictForKey("PhysicProperties");
        end   
	end
	
	coronaSprite.lhPhysicalInfo = phyDict;
	
	recreatePhysicObjectForSprite(coronaSprite, coronaSprite.lhPhysicalInfo)
--					
--	local pType = phyDict:intForKey("Type");							
--	if(pType == 3) then
--		return
--	end
--
--	local physicType = "static"	
--	if(pType == 1)then
--		physicType = "kinematic";
--	elseif(pType == 2)then
--		physicType = "dynamic";
--	end
--
--	local fixturesInfo = phyDict:arrayForKey("SH_ComplexShapes");
--	
--	if(nil == fixturesInfo)then
--		return
--	end
--	
--	local completeBodyFixtures = {};
--	
-- 	for i=1, fixturesInfo:count() do
-- 		local fixInfo = fixturesInfo:dictAtIndex(i);
--		local previousFixSize = #completeBodyFixtures
-- 		local fixture = LHFixture:fixtureWithDictionary(fixInfo, coronaSprite, physics, completeBodyFixtures);
--
--		fixture.coronaMinFixtureIdForThisObject = previousFixSize +1;
-- 		fixture.coronaMaxFixtureIdForThisObject = #completeBodyFixtures;
-- 		 		
--		coronaSprite.lhFixtures[#coronaSprite.lhFixtures +1] = fixture;		
-- 	end
-- 	
-- 	physics.addBody(coronaSprite, 
--					physicType,
--					unpack(completeBodyFixtures))
--
--	coronaSprite.isFixedRotation = phyDict:boolForKey("FixedRot")	
--	coronaSprite.isBullet = phyDict:boolForKey("IsBullet")
--	coronaSprite.isSleepingAllowed = phyDict:boolForKey("CanSleep")
--	coronaSprite.linearDamping = phyDict:floatForKey("LinearDamping")
--	coronaSprite.angularDamping = phyDict:floatForKey("AngularDamping");
--	coronaSprite.angularVelocity =  phyDict:floatForKey("AngularVelocity")
--	
--	local velocity = phyDict:pointForKey("LinearVelocity")
--	coronaSprite:setLinearVelocity( velocity.x, velocity.y)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
return LHSprite;
	