
require "LevelHelper.Helpers.LHObject"
require "LevelHelper.Helpers.LHHelpers"


LHDictionary = {}
--------------------------------------------------------------------------------
function LHDictionary:initWithContentOfFile(lvlFile, curLine) --curLine might be nil

local object = {objects = {} }-- contains LHObject objects

	setmetatable(object, { __index = LHDictionary })  -- Inheritance		
			
	if(curLine)then
		return object:readContentOfFile(lvlFile);
	else
		for line in lvlFile:lines() do
			if (nil ~= string.find(line, "<dict>"))then
				return object:readContentOfFile(lvlFile);
			end
		end
	end
	return object;
end
--------------------------------------------------------------------------------
function LHDictionary:readContentOfFile(lvlFile)
    
	assert(lvlFile,"Table in LHDictionary is nil");
		
	local lastKey = "";
	for line in lvlFile:lines() do
		if (nil ~= string.find(line, "<key>"))then
                lastKey = lh_valueForField(line);                    
        elseif (nil ~= string.find(line, "<string>"))then
        	self:setObjectForKey(	LHObject:init(lh_valueForField(line), LH_OBJECT_TYPE.STRING_TYPE), 
                					   	lastKey);
        elseif (nil ~= string.find(line, "<real>"))then
        	self:setObjectForKey(	LHObject:init(lh_numberValue(lh_valueForField(line)), LH_OBJECT_TYPE.FLOAT_TYPE), 
                						lastKey);
        elseif (nil ~= string.find(line, "<integer>"))then
	   		self:setObjectForKey(	LHObject:init(lh_valueForField(line), LH_OBJECT_TYPE.INT_TYPE), 
                						lastKey);
        elseif (nil ~= string.find(line, "<true/>"))then
            self:setObjectForKey(	LHObject:init(true, LH_OBJECT_TYPE.BOOL_TYPE), 
                						lastKey);
        elseif (nil ~= string.find(line, "<false/>"))then
            self:setObjectForKey(	LHObject:init(false, LH_OBJECT_TYPE.BOOL_TYPE), 
                						lastKey);
        elseif (nil ~= string.find(line, "<dict>"))then
            self:setObjectForKey(LHObject:init(LHDictionary:initWithContentOfFile(lvlFile, line), LH_OBJECT_TYPE.LH_DICT_TYPE), 
                					   lastKey);
        elseif (nil ~= string.find(line, "</dict>"))then
	        return self;
        elseif (nil ~= string.find(line, "<dict/>"))then            
            self:setObjectForKey(LHObject:init(LHDictionary:emptyDictionary(), LH_OBJECT_TYPE.LH_DICT_TYPE), 
            					  lastKey);
        elseif (nil ~= string.find(line, "<array>"))then
         	local arrayObj = LHObject:init(LHArray:initWithContentOfFile(lvlFile, line),LH_OBJECT_TYPE.LH_ARRAY_TYPE);
             self:setObjectForKey(arrayObj, lastKey);
        elseif (nil ~= string.find(line, "</array>"))then
        	print("ERROR: End of array cannot be in a dictionary");
        elseif (nil ~= string.find(line, "<array/>"))then
            self:setObjectForKey(LHObject:init(LHArray:emptyArray(), LH_OBJECT_TYPE.LH_ARRAY_TYPE), 
            						lastKey);
        else
        	--unknown type
        end
	end
		
	return self
end
--------------------------------------------------------------------------------
function LHDictionary:removeSelf()
    self:removeAllObjects()
	self.objects = nil;	
	self = nil;
end
--------------------------------------------------------------------------------
function LHDictionary:setObjectForKey(obj, key)
    
    old_obj = self.objects[key];
    
    if(nil ~= old_obj)then
        old_obj:removeSelf();
    end
    
    if(nil ~= obj)then
        self.objects[key] = obj;
    end
    --print("D set object for KEY " .. key .. " - objType " .. tostring(obj.m_type) .. "\n");
end
--------------------------------------------------------------------------------
function LHDictionary:emptyDictionary()
	local object = {objects = {} }-- contains LHObject objects
	setmetatable(object, { __index = LHDictionary })  -- Inheritance		
	return object;
end
--------------------------------------------------------------------------------
function LHDictionary:initWithDictionary(otherDict)
	local object = nil;
	if(nil ~= otherDict)then    
		object = {objects = lh_deepcopy(otherDict.objects) }-- contains LHObject objects
	else
		object = {objects = {}}
	end
	
	setmetatable(object, { __index = LHDictionary })  -- Inheritance		
	return object
