
require "LevelHelper.Helpers.LHHelpers"
require "LevelHelper.Helpers.LHObject"
require "LevelHelper.Helpers.LHArray"
require "LevelHelper.Helpers.LHDictionary"

local lh_untitledLayersCount = 0;

local LHLayer = {}
function LHLayer.layerWithDictionary(selfLayer, dictionary)
	
	if (nil == dictionary) then
		print("Invalid LHLayer initialization! - dictionary is nil")
	end

	local object = display.newGroup();
				
	--add all LevelHelper valid properties to the object
	object.lhNodeType = "LHLayer";
	object.lhIsMainLayer = false;
	object.lhParentLoader= nil; -- just as a reminder that this property exist
		
	--add all LevelHelper valid methods to the object
	object.addLayerChildFromDictionary = addLayerChildFromDictionary;
	object.addChild = layer_addChild;
	object.uniqueName = layer_uniqueName;
	object.isMainLayer = layer_isMainLayer;
	object.originalCoronaRemoveSelf = object.removeSelf;
	object.removeSelf = layer_removeSelf;
	object.layerWithUniqueName = layer_layerWithUniqueName;
	object.batchWithUniqueName = layer_batchWithUniqueName;
	object.spriteWithUniqueName = layer_spriteWithUniqueName;
	object.bezierWithUniqueName = layer_bezierWithUniqueName;
	object.allLayers = layer_allLayers;
	object.allBatches= layer_allBatches;
	object.allSprites= layer_allSprites;
	object.allBeziers = layer_allBeziers;
	object.layersWithTag = layer_layersWithTag;
	object.batchesWithTag= layer_batchesWithTag;
	object.spritesWithTag= layer_spritesWithTag;
	object.beziersWithTag= layer_beziersWithTag;
				
	uName = dictionary:stringForKey("UniqueName");
    if(uName)then
       object.lhUniqueName = uName;
    else 
       object.lhUniqueName = "UntitledLayer_" .. lh_untitledLayersCount;
       lh_untitledLayersCount = lh_untitledLayersCount + 1;
	end
                
	object.lhZOrder = dictionary:intForKey("ZOrder")
      
    local childsInfo = dictionary:objectForKey("Children");
	if(childsInfo~=nil)then
		local childrenInfo = childsInfo:arrayValue();
		if(childrenInfo ~=nil)then
			for i=1,childrenInfo:count() do	
				local dict = childrenInfo:dictAtIndex(i);
				object:addLayerChildFromDictionary(dict);
			end
		end
	end
		
	return object
end
--------------------------------------------------------------------------------
function addLayerChildFromDictionary(selfLayer, childDict)

	if(nil == childDict)then
		return
	end
	
	nodeType = childDict:stringForKey("NodeType");
		
	if(nodeType == "LHBatch")then
		LHBatch = require("LevelHelper.Nodes.LHBatch");
	   	local batch = LHBatch:batchWithDictionary(childDict);
	   	selfLayer:addChild(batch, batch.lhZOrder);
	   	batch.lhParentLoader = selfLayer.lhParentLoader;
	   	
	elseif(nodeType == "LHSprite")then
		LHSprite = require("LevelHelper.Nodes.LHSprite");
		local spr = LHSprite:spriteWithDictionary(childDict);
		if(spr ~= nil)then
			selfLayer:addChild(spr, spr.lhZOrder);
			spr.lhParentLoader = selfLayer.lhParentLoader;		
		end
	elseif(nodeType == "LHBezier")then
		LHBezier = require("LevelHelper.Nodes.LHBezier");
		local bez = LHBezier:bezierWithDictionary(childDict);
		if(bez ~= nil)then
			selfLayer:addChild(bez, bez.lhZOrder)
			bez.lhParentLoader = selfLayer.lhParentLoader
		end
	elseif(nodeType == "LHLayer")then
		local newLayer = layerWithDictionary(childDict)
        selfLayer:addChild(newLayer, newLayer.lhZOrder);
        newLayer.lhParentLoader = selfLayer.lhParentLoader;
	end
	
	nodeType = nil
