CiderRunMode = {};CiderRunMode.runmode = true;CiderRunMode.assertImage = true;require "CiderDebugger";-- Project: PaddleBall                         																															
-- Description: A Breakout inspired game for iOS devices. 
-- Twitter: @CraftyDeano
-- GitHub: @CraftyDeano
-- Web: http://echoecho.es
-- Email: echo@echoecho.es
-- Version: 0.1
-- Copyright 2012 . All Rights Reserved.

display.setStatusBar(display.HiddenStatusBar)

physics = require("physics")
physics.start()
physics.setGravity(0, 0)

system.setAccelerometerInterval( 100 )


menus = require("menus")
game = require("game")

-- global display.variables
_W = display.contentWidth / 2
_H = display.contentHeight / 2

-- main function that starts the app
function main()
    mainMenu()
end


main()