end
--------------------------------------------------------------------------------
function LHDictionary:tableWithKeysAndObjects()

	local dictTable = {};
	
	for k, v in pairs (self.objects) do		
		if v ~= nil then
		
			if(v.m_type == LH_OBJECT_TYPE.INT_TYPE)then
	        	dictTable[k] = v:intValue()
		    end

			if(v.m_type == LH_OBJECT_TYPE.FLOAT_TYPE)then
	        	dictTable[k] = v:floatValue()
		    end

			if(v.m_type == LH_OBJECT_TYPE.BOOL_TYPE)then
	        	dictTable[k] = v:boolValue()
		    end

			if(v.m_type == LH_OBJECT_TYPE.STRING_TYPE)then
	        	dictTable[k] = v:stringValue()
		    end
  
		end
	end		
	return dictTable;
end
--------------------------------------------------------------------------------
function LHDictionary:objectForKey(key)
    return self.objects[key];
end
--------------------------------------------------------------------------------
function LHDictionary:dictForKey(key)
   
    obj =  self:objectForKey(key)
    if(nil ~= obj)then
        return obj:dictValue();
    end
    
    return nil;
end
--------------------------------------------------------------------------------
function LHDictionary:arrayForKey(key)
    
    obj =  self.objects[key];
    if(nil ~= obj)then
	    if(obj.m_type ~= LH_OBJECT_TYPE.LH_ARRAY_TYPE)then
		    print("Object for key " .. key .. " is not an array");
    	end
        return obj:arrayValue();
    end  
    print("Array for key " .. key .. " is not available");
    return nil;    
end
--------------------------------------------------------------------------------
function LHDictionary:floatForKey(aKey)
	str = self:objectForKey(aKey);
    if(nil == str)then
        print("Float for key " .. aKey .. " is not available");
        return 0.0
    end
    return str:floatValue();

end
--------------------------------------------------------------------------------
function LHDictionary:intForKey(aKey)
	str = self:objectForKey(aKey);

    if(nil == str)then
        print("Int for key " .. aKey .. " is not available");
        return 0
    end
    return str:intValue();
end
--------------------------------------------------------------------------------
function LHDictionary:boolForKey(aKey)
	str = self:objectForKey(aKey);
    if(nil == str)then
        print("Bool for key " .. aKey .. " is not available");
        return false
    end
    return str:boolValue();
end
--------------------------------------------------------------------------------
function LHDictionary:pointForKey(aKey)
	str = self:objectForKey(aKey);

    if(nil == str)then
        print("Point for key " .. aKey .. " is not available");
        return {x = 0, y = 0};
    end
    
    return lh_pointFromString(str:stringValue());
end
--------------------------------------------------------------------------------
function LHDictionary:rectForKey(aKey)

	str = self:objectForKey(aKey);

    if(nil == str)then
        print("Rect for key " .. aKey .. " is not available");
        return {origin = {x = 0, y = 0}, size = {width = 0, height = 0}};
    end
    
    return lh_rectFromString(str:stringValue());
end
--------------------------------------------------------------------------------
function LHDictionary:sizeForKey(aKey)

	str = self:objectForKey(aKey);

    if(nil == str)then
        print("Size for key " .. aKey .. " is not available");
        return {width = 0, height = 0};
    end
    
    return lh_sizeFromString(str:stringValue());
end
function LHDictionary:isEmpty()
	
	local keys = self:allKeys();
	if #keys == 0 then
		return true
	end
	return false
end
--------------------------------------------------------------------------------
--(ccColor3B) colorForKey:(NSString*)key;
--------------------------------------------------------------------------------
function LHDictionary:stringForKey(aKey)
	str = self:objectForKey(aKey);

    if(nil == str)then
        print("String for key " .. aKey .. " is not available");
        return ""
    end
    return str:stringValue();
end
--------------------------------------------------------------------------------
function LHDictionary:removeObjectForKey(key)

   obj = self.objects[key];
    
   if(nil ~= obj)then
	   obj:removeSelf()
	   self.objects[key] = nil;
   end
end
--------------------------------------------------------------------------------
function LHDictionary:removeAllObjects()
    
   	for k, v in pairs (self.objects) do		
		if v ~= nil then
			v:removeSelf()
			v = nil
			self.objects[k] = nil;
		end
	end		
end
--------------------------------------------------------------------------------
function LHDictionary:allKeys()
	local keys = {};
	
	for k, v in pairs (self.objects) do		
		keys[#keys+1] = k;
	end	
	return keys;
end
--------------------------------------------------------------------------------
function LHDictionary:print()

--	print("DICTIONARY BEGIN PRINTING…....\n")
	--lhObject_growPrinterSpace()	
	for k, v in pairs (self.objects) do		
		if v ~= nil then
			--print(printerSpace .. " key is " ..tostring(k))
			v:printWithKey(k)
		end
	end	
	--lhObject_shrinkPrinterSpace()	
--	print("DICTIONARY END PRINTING...\n");
end
--------------------------------------------------------------------------------
