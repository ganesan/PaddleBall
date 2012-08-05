
--v1.5
-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------


-- Your code here
local socket = require "socket"
local udpSocket = socket.udp()
udpSocket:setsockname("localhost",51248)
udpSocket:setpeername("localhost",51249)
udpSocket:settimeout(0)
--[[
CoronaCider Debugger Library v 1.0
Author: M.Y. Developers
Copyright (C) 2012 M.Y. Developers All Rights Reserved
Support: mydevelopergames@gmail.com
Website: http://www.mydevelopersgames.com/
License: Many hours of genuine hard work have gone into this project and we kindly ask you not to redistribute or illegally sell this package.
We are constantly developing this software to provide you with a better development experience and any suggestions are welcome. Thanks for you support.

-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
-- FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
-- DEALINGS IN THE SOFTWARE.
--]]


local json = require "json"
local jsonNull = "nil"
if(type(json.null)=="function") then
    jsonNull = json.null()
elseif (json.Null) then
    jsonNull = json.Null
end 
local CIDER_DIR = ".cider/"
local toNetbeansFile
local pathToNetbeansFile = CIDER_DIR.."fromCorona.cider"
local fromNetbeansFile
local pathFromNetbeansFile = CIDER_DIR.."toCorona.cider"
local startDebuggerMessage = {type = "s"};
local statusMessage
local previousLine, previousFile
local Root = {} --this is for variable dumps
local globalsBlacklist = {}
local breakpoints = {}
local breakpointLines = {}
local runToCursorKey = nil
local runToCursorKeyLine = nil
local logfile
local logEverything = true
local snapshotCounter = 0
local snapshotInterval = -10
local maxSize = 2000
local fileFilters = {}
local lineBlacklist = {}
local myStack =  {}
local stackIndex = 0;
local varDumpFile, pathToVar;
local stackDumpFile, pathToStack;
local startupMode = "require"
local preFrameTimer,postFrameTimer,timeInFrame,frameTime
--override display methods so warnings are thrown
if(CiderRunMode==nil) then
    CiderRunMode = {};
end

if(CiderRunMode.assertImage) then
    local ov = {"newImage", "newImageRect",}
    local displayFunc = {}
    for i,v in pairs(ov) do
        local nativeF = display[v];
        display[v] = function(...)       
            return assert(nativeF(...), "display."..v.." assertion failed, check filename")        
        end   
        
    end
end


--Dont get globals already here
for i,v in pairs(_G) do
    globalsBlacklist[v] = true --dont profile corona stuff
end



local nativePrint = print
local nativeError = error
local function sendConsoleMessage(...)
    --also send via udp to cider
    --we must break up this message into parts so that it does not get truncated
    local message = {}
    message.type = "pr"
    local str = ""
    for i=1,arg.n do
        str = str..tostring(arg[i]).."\t"
    end
    message.str = str
    local messageString = json.encode(message)
    if(messageString:len()>maxSize) then
        while(messageString:len()>maxSize) do				
            local part = messageString:sub(1,maxSize)
            message = {}
            message.type = "ms"
            message.value = part			
            udpSocket:send(json.encode(message))
            messageString = messageString:sub(maxSize+1)
        end
        message = {}
        message.type = "me"
        message.value = messageString			
        udpSocket:send(json.encode(message))				
    else
        
        udpSocket:send(messageString)	
    end	
end
local function debugPrint(...)
    nativePrint(...)
    sendConsoleMessage(...)
end
print = debugPrint
local function debugError(...)
    nativeError(...)
    sendConsoleMessage(...)
    
end

error = debugError
--this will block the program initially and wait for netbeans connection

local varRefTable = {} --holds ref to all discovered vars, must remove or leak.
local function globalsDump()
    
    local globalsVars = {}
    for i,globalv in pairs(_G) do
        
        if(globalsBlacklist[globalv]==nil) then
            globalsVars[i] = globalv
        end
    end		
    --return serializeDump(globalsVars)
    return globalsVars