end
--------------------------------------------------------------------------------
--function LHLayer:addChild(object, zOrder)
function layer_addChild(selfLayer, object, zOrder)
	--currently we dont use zOrder
	selfLayer:insert(object)
end
--------------------------------------------------------------------------------
function layer_uniqueName(selfLayer)
	return selfLayer.lhUniqueName;
end
--------------------------------------------------------------------------------
function layer_isMainLayer(selfLayer)
	return selfLayer.lhIsMainLayer;
end
--------------------------------------------------------------------------------
function layer_removeSelf(selfLayer) --this will also remove all children

	--print("calling LHLayer remove self " .. selfLayer.lhUniqueName .. " children " .. tostring(selfLayer.numChildren));

	 --we use while because if we use for - when removing object we may lose some other objects that now have a lower index
	while(selfLayer.numChildren ~= 0) do
		local node = selfLayer[1]
		if(node)then
			node:removeSelf()
		end
		node = nil;
	end

	selfLayer:originalCoronaRemoveSelf();
	selfLayer = nil;
end
--------------------------------------------------------------------------------
function layer_layerWithUniqueName(selfLayer, name) --returns LHLayer with name, does not return self (group)

	for i = 1, selfLayer.numChildren do

		local node = selfLayer[i]
			
		if(nil ~= node and node.lhNodeType ~= nil)then	
			if(node.lhNodeType == "LHLayer")then
	
				if(node.lhUniqueName == name)then
					return node;		
				else
					local layer = node:layerWithUniqueName(name)
					if(layer ~= nil)then
						return layer;
					end
				end
			end			
		end
	end
	return nil;
end
--------------------------------------------------------------------------------
function layer_batchWithUniqueName(selfLayer, name)--returns LHBatch with name (group)
	for i = 1, selfLayer.numChildren do

		local node = selfLayer[i]
			
		if(nil ~= node and node.lhNodeType ~= nil)then	
			if(node.lhNodeType == "LHBatch")then
			
				if(node.lhUniqueName == name)then
					return node;		
				end
			
			elseif(node.lhNodeType == "LHLayer")then
			
				local child = node:batchWithUniqueName(name)
				if(child~= nil)then
					return child;
				end
			end
		end
	end
	
	return nil;
end
--------------------------------------------------------------------------------
function layer_spriteWithUniqueName(selfLayer, name)--returns LHSprite with name (displayObject)

	for i = 1, selfLayer.numChildren do

		local node = selfLayer[i]
			
		if(nil ~= node and node.lhNodeType ~= nil)then	
			if(node.lhNodeType == "LHSprite")then
				if(node.lhUniqueName == name)then
					return node;
				end
			elseif(node.lhNodeType == "LHBatch")then
				local child = node:spriteWithUniqueName(name)
				if(child)then
					return child;		
				end
			elseif(node.lhNodeType == "LHLayer")then
				local child = node:spriteWithUniqueName(name)
				if(child)then
					return child;
				end
			end
		end
	end
	
	return nil;
end
--------------------------------------------------------------------------------
function layer_bezierWithUniqueName(selfLayer, name)--returns LHBezier with name

	for i = 1, selfLayer.numChildren do
		local node = selfLayer[i]
		if(nil ~= node and node.lhNodeType ~= nil)then	
			if(node.lhNodeType == "LHBezier")then
				if(node.lhUniqueName == name)then
					return node;
				end
			elseif(node.lhNodeType == "LHLayer")then
				local child = node:bezierWithUniqueName(name)
				if(child)then
					return child;
				end
			end
		end
	end
	
	return nil;
