--[[
//  This file was created by LevelHelper
//  http://www.levelhelper.org
//
//  Author: Bogdan Vladu
//  Copyright 2011 Bogdan Vladu. All rights reserved.
//
//////////////////////////////////////////////////////////////////////////////////////////
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//  The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//  Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//  This notice may not be removed or altered from any source distribution.
//  By "software" the author refers to this code file and not the application 
//  that was used to generate this file.
//
//////////////////////////////////////////////////////////////////////////////////////////
//  Version history
//  v1.0 First version for LevelHelper 1.4.9
//////////////////////////////////////////////////////////////////////////////////////////
--]]
require "config"
require "LevelHelper.Helpers.LHHelpers"
require "LevelHelper.Helpers.LHObject"
require "LevelHelper.Helpers.LHArray"
require "LevelHelper.Helpers.LHDictionary"

require "LevelHelper.Nodes.LHBatch"
require "LevelHelper.Nodes.LHSprite"
require "LevelHelper.Nodes.LHBezier"
require "LevelHelper.Nodes.LHJoint"
require "LevelHelper.Nodes.LHPathNode"

require "LevelHelper.Nodes.LHParallaxNode"
require "LevelHelper.Nodes.LHSettings"

LevelHelper_TAG =
{ 
	DEFAULT_TAG 	= 0,
	NUMBER_OF_TAGS 	= 1
}

LHLevelLoadingNotification = "LHLevelLoadingNotification"

LevelHelperLoader = {} 
function LevelHelperLoader:initWithContentOfFile(levelFile) -- pass level file as string
		
	if levelFile == "" then
		print("Invalid level file given!")
	end

	local object = {lhNodes 	= nil, --nodes info
					mainLHLayer = nil, --all loaded nodes 
					lhJoints	= nil, --joints info
					loadedJoints = {}, --all loaded joints
					lhParallaxes  = nil, --parallaxes info
					loadedParallaxes = {},
					lhWb		= nil, --world physic boundary info
					lhSafeFrame = nil, -- point
					lhGameWorldRect = nil, -- rect
					lhBackgroundColor = nil, -- rect
					loadedBackgroundObj = nil, --display object
					lhGravityInfo = nil, -- point
					
					beginOrEndCollisionMap = {}, --dictionary
					preCollisionMap = {}, --dictionary
					postCollisionMap = {}, --dictionary
					}
					
					
					
	setmetatable(object, { __index = LevelHelperLoader })  -- Inheritance
	
	object:loadLevelHelperSceneFile(levelFile, system.ResourceDirectory)
	
	return object
end
--------------------------------------------------------------------------------
function LevelHelperLoader:removeSelf()
	
	self.lhNodes:removeSelf();
	self.lhNodes = nil;
	self.lhJoints:removeSelf();		
	self.lhJoints = nil;
	self.lhParallaxes:removeSelf();
	self.lhParallaxes = nil;
							
	self.lhSafeFrame = nil
	self.lhGameWorldRect = nil
	self.lhBackgroundColor = nil

	self:removeBackgroundColor();
	
	self.lhGravityInfo = nil;
		
	if(self.lhWb~=nil)then		
		self.lhWb:removeSelf();
	end
	self.lhWb = nil
						
	LHSettings:sharedInstance():removeLHMainLayer(self.mainLHLayer);
	self.mainLHLayer:removeSelf();
	self.mainLHLayer = nil;
					
	self.loadedJoints = nil; --all joints are removed when sprites are removed
	
	for k,v in pairs(self.loadedParallaxes) do 
		if v~=nil then
			v:removeSelf();
		end
	end
	self.loadedParallaxes = nil
	
	self.preCollisionMap = nil;
	self.postCollisionMap = nil;
	self.beginOrEndCollisionMap = nil;

	Runtime:removeEventListener("collision", self)
	Runtime:removeEventListener("postCollision", self)
	Runtime:removeEventListener("preCollision", self)
		
	self.notUsed = nil					
	self = nil	
	
--	removeLHSettings()
end
--------------------------------------------------------------------------------
function LevelHelperLoader:instantiateSprites()
	self:instantiateObjects()