end
local tostring = tostring
local serializeQueue = {}
local luaIDs
local queueIndex = 1;
local maxqueueIndex = 100;
local function serializeDump(tab, tables)--mirrors table and removes functions, userdata, and tries to identify type\
    luaIDs = {}
    if(tables == nil) then
        tables = {}
    end
    luaIDs[tostring(tab)] = {[".CIDERPath"] = "root"}    
    while(tab) do
        local tabKey = tostring(tab)
        varRefTable[tabKey] = tab
        if(tab == _G) then
            --dealing with global so filter the blacklist and proxy this but leave refernces to global
            tab = globalsDump()
        end
        --tab must be type table
        
        
        if(tables[tabKey] == nil) then
            local newTab = {}
            newTab[".myRef"] = tabKey
            if(tab._class and tab.x and tab.y and tab.rotation and tab.alpha) then            
                --in a displayGroup
                newTab[".isDisplayObject"] = true
                newTab.x, newTab.y, newTab.rotation, newTab.alpha, newTab.width, newTab.height, newTab.isVisible, newTab.xReference, newTab.yReference, newTab.xScale, newTab.yScale=
                tab.x,tab.y,tab.rotation,tab.alpha,tab.width,tab.height,tab.isVisible, tab.xReference, tab.yReference, tab.xScale, tab.yScale
                --also add the custom data
                if(tab.numChildren) then
                    --in a display object
                    newTab.numChildren = tab.numChildren;	
                    newTab[".isDisplayGroup"] = true
                else
                    
                end					
            end
            
            
            tables[tabKey] = newTab            
            local ciderPath = luaIDs[tabKey][".CIDERPath"] or "root";
            --traverse through table and add values
            for i,v in pairs(tab) do		
                local typev = type(v)
                if(type(i)=="table") then
                    i = tostring(i)
                end
                
                if(typev=="string" or type(v)=="boolean" or type(v)=="number" ) then
                    newTab[i] = v;			
                elseif(typev=="table" ) then			
                    --local tabKey = tostring(v)
                    newTab[i] = {}
                    newTab[i][".isCiderRef"] = tostring(v);--save the reference of v
                    
                    if(tables[tostring(v)]==nil) then		--check if we have serialized this table or not			
                        --check if this is a display object (see if there is a _class key)								
                        --add it to the queue instead
                        if(maxqueueIndex ~= queueIndex) then
                            serializeQueue[queueIndex] = v;
                            queueIndex = queueIndex+1;
                        end
                        
                        tabKey = tostring(v)
                        if(luaIDs[tabKey]==nil) then
                            luaIDs[tabKey]={}
                        end
                        local luaID = luaIDs[tabKey];
                        luaID[".CIDERPath"] = ciderPath..i
                        luaID[".luaID"] = i; --the table itself knows its ID
                        --serializeDump(v, tables)
                    end	
                    
                elseif(v==nil) then
                    newTab[i] = jsonNull;
                elseif(typev=="function") then
                    newTab[i]  = {}
                    newTab[i].isCoronaBridgeFunction = true
                    newTab[i].id = i
                elseif(typev=="userdata") then
                    newTab[i] = ".userdata"
                end
            end		
        end
        queueIndex = queueIndex-1
        tab = serializeQueue[queueIndex]
    end
    for i,v in pairs(luaIDs) do
        if(tables[i]) then
            tables[i][".CIDERPath"] = v[".CIDERPath"]
            tables[i][".luaID"] = v[".luaID"]
        end
    end
    
    return tables	
end
local function localsDump(stackLevel, vars) --puts all locals into table
    
    if(vars==nil) then
        vars = {}
    end
    
    local db = debug.getinfo(stackLevel, "fS")
    local func = db.func
    local i = 1
    while true do
        local name, value = debug.getupvalue(func, i)
        if not name then break end
        if(value==nil) then
            vars[name] = jsonNull
        else
            vars[name] = value
        end
        
        i = i + 1
    end
    i = 1
    while true do
        local name, value = debug.getlocal(stackLevel, i)
        if not name then break end
        if(name:sub(1,1)~="(") then
            if(value==nil) then
                vars[name] = jsonNull
            else
                vars[name] = value
            end
            
            
            
        end
        i = i + 1
    end
    --setmetatable(vars, { __index = getfenv(func), __newindex = getfenv(func) })
    --	local dump = serializeDump(   vars	)
    return vars
end
local function searchLocals(localName,newValue,stackLevel) --puts all locals into table
    local db = debug.getinfo(stackLevel, "fS")
    local func = db.func
    local i = 1
    
    while true do
        
        local name, value = debug.getlocal(stackLevel, i)
        print("Var,",name,localName)
        if not name then break end
        if(name == localName) then  print("var found");debug.setlocal(stackLevel, i, newValue); return; end
        i = i + 1
    end
    
    i = 1
    while true do
        local name, value = debug.getupvalue(func, i)
        if not name then break end
        if(name == localName) then debug.setupvalue(func, i, newValue); return; end
        i = i + 1
    end  
