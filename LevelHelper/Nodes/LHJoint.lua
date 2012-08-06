
LHJoint = {}
function LHJoint:jointWithDictionary(jointDict, parentLoader)

	if(nil == jointDict)then
		print("ERROR: joint info dictionary is nil");
		return nil;
	end

	local object = {coronaJoint = nil,
					lhParentLoader = parentLoader,
					lhUniqueName = jointDict:stringForKey("UniqueName"),
					lhTag = jointDict:intForKey("Tag"),
					lhSpriteA = nil,
					lhSpriteB = nil,
					lhJointType = "distance"
					}

	setmetatable(object, { __index = LHJoint })  -- Inheritance	
			
	object:createJointFromDictionary(jointDict)
		
	if(object.coronaJoint~=nil)then
		if(object.lhSpriteA ~= nil)then
			object.lhSpriteA.lhAttachedJoint[#object.lhSpriteA.lhAttachedJoint+1] = object;
		end
	
		if(object.lhSpriteB ~= nil)then
			object.lhSpriteB.lhAttachedJoint[#object.lhSpriteB.lhAttachedJoint+1] = object;
		end
	end			
		
	return object
end
--------------------------------------------------------------------------------
function LHJoint:removeSelf()
	
	--print("LHJoint removeSelf");
	
	if(self.lhParentLoader ~= nil)then
		for i = 1, #self.lhParentLoader.loadedJoints do
			if(self.lhParentLoader.loadedJoints[i] == self)then
				self.lhParentLoader.loadedJoints[i] = nil;
			end
		end
	end
		
	self.lhParentLoader = nil;
	self.lhUniqueName = nil;
	self.lhTag = nil;
	
	if(self.lhSpriteA ~= nil)then
		for i = 1, #self.lhSpriteA.lhAttachedJoint do
			if(self.lhSpriteA.lhAttachedJoint[i] == self)then
				self.lhSpriteA.lhAttachedJoint[i] = nil
			end
		end
	end

	if(self.lhSpriteB ~= nil)then
		for i = 1, #self.lhSpriteB.lhAttachedJoint do
			if(self.lhSpriteB.lhAttachedJoint[i] == self)then
				self.lhSpriteB.lhAttachedJoint[i] = nil
			end
		end
	end
	
	self.lhSpriteA = nil;
	self.lhSpriteB = nil;
	self.lhJointType = nil;
	self.coronaJoint:removeSelf();
	self.coronaJoint = nil
	self = nil
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function LHJoint:createJointFromDictionary(jointInfo)

	local physics = require("physics")	
	if(nil == physics)then
		return nil;
	end
	
	if(nil == self.lhParentLoader)then
		return nil;
	end

	local objA = self.lhParentLoader:spriteWithUniqueName(jointInfo:stringForKey("ObjectA"));
	local objB = self.lhParentLoader:spriteWithUniqueName(jointInfo:stringForKey("ObjectB"));
	
	if objA == nil or objB == nil then
		return nil
	end
		
	if objA == objB then
		print("ERROR: ObjectA equal ObjectB in joint creation - Box2D will assert.")
		return nil
	end
	
	self.lhSpriteA = objA;
	self.lhSpriteB = objB;
	
	local anchorA = jointInfo:pointForKey("AnchorA");
	local anchorB = jointInfo:pointForKey("AnchorB");
	
	anchorA.x = anchorA.x*objA.lhScaleWidth;
	anchorA.y = anchorA.y*objA.lhScaleHeight;
		
	anchorB.x = anchorB.x*objB.lhScaleWidth;
	anchorB.y = anchorB.y*objB.lhScaleHeight;
	
	if true == jointInfo:boolForKey("CenterOfMass") then
		anchorA.x = 0
		anchorB.x = 0
		anchorA.y = 0
		anchorB.y = 0
	end
	
	if jointInfo:intForKey("Type") == 0 then -- distance joint	

		self.coronaJoint = physics.newJoint( "distance", 
										objA, 
										objB, 
										objA.x +anchorA.x,
										objA.y +anchorA.y,
										objB.x +anchorB.x,
										objB.y +anchorB.y)
		self.coronaJoint.frequency = jointInfo["Frequency"]
		self.coronaJoint.dampingRatio = jointInfo["Damping"]
		self.lhJointType = "distance";
		
	elseif jointInfo:intForKey("Type") == 1 then -- revolute joint
			
		self.coronaJoint = physics.newJoint( "pivot", objA, objB, objA.x +anchorA.x, objA.y +anchorA.y)
		
		self.coronaJoint.isMotorEnabled = jointInfo:boolForKey("EnableMotor")
		self.coronaJoint.motorSpeed = (-1)*jointInfo:floatForKey("MotorSpeed") --for CORONA we inverse to be the same as 
														--as the other engines from left to right
		self.coronaJoint.maxMotorTorque = jointInfo:floatForKey("MaxTorque")
		
		self.coronaJoint.isLimitEnabled = jointInfo:boolForKey("EnableLimit")
		self.coronaJoint:setRotationLimits( jointInfo:floatForKey("LowerAngle"), jointInfo:floatForKey("UpperAngle") )
		self.lhJointType = "pivot";

	elseif jointInfo:intForKey("Type") == 2 then -- prismatic joint

		local axis = jointInfo:pointForKey("Axis");
		self.coronaJoint = physics.newJoint( "piston", objA, objB, 
									objA.x +anchorA.x, objA.y +anchorA.y,
									axis.x,axis.y )
	
		self.coronaJoint.isMotorEnabled = jointInfo:boolForKey("EnableMotor")
		self.coronaJoint.motorSpeed = (-1)*jointInfo:floatForKey("MotorSpeed") --for CORONA we inverse to be the same as 
														--as the other engines from left to right
		self.coronaJoint.maxMotorForce = jointInfo:floatForKey("MaxMotorForce")
		self.coronaJoint.isLimitEnabled = jointInfo:boolForKey("EnableLimit")
		self.coronaJoint:setLimits( jointInfo:floatForKey("LowerTranslation")/2, jointInfo:floatForKey("UpperTranslation")/2 )
		self.lhJointType = "piston";

	elseif jointInfo:intForKey("Type") == 3 then -- pulley joint
	
		local groundAnchorA = jointInfo:pointForKey("GroundAnchorRelativeA");
		local groundAnchorB = jointInfo:pointForKey("GroundAnchorRelativeB");
	
		self.coronaJoint = physics.newJoint( "pulley", objA, objB, 
											objA.x + groundAnchorA.x, objA.y + groundAnchorA.y, 
											objB.x + groundAnchorB.x, objB.y + groundAnchorB.y, 
											objA.x + anchorA.x,objA.y + anchorA.y, 
											objB.x + anchorB.x,objB.y + anchorB.y, 
										jointInfo["Ratio"] )
		self.lhJointType = "pulley";
		
	elseif jointInfo:intForKey("Type") == 4 then -- gear joint										
		print("Corona SDK currently does not support Gear Joints. When they will make it available I will add it in LevelHelper also.");
	elseif jointInfo:intForKey("Type") == 5 then -- wheel joint

		local axis = jointInfo:pointForKey("Axis");
		
		self.coronaJoint = physics.newJoint( "wheel", objA, objB, 
									objA.x +anchorA.x, objA.y +anchorA.y, 
									axis.x,axis.y )
	
		self.coronaJoint.isMotorEnabled = jointInfo:boolForKey("EnableMotor");
		self.coronaJoint.motorSpeed = (-1)*jointInfo:floatForKey("MotorSpeed") --for CORONA we inverse to be the same as 
														--as the other engines from left to right
		--self.coronaJoint.motorForce = jointInfo["MaxTorque"];
		
		self.coronaJoint.frequency = jointInfo:floatForKey("Frequency");
		self.coronaJoint.dampingRatio = jointInfo:floatForKey("Damping");
		
		self.lhJointType = "wheel";
		
	elseif jointInfo:intForKey("Type") == 6 then -- weld joint

		self.coronaJoint = physics.newJoint( "weld", objA, objB, objA.x +anchorA.x,objA.y +anchorA.y )
		self.lhJointType = "weld";
		
	elseif jointInfo:intForKey("Type") == 8 then -- friction joint
	
		self.coronaJoint = physics.newJoint( "friction", objA, objB, objA.x +anchorA.x, objA.y +anchorA.y)
		
		self.coronaJoint.maxForce  = jointInfo:floatForKey("MaxForce");
		self.coronaJoint.maxTorque = jointInfo:floatForKey("MaxTorque");
		self.lhJointType = "friction";		
	else
		print("Unknown joint type " .. jointInfo:intForKey("Type") .." in LevelHelper file.")
	end
		
end