end
--------------------------------------------------------------------------------
function LevelHelperLoader:instantiateObjects()

	self:callLoadingProgressWithValue(0.0)
		self:createBackgroundColor();
	self:callLoadingProgressWithValue(0.05)
		self:createGravity();
	self:callLoadingProgressWithValue(0.10)
	    self:createAllNodes();
   	self:callLoadingProgressWithValue(0.60)
    	self:createAllJoints();
    self:callLoadingProgressWithValue(0.70)
    	self:createParallaxes()
    self:callLoadingProgressWithValue(0.80)
  	 	self:startAllPaths()
    self:callLoadingProgressWithValue(0.90) 
  	if(self:hasPhysicBoundaries())then
	  	self:createPhysicBoundaries()
	end
    self:callLoadingProgressWithValue(1.0)
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--to remove any of the LHLayer, LHBatch, LHSprite, LHBezier, LHJoint objects call
--object:removeSelf()
--------------------------------------------------------------------------------
function LevelHelperLoader:layerWithUniqueName(name)
	if(self.mainLHLayer == nil) then
		print("LevelHelper Error: Main Layer has not been created yet. Call this method after you have loaded the level");
		return nil;
	end
	if(self.mainLHLayer.lhUniqueName == name)then
		return self.mainLHLayer;
	end
	return self.mainLHLayer:layerWithUniqueName(name)
end
--------------------------------------------------------------------------------
function LevelHelperLoader:batchWithUniqueName(name)
	if(self.mainLHLayer == nil) then
		print("LevelHelper Error: Main Layer has not been created yet. Call this method after you have loaded the level");
		return nil;
	end
	return self.mainLHLayer:batchWithUniqueName(name);
end
--------------------------------------------------------------------------------
function LevelHelperLoader:spriteWithUniqueName(name)
	if(self.mainLHLayer == nil) then
		print("LevelHelper Error: Main Layer has not been created yet. Call this method after you have loaded the level");
		return nil;
	end
	return self.mainLHLayer:spriteWithUniqueName(name);
end
--------------------------------------------------------------------------------
function LevelHelperLoader:bezierWithUniqueName(name)
	if(self.mainLHLayer == nil) then
		print("LevelHelper Error: Main Layer has not been created yet. Call this method after you have loaded the level");
		return nil;
	end
	return self.mainLHLayer:bezierWithUniqueName(name);
end
--------------------------------------------------------------------------------
function LevelHelperLoader:jointWithUniqueName(name)

	local jt = self.loadedJoints[name];
	if(jt)then
		if(jt.lhUniqueName == name)then
			return jt;
		end
	end
	return nil;