end
local function stackDump(stackLevel)
    
    local stackDump = {};
    local stackIndex = stackLevel
    local index = 0;
    local info 
    local filename;
    local info = debug.getinfo(stackIndex,"S")  
    while(info) do
        
        
        filename = info.source
        if( filename:find("CiderDebugger.lua") ) then
            break;
        end
        
        if( filename:find( "@" ) ) then
            filename = filename:sub( 2 )
        end    
        
        --  print(i, "linedefined=",info.linedefined, filename)
        stackDump[index] = {filename,info.linedefined}
        
        
        index = index+1
        stackIndex = stackIndex+1
        info = debug.getinfo(stackIndex,"S")  
    end
    
    return stackDump
    
end


local function writeStackDump() --write the var dump to file
    stackDumpFile = io.open(pathToStack,"w") --clear dump
    stackDumpFile:write( json.encode(stackDump(5)).."\n" )
    stackDumpFile:close( );
    udpSocket:send( json.encode( {["type"]="st"} ) )   
    -- stackDump(6);
    --    local Root = {}
    --    Root = localsDump(5)
    --    Root[".Globals"] = _G
    --    local rootKey = tostring(Root)
    --    Root = serializeDump(Root)
    --    Root[".ROOT"] = rootKey --index to the root element
    --    local message = {}
    --    message.type = "gl"
    
    
    
    --we must break up this message into parts so that it does not get truncated
    --    if(messageString:len()>maxSize) then
    --        while(messageString:len()>maxSize) do				
    --            local part = messageString:sub(1,maxSize)
    --            message = {}
    --            message.type = "ms"
    --            message.value = part			
    --            udpSocket:send(json.encode(message))
    --            messageString = messageString:sub(maxSize+1)
    --            print("sending part", messageString:len())
    --        end
    --        message = {}
    --        message.type = "me"
    --        message.value = messageString			
    --        udpSocket:send(json.encode(message))				
    --    else
    --        
    --        udpSocket:send(messageString)
    --    end
    
    --    varDumpFile = io.open(pathToVar,"w") --clear dump
    --    varDumpFile:write( json.encode(Root) )
    --    varDumpFile:close( );
    --    udpSocket:send( json.encode( message ) )    
    
end
local dumpTable = {};
local function writeVariableDump() --write the var dump to file
    for k,v in pairs(dumpTable) do dumpTable[k]=nil end --clear the table but keep the reference
    for k,v in pairs(Root) do Root[k]=nil end
    localsDump(5, Root)
    Root[".Globals"] = _G
    local rootKey = tostring(Root)
    serializeDump(Root, dumpTable)
    Root[".luaID"]="local vars"
    dumpTable[".ROOT"] = rootKey --index to the root element
    local message = {}
    message.type = "gl"
    
    --we must break up this message into parts so that it does not get truncated
    --    if(messageString:len()>maxSize) then
    --        while(messageString:len()>maxSize) do				
    --            local part = messageString:sub(1,maxSize)
    --            message = {}
    --            message.type = "ms"
    --            message.value = part			
    --            udpSocket:send(json.encode(message))
    --            messageString = messageString:sub(maxSize+1)
    --            print("sending part", messageString:len())
    --        end
    --        message = {}
    --        message.type = "me"
    --        message.value = messageString			
    --        udpSocket:send(json.encode(message))				
    --    else
    --        
    --        udpSocket:send(messageString)
    --    end
    
    varDumpFile = io.open(pathToVar,"w") --clear dump
    varDumpFile:write( json.encode(dumpTable) )
    varDumpFile:close( );
    udpSocket:send( json.encode( message ) )    
    
end

local function standardizePath( input )
    input = string.lower( input )
    input = string.gsub( input, "/", "\\" )
    return input
end
local steppingInto
local steppingOver
local pauseOnReturn
local stepOut
local firstLine = false
local callDepth = 0
local processFunctions = {}
processFunctions.gpc = function()
    --now send the program counter position to netbeans
    local message = {}
    message.type = "gpc"
    if(previousFile:find("@")) then
        previousFile = previousFile:sub(2)
    end     
    if(previousLine==nil) then
        previousLine = 0;
    end        
    message.value = {["file"] = previousFile,["line"] = previousLine}    
    udpSocket:send(json.encode(message))
end
processFunctions.gl = function( )
    --gets the global and local variable state
    writeVariableDump( )
