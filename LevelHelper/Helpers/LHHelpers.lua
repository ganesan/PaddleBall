--------------------------------------------------------------------------------
function lh_fileExists(name)

	local path = system.pathForFile(name, system.ResourceDirectory )
		
	if(path == nil)then
		return false;
	end

--while this imposes a limitation of a minimum image of 16x16 it is the only way 
--to make it work on android until ansca fixes system.pathForFile to give proper
--results on android
	local androidUglyTest = sprite.newSpriteSheet(name , 16,16 )	
	if(nil ~= androidUglyTest)then
		androidUglyTest:dispose()
		return true;
	end
	return false

--[[	
	local f=io.open(path,"r") --this does not work on android
   	if f~=nil then 
   		io.close(f) 
   		return true 
	end
  	return false
  	--]]
end
--------------------------------------------------------------------------------
function imageFileWithFolder(imageFile)

	local imgFile = imageFile
	if(application ~= nil)then
		if(application.LevelHelperSettings ~= nil)then
			if(application.LevelHelperSettings.imagesSubfolder ~= nil)then
				imgFile = application.LevelHelperSettings.imagesSubfolder .. "/" .. imageFile;
			end
		end
	end

	return imgFile;
end
--------------------------------------------------------------------------------
function lh_addToDirectorGroup(object)
	if(nil == object)then
		return
	end
	
	if(nil == application.LevelHelperSettings.directorGroup)then
		--print("Director group is nil")
	else
		--print("adding sprite to group")
		application.LevelHelperSettings.directorGroup:insert(object)
	end
end
--------------------------------------------------------------------------------
function lh_valueForField(field)

	local argument = nil

	local function computeArg(arg)
		argument = arg;
	end

	string.gsub(field, ">(.*)</", computeArg)					
	
	return argument;
end
--------------------------------------------------------------------------------
function lh_numberValue(arg)
	return tonumber(arg)
end
--------------------------------------------------------------------------------
function lh_pointFromString(str)

	local xStr = 0;
	local yStr = 0;
	local function pointHelper(a,b)
		xStr = tonumber(a)
		yStr = tonumber(b)
	end

	string.gsub(str, "{(.*), (.*)}", pointHelper) 
	return  { x = xStr, y = yStr}
end
--------------------------------------------------------------------------------
function lh_sizeFromString(str)

	local wStr = 0;
	local hStr = 0;
	
	local function sizeHelper(a, b)
		wStr = tonumber(a)
		hStr = tonumber(b)
	end
	local retinaRatio = 1; --should be added shortly in LHSettings
	
	string.gsub(str, "{(.*), (.*)}", sizeHelper) 
	return  { width = wStr/retinaRatio, height = hStr/retinaRatio}				
end
function lh_printSize(obj)

	print("{ size = { width: " .. tostring(obj.width) .. " height: " .. tostring(obj.height) .. " }}");
end

--------------------------------------------------------------------------------
function lh_rectFromString(str)

	local xStr = 0;
	local yStr = 0;
	local wStr = 0;
	local hStr = 0;

	local function rectHelper(a, b, c, d)
		xStr = tonumber(a)
		yStr = tonumber(b)
		wStr = tonumber(c)
		hStr= tonumber(d)
	end

	local retinaRatio = 1; --should be added shortly in LHSettings

	string.gsub(str, "{{(.*), (.*)}, {(.*), (.*)}}", rectHelper)
	return { origin = {x = xStr*retinaRatio, y = yStr*retinaRatio}, 
			   size = {width = wStr*retinaRatio, height = hStr*retinaRatio}}
end
function lh_printRect(rect)

	print("{ origin { x: " .. tostring(rect.origin.x) .. " y: " .. tostring(rect.origin.y) .. " } size = { width: " .. tostring(rect.size.width) .. " height: " .. tostring(rect.size.height) .. " }}");
end
--------------------------------------------------------------------------------
function lh_quadFromSize(width, height)

    local pos = { x = 0, y = 0 } 
	return { pos.x - width/2, 
			 pos.y + height/2,
			 
             pos.x - width/2,
             pos.y - height/2,
        
	         pos.x + width/2,
      		 pos.y - height/2,
             
             pos.x + width/2,
        	 pos.y + height/2}
end
--------------------------------------------------------------------------------
function lh_polygonPointsFromStrings(fixtures, scale, sdensity, sfriction, 
									 srestitution, scollisionFilter)
-- for CORONA points must be inverse so multiply y by -1 and then inverse the points order
	local finalBodyShape = {}
	local currentFixInfo;
	local currentShapeRevised = {}
	local currentShape = {}
	
	local retinaRatio = 1; --should be added shortly in LHSettings
	
	for i = 1, #fixtures do
		local currentFix = fixtures[i]
			
		for j = 1, #currentFix do
			local point = lh_pointFromString(currentFix[j])
			currentShape[#currentShape+1] = point.x
			currentShape[#currentShape+1] = point.y
		end
		
		currentFix = nil;
		
		for k = #currentShape,1,-2 do
			currentShape[k-1] = currentShape[k-1]*scale.width
			currentShape[k] = currentShape[k]*(-1)*scale.height
		end	

		for l = #currentShape,1,-2 do
			currentShapeRevised[#currentShapeRevised + 1] = currentShape[l-1]*retinaRatio;
			currentShapeRevised[#currentShapeRevised + 1] = currentShape[l]*retinaRatio;
		end	
		
		currentFixInfo = { density = sdensity,
						   friction = sfriction,
						   bounce = srestitution,
						   shape = lh_deepcopy(currentShapeRevised),
						   filter = scollisionFilter
								 }
		currentShape = nil
		currentShape = {}
		currentShapeRevised = nil
		currentShapeRevised = {}
		finalBodyShape[#finalBodyShape+1] = currentFixInfo;
	end


	return finalBodyShape
end
--------------------------------------------------------------------------------
function lh_splitString(pString, pPattern)
   local Table = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pPattern
   local last_end = 1
   local s, e, cap = pString:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
     table.insert(Table,cap)
      end
      last_end = e+1
      s, e, cap = pString:find(fpat, last_end)
   end
   if last_end <= #pString then
      cap = pString:sub(last_end)
      table.insert(Table, cap)
   end
   return Table
end
--------------------------------------------------------------------------------
function lh_deepcopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end
--------------------------------------------------------------------------------
function lh_toInt(value)
	if(value > 0)then
		return math.floor(value)
	else
		return math.ceil(value)
	end
	return 0;
end
--------------------------------------------------------------------------------
function lh_PointEqualToPoint(point1, point2)
	if(point1.x == point2.x and 
	  point1.y == point2.y)then
	  return true
	end
	
	return false
end
--------------------------------------------------------------------------------
function lh_Sub(v1, v2)
	return {x = v1.x - v2.x, y = v1.y - v2.y};
end
--------------------------------------------------------------------------------
function lh_Length(v)
	return math.sqrt(lh_LengthSQ(v));
end
--------------------------------------------------------------------------------
function lh_Distance(v1, v2)
	return lh_Length(lh_Sub(v1, v2));
end
--------------------------------------------------------------------------------
function lh_Dot(v1, v2)
	return v1.x*v2.x + v1.y*v2.y;
end
--------------------------------------------------------------------------------
function lh_LengthSQ(v)
	return lh_Dot(v, v);
end
--------------------------------------------------------------------------------