end
--------------------------------------------------------------------------------
function LevelHelperLoader:parallaxWithUniqueName(name)

	local par = self.loadedParallaxes[name];
	if(par)then
		if(par.lhUniqueName == name)then
			return par;
		end
	end
	return nil;
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function LevelHelperLoader:allLayers()
	if(self.mainLHLayer == nil) then
		print("LevelHelper Error: Main Layer has not been created yet. Call this method after you have loaded the level");
		return nil;
	end
	local tempTable = self.mainLHLayer:allLayers();
	tempTable[#tempTable+1] = self.mainLHLayer;
	return tempTable;
end
--------------------------------------------------------------------------------
function LevelHelperLoader:allBatches()
	if(self.mainLHLayer == nil) then
		print("LevelHelper Error: Main Layer has not been created yet. Call this method after you have loaded the level");
		return nil;
	end
	return self.mainLHLayer:allBatches();
end
--------------------------------------------------------------------------------
function LevelHelperLoader:allSprites()
	if(self.mainLHLayer == nil) then
		print("LevelHelper Error: Main Layer has not been created yet. Call this method after you have loaded the level");
		return nil;
	end
	return self.mainLHLayer:allSprites();
end
--------------------------------------------------------------------------------
function LevelHelperLoader:allBeziers()
	if(self.mainLHLayer == nil) then
		print("LevelHelper Error: Main Layer has not been created yet. Call this method after you have loaded the level");
		return nil;
	end
	return self.mainLHLayer:allBeziers();
end
--------------------------------------------------------------------------------
function LevelHelperLoader:allJoints()	
	local tempTable = {}
	for k,v in pairs(self.loadedJoints) do 
		if v~=nil then
			tempTable[#tempTable+1] = v;
		end
	end
	return tempTable;
end
--------------------------------------------------------------------------------
function LevelHelperLoader:allParallaxes()
	local tempTable = {}
	for k,v in pairs(self.loadedParallaxes) do 
		if v~=nil then
			tempTable[#tempTable+1] = v;
		end
	end
	return tempTable;
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function LevelHelperLoader:layersWithTag(tag)

end
--------------------------------------------------------------------------------
function LevelHelperLoader:batchesWithTag(tag)
	if(self.mainLHLayer == nil) then
		print("LevelHelper Error: Main Layer has not been created yet. Call this method after you have loaded the level");
		return nil;
	end
	return self.mainLHLayer:batchesWithTag(tag);
end
--------------------------------------------------------------------------------
function LevelHelperLoader:spritesWithTag(tag)
	if(self.mainLHLayer == nil) then
		print("LevelHelper Error: Main Layer has not been created yet. Call this method after you have loaded the level");
		return nil;
	end
	return self.mainLHLayer:spritesWithTag(tag);
end
--------------------------------------------------------------------------------
function LevelHelperLoader:beziersWithTag(tag)
	if(self.mainLHLayer == nil) then
		print("LevelHelper Error: Main Layer has not been created yet. Call this method after you have loaded the level");
		return nil;
	end
	return self.mainLHLayer:beziersWithTag(tag);
end
--------------------------------------------------------------------------------
function LevelHelperLoader:jointsWithTag(tag)
	
	local tempTable = {}
	for k,v in pairs(self.loadedJoints) do 
		if v~=nil then
			if(v.lhTag == tag)then
				tempTable[#tempTable+1] = v;
			end
		end
	end
	return tempTable;
end
--------------------------------------------------------------------------------
--GAME WORLD
function LevelHelperLoader:getGameWorldRect()
	return self.lhGameWorldRect;
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function LevelHelperLoader:hasPhysicBoundaries()
	if self.lhWb ~= nil then
		local rect = self.lhWb:rectForKey("WBRect");
	   	if rect.size.width == 0 or rect.size.height == 0 then
   			return false
   		end
		return true
	end
	return false
end
--------------------------------------------------------------------------------
function LevelHelperLoader:getPhysicBoundariesRect()
	if false == self:hasPhysicBoundaries() then
		print("LevelHelper ERROR: Please create physic boundaries inside LevelHelper in order to call \"getPhysicBoundariesRect\" method.")
		return
	end
    local rect = self.lhWb:rectForKey("WBRect");
	return {origin = {x = rect.origin.x, y = rect.origin.y}, 
			size   = {width = rect.size.width, height = rect.size.height}}
end
--------------------------------------------------------------------------------
function LevelHelperLoader:createPhysicBoundaries()

	local physics = require("physics")	
	if(nil == physics)then
		return
	end
	

	if false == self:hasPhysicBoundaries() then
		print("LevelHelper ERROR: Please create physic boundaries inside LevelHelper in order to call \"createPhysicBoundaries\" method.")
		return
	end
    
	local wbInfo = self.lhWb;								
	local rect 			= wbInfo:rectForKey("WBRect");
								
	local createLineBoundary = function(info, uniqueName, groupParent, shapePoints, tagName)
	    local borderLine = display.newLine( 0,0, 0,0 )    

	    borderLine.lhTag 		= info:intForKey(tagName)
		borderLine.lhUniqueName = uniqueName
		borderLine.lhNodeType = "PHYSIC_BOUNDARY_LINE"
				
	    local friction 		= wbInfo:floatForKey("Friction")
	    local density 		= wbInfo:floatForKey("Density")
    	local restitution 	= wbInfo:floatForKey("Restitution")
    
    	local collisionFilter = { 	categoryBits 	= wbInfo:intForKey("Category"), 
									maskBits 		= wbInfo:intForKey("Mask"), 
									groupIndex 		= wbInfo:intForKey("Group") } 
		  					
		physics.addBody( borderLine, "static", { density=density, 
												friction=friction, 
												bounce	=restitution, 
												shape	=shapePoints, 
												filter = collisionFilter } )
		
		function removeBorderLineSelf(spriteSelf)
			--print("remove border line self " .. spriteSelf.lhUniqueName);
			spriteSelf.lhTag = nil;
			spriteSelf.lhUniqueName = nil;
			spriteSelf.lhNodeType = nil;
			spriteSelf:originalCoronaRemoveSelf();
			spriteSelf = nil;
		end
		borderLine.originalCoronaRemoveSelf = borderLine.removeSelf;
		borderLine.removeSelf 				= removeBorderLineSelf;
		
		groupParent:insert(borderLine);
	end


	local wbConv = { x = 1.0, y = 1.0}
  	local shape = { rect.origin.x*wbConv.x, 
  					rect.origin.y*wbConv.y, 
  					(rect.origin.x + rect.size.width)*wbConv.x, 
	  				rect.origin.y*wbConv.y }
	createLineBoundary(wbInfo, "LH_PHYSIC_BOUNDARIES_TOP", self.mainLHLayer, shape, "TagTop");


  	shape = { 	rect.origin.x*wbConv.x, 
  				rect.origin.y*wbConv.y, 
  				rect.origin.x*wbConv.x, 
  				(rect.origin.y + rect.size.height)*wbConv.y}
	createLineBoundary(wbInfo, "LH_PHYSIC_BOUNDARIES_LEFT", self.mainLHLayer, shape, "TagLeft");


  	shape = { 	(rect.origin.x + rect.size.width)*wbConv.x,
  				rect.origin.y*wbConv.y, 
  				(rect.origin.x + rect.size.width)*wbConv.x, 
  				(rect.origin.y + rect.size.height)*wbConv.y}
	createLineBoundary(wbInfo, "LH_PHYSIC_BOUNDARIES_RIGHT", self.mainLHLayer, shape, "TagRight");
	
	
  	shape = { 	rect.origin.x*wbConv.x, 
  				(rect.origin.y + rect.size.height)*wbConv.y, 
	  			(rect.origin.x + rect.size.width)*wbConv.x, 
  				(rect.origin.y + rect.size.height)*wbConv.y}
	createLineBoundary(wbInfo, "LH_PHYSIC_BOUNDARIES_BOTTOM", self.mainLHLayer, shape, "TagBottom");
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--function LevelHelperLoader:instantiateObjectsInGroup(physics, theGroup)
--	if(nil == application)then
--		print("LevelHelper ERROR: Missing or bad config.lua file. application is not present");
--		return
--	end
--	
--	if(nil == application.LevelHelperSettings)then
--		print("LevelHelper ERROR: Missing LevelHelperSettings in config.lua file. Please see API Documentation -> Getting Started");
--		return
--	end
--
--	application.LevelHelperSettings.directorGroup = theGroup
--	self:instantiateObjects(physics)
--end
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function LevelHelperLoader:setPaused(pauseState)

	local allSprites = self:allSprites();
	
	for i = 1, #allSprites do
		local spr = allSprites[i];
		
		if(pauseState == true)then
			
			if spr ~= nil then
			
				if(spr:isPathMovementPaused() == false)then
					spr.lhSpritePathMovementWasPausedByLoader = true;	
					spr:pausePathMovement()
				end
				
				if(spr:isAnimationPaused() == false)then
					spr.lhSpriteAnimWasPausedByLoader = true;
					spr:pauseAnimation()
				end
			end

		else
		
			if spr ~= nil then
				if(spr.lhSpritePathMovementWasPausedByLoader)then
					spr:startPathMovement()
					spr.lhSpritePathMovementWasPausedByLoader = nil
				end
				
				if(spr.lhSpriteAnimWasPausedByLoader)then
					spr:playAnimation()
					spr.lhSpriteAnimWasPausedByLoader = nil;
				end
			end

		end
	end	


	for k,v in pairs(self.loadedParallaxes) do 
		if v~=nil then
			if(pauseState)then
				if(v:isPaused() == false)then
					v:setPaused(true)
					v.lhParallaxWasPausedByLoader = true;
				end
			else
				if(v.lhParallaxWasPausedByLoader)then
					v:setPaused(false)
					v.lhParallaxWasPausedByLoader = nil
				end
			end
		end
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--COLLISION HANDLING METHODS
function LevelHelperLoader:useLevelHelperCollisionHandling()
	Runtime:addEventListener( "collision", self);
	Runtime:addEventListener( "postCollision", self );
	Runtime:addEventListener( "preCollision", self );
end
--------------------------------------------------------------------------------
function LevelHelperLoader:registerBeginOrEndCollisionCallbackBetweenTags(tagA, tagB, callbackFunction)
	local tableA = self.beginOrEndCollisionMap[tagA];
	if(nil == tableA)then
		local myMap = {}
		myMap[tagB] = callbackFunction;
		self.beginOrEndCollisionMap[tagA] = myMap
	else
		tableA[tagB] = callbackFunction;
	end
end
--------------------------------------------------------------------------------
function LevelHelperLoader:cancelBeginOrEndCollisionCallbackBetweenTags(tagA, tagB)
	local callbackA = self.beginOrEndCollisionMap[tagA];
	if(nil ~= callbackA)then
	  	callbackA[tagB] = nil;
	end	
end
--------------------------------------------------------------------------------
function LevelHelperLoader:registerPreColisionCallbackBetweenTags(tagA, tagB, callbackFunction)
	local tableA = self.preCollisionMap[tagA];
	if(nil == tableA)then
		local myMap = {}
		myMap[tagB] = callbackFunction;
		self.preCollisionMap[tagA] = myMap
	else
		tableA[tagB] = callbackFunction;
	end
end
--------------------------------------------------------------------------------
function LevelHelperLoader:cancelPreCollisionCallbackBetweenTags(tagA, tagB)
	local callbackA = self.preCollisionMap[tagA];
	if(nil ~= callbackA)then
	  	callbackA[tagB] = nil;
	end	
end
--------------------------------------------------------------------------------
function LevelHelperLoader:registerPostColisionCallbackBetweenTags(tagA, tagB, callbackFunction)
	local tableA = self.postCollisionMap[tagA];
	if(nil == tableA)then
		local myMap = {}
		myMap[tagB] = callbackFunction;
		self.postCollisionMap[tagA] = myMap
	else
		tableA[tagB] = callbackFunction;
	end
end
--------------------------------------------------------------------------------
function LevelHelperLoader:cancelPostCollisionCallbackBetweenTags(tagA, tagB)
	local callbackA = self.postCollisionMap[tagA];
	if(nil ~= callbackA)then
	  	callbackA[tagB] = nil;
	end	
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--CREATION METHODS
--this method can be called both 
--loader:createSpriteFromSHDocument --when you already loaded a level
--and
--LevelHelperLoader:createSpriteFromSHDocument --when you dont have a level loaded
function LevelHelperLoader:createSpriteFromSHDocument(spriteName, sheetName, documentName)

	if(	documentName ~= nil and
	   	sheetName ~= nil and
	    spriteName~= nil)then
		   		    
	   local SHLoaded = SHDocumentLoader:sharedInstance();
	   local spriteDict = SHLoaded:dictionaryForSpriteNamed(spriteName, 
	   														sheetName,
	   														documentName)												
	   if(spriteDict ~= nil)then
	   		
		   LHSprite = require("LevelHelper.Nodes.LHSprite");
		   spriteDict:setObjectForKey(LHObject:init(documentName, LH_OBJECT_TYPE.STRING_TYPE), 
               					   	"SHSceneName");
               					   				   
			local spr = LHSprite:spriteWithDictionary(spriteDict);
			if(spr ~= nil)then
				if(self)then
					if(self.mainLHLayer)then
						self.mainLHLayer:addChild(spr, spr.lhZOrder);
					end
				end
				return spr;
			end
	   	end
	end	
	return nil;		
end
--------------------------------------------------------------------------------
--this method can be called both 
--loader:createAnimatedSpriteFromSHDocument --when you already loaded a level
--and
--LevelHelperLoader:createAnimatedSpriteFromSHDocument --when you dont have a level loaded
function LevelHelperLoader:createAnimatedSpriteFromSHDocument(spriteName, sheetName, SHDocumentFile, mainAnimName)

	if(	SHDocumentFile ~= nil and
	   	sheetName ~= nil and
	    spriteName~= nil)then
		   		    
	   local SHLoader = SHDocumentLoader:sharedInstance();
	   local spriteDict = SHLoader:dictionaryForSpriteNamed(spriteName, 
	   														sheetName,
	   														SHDocumentFile)												
	   if(spriteDict ~= nil)then
	   		
	   	   local animDict = SHLoader:dictionaryForAnimationNamed(mainAnimName, SHDocumentFile)
	   	   
	   	   if(animDict)then
	   	   
		   	   	local newSpriteDict = LHDictionary:initWithDictionary(spriteDict)
	   	   		if(newSpriteDict)then
		   	   		local tempDict = LHDictionary:initWithDictionary(animDict);
		   	   		if(tempDict)then	   	   
			   		   	newSpriteDict:setObjectForKey(LHObject:init(tempDict, LH_OBJECT_TYPE.LH_DICT_TYPE), 
            	   						   	"AnimationsProperties");
		     		end
		     	
			        LHSprite = require("LevelHelper.Nodes.LHSprite");
				    newSpriteDict:setObjectForKey(LHObject:init(SHDocumentFile, LH_OBJECT_TYPE.STRING_TYPE), 
        	       					   	"SHSceneName");
               					   				   
					local newCreatedSprite = LHSprite:spriteWithDictionary(newSpriteDict);
				
					newSpriteDict:removeSelf();
				
					if(newCreatedSprite ~= nil)then
						if(self)then
							if(self.mainLHLayer)then
								self.mainLHLayer:addChild(newCreatedSprite, 0);--z is not yet used
							end
						end
						return newCreatedSprite;
					end
				end
			end	   
	  	end
	end
	return nil;		
end
--------------------------------------------------------------------------------
--this duplicate a sprite from the loaded level
function LevelHelperLoader:createSpriteWithUniqueName(uniqueName)

	local spriteInLevel = self:spriteWithUniqueName(uniqueName);
	
	if(spriteInLevel ~= nil)then

		if(spriteInLevel.shSceneName ~= nil and
		   spriteInLevel.shSheetName ~= nil and
		   spriteInLevel.shSpriteName~= nil)then
		   		    
		   return self:newSpriteFromSHDocument(	spriteInLevel.shSceneName, 
		   										spriteInLevel.shSheetName, 
		   										spriteInLevel.shSpriteName);
		end	
	end
	
	return nil;
end
--------------------------------------------------------------------------------
function LevelHelperLoader:removeBackgroundColor()
	if(self.loadedBackgroundObj ~= nil)then
		self.loadedBackgroundObj:removeSelf();
	end
	self.loadedBackgroundObj = nil
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-------PRIVATE METHODS - THIS SHOULD NOT BE USED BY THE USER--------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function LevelHelperLoader:callLoadingProgressWithValue(value)
	local loadGEvent = { name=LHLevelLoadingNotification, object = self, progress = value} 
	Runtime:dispatchEvent(loadGEvent);
end
--------------------------------------------------------------------------------
function LevelHelperLoader:createAllNodes()	
	for i=1,self.lhNodes:count() do
		local dictionary = self.lhNodes:dictAtIndex(i);		
		if(nil ~= dictionary)then				
			if(dictionary:stringForKey("NodeType") == "LHLayer")then
				
				local LHLayer = require("LevelHelper.Nodes.LHLayer");
				self.mainLHLayer = LHLayer:layerWithDictionary(dictionary)
				self.mainLHLayer.lhIsMainLayer = true;
				self.mainLHLayer.lhParentLoader = self;
				
				LHSettings:sharedInstance():addLHMainLayer(self.mainLHLayer);
			end
		else
			print("just read a nil value from lhNodes");
		end
	end
end
--------------------------------------------------------------------------------
function LevelHelperLoader:createAllJoints()
 
 	for i = 1, self.lhJoints:count() do
 	
 		local jointDict = self.lhJoints:dictAtIndex(i);

		if(nil ~= jointDict)then
			local joint = LHJoint:jointWithDictionary(jointDict, self);
			if(joint~= nil)then
				self.loadedJoints[joint.lhUniqueName] = joint;
			end
		end 		
	end        
end
--------------------------------------------------------------------------------
function LevelHelperLoader:createParallaxes()
	
	for i = 1, self.lhParallaxes:count() do
		local parInfo = self.lhParallaxes:dictAtIndex(i);
		
		if(nil ~= parInfo)then
			local parallax = LHParallaxNode:parallaxWithDictionary(parInfo, self);
			if(nil ~= parallax)then
				self.loadedParallaxes[parallax.lhUniqueName] = parallax;
			end
		end
	end	
end
--------------------------------------------------------------------------------
function LevelHelperLoader:startAllPaths()

    if(nil == self.mainLHLayer)then
	    return;
    end
    
	local allSprites = self.mainLHLayer:allSprites();
        
    for i = 1, #allSprites do
    	local spr = allSprites[i];
    	
        local pathName = spr.lhPathUniqueName;
                
        if(pathName ~= nil)then
        	spr:prepareMovementOnPathWithUniqueName(pathName);
        end
           
        if(spr.pathDefaultStartAtLaunch)then
          	spr:startPathMovement();
        end
	end
end
--------------------------------------------------------------------------------
function LevelHelperLoader:isGravityZero()
	if(nil == self.lhGravityInfo)then
		print("ERROR: Gravity info cound not be found")
		return true;
	end
	if self.lhGravityInfo.x == 0 and self.lhGravityInfo.y == 0 then
		return true
	end
	return false;
end
--------------------------------------------------------------------------------
function LevelHelperLoader:createGravity()
	if(self:isGravityZero() == false)then
		local physics = require("physics")
		if(nil == physics)then
			return
		end
		physics.setGravity( self.lhGravityInfo.x, -1* self.lhGravityInfo.y )	
	end	
end
--------------------------------------------------------------------------------
local setLevelHelperInfoToCollisionEvent = function(event)
		
 	if(event.spriteA)then
 	
 	  	event.lhFixtureNameA = event.spriteA.lhUniqueName
	  	event.lhFixtureIdA = 0

 		if(event.spriteA.lhFixtures)then
 			for i = 1, #event.spriteA.lhFixtures do
  				local fixture = event.spriteA.lhFixtures[i];	
  				if(fixture)then	
  					if(	event.element1 >= fixture.coronaMinFixtureIdForThisObject and 
 						event.element1 <= fixture.coronaMaxFixtureIdForThisObject)then

					   	event.lhFixtureNameA = fixture.lhFixtureName;
		   				event.lhFixtureIdA = fixture.lhFixtureID;
	   					break;
 					end
 				end
 			end
 		end
 	end

 	if(event.spriteB)then
 	
	 	event.lhFixtureNameB = event.spriteB.lhUniqueName
  		event.lhFixtureIdB = 0

 		if(event.spriteB.lhFixtures)then
 			for i = 1, #event.spriteB.lhFixtures do
  				local fixture = event.spriteB.lhFixtures[i];	
  				if(fixture)then	
  					if(	event.element2 >= fixture.coronaMinFixtureIdForThisObject and 
 						event.element2 <= fixture.coronaMaxFixtureIdForThisObject)then

				   		event.lhFixtureNameB = fixture.lhFixtureName;
	   					event.lhFixtureIdB = fixture.lhFixtureID;
	   					break;
 					end
 				end
 			end
 		end
 	end
end
--------------------------------------------------------------------------------
function LevelHelperLoader:collision(event)
	if ( event.phase == "began" ) then	
	
		local foundEvent = false;
		local callbackA = self.beginOrEndCollisionMap[event.object1.lhTag];
		if(nil ~= callbackA)then
	   		if(nil ~= callbackA[event.object2.lhTag])then
		   		foundEvent = true;
		   		event.spriteA = event.object1;
		  		event.spriteB = event.object2;
		   		setLevelHelperInfoToCollisionEvent(event)
		   		callbackA[event.object2.lhTag](event)
	   		end
	   	end

		if(foundEvent == false)then
		   	local callbackB = self.beginOrEndCollisionMap[event.object2.lhTag];
		   	if(nil ~= callbackB)then
	   			if(nil ~= callbackB[event.object1.lhTag])then
		   			event.spriteA = event.object2;
			  		event.spriteB = event.object1;
	   				setLevelHelperInfoToCollisionEvent(event)
					callbackB[event.object1.lhTag](event)
				end
	   		end
	   	end
    elseif ( event.phase == "ended" ) then
    	local foundEvent = false
		local callbackA = self.beginOrEndCollisionMap[event.object1.lhTag];
		if(nil ~= callbackA)then
	   		if(nil ~= callbackA[event.object2.lhTag])then
		   		foundEvent = true;		   	
		   		event.spriteA = event.object1;
			  	event.spriteB = event.object2;	
		   		setLevelHelperInfoToCollisionEvent(event)
	   			callbackA[event.object2.lhTag](event)
	   		end
	   	end

		if(foundEvent == false)then
		   	local callbackB = self.beginOrEndCollisionMap[event.object2.lhTag];
		   	if(nil ~= callbackB)then
	   			if(nil ~= callbackB[event.object1.lhTag])then
		   			event.spriteA = event.object2;
			  		event.spriteB = event.object1;
	   				setLevelHelperInfoToCollisionEvent(event)
	   				callbackB[event.object1.lhTag](event)
	   			end
			end
		end
    end
end
--------------------------------------------------------------------------------
function LevelHelperLoader:postCollision(event)

	local foundEvent = false;
	local callbackA = self.postCollisionMap[event.object1.lhTag];
	if(nil ~= callbackA)then
  		if(nil ~= callbackA[event.object2.lhTag])then
	  		foundEvent = true;
	  		event.spriteA = event.object1;
	  		event.spriteB = event.object2;
	  		setLevelHelperInfoToCollisionEvent(event)
 			callbackA[event.object2.lhTag](event)
 		end
	end

	if(foundEvent == false)then
		local callbackB = self.postCollisionMap[event.object2.lhTag];
	   	if(nil ~= callbackB)then
	   		if(nil ~= callbackB[event.object1.lhTag])then
		   		event.spriteA = event.object2;
			  	event.spriteB = event.object1;
		   		setLevelHelperInfoToCollisionEvent(event)
	   			callbackB[event.object1.lhTag](event)
	   		end
		end
	end
end
--------------------------------------------------------------------------------
function LevelHelperLoader:preCollision(event)

	local foundEvent = false;
	local callbackA = self.preCollisionMap[event.object1.lhTag];
	if(nil ~= callbackA)then
	  	if(nil ~= callbackA[event.object2.lhTag])then
		  	foundEvent = true;
		  	event.spriteA = event.object1;
		  	event.spriteB = event.object2;
		  	setLevelHelperInfoToCollisionEvent(event)
	   		callbackA[event.object2.lhTag](event)
	   	end
	end

	if(foundEvent == false) then
	   	local callbackB = self.preCollisionMap[event.object2.lhTag];
	   	if(nil ~= callbackB)then
	   		if(nil ~= callbackB[event.object1.lhTag])then
		   		event.spriteA = event.object2;
		  		event.spriteB = event.object1;
		   		setLevelHelperInfoToCollisionEvent(event)
				callbackB[event.object1.lhTag](event)
			end
	   	end	
	end
end
--------------------------------------------------------------------------------
function LevelHelperLoader:createBackgroundColor()
	if(nil ~= self.lhGameWorldRect and nil ~= self.lhBackgroundColor)then
		local backgroundColorObj = display.newRect(self.lhGameWorldRect.origin.x,self.lhGameWorldRect.origin.y,
												   self.lhGameWorldRect.size.width,self.lhGameWorldRect.size.height)
		backgroundColorObj:setFillColor(self.lhBackgroundColor.origin.x*255, 
										self.lhBackgroundColor.origin.y*255,
										self.lhBackgroundColor.size.width*255)
										
		self.loadedBackgroundObj = backgroundColorObj
	end
end
--------------------------------------------------------------------------------
function  LevelHelperLoader:loadLevelHelperSceneFile(levelFile, resourceDirectory)

	local path = nil;
	
	if(nil == application)then
		print("LevelHelper ERROR: Missing or bad config.lua file. \"application\" is not present. Please see API Documentation -> Getting Started.");
		return
	end
		
	if(nil ~= application.LevelHelperSettings)then
		if(nil ~= application.LevelHelperSettings.levelsSubfolder)then
			path = system.pathForFile(application.LevelHelperSettings.levelsSubfolder .. "/" .. levelFile, resourceDirectory);
		end
	end
	
	if(nil == path)then
		path = system.pathForFile(levelFile, resourceDirectory)
	end
	
	if(nil == path)then
		print("LEVELHELPER ERROR: Level file not found.");
		return;
	end

	local lvlFile = io.open(path, "r")

	local dictionary = LHDictionary:initWithContentOfFile(lvlFile,nil);
	
	self:processLevelFileFromDictionary(dictionary);

	dictionary:removeSelf()
	dictionary = nil;
	
   	io.close (lvlFile)					
end
--------------------------------------------------------------------------------
function LevelHelperLoader:processLevelFileFromDictionary(dictionary)

	if(nil == dictionary)then
		return;
	end
    
	local fileInCorrectFormat =	dictionary:stringForKey("Author") == "Bogdan Vladu" and 
                                dictionary:stringForKey("CreatedWith") == "LevelHelper";
	
	if(fileInCorrectFormat == false)then
		print("This file was not created with LevelHelper or file is damaged.");
		return;
	end
        
 
 	local scenePref = dictionary:dictForKey("ScenePreference");
 	self.lhSafeFrame = scenePref:pointForKey("SafeFrame");
 	self.lhGameWorldRect = scenePref:rectForKey("GameWorld");
	self.lhBackgroundColor = scenePref:rectForKey("BackgroundColor");	    
        
    if(nil ~= dictionary:objectForKey("WBInfo"))then
		self.lhWb = LHDictionary:initWithDictionary(dictionary:dictForKey("WBInfo"));
	end

	self.lhNodes = LHArray:initWithArray(dictionary:arrayForKey("NODES_INFO"));
	self.lhJoints = LHArray:initWithArray(dictionary:arrayForKey("JOINTS_INFO"));
	self.lhParallaxes = LHArray:initWithArray(dictionary:arrayForKey("PARALLAX_INFO"));
	
	self.lhGravityInfo = dictionary:pointForKey("Gravity");
end

