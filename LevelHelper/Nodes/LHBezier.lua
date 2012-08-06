require "LevelHelper.Helpers.LHHelpers"
require "LevelHelper.Nodes.LHSettings"
--------------------------------------------------------------------------------
--forward declaration of local functions
local initTileVerticesFromDictionary;
local constructPathPoints;
local pointOnCurve;
local createRenderVerticesFromDictionary;
local constructPhysicObjectFromDictionary;

local LHBezier = {}
function LHBezier.bezierWithDictionary(selfBezier, fullProperties) --returns a display object

	local bezierObj = display.newGroup();

	local properties = fullProperties:dictForKey("TextureProperties");
	
	bezierObj.lhIsClosed 	= properties:boolForKey("IsClosed")
	bezierObj.lhUniqueName 	= properties:stringForKey("UniqueName")
	bezierObj.lhIsTile 		= properties:boolForKey("IsTile")
	bezierObj.lhIsLine 		= properties:boolForKey("IsSimpleLine")
	bezierObj.isVisible 	= properties:boolForKey("IsDrawable")
	bezierObj.lhIsPath 		= properties:boolForKey("IsPath")
	bezierObj.lhPathPoints 	= {};
	bezierObj.lhTag 		= properties:intForKey("Tag")
	bezierObj.lhColor 		= properties:rectForKey("Color")
	bezierObj.lhLineWidth 	= properties:floatForKey("LineWidth")
	bezierObj.lhLineColor 	= properties:rectForKey("LineColor")
	bezierObj.lhZOrder 		= properties:intForKey("ZOrder");
	bezierObj.lhNodeType 	= "LHBezier"
		
	createRenderVerticesFromDictionary(bezierObj, properties)
	constructPathPoints(bezierObj, properties)	
	constructPhysicObjectFromDictionary(bezierObj, fullProperties)
	
	--overloaded functions
	----------------------------------------------------------------------------
	bezierObj.originalCoronaRemoveSelf 	= bezierObj.removeSelf;
	bezierObj.removeSelf 				= bezier_removeSelf;

	return bezierObj; --displayObject of corona
end
--------------------------------------------------------------------------------
function bezier_removeSelf(selfBezier)
	--print("calling LHBezier removeSelf " .. selfBezier.lhUniqueName .. " parent " .. selfBezier.parent.lhUniqueName);
	--remove all properties of this sprite here
	selfBezier.lhIsClosed 	= nil
	selfBezier.lhUniqueName = nil
	selfBezier.lhIsTile 	= nil
	selfBezier.lhIsLine 	= nil
	selfBezier.lhIsPath 	= nil	
	for i = 1, # selfBezier.lhPathPoints do
		selfBezier.lhPathPoints[i].x = nil
		selfBezier.lhPathPoints[i].y = nil
	end
	selfBezier.lhPathPoints = nil
	selfBezier.lhTag 		= nil
	selfBezier.lhColor 		= nil
	selfBezier.lhLineWidth 	= nil
	selfBezier.lhLineColor 	= nil
	selfBezier.lhZOrder 	= nil
	selfBezier.lhNodeType 	= nil

	selfBezier:originalCoronaRemoveSelf();
	selfBezier = nil;
end
--------------------------------------------------------------------------------
pointOnCurve = function(p1, p2, p3, p4, t)
	local var1
	local var2
	local var3
    local vPoint = {x = 0.0, y = 0.0}
    
    var1 = 1 - t
    var2 = var1 * var1 * var1
    var3 = t * t * t
    vPoint.x = var2*p1.x + 3*t*var1*var1*p2.x + 3*t*t*var1*p3.x + var3*p4.x
    vPoint.y = var2*p1.y + 3*t*var1*var1*p2.y + 3*t*t*var1*p3.y + var3*p4.y

	return vPoint;
