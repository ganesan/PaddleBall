function gameStart()
    require "LevelHelperLoader"

    loader = LevelHelperLoader:initWithContentOfFile("pblv1.plhs")
--path notifiers and event listener for all sprites should be placed here
--see "Collision Handling and Events" and "Beziers" sections for more info
    loader:instantiateObjects(physics) 
end
