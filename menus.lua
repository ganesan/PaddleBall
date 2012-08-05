-- function to load the main menu
-- display.variables

function mainMenu()
    menuScreenGroup = display.newGroup()

    menuBG = display.newImageRect("image/menu.png",320,480)
    menuBG.x = _W
    menuBG.y = _H
    
    playBTN = display.newImageRect("image/playbtn.png",142,31)
    playBTN.x = _W
    playBTN.y = _H
    playBTN.name = "playBTNpress"

    
    helpBTN = display.newImageRect("image/helpbtn.png",142,31)
    helpBTN.x = _W
    helpBTN.y = _H + 50
    helpBTN.name = "helpBTNpress"
 
    creditsBTN = display.newImageRect("image/creditsbtn.png",142,31)
    creditsBTN.x = _W
    creditsBTN.y = _H + 100
    creditsBTN.name = "creditsBTNpress"
    

    menuScreenGroup:insert( menuBG )
    menuScreenGroup:insert(playBTN)
    menuScreenGroup:insert(helpBTN)
    menuScreenGroup:insert(creditsBTN)
    
    playBTN:addEventListener("tap", playGame)
    helpBTN:addEventListener("tap", menuTween)
    creditsBTN:addEventListener("tap", menuTween)

end

function playGame()
    gameStart()
end

-- event transition for the main,help & credit menus
function menuTween(event)
    if event.target.name == "helpBTNpress" then
        transition.to(menuScreenGroup,{time = 750, alpha = 0,transition = easing.inlinear, onComplete = helpMenu})
        playBTN:removeEventListener("tap", playGame)
        helpBTN:removeEventListener("tap", menuTween)
        creditsBTN:removeEventListener("tap", creditsMenu)
    elseif event.target.name == "creditsBTNpress" then
        transition.to(menuScreenGroup,{time = 750, alpha = 0,transition = easing.inlinear, onComplete = creditsMenu})
        playBTN:removeEventListener("tap", playGame)
        helpBTN:removeEventListener("tap", menuTween)
        creditsBTN:removeEventListener("tap", creditsMenu)
    elseif event.target.name == "helpbackBTNpress" then
        transition.to(helpScreenGroup,{time = 750, alpha = 0,transition = easing.inlinear, onComplete = main})
        helpBackBTN:removeEventListener("tap", menuTween)
    elseif event.target.name == "creditsbackBTNpress" then
        transition.to(creditsScreenGroup,{time = 750, alpha = 0,transition = easing.inlinear, onComplete = main})
        creditsBackBTN:removeEventListener("tap", menuTween)
    end
end

-- loads the help menu
function helpMenu()
    helpScreenGroup = display.newGroup()

    helpBG = display.newImageRect("image/helpBG.png",320,480)
    helpBG.x = _W
    helpBG.y = _H
    
    helpBackBTN = display.newImageRect("image/backbtn.png",142,31)
    helpBackBTN.x = _W; 
    helpBackBTN.y = _H + 100
    helpBackBTN.name = "helpbackBTNpress"
    
    helpScreenGroup:insert( helpBG )
    helpScreenGroup:insert( helpBackBTN )   
    
    helpBackBTN:addEventListener("tap", menuTween)
end

-- loads the credits menu
function creditsMenu()
    creditsScreenGroup = display.newGroup()

    creditsBG = display.newImageRect("image/creditsBG.png",320,480)
    creditsBG.x = _W
    creditsBG.y = _H
    
    creditsBackBTN = display.newImageRect("image/backbtn.png",142,31)
    creditsBackBTN.x = _W; 
    creditsBackBTN.y = _H + 125
    creditsBackBTN.name = "creditsbackBTNpress"
    
    creditsScreenGroup:insert( creditsBG )
    creditsScreenGroup:insert( creditsBackBTN )   
    
    creditsBackBTN:addEventListener("tap", menuTween)
end