end
--------------------------------------------------------------------------------
function layer_allLayers(selfLayer) --returns array with all LHLayer objects, does not return self
	--does not return self
	
	local tempTable = {}
	for i = 1, selfLayer.numChildren do
		local obj = selfLayer[i]
		
		if(obj and obj.lhNodeType and obj.lhNodeType == "LHLayer")then
			tempTable[#tempTable+1] = obj;
		end
	end
	
	return tempTable;
end
--------------------------------------------------------------------------------
function layer_allBatches(selfLayer) --returns array with LHBatch objects
	local tempTable = {}
	for i = 1, selfLayer.numChildren do
		local obj = selfLayer[i]
		
		if(obj and obj.lhNodeType and obj.lhNodeType == "LHBatch")then
			tempTable[#tempTable+1] = obj;
		end
	end
	
	return tempTable;
end
--------------------------------------------------------------------------------
function layer_allSprites(selfLayer)--returns array with LHSprite objects
	local tempTable = {}
	for i = 1, selfLayer.numChildren do
		local obj = selfLayer[i]
		
		if(obj and obj.lhNodeType and obj.lhNodeType == "LHSprite")then
			tempTable[#tempTable+1] = obj;
		end
		
		if(obj and obj.lhNodeType and obj.lhNodeType == "LHBatch")then
			local batchSprites = obj:allSprites()
			for j = 1, #batchSprites do
				tempTable[#tempTable+1] = batchSprites[j];				
			end
		end

		if(obj and obj.lhNodeType and obj.lhNodeType == "LHBayer")then
			local layerSprites = obj:allSprites()
			for j = 1, #layerSprites do
				tempTable[#tempTable+1] = layerSprites[j];				
			end
		end
	end
	
	return tempTable;
end
--------------------------------------------------------------------------------
function layer_allBeziers(selfLayer)--returns array with LHBezier objects
	local tempTable = {}
	for i = 1, selfLayer.numChildren do
		local obj = selfLayer[i]
		
		if(obj and obj.lhNodeType and obj.lhNodeType == "LHBezier")then
			tempTable[#tempTable+1] = obj;
		end
	end
	
	return tempTable;
end
--------------------------------------------------------------------------------
function layer_layersWithTag(selfLayer, tag) --returns array with LHLayer objects with tag, does not return self
	local tempTable = {}
	for i = 1, selfLayer.numChildren do
		local obj = selfLayer[i]
		
		if(obj and obj.lhNodeType and obj.lhNodeType == "LHLayer")then
			if(obj.lhTag and obj.lhTag == tag)then
				tempTable[#tempTable+1] = obj;
			end
		end
	end
	
	return tempTable;
end
--------------------------------------------------------------------------------
function layer_batchesWithTag(selfLayer, tag) --returns array with LHBatch objects with tag
	local tempTable = {}
	for i = 1, selfLayer.numChildren do
		local obj = selfLayer[i]
		
		if(obj and obj.lhNodeType and obj.lhNodeType == "LHBatch")then
			if(obj.lhTag and obj.lhTag == tag)then
				tempTable[#tempTable+1] = obj;
			end
		end
	end
	
	return tempTable;
end
--------------------------------------------------------------------------------
function layer_spritesWithTag(selfLayer, tag) --returns array with LHSprite objects with tag
	local tempTable = {}
	for i = 1, selfLayer.numChildren do
		local obj = selfLayer[i]
		
		if(obj and obj.lhNodeType and obj.lhNodeType == "LHBatch")then
			local otherTable = obj:spritesWithTag(tag);
			for j = 1, #otherTable do
				tempTable[#tempTable+1] = otherTable[j];
			end
		end
		
		if(obj and obj.lhNodeType and obj.lhNodeType == "LHSprite")then
			if(obj.lhTag and obj.lhTag == tag)then
				tempTable[#tempTable+1] = obj;
			end
		end

	end
	
	return tempTable;
end
--------------------------------------------------------------------------------
function layer_beziersWithTag(selfLayer, tag) --returns array with LHBezier objects with tag
	local tempTable = {}
	for i = 1, selfLayer.numChildren do
		local obj = selfLayer[i]
		
		if(obj and obj.lhNodeType and obj.lhNodeType == "LHBezier")then
			if(obj.lhTag and obj.lhTag == tag)then
				tempTable[#tempTable+1] = obj;
			end
		end
	end
	
	return tempTable;
end
--------------------------------------------------------------------------------
--LHLayer.layerWithDictionary = layerWithDictionary
return LHLayer;