end
processFunctions.p = function( )
    local inPause = true
    --pause execution until resume is recieved, process other commands as they are received
    statusMessage = "paused"
    processFunctions.gpc( )
    writeVariableDump( )
    writeStackDump()
    local line = udpSocket:receive( );
    local keepWaiting = true;
    while( keepWaiting ) do
        if( line ) then
            line = json.decode( line )
            if( line.type~="p" ) then
                processFunctions[line.type]( line );
            end
            if( line.type == "k" or line.type == "r" or line.type == "si" or line.type == "sov" or line.type == "sou" or line.type == "rtc" ) then --if run or step
                return;
            end
            if( line.type == "sv" ) then
                --print( "update dump" )
                writeVariableDump( );
            end			
        end
        line = udpSocket:receive( )
        socket.sleep( 0.1 )
    end
    varRefTable = {}; --must clear reference or else we will have leaks.
end
processFunctions.r = function( )
    runToCursorKey = nil
    runToCursorKeyLine = nil
end
processFunctions.s = function( )
    
end


processFunctions.sb = function( input )
    --sets a breakpoint
    --	file = system.pathForFile( input.path )
    if( breakpointLines[input.line]==nil ) then
        breakpointLines[input.line] = 1 
    else
        breakpointLines[input.line] = breakpointLines[input.line]+1
    end
    
    breakpoints[ standardizePath( input.path )..input.line] = true;
end




processFunctions.rb = function( input )
    if( breakpointLines[input.line]==0 ) then
        breakpointLines[input.line] = nil
    else
        breakpointLines[input.line] = breakpointLines[input.line]-1
    end
    
    breakpoints[ standardizePath( input.path )..input.line] = nil;
end

processFunctions.rtc = function( input )
    --removes a breakpoint
    --	file = system.pathForFile( input.path )
    runToCursorKeyLine = input.line
    runToCursorKey = standardizePath( input.path )..input.line;
end

processFunctions.si = function( )
    print( "stepping into" )
    steppingInto = true
    runToCursorKey = nil
    runToCursorKeyLine = nil
end
processFunctions.sov = function( )
    print( "stepping over" )
    callDepth = 0;
    steppingOver= true
    runToCursorKey = nil
    runToCursorKeyLine = nil
end
processFunctions.sou = function( )
    print( "stepping out" )
    callDepth = 1;
    pauseOnReturn = true
    steppingInto = false
    steppingOver= false
    runToCursorKey = nil
    runToCursorKeyLine = nil
end
processFunctions.sv = function( input )
    print( "setting var", input.parent, input.key, input.value, _G )
    
    if( input.parent == "Root" ) then--now we must search for it
        print( "search locals")
        searchLocals( input.key,input.value, 5 );
        return;			
    elseif( input.parent == "GLOBAL" ) then--now we must search for it
        _G[input.key] = input.value
        return;		
    end	
    local mytab = varRefTable[input.parent]
    if( mytab ) then
        --try to guess the content of the input
        if( input.value == "true" ) then
            mytab[input.key] = true
        elseif( input.value == "false" ) then
            mytab[input.key] = false
        elseif( input.value == "nil" ) then
            mytab[input.key] = nil			
        else
            mytab[input.key] = input.value;
        end
    end
    writeVariableDump( )
end
processFunctions.e = function( evt )
    evt = evt.value
    --print( "event recieved",evt.name, evt.xGravity, evt.yGravity, evt.zGravity );
    Runtime:dispatchEvent( evt );
end
processFunctions.k = function( evt )
    --just remove all the breakpoints
    os.exit( )
    breakpoints = {}
    steppingInto = false
    steppingOver= false
    pauseOnReturn = false
    runToCursorKey = nil
end
--this will do the debug loop, listen for netbeans commands and respond accordingly, executes every line, return, call
local stringlen = string.len
local getinfo = debug.getinfo
local sethook =  debug.sethook
local tostring = tostring
local function runloop( phase, lineKey, err )
    sethook ( )	
    --      local fileKey =  getinfo( 2,"S" ).source 
    --       if( fileKey~="=?" and fileKey~="C" ) then
    --           previousFile,previousLine = fileKey,lineKey
    --       end
    if( phase == "error" ) then
        --send the error and just stop h
        local message = {}
        message.type = "pe"	
        message.str = err
        udpSocket:send( json.encode( message ) )
        
        --    processFunctions.p( ) 			
    end   
    sethook ( runloop, "r",0 ) --errors occur during returns
end


