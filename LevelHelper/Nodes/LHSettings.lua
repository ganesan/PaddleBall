require "LevelHelper.Helpers.LHHelpers"
require "config"
LHSettings = {}
lh_settings_sharedInstance = nil;
function LHSettings:init()

	local object = {spritesEvents = {},
					enableRetina = true,
					levelDeviceWidth = 480,
					levelDeviceHeight = 320,
					newSpriteCreated = 0,
					batchNodesSizes = {},
					allLHMainLayers = {}
					}
	setmetatable(object, { __index = LHSettings })  -- Inheritance	
	
	lh_settings_sharedInstance = object;
	return object
end
--------------------------------------------------------------------------------
function removeLHSettings()
lh_settings_sharedInstance.spritesEvents = nil;
lh_settings_sharedInstance.enableRetina = nil
lh_settings_sharedInstance.levelDeviceWidth = nil
lh_settings_sharedInstance.levelDeviceHeight = nil;
lh_settings_sharedInstance.newSpritesCreated = nil;
lh_settings_sharedInstance = nil;
end
--------------------------------------------------------------------------------
function LHSettings:sharedInstance()

	if(lh_settings_sharedInstance == nil) then
		return self:init();
	end
	
	return lh_settings_sharedInstance;
end
--------------------------------------------------------------------------------
function LHSettings:addLHMainLayer(mainLayer)
	self.allLHMainLayers[#self.allLHMainLayers + 1] = mainLayer;
end
--------------------------------------------------------------------------------
function LHSettings:removeLHMainLayer(mainLayer)
	for i = 1, #self.allLHMainLayers do
		if(self.allLHMainLayers[i] == mainLayer)then
			table.remove(self.allLHMainLayers,i)
			self.allLHMainLayers[i] = nil;
		end
	end
end
--------------------------------------------------------------------------------
function LHSettings:sizeForImageFile(imageFile)

	local batchSize = self.batchNodesSizes[imageFile];
	
	if(batchSize == nil)then
	
		local findSizeFromThisObject = display.newImage(imageFile, system.ResourceDirectory,  0, 0,  true);
		
		batchSize = {width = findSizeFromThisObject.width, height = findSizeFromThisObject.height};
		self.batchNodesSizes[imageFile] = batchSize;
		findSizeFromThisObject:removeSelf();
	end

	return batchSize;
end


function LHSettings:newSpriteNumber()
	self.newSpriteCreated = self.newSpriteCreated+1;
	return self.newSpriteCreated;
end
--------------------------------------------------------------------------------
function LHSettings:convertRatio()
	return {x = 1.0, y = 1.0}
end
--------------------------------------------------------------------------------
function LHSettings:correctedImageFileAndTextureRect(imageFile)

	local imagesFolder = "";
	if(nil ~= application.LevelHelperSettings.imagesSubfolder)then
		imagesFolder = application.LevelHelperSettings.imagesSubfolder;
		imagesFolder = imagesFolder .. "/"
	end
	
	local rectMultiplier = 1.0;
	
	local isIphone1 = false
	
	if(system.getInfo("model") == "iPhone" or
	   system.getInfo("model") == "iPod touch") then
		if	system.getInfo("architectureInfo") == "iPhone1,1" or
			system.getInfo("architectureInfo") == "iPhone1,2" or
			system.getInfo("architectureInfo") == "iPhone2,1" or
			system.getInfo("architectureInfo") == "iPod1,1" or
			system.getInfo("architectureInfo") == "iPod2,1" then
			isIphone1 = true
		end
	end
	
	
	if(isIphone1 or
	   system.getInfo("model") == "myTouch")then
	   
	   	local correctFile = imageFile;
	   	local correctStrWithSubFolder = imagesFolder ..  imageFile;
	  	if(true == lh_fileExists(correctStrWithSubFolder))then
			correctFile = correctStrWithSubFolder
		end
		
		return correctFile, rectMultiplier
	end

	local correctStr = imageFile;
	local correctStrWithSubFolder = imagesFolder  .. imageFile;
	
	local img = string.sub(imageFile, 1, -5)
	local ext = string.sub(imageFile, -3)
	
	if self.enableRetina then
		correctStr = img .. "-hd" .. "." .. ext;
		rectMultiplier = 2.0
		correctStrWithSubFolder = imagesFolder  .. img .. "-hd" .. ".".. ext;
	end

	local correctFile = correctStr;
	
	if(true == lh_fileExists(correctStrWithSubFolder))then
		correctFile = correctStrWithSubFolder
	else
		correctStrWithSubFolder = imagesFolder .. img .. "."..ext;
		if(true == lh_fileExists(correctStrWithSubFolder))then
			correctFile = correctStrWithSubFolder
			rectMultiplier = 1.0
		else
			correctFile = correctStrWithSubFolder
			--if(false == lh_fileExists(correctFile))then
			--	correctFile = imageFile;
			--	rectMultiplier = 1.0
			--end
		end
	end
	
	return correctFile, rectMultiplier;
end
--------------------------------------------------------------------------------