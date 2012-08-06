
LH_OBJECT_TYPE =
{ 
	INT_TYPE    = 0,
	FLOAT_TYPE  = 1,
    BOOL_TYPE   = 2,
    STRING_TYPE = 3,
	LH_DICT_TYPE = 4,
    LH_ARRAY_TYPE = 5,
	LH_VOID_TYPE = 6
}
local printerSpace = ""
--------------------------------------------------------------------------------
LHObject = {}
function LHObject:init(obj, typeOfObj)
    
	local object = {m_object = obj,
					m_type = typeOfObj
					}
	setmetatable(object, { __index = LHObject })  -- Inheritance		
	return object
end
--------------------------------------------------------------------------------
--[[
LHObject::LHObject(const int& obj){ ++numberOfObjects; m_object = new int(obj); m_type = INT_TYPE;}
LHObject::LHObject(const float& obj){ ++numberOfObjects; m_object = new float(obj); m_type = FLOAT_TYPE;}
LHObject::LHObject(const bool& obj){ ++numberOfObjects; m_object = new bool(obj); m_type = BOOL_TYPE;}
LHObject::LHObject(const std::string& obj){ ++numberOfObjects; m_object = new std::string(obj); m_type = STRING_TYPE;}
LHObject::LHObject(LHDictionary* obj){ ++numberOfObjects; m_object = obj; m_type = LH_DICT_TYPE;}
LHObject::LHObject(LHArray* obj){ ++numberOfObjects; m_object = obj; m_type = LH_ARRAY_TYPE;}
LHObject::LHObject(void* obj){ ++numberOfObjects; m_object = obj; m_type = LH_VOID_TYPE;}
--]]
--------------------------------------------------------------------------------
function LHObject:initWithObject(obj)
    
	local object = {m_object = obj.m_object,
					m_type = obj.m_type
					}
	setmetatable(object, { __index = LHObject })  -- Inheritance		
	return object
end
--------------------------------------------------------------------------------
function LHObject:dictValue()

	if(self.m_type ~= LH_OBJECT_TYPE.LH_DICT_TYPE)then
        print("ERROR! Object is not a dictionary. It is a " .. tostring(self.m_type));
    end
    return self.m_object;
end
--------------------------------------------------------------------------------
function LHObject:arrayValue()

	if(self.m_type ~= LH_OBJECT_TYPE.LH_ARRAY_TYPE)then
        print("ERROR! Object is not a array. It is a " .. tostring(self.m_type));
    end
    return self.m_object;
end
--------------------------------------------------------------------------------
function LHObject:stringValue()

	if(self.m_type ~= LH_OBJECT_TYPE.STRING_TYPE)then
        print("ERROR! Object is not a string. It is a " .. tostring(self.m_type));
    end
    return self.m_object;
end
--------------------------------------------------------------------------------
function LHObject:floatValue()

	if(self.m_type ~= LH_OBJECT_TYPE.FLOAT_TYPE)then
        print("ERROR! Object is not a float. It is a " .. tostring(self.m_type));
    end
    return tonumber(self.m_object);
end
--------------------------------------------------------------------------------
function LHObject:intValue()

	--if(self.m_type ~= LH_OBJECT_TYPE.INT_TYPE)then
    --    print("ERROR! Object is not a int. It is a " .. tostring(self.m_type));
    --end
    
    return tonumber(self.m_object);
end
--------------------------------------------------------------------------------
function LHObject:boolValue()

	if(self.m_type ~= LH_OBJECT_TYPE.BOOL_TYPE)then
        print("ERROR! Object is not a bool. It is a " .. tostring(self.m_type));
    end
    return self.m_object;
end
--------------------------------------------------------------------------------
function LHObject:voidValue()

	if(self.m_type ~= LH_OBJECT_TYPE.LH_VOID_TYPE)then
        print("ERROR! Object is not a void. It is a " .. tostring(self.m_type));
    end
    return self.m_object;
end
--------------------------------------------------------------------------------
function LHObject:removeSelf()

	--print("object removeSelf");
	if(self.m_type == LH_OBJECT_TYPE.LH_DICT_TYPE or
	   self.m_type == LH_OBJECT_TYPE.LH_ARRAY_TYPE)then

		self.m_object:removeSelf(); 

	 end

	self.m_object = nil;
	self.m_type = nil;
	self = nil;
end
--------------------------------------------------------------------------------
function LHObject:print()

	if(self.m_type ~= LH_OBJECT_TYPE.LH_ARRAY_TYPE and
	   self.m_type ~= LH_OBJECT_TYPE.LH_DICT_TYPE and
	   self.m_type ~= LH_OBJECT_TYPE.LH_VOID_TYPE) then
   		if(self.m_type == LH_OBJECT_TYPE.INT_TYPE or
		   self.m_type == LH_OBJECT_TYPE.FLOAT_TYPE)then
		   print(printerSpace .. "<real>" .. tostring(self.m_object) .. "</real>")			
		elseif(self.m_type == LH_OBJECT_TYPE.BOOL_TYPE)then
			print(printerSpace .. "<bool>" .. tostring(self.m_object) .. "</bool>")			
		elseif(self.m_type == LH_OBJECT_TYPE.STRING_TYPE)then
			print(printerSpace .. "<string>" .. tostring(self.m_object) .. "</string>")			
		else
			print(printerSpace .. "<unknown>" .. tostring(self.m_object) .. "</unknown>")
		end
	else
		self:printComplexObject()
	end
end
--------------------------------------------------------------------------------
function LHObject:printWithKey(k)
	if(self.m_type ~= LH_OBJECT_TYPE.LH_ARRAY_TYPE and
	   self.m_type ~= LH_OBJECT_TYPE.LH_DICT_TYPE and
	   self.m_type ~= LH_OBJECT_TYPE.LH_VOID_TYPE) then
	   	print(printerSpace .. "<key>" .. tostring(k) .. "</key>")
	   	self:print()
	else
		print(printerSpace .. "<key>" .. tostring(k) .. "</key>")
		self:printComplexObject()
	end
end
function LHObject:printComplexObject()
	
	if(self.m_type == LH_OBJECT_TYPE.LH_ARRAY_TYPE)then
		print(printerSpace .. "<array>")
	elseif(self.m_type == LH_OBJECT_TYPE.LH_DICT_TYPE)then
		print(printerSpace .. "<dict>")
	else
		print(printerSpace .. "<void>")
	end
	self:growPrinterSpace()
	self.m_object:print();
	self:shrinkPrinterSpace();
	if(self.m_type == LH_OBJECT_TYPE.LH_ARRAY_TYPE)then
		print(printerSpace .. "</array>")
	elseif(self.m_type == LH_OBJECT_TYPE.LH_DICT_TYPE)then
		print(printerSpace .. "</dict>")
	else
		print(printerSpace .. "</void>")
	end
end
--------------------------------------------------------------------------------
function LHObject:growPrinterSpace()
	printerSpace = printerSpace .. "   ";
end
--------------------------------------------------------------------------------
function LHObject:shrinkPrinterSpace()
	printerSpace = string.sub(printerSpace, 1, -2)
	printerSpace = string.sub(printerSpace, 1, -2) 
	printerSpace = string.sub(printerSpace, 1, -2) 
end
--------------------------------------------------------------------------------