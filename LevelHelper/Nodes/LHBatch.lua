
require "LevelHelper.Helpers.LHDictionary"

local lh_untitledBatchCount = 0;

local LHBatch = {}
function LHBatch.batchWithDictionary(selfBatch, dictionary)

	if (nil == dictionary) then
		print("Invalid LHLayer initialization!")
	end
				
	local object = display.newGroup();
	
	--add all LevelHelper valid properties to the object
	object.lhNodeType = "LHBatch"
	object.lhImagePath = dictionary:stringForKey("SheetImage")
	object.lhZOrder = dictionary:intForKey("ZOrder")
	object.lhSHFile = nil -- just a reminder that this is here
	
	
	uName = dictionary:stringForKey("UniqueName");
    if(uName)then
       object.lhUniqueName = uName;
    else 
    	uName = dictionary:stringForKey("SheetName");
    	if(uName)then
	    	object.lhUniqueName = uName;
    	else
	       object.lhUniqueName = "UntitledBatch_" .. lh_untitledBatchCount;
    	   lh_untitledBatchCount = lh_untitledBatchCount + 1;
       end
	end

	
	--add all LevelHelper valid methods to the object
	object.addBatchChildFromDictionary = addBatchChildFromDictionary;
	object.addChild = batch_addChild;
	object.uniqueName = batch_uniqueName;
--	object.imagePath
--	object.spriteHelperFile
	object.originalCoronaRemoveSelf = object.removeSelf;
	object.removeSelf = batch_removeSelf;
	object.spriteWithUniqueName = batch_spriteWithUniqueName;          
    object.allSprites = batch_allSprites;
    object.spritesWithTag = batch_spritesWithTag;
    
    local childsInfo = dictionary:objectForKey("Children");
	if(childsInfo~=nil)then
		local childrenInfo = childsInfo:arrayValue();
		if(childrenInfo~=nil)then
			for i=1,childrenInfo:count() do
				local childDict = childrenInfo:dictAtIndex(i);
				object:addBatchChildFromDictionary(childDict);
			end
		end
	end
	
	return object
end
--------------------------------------------------------------------------------
function addBatchChildFromDictionary(selfBatch, childDict)

	nodeType = childDict:stringForKey("NodeType");
	
	if(nodeType == "LHSprite")then
		LHSprite = require("LevelHelper.Nodes.LHSprite");
		local spr = LHSprite:spriteWithDictionary(childDict);
		if(spr ~= nil)then
			selfBatch:addChild(spr, spr.lhZOrder);
			spr.lhParentLoader = selfBatch.lhParentLoader;		
		end
		return;
	end

	if(nodeType == "LHBezier")then
		print("ERROR: Batch nodes should not have LHBezier as children.");
		return;
	end
	
	if(nodeType == "LHBatch")then
		print("ERROR: Batch nodes should not have LHBatch as children.");
		return;
	end
	
	if(nodeType == "LHLayer")then
	    print("ERROR: Batch nodes should not have LHLayer as children.");
	    return;
	end
end
--------------------------------------------------------------------------------
function batch_addChild(selfBatch, object, zOrder)
	--zorder is not used in corona - it behave differently - but order of z from LH is kept
	selfBatch:insert(object)
end
--------------------------------------------------------------------------------
function batch_uniqueName(selfBatch)
	return selfBatch.lhUniqueName;
end
--------------------------------------------------------------------------------
function batch_removeSelf(selfBatch) --this will also remove all children

	--print("calling LHBatch remove self " .. selfBatch.lhUniqueName .. " children " .. tostring(selfBatch.numChildren));
	
	--we use while because if we use for - when removing object we may lose some other objects that now have a lower index
	while(selfBatch.numChildren ~= 0) do
		local node = selfBatch[1]
		if(node)then
			node:removeSelf()
		end
		node = nil;
	end
	
	selfBatch:originalCoronaRemoveSelf()
	selfBatch = nil;
end
--------------------------------------------------------------------------------
function batch_spriteWithUniqueName(selfBatch, name)--returns LHSprite with name (displayObject)
	
	for i = 1, selfBatch.numChildren do

		local node = selfBatch[i]
			
		if(nil ~= node and node.lhNodeType ~= nil)then	
			if(node.lhNodeType == "LHSprite")then
				if(node.lhUniqueName ~= nil)then
					if(node.lhUniqueName == name)then
						return node;
					end
				end
			end
		end
	end
	
	return nil;
end
--------------------------------------------------------------------------------
function batch_allSprites(selfBatch)--returns array with LHSprite objects

	--we only have to put the sprites from self to a table
	local spritesTable = {}
	for i = 1, selfBatch.numChildren do
		spritesTable[#spritesTable+1] = selfBatch[i];
	end

	return spritesTable
end
--------------------------------------------------------------------------------
function batch_spritesWithTag(selfBatch, tag) --returns array with LHSprite objects with tag
	local spritesTable = {}
	for i = 1, selfBatch.numChildren do
		local spr = selfBatch[i];
		
		if(spr.lhTag and spr.lhTag == tag)then
			spritesTable[#spritesTable+1] = spr;
		end
	end

	return spritesTable
end
--------------------------------------------------------------------------------
return LHBatch;
