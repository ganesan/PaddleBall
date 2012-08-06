--require "LevelHelper.Helpers.LHHelpers"

LHFixture = {}
function LHFixture:fixtureWithDictionary(dictionary, coronaSprite, physics, completeBodyFixtures)

	local object = {lhFixtureName = dictionary:stringForKey("Name"),
					lhFixtureID = dictionary:intForKey("Tag"),
					coronaMinFixtureIdForThisObject = 1,
					coronaMaxFixtureIdForThisObject = 1,
					fixtureShape = {},
					}
	setmetatable(object, { __index = LHFixture })  -- Inheritance	
	
	
    local fcollisionFilter = { 	categoryBits = dictionary:intForKey("Category"),	
								maskBits 	 = dictionary:intForKey("Mask"), 
								groupIndex 	 = dictionary:intForKey("Group") } 

    local fdensity 		= dictionary:floatForKey("Density");
	local ffriction 	= dictionary:floatForKey("Friction");
	local frestitution	= dictionary:floatForKey("Restitution");
        
	local fisSensor 	= dictionary:boolForKey("IsSensor");
        
    local offset 	= dictionary:pointForKey("LHShapePositionOffset");
	
	local fixturePoints = dictionary:objectForKey("Fixture");
	if(nil ~= fixturePoints)then --fixture object may be missing - this way we dont get a warning
		fixturePoints = fixturePoints:arrayValue();
	end

	
	sprW = coronaSprite.width/2.0;
	sprH = coronaSprite.height/2.0;

	sprScaleX = coronaSprite.xScale;
	sprScaleY = coronaSprite.yScale;
	
	
	if(fixturePoints ~= nil and fixturePoints:count() > 0 and
	   fixturePoints:objectAtIndex(1).m_type == 5)then 
		
		for i=1,fixturePoints:count() do
		
			local fixInfo = fixturePoints:objectAtIndex(i);
			
			if(fixInfo.m_type ~= 5)then--array type
				 print("ERROR: Please update to SpriteHelper 1.8.1 and resave all your scenes. Body will be created without a shape.");
				 break;
			end
		
			fixInfo = fixInfo:arrayValue()
			local verts = {};
			local k = fixInfo:count();
			for j = 1, fixInfo:count()do
			
				local pt = lh_pointFromString(fixInfo:objectAtIndex(k):stringValue());
				
				pt.y = coronaSprite.height - pt.y;
				pt.y = pt.y - coronaSprite.height;
			
				verts[#verts+1] = pt.x*sprScaleX;
				verts[#verts+1] = pt.y*sprScaleY;		
				k = k -1		
			end
						
			currentFixInfo = { density 	= fdensity,
							   friction = ffriction,
							   bounce 	= frestitution,
							   isSensor = fisSensor,
							   shape 	= verts,
							   filter 	= fcollisionFilter
							 }
	
			object.fixtureShape[#object.fixtureShape+1] = currentFixInfo;
			completeBodyFixtures[#completeBodyFixtures+1] = object.fixtureShape[#object.fixtureShape];

		
		end
	else
		--we dont have points - it means we have circle or quad;
		if false == dictionary:boolForKey("IsCircle") then
			-- object is not circle
			local quad = lh_quadFromSize(dictionary:floatForKey("LHWidth")*sprScaleX, 
							   							  dictionary:floatForKey("LHHeight")*sprScaleY);
							   							  
			
			local offset = dictionary:pointForKey("LHShapePositionOffset");
			   
			quad[1] = quad[1] + offset.x*sprScaleX;
			quad[2] = quad[2] + offset.y*sprScaleY;

			quad[3] = quad[3] + offset.x*sprScaleX;
			quad[4] = quad[4] + offset.y*sprScaleY;

			quad[5] = quad[5] + offset.x*sprScaleX;
			quad[6] = quad[6] + offset.y*sprScaleY;

			quad[7] = quad[7] + offset.x*sprScaleX;
			quad[8] = quad[8] + offset.y*sprScaleY;

			currentFixInfo = { density 	= fdensity,
							   friction = ffriction,
							   bounce 	= frestitution,
							   isSensor = fisSensor,
							   shape 	= quad,
							   filter 	= fcollisionFilter
							 }
							 
			object.fixtureShape[#object.fixtureShape+1] = currentFixInfo;
			completeBodyFixtures[#completeBodyFixtures+1] = object.fixtureShape[#object.fixtureShape];
						
		else
			--object is circle
			--No way to offset a circle inside Corona - really bad that this feature is missing
			currentFixInfo = { density 	= fdensity,
							   friction = ffriction,
							   bounce 	= frestitution,
							   isSensor = fisSensor,
							   radius 	= dictionary:floatForKey("LHWidth")/2.0*sprScaleX,
							   filter 	= fcollisionFilter
							 }
							 
			object.fixtureShape[#object.fixtureShape+1] = currentFixInfo;
			completeBodyFixtures[#completeBodyFixtures+1] = object.fixtureShape[#object.fixtureShape];
		end		
	end

	return object
end
--------------------------------------------------------------------------------
function LHFixture:removeSelf()

	--print("LHFixture removeSelf");

	self.coronaMinFixtureIdForThisObject = nil
 	self.coronaMaxFixtureIdForThisObject = nil
	self.lhFixtureName = nil;
	self.lhFixtureID = nil;
	self.fixtureShape = nil;
	self = nil
end