local function debugloop( phase,lineKey,err )
    sethook ( )	
    local fileKey = getinfo( 2,"S" ).source 
    if( phase == "error" ) then
        --send the error and just stop h
        local message = {}
        message.type = "pe"	
        message.str = err
        udpSocket:send( json.encode( message ) )   
        processFunctions.p( ) 			
    end
    
    
    if( fileKey~="=?" and fileKey~="=[C]" ) then
        
        
        if( lineBlacklist[fileKey]==nil ) then
            --  print( "filekey", fileKey )
            --check all the filters
            local filter
            for i=1, #fileFilters do
                
                filter = fileFilters[i]
                --print( "black", filter, fileKey,string.find( fileKey,filter,1,true ) )
                lineBlacklist[fileKey] = lineBlacklist[fileKey] or ( string.find( fileKey,filter,1,true ) or false )
                
            end                
        end
        if( lineBlacklist[fileKey] ) then
            
            if( phase ~= "line" ) then
                sethook ( debugloop, "l",0 )
            else
                sethook ( debugloop, "r",0 ) --future option
            end                        
            return;
        end        
        
        if( lineKey ) then
            previousLine, previousFile =  lineKey ,fileKey	--do before standardization 
        end
        -- previousLine, previousFile =  lineKey ,fileKey	--do before standardization        
        --print( phase,fileKey,lineKey )
        
        if( phase == "call" ) then
            if( fileKey:find( "@" ) ) then
                previousFile = fileKey:sub( 2 )
            end  
            callDepth = callDepth+1;
            --iterate through file filters
            if( steppingOver ) then
                pauseOnReturn = true;
                steppingOver = false;
            end
        elseif( phase == "return" ) then
            callDepth = callDepth-1;
            if( steppingOver ) then
                steppingOver =  false
                steppingInto = true
            end				
            if( pauseOnReturn and callDepth==0) then
                pauseOnReturn = false;
                steppingInto = true;--pause after stepping one more
            end
        elseif( phase == "line" ) then
            
            postFrameTimer = system.getTimer()
            
            snapshotCounter = snapshotCounter+1
            if( snapshotInterval == snapshotCounter or steppingInto or steppingOver ) then
                snapshotCounter = 0
                local logMessage = {}
                for k,v in pairs(dumpTable) do dumpTable[k]=nil end --clear the table but keep the reference
                for k,v in pairs(Root) do Root[k]=nil end
                localsDump(3, Root)
                Root[".Globals"] = _G
                local rootKey = tostring(Root)
                serializeDump(Root, dumpTable)
                Root[".luaID"]="local vars"
                dumpTable[".ROOT"] = rootKey --index to the root element
                local message = {}
                message.type = "hgl"
                message.value = dumpTable	
                logMessage.var = message
                --                
                --Program counter component
                local message2 = {}
                message2.type = "gpc"
                if( previousFile:find( "@" ) ) then
                    previousFile = previousFile:sub( 2 )
                end            
                message2.value = {["file"] = previousFile , ["line"] = previousLine};
                logMessage.pc = message2
                
                local message3 = {}
                message3.type="hst"
                message3.value = stackDump(3)
                logMessage.st =message3
                
                
                --we must break up this message into parts so that it does not get truncated
                logfile:write( json.encode( logMessage ).."\n" )
                logfile:flush( )
                
                
            end
            local inLine = true
            if( steppingInto or steppingOver or firstLine ) then
                firstLine = false;
                steppingInto = false;
                steppingOver = false;
                processFunctions.p( ) --pause after stepping one line					
            else
                --check if we are at a breakpoint or if we are at run to cursor 
                if( breakpointLines[lineKey] or runToCursorKeyLine ) then
                    if( previousFile:find( "@" ) ) then
                        previousFile = previousFile:sub( 2 )
                    end                      
                    fileKey = standardizePath( previousFile )
                    local key = fileKey..lineKey                    
                    if( breakpoints[key] or runToCursorKey==key ) then
                        --we are at breakpoint
                        print( "breakpoint" )
                        if( runToCursorKey==key ) then
                            runToCursorKey = nil
                            runToCursorKeyLine = nil
                        end
                        processFunctions.p( ) 	
                    end
                end
            end
            
        end
        
        --in a lua function
        --check for netbeans commands
        
        local line = udpSocket:receive( )
        while( line ) do
            --Process Line Here
            
            line = json.decode( line )
            processFunctions[line.type]( line );
            if( line.type=="sv" )then
                processFunctions.gl( ) --send the locals.
            end
            
            
            
            line = udpSocket:receive( )				
        end
        
    end
    
    debug.sethook ( debugloop, "crl",0 )
end


