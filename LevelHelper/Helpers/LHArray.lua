
require "LevelHelper.Helpers.LHHelpers"
require "LevelHelper.Helpers.LHDictionary"
require "LevelHelper.Helpers.LHObject"

LHArray = {}
--------------------------------------------------------------------------------
function LHArray:initWithContentOfFile(lvlFile, curLine) --curLine might be nil
		
	local object = {objects = {} }-- contains LHObject objects
	
	setmetatable(object, { __index = LHArray })  -- Inheritance		
	
	if(curLine)then
		return object:readContentOfFile(lvlFile)
	else
		for line in lvlFile:lines() do
			if (nil ~= string.find(line, "<array>"))then
				return object:readContentOfFile(lvlFile)
			end
		end
	end
	return object
end
function LHArray:readContentOfFile(lvlFile)

	assert(lvlFile, "Table in LHArray is nil");	
    
	for line in lvlFile:lines() do	
		if (nil ~= string.find(line, "<string>"))then
	       self:addObject(LHObject:init(lh_valueForField(line),LH_OBJECT_TYPE.STRING_TYPE));
        elseif (nil ~= string.find(line, "<real>"))then
           self:addObject(LHObject:init(lh_numberValue(lh_valueForField(line)),LH_OBJECT_TYPE.FLOAT_TYPE));
        elseif (nil ~= string.find(line, "<integer>"))then
           self:addObject(LHObject:init(lh_numberValue(lh_valueForField(line)),LH_OBJECT_TYPE.INT_TYPE));
        elseif (nil ~= string.find(line, "<true/>"))then
           self:addObject(LHObject:init(true, LH_OBJECT_TYPE.BOOL_TYPE));
        elseif (nil ~= string.find(line, "<false/>"))then
           self:addObject(LHObject:init(false, LH_OBJECT_TYPE.BOOL_TYPE));
       	elseif (nil ~= string.find(line, "<dict>"))then
            self:addObject(LHObject:init(LHDictionary:initWithContentOfFile(lvlFile, line),LH_OBJECT_TYPE.LH_DICT_TYPE));            
        elseif (nil ~= string.find(line, "<dict/>"))then
            self:addObject(LHObject:init(LHDictionary:emptyDictionary(), LH_OBJECT_TYPE.LH_DICT_TYPE));
        elseif (nil ~= string.find(line, "<array>"))then
            self:addObject(LHObject:init(LHArray:initWithContentOfFile(lvlFile, line), LH_OBJECT_TYPE.LH_ARRAY_TYPE));
        elseif (nil ~= string.find(line, "</array>"))then		
			return self;
        elseif (nil ~= string.find(line, "<array/>"))then 
            self:addObject(LHObject:init(LHArray:emptyArray()), LH_OBJECT_TYPE.LH_ARRAY_TYPE);
        elseif (nil ~= string.find(line, "</dict>"))then
         	print("ERROR: Can't have end of dict in an array.")
        else
	        --not a knows object type
        end
	end
end
--------------------------------------------------------------------------------
function LHArray:emptyArray()
	local object = {objects = {} }-- contains LHObject objects
	setmetatable(object, { __index = LHArray })  -- Inheritance		
	return object;
end
--------------------------------------------------------------------------------
function LHArray:initWithArray(otherArray)
    
	local object = {objects = lh_deepcopy(otherArray.objects) }-- contains LHObject objects
	
	setmetatable(object, { __index = LHArray })  -- Inheritance		
	return object
end
--------------------------------------------------------------------------------
function LHArray:tableWithObjects()

	local dictTable = {};
	
	for i=1, #self.objects do
		
		local v = self.objects[i];
			
		if v ~= nil then
		
			if(v.m_type == LH_OBJECT_TYPE.INT_TYPE)then
	        	dictTable[#dictTable+1] = v:intValue()
		    end

			if(v.m_type == LH_OBJECT_TYPE.FLOAT_TYPE)then
	        	dictTable[#dictTable+1] = v:floatValue()
		    end

			if(v.m_type == LH_OBJECT_TYPE.BOOL_TYPE)then
	        	dictTable[#dictTable+1] = v:boolValue()
		    end

			if(v.m_type == LH_OBJECT_TYPE.STRING_TYPE)then
	        	dictTable[#dictTable+1] = v:stringValue()
		    end
  
		end
	end		
	return dictTable;
end
--------------------------------------------------------------------------------
function LHArray:insertObjectsInTable(tableObj)
	
	if(nil == tableObj)then
		return
	end
	
	for i=1, #self.objects do
		
		local v = self.objects[i];
			
		if v ~= nil then
		
			if(v.m_type == LH_OBJECT_TYPE.INT_TYPE)then
	        	tableObj[#tableObj+1] = v:intValue()
		    end

			if(v.m_type == LH_OBJECT_TYPE.FLOAT_TYPE)then
	        	tableObj[#tableObj+1] = v:floatValue()
		    end

			if(v.m_type == LH_OBJECT_TYPE.BOOL_TYPE)then
	        	tableObj[#tableObj+1] = v:boolValue()
		    end

			if(v.m_type == LH_OBJECT_TYPE.STRING_TYPE)then
	        	tableObj[#tableObj+1] = v:stringValue()
		    end
  
		end
	end		
end
--------------------------------------------------------------------------------
function LHArray:removeSelf()
    
   -- print("array remove self");
    for i=1, #self.objects do
		obj = self.objects[i];
		obj:removeSelf()
		obj = nil;
		self.objects[i] = nil;
	end
	
	self.objects = nil
	self = nil;
end
--------------------------------------------------------------------------------
function LHArray:addObject(obj)

	if(nil ~= obj)then
	
	--	print("adding object to array");
	--	obj:print()
		self.objects[#self.objects+1] = obj
	end
end
--------------------------------------------------------------------------------
function LHArray:objectAtIndex(idx)
	
	return self.objects[idx];
	
--	if(idx >= 1 and idx < #self.objects)then
--		return self.objects[idx];
--	end
--	return nil;
end
function LHArray:pointAtIndex(idx)

	str = self:objectAtIndex(idx);

    if(nil == str)then
        --print("Point for key " .. aKey .. " is not available");
        return {x = 0, y = 0};
    end
    return lh_pointFromString(str:stringValue());
end
--------------------------------------------------------------------------------
function LHArray:dictAtIndex(idx)
	
	obj = self.objects[idx];
	
	if(obj)then
		return obj:dictValue()
	end
--	if(idx >= 1 and idx < #self.objects)then
--		return self.objects[idx];
--	end
	return nil;
end
--------------------------------------------------------------------------------
function LHArray:arrayAtIndex(idx)
	
	obj = self.objects[idx];
	
	if(obj)then
		return obj:arrayValue()
	end
--	if(idx >= 1 and idx < #self.objects)then
--		return self.objects[idx];
--	end
	return nil;
end
--------------------------------------------------------------------------------
function LHArray:count()
	return #self.objects;
end    
--------------------------------------------------------------------------------
function LHArray:print()

--	print("ARRAY BEGIN PRINTING…....\n")

--	lhObject_growPrinterSpace()
	for i=1, #self.objects do
		obj = self.objects[i];
		obj:print()
	end
	
--	lhObject_shrinkPrinterSpace()
--	print("ARRAY END PRINTING...\n");
end
--------------------------------------------------------------------------------