end
--------------------------------------------------------------------------------
constructPathPoints = function(bezierObj, bezierDict)

	if false == bezierObj.lhIsPath then
		return
	end

	local convert = {x = 1.0, y = 1.0};

	local curves = bezierDict:arrayForKey("Curves")
	local MAX_STEPS = 25;

	for i= 1, curves:count() do
		
		local curve = curves:dictAtIndex(i)
    	local endCtrlPt   = curve:pointForKey("EndControlPoint")
        local startCtrlPt = curve:pointForKey("StartControlPoint")
        local endPt       = curve:pointForKey("EndPoint")
        local startPt     = curve:pointForKey("StartPoint")

  		if false == bezierObj.lhIsLine then
            local t = 0.0
            while ( t >= 0.0 and  t <= 1 + (1.0 / MAX_STEPS) ) do
            	local vPoint = pointOnCurve(startPt, startCtrlPt, endCtrlPt, endPt, t)
				            
				bezierObj.lhPathPoints[#bezierObj.lhPathPoints+1] = {	x = vPoint.x*convert.x, 
																		y = vPoint.y*convert.y}
                        
        		t = t + 1.0 / MAX_STEPS
            end
            
			table.remove(bezierObj.lhPathPoints,#bezierObj.lhPathPoints)
  		else

			bezierObj.lhPathPoints[#bezierObj.lhPathPoints+1] = { 	x = startPt.x*convert.x,
																	y = startPt.y*convert.y}
			if(i == curves:count())then
				bezierObj.lhPathPoints[#bezierObj.lhPathPoints+1] = { 	x = endPt.x*convert.x, 
																		y = endPt.y*convert.y}
			end
  		end					 	
	end
end
--------------------------------------------------------------------------------
createLineShape = function(bezierObj, pt1, pt2, color)
 local line = display.newLine(pt1.x, pt1.y, pt2.x, pt2.y)
 bezierObj:insert(line)
 line.width = bezierObj.lhLineWidth
 line:setColor(color.origin.x*255, color.origin.y*255, color.size.width*255, 255)           
end
--------------------------------------------------------------------------------
createRenderVerticesFromDictionary = function(bezierObj, bezierDict)
	 
	local convert = {x = 1.0, y = 1.0};
	--local winSize = {width = 320, height = 480};	

	if true == bezierObj.isVisible then
	
		local curves = bezierDict:arrayForKey("Curves")	
		local MAX_STEPS = 25;

		for i= 1, curves:count() do
			local currentCurve = curves[i];

			local curve = curves:dictAtIndex(i)
    		local endCtrlPt   = curve:pointForKey("EndControlPoint")
        	local startCtrlPt = curve:pointForKey("StartControlPoint")
	        local endPt       = curve:pointForKey("EndPoint")
    	    local startPt     = curve:pointForKey("StartPoint")

			if( false == bezierObj.lhIsLine) then
			
				local prevPoint = {};
				local firstPt = true;
				
					
		        local t = 0.0
        	    while ( t >= 0.0 and  t <= 1 + (1.0 / MAX_STEPS) ) do
            		
            		local vPoint = pointOnCurve(startPt, startCtrlPt, 
            									endCtrlPt, endPt, t)

					if(false == firstPt)then
					
						local point1 = {x = prevPoint.x*convert.x, 
										y = prevPoint.y*convert.y};
						local point2 = {x = vPoint.x*convert.x,
										y = vPoint.y*convert.y};
					
						createLineShape(bezierObj, point1, point2, bezierObj.lhLineColor);
					end
					prevPoint = vPoint
					firstPt = false;

        			t = t + 1.0 / MAX_STEPS
            	end
			else
			
				local pos1 = {x = startPt.x*convert.x,
							  y = startPt.y*convert.y};
				local pos2 = {x = endPt.x*convert.x,
							  y = endPt.y*convert.y};
							  
				createLineShape(bezierObj, pos1, pos2, bezierObj.lhLineColor);
								
			end
  		end
	end
	
	 --THIS DOES NOT MET THE QUALLITY NEEDED TO BE MADE PUBLIC 
	 --CORONA IS MISSING SUCH A NICE AND USEFUL FEATURE
--	local fixtures = bezierDict["TileVertices"];
--	if(nil ~= fixtures) then
--		for i = 1, #fixtures do
--    	    local triangle = fixtures[i];
--        
--       	 local shapeTriangle = {}
--			for j = 1, #triangle do	
--				local pointString = triangle[j];
--				local point	= lh_pointFromString(pointString)	
--			
--				shapeTriangle[#shapeTriangle+1] = point;
--			end
--		
--			self:createShape(shapeTriangle, self.color)
--    	end
--    end
end
--------------------------------------------------------------------------------
constructPhysicObjectFromDictionary= function(bezierObj, bezierDict)

	local physics = require("physics")	
	if(nil == physics)then
		return
	end

--	if(bezierObj.lhIsTile)then
--		return
--	end

	local propDict = bezierDict:dictForKey("TextureProperties");
	local physicsDict = bezierDict:dictForKey("PhysicsProperties")	


	local ptype = physicsDict:intForKey("Type")
    if( 3 == ptype)then --no physics - dont create bodies
	    return
    end
	
	local convert = {x = 1.0, y = 1.0};
    
	local sdensity 		= physicsDict:floatForKey("Density");
	local sfriction 	= physicsDict:floatForKey("Friction");
	local srestitution 	= physicsDict:floatForKey("Restitution")
		
    local collisionFilter = { 	categoryBits = physicsDict:intForKey("Category"), 
								maskBits 	 = physicsDict:intForKey("Mask"), 
								groupIndex 	 = physicsDict:intForKey("Group") } 

	local physicType = "static"
	if ptype == 1 then
		physicType = "kinematic"
	elseif ptype == 2 then
		physicType = "dynamic"
	end

	local finalBodyShape = {}
	local currentFixInfo;
	local currentShape = {}
		
	local tileVerts = physicsDict:objectForKey("TileVertices")
	if(tileVerts and tileVerts:arrayValue():count() > 0 )then
		local fixtures = physicsDict:arrayForKey("TileVertices");
		if(nil ~= fixtures) then
			
			for i = 1, fixtures:count() do
	    	
	    	    local triangle = fixtures:arrayAtIndex(i);
	        
				for j = 1, triangle:count() do	
				
					local point = triangle:pointAtIndex(j);
					currentShape[#currentShape+1] = point.x
					currentShape[#currentShape+1] = point.y
		
				end
				
				triangle = nil;
			
				currentFixInfo = { density = sdensity,
								   friction = sfriction,
								   bounce = srestitution,
								   shape = lh_deepcopy(currentShape),
								   filter = scollisionFilter
									 }
				currentShape = nil
				currentShape = {}
				currentShapeRevised = nil
				currentShapeRevised = {}
				finalBodyShape[#finalBodyShape+1] = currentFixInfo;
			end
			
			physics.addBody(bezierObj, 
						 	physicType,
							unpack(finalBodyShape))
						 
			bezierObj.isFixedRotation = physicsDict:boolForKey("FixedRot")
			bezierObj.isSensor = physicsDict:boolForKey("IsSensor");
	    	return
	    end
   	end
    	
	local curves = propDict:arrayForKey("Curves")
	local MAX_STEPS = 25;

	local finalBodyShape = {}
	local currentFixInfo;
	local currentShape = {}
	
	for i= 1, curves:count() do
		
		local curve = curves:dictAtIndex(i)
    	local endCtrlPt   = curve:pointForKey("EndControlPoint")
    	local startCtrlPt = curve:pointForKey("StartControlPoint")
        local endPt       = curve:pointForKey("EndPoint")
        local startPt     = curve:pointForKey("StartPoint")
  
  		if false == bezierObj.lhIsLine then
	  		
  			local prevPoint
            local firstPt = true
            
            local t = 0.0
            while ( t >= 0.0 and  t <= 1 + (1.0 / MAX_STEPS) ) do
            	local vPoint = pointOnCurve(startPt, startCtrlPt, endCtrlPt, endPt, t)
				            
                if false == firstPt then

  					currentShape[#currentShape+1] = prevPoint.x*convert.x
		 			currentShape[#currentShape+1] = prevPoint.y*convert.y
		 			currentShape[#currentShape+1] = vPoint.x*convert.x
		 			currentShape[#currentShape+1] = vPoint.y*convert.y
		 					 			
						   
				   currentFixInfo = {density 	= sdensity,
									 friction 	= sfriction,
									 bounce 	= srestitution,
									 shape 		= lh_deepcopy(currentShape),
									 filter 	= collisionFilter }
						  			   
					finalBodyShape[#finalBodyShape+1] = currentFixInfo;
					
					currentShape = nil;
					currentShape = {}
					currentFixInfo = nil
	
                end
                
                prevPoint = vPoint;
                firstPt = false;
        
        		t = t + 1.0 / MAX_STEPS
            end
            

  		else
  		
  			currentShape[#currentShape+1] = startPt.x*convert.x
			currentShape[#currentShape+1] = startPt.y*convert.y
		 	currentShape[#currentShape+1] = endPt.x*convert.x
			currentShape[#currentShape+1] = endPt.y*convert.y
		 					 			
						   
		   currentFixInfo = {  density 	= sdensity,
							   friction = sfriction,
							   bounce 	= srestitution,
							   shape 	= lh_deepcopy(currentShape),
							   filter 	= collisionFilter }
						  			   
			finalBodyShape[#finalBodyShape+1] = currentFixInfo;
					
			currentShape = nil;
			currentShape = {}
			currentFixInfo = nil
  		end					 	
	end
	
	physics.addBody( bezierObj, 
					 physicType,
					 unpack(finalBodyShape))
					 
	bezierObj.isFixedRotation = physicsDict:boolForKey("FixedRot")
	bezierObj.isSensor = physicsDict:boolForKey("IsSensor")
	
end
--------------------------------------------------------------------------------
return LHBezier;