------------------------------FRAME TIMER-------------------------------------
local cpuFraction,memoryUsed,runningSumCPU,runningSumMemory=0,0,0,0;--used for averaging
local runningFrames = 1;
local function enterFrame()
    --debug.sethook ( )
    
    local currentTime = system.getTimer( );
    
    if(preFrameTimer) then
        frameTime = currentTime-preFrameTimer;
        if(postFrameTimer) then
            timeInFrame = currentTime-postFrameTimer            
            runningSumCPU = (frameTime-timeInFrame)/frameTime + runningSumCPU      
            runningSumMemory = collectgarbage("count")+runningSumMemory            
            runningFrames = runningFrames+1
            
        end        
    end
    preFrameTimer = currentTime
    --record the system timer, this is the first enterfram event so it will be the first to be executed
    
    --debug.sethook ( debugloop, "crl",0 )
end
Runtime:addEventListener( "enterFrame", enterFrame )
local function reporter()
    if(runningSumCPU and runningSumMemory) then
        --print(runningSumCPU/runningFrames*100,runningSumMemory/runningFrames,runningFrames) 
        --send the data UDP
        local message = {}
        message.type = "p"
        message.m = runningSumMemory/runningFrames
        message.c = runningSumCPU/runningFrames
        message.f = frameTime
        udpSocket:send(json.encode(message))	
        
        runningSumCPU = 0;
        runningSumMemory= 0;
        runningFrames = 0        
    end
    
end
local profilerTimer = timer.performWithDelay( 50, reporter, -1 );
processFunctions.pr = function( evt )
    --update the profiler
    if(evt.gc) then
        print("garbage collecting now...")
        collectgarbage("collect")
    end
    
    if(evt.p) then
        if(profilerTimer) then
            timer.cancel( profilerTimer )
        end
        if(evt.p~=-1) then
            profilerTimer = timer.performWithDelay( evt.p, reporter, -1 )           
        end
        
    end
end
-------------------------------------------------------------------------------

local function initBlock( )
    
    --send start command and wait for response
    --first get debugger state send gb command
    
    
    local pathToHistory  = system.pathForFile( "CiderExecutionLog.dat", system.DocumentsDirectory )
    logfile = io.open( pathToHistory,"w" )	
    pathToVar = system.pathForFile( "CiderVarDump.dat", system.DocumentsDirectory )
    varDumpFile = io.open( pathToVar,"w" )
    varDumpFile:close();
    pathToStack = system.pathForFile( "CiderStackDump.dat", system.DocumentsDirectory )
    stackDumpFile = io.open( pathToStack,"w" )    
    stackDumpFile:close();    
    local message = {}
    message.type = "s"	
    message.path = tostring(pathToHistory)
    message.varDump = tostring(pathToVar);
    message.stackDump = tostring(pathToStack)
    udpSocket:send(json.encode(message))		
    print( "waiting for netbeans debugger initialization")	
    local line = udpSocket:receive()
    local keepWaiting = true
    while( keepWaiting ) do
        socket.sleep(0.1)
        if(line) then
            --	print(line)
            line = json.decode(line)
            if(line.type=="s") then
                if(line.snapshot) then
                    snapshotInterval = tonumber(line.snapshot)
                end
                for i,v in pairs(line.filters) do
                    line.filters[i] = (string.gsub(v, "^%s*(.-)%s*$", "%1"))    
                end
                
                fileFilters = line.filters;                
                CiderRunMode = line.run
                startupMode = line.startup;
                keepWaiting = false
                break;
            end
            if(line.type=="sb") then
                processFunctions[line.type](line);--proccess current then the rest		
            end
        end
        line = udpSocket:receive()		
    end
    --lets initialize a log file
    
    line = udpSocket:receive()	
    while(line) do
        line = json.decode(line)
        if(line.type=="sb")  then
            processFunctions[line.type](line);
            
        end
        line = udpSocket:receive()	
    end	
    
    --now we have the first line with the start command, we can give back control of the program
    print("debugger started")	
end


if(CiderRunMode.runmode) then
    sethook (runloop, "r",0 )
else       
    initBlock()
    if(startupMode=="require") then
        debug.sethook (debugloop, "crl",0 );
    elseif(startupMode=="noRequire") then
        timer.performWithDelay(1,function() debug.sethook (debugloop, "crl",0 ); end)
    elseif(startupMode=="delay") then
        timer.performWithDelay(1000,function() debug.sethook (debugloop, "crl",0 ); end)
    end
    
end
CiderRunMode = nil;

isCorona = nil;

