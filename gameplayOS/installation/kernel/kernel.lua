local apis = fs.find("gameplayOS/installation/apis/before/*/*")
for i,v in pairs(apis) do
    if not string.find(apis[i],"fs.reg1")
    then
    os.loadAPI(apis[i])
    end
end
local expect = require("cc.expect")
_G.kernel = {}
_G.sys = {}
_G.Perms = {}
_G.multishell = {}
local CurrentProcess = "kernel"
-- stores the fs API for reconfiguration 
local core_registry = {{"shutdown",false},{"current_user","installer"}}
local open = fs.open
local delete = fs.delete
local copy = fs.copy
local mkdir = fs.makeDir
local move = fs.move
local readonly = fs.isReadOnly
local natviereboot = os.reboot
local nativeshutdown = os.shutdown
local tAPIsLoading = {}
    --basic file controls 
    function readfile(file,depth)
        if fs.exists(file) 
        then
        local datafile = open(file,"r")
        local data = datafile.readAll()
        datafile.close()
        return textutils.unserialise(data)
        else
            if depth 
            then
                error(file.." dose not exists",depth)
            else
            error(file.." dose not exists",2)
            end
        end
    end
    function store(file,data)
        local datafile = open(file,"w")   
        if type(data) == "table"
        then 
            local data = textutils.serialize(data)
            datafile.write(data)
            datafile.close()
            datafile = nil
        else
            error("expected table",2)
        end
    end
    function loadfile(filename, mode, env)
        -- Support the previous `loadfile(filename, env)` form instead.
        if type(mode) == "table" and env == nil then
            mode, env = nil, mode
        end
    
        expect(1, filename, "string")
        expect(2, mode, "string", "nil")
        expect(3, env, "table", "nil")
    
        local file = open(filename, "r")
        if not file then return nil, "File not found" end
    
        local func, err = load(file.readAll(), "@" .. filename, mode, env)
        file.close()
        return func, err
    end
    function dofile(_sFile)
        expect(1, _sFile, "string")
    
        local fnFile, e = loadfile(_sFile, nil, _G)
        if fnFile then
            return fnFile()
        else
            error(e, 2)
        end
    end
-- Perms API
    Perms.isPermitted = function (ID)
        local Table = readfile("gameplayOS/data/Perms.reg1")
        local Table = database.getTable(Table,CurrentProcess)
        if Table == nil
        then
            return false,"not a known program"
        end
        local Table = Table[2]
        if Table[1] == "full"
        then
            return true
        else
            for i,v in pairs(Table) do
                if Table[i] == ID
                then
                    return true
                end
            end
            return false
        end
    end
    Perms.givePerms = function(ID,giveperm)
        if Perms.isPermitted("full")
        then
            if kernel.isAdministrator(kernel.current_user())
            then
                local mainTable = readfile("gameplayOS/data/Perms.reg1")
                local Table,i = database.getTable(mainTable,ID)
                table.insert(mainTable[i][2],tostring(giveperm))
                store("gameplayOS/data/Perms.reg1",mainTable)
            else
                error("Permission denied "..kernel.current_user().." is not a admin",0)
            end
        else
            error("Permission denied, give perms",2)
        end
    end
    Perms.remPerms = function(ID,perm)
        if Perms.isPermitted("full") or Perms.isPermitted("remove")
        then
            if kernel.isAdministrator(kernel.current_user())
            then
                local mainTable = readfile("gameplayOS/data/Perms.reg1")
                if perm == "all"
                then
                    database.remove(mainTable,ID)
                else
                    local Table,i = database.getTable(mainTable,ID)
                    for b,v in pairs(mainTable[i][2]) do
                        if mainTable[i][2][b] == perm
                        then
                        table.remove(mainTable[i][2],b)
                        end
                    end
                end
                store("gameplayOS/data/perms.reg1",mainTable)
            else
                error("Permission denied "..kernel.current_user().." is not a admin",0)
            end
        else
            error("Permission denied remove perms",2)
        end  
    end
    Perms.mkPerms = function(ID,...)
        if Perms.isPermitted("full") 
        then
            if kernel.isAdministrator(kernel.current_user())
            then
                local mainTable = readfile("gameplayOS/data/Perms.reg1")
                local Table = {ID,{...}}
                table.insert(mainTable,Table)
                store("gameplayOS/data/Perms.reg1",mainTable)
                return true
            else
                error("Permission denied "..kernel.current_user().." is not a admin",0)
            end
        else
            error("Permission denied mkPerms",2)
        end

    end
    -- starts the kernel apis
    kernel.currentProcess = function ()
        return CurrentProcess
    end
    kernel.shuttingdown = function (boolean)
        if boolean ~= nil
        then
            if Perms.isPermitted("kernel") or Perms.isPermitted("shutdown")
            then
                core_registry[1][2] = boolean 
            else
                error("Permission denied kernel shutdown",2)
            end
        else
            return core_registry[1][2]
        end
    end
    kernel.current_user = function()
       return  core_registry[2][2] 
    end
    kernel.isAdministrator = function(user)
        expect(1,user,"string")
        if kernel.current_user() == "installer"
        then
            return true
        end
        local Table = sys.getdata("users/"..user,user)
        return Table[2][1]
    end
    kernel.SetAdministrator = function(user,bool)
        if Perms.isPermitted("setAdministrator") or Perms.isPermitted("kernel")
        then
            if kernel.isAdministrator(kernel.current_user())
            then
                if fs.exists(user)
                then
                    local Table = sys.getdata("users/"..user,user)
                    Table[2][1] = bool
                    sys.setdata("users/"..user,user,Table)
                else
                    error(user.." dose not exists",0)
                end
            else
                error("Permission denied "..kernel.current_user().." is not a admin",0)
            end
        else
            error("Permission denied,setAdministrator",2)
        end
    end
    kernel.setuser = function (user)
        if Perms.isPermitted("kernel")
        then
            if not kernel.isAdministrator(kernel.current_user())
            then
                error("Permission denied "..kernel.current_user().." is not a admin",0)
            end
            core_registry[2][2] = user
        else
            error("Permission denied, setuser",2)
        end
    end   


    -- starts the sys_registry APis
    local function sys_initialization(path,ID)
        local mainTable = readfile(path.."/sys.reg1")
        local Table,i = database.getTable(mainTable,ID)
        return Table,mainTable,i
    end
    
    sys.getdata = function(path,ID)
        local Table,mainTable,i = sys_initialization(path,ID)
        return Table,mainTable,i
    end

    sys.remove = function (path,ID)
        if Perms.isPermitted("sys")
        then
            local path2 = path.."/sys.reg1"
            local Table,mainTable,i = sys_initialization(path,ID)
            Table = nil
            table.remove(mainTable,i)
            store(path2,mainTable)
        else
            error("Permission denied, sys.remove",2)
        end
    end
    sys.insertnew = function(directroy,ID,...)
        if Perms.isPermitted("sys")
        then
            local Table,mainTable = sys_initialization(directroy,ID)
            Table = {ID,{...}}
            table.insert(mainTable,Table)
            store(directroy.."/sys.reg1",mainTable)
        else
            error("Permission denied, sys.insertnew",2)
        end
    end
    sys.makefile = function(path,ID,...)
        if Perms.isPermitted("sys")
        then
            if fs.exists(path.."/sys.reg1")
            then
               error("already exists",2) 
            end
            if fs.exists(path.."/fs.reg1")
            then
                local file = open(path.."/sys.reg1","w")
                file.write({})
                file.close()
                file = nil
                local mainTable = readfile(path.."/fs.reg1")
                local Table = {"sys.reg1",{false,false,"installer"}}
                table.insert(mainTable,Table)
                store(path.."/fs.reg1",mainTable)
                mainTable = nil
                local name = "sys.reg1"
                Table = {{ID,{...}}}
                store(path.."/sys.reg1",Table)
            else
                error("couldn't make file because fs_registry file was not found",2)
            end
        else
            error("Permission denied, sys.makefile",2)
        end
    end
    sys.setData = function (path,ID,Table)
        expect.expect(3,Table,"table")
        expect.expect(2,ID,"string")
        expect.expect(1,path,"string")
        if Perms.isPermitted("sys")
        then
            local look,mainTable,i = sys_initialization(path,ID)
            look = nil
            mainTable[i] = Table
            store(path.."/sys.reg1",mainTable)
        else
            error("Permission denied,sys.setData",2)
        end
    end
    -- starts the fs APis
    local function fs_initialization(fullpath)
        local name = fs.getName(fullpath)
        local path = fs.getDir(fullpath) 
        if path == ".."
        then
            path = ""
        end
        local mainTable = readfile(path.."/fs.reg1",3)
        local Table,i = database.getTable(mainTable,name)
        fullpath = nil
        return Table,mainTable,i,path
    end
    local function fs_store(fullpath,data)
        local path = fs.getDir(fullpath).."/fs.reg1"
        store(path,data)
        path = nil
        data = nil
        fullpath = nil
        return true
    end
    fs.isReadOnly = function (fullpath)
        if readonly(fullpath)
        then
            return true
        end
        if fullpath == ""
        then
            return false
        end
        if not fs.exists(fullpath)
        then
            if fs.exists(fs.getDir(fullpath))
            then
                if fs.getDir(fullpath) == ""
                then 
                    return false
                end
                return fs_initialization(fs.getDir(fullpath))[2][1]
            else
                error("Could not find root path")
            end
        end
        print(fullpath)
        sleep(1)
        return fs_initialization(tostring(fullpath))[2][1]
    end
    fs.currentuser_isowner = function (fullpath)
        if string.find(fullpath,"rom")
        then
            return true
        else
            if fullpath == ""
            then
                return true
            end
            if  fs_initialization(fullpath)[2][3] == kernel.current_user() or fs_initialization(fullpath)[2][3] == "public"
            then
                return true
            else
                return false
            end
        end
    end
    fs.setReadOnly = function (path,bool)
        if Perms.isPermitted("fs")
        then
            if fs.currentuser_isowner(path) 
            then
                if bool == nil 
                then
                    error("missing argument #2",2)
                elseif type(bool) ~= "boolean"
                then
                    error("2 argument invalid, must be a boolean",2)
                end
                local Table,mainTable,i = fs_initialization(path)
                Table = nil
                mainTable[i][2][1] = bool
                fs_store(path,mainTable)
                return true
            else
                error(kernel.current_user().." dose not own "..path,0)
            end
        else
            error("Permission denied, fs.setReadOnly",2)
        end
    end
    fs.setowner = function (fullpath,newowner)
        if  Perms.isPermitted("fs")
        then
            if fs.currentuser_isowner(fullpath)
            then
                local Table,mainTable,i = fs_initialization(fullpath)
                Table = nil
                mainTable[i][2][3] = tostring(newowner)
                fs_store(fullpath,mainTable)
            else
                error(kernel.current_user().." dose not own"..fullpath,0)
            end
        else
            error("Permission denied, fs.setowner",2)
        end
    end
    fs.open = function (path,m)
        if Perms.isPermitted("fs")
        then
            if fs.exists(path)
            then
                if string.find(path,"gameplayOS/data/icons") and m == "r"
                then
                    return open(path,"r")
                elseif fs.currentuser_isowner(path) 
                then
                    if fs.isReadOnly(path) and m ~= "r"
                    then
                        error("can't edit a read only file",2)
                    end
                    return open(path,m)
                else
                    error(kernel.current_user().." dose not own "..path,0)
                end
            else
                if fs.currentuser_isowner(fs.getDir(path))
                then
                    if fs.isReadOnly(fs.getDir(path))
                    then
                        error("can't edit a read only folder",2)
                    end
                    local Table,mainTable,i = fs_initialization(path)
                    i = nil
                    Table = {fs.getName(path),{false,false,kernel.current_user()}}
                    table.insert(mainTable,Table)
                    fs_store(path,mainTable)
                    return open(path,m)
                else
                    error(kernel.current_user().." dose not own "..fs.getDir(path),0)
                end 
            end
        else
            error("Permission denied, fs.open ",2)
        end
    end
    fs.delete = function (path)
        if Perms.isPermitted("fs")
        then
            if fs.currentuser_isowner(path)
            then
                if fs.isReadOnly(path)
                then
                    error("can't delete a read only file",2)
                end
                local list = fs.listSubs(path)
                for i,v in pairs(list) do
                    if string.find(path,".lua")
                    then
                        Perms.remPerms(string.sub(fs.getName(path),1,#fs.getName(path)-4),"all")
                    end
                end
                local Table,mainTable,i = fs_initialization(path)
                Table = nil
                table.remove(mainTable,i)
                fs_store(path,mainTable)
                delete(path)
            else
                error(kernel.current_user().." dose not own, "..fs.getName(path),0)
            end
        else
            error("Permission denied, fs.delete",2)
        end
    end

    fs.makeDir = function(path)
        if Perms.isPermitted("fs")
        then
            if fs.exists(fs.getDir(path))
            then
                if fs.getDir(path) == ""
                then
                    local mainTable = readfile("fs.reg1")
                    local Table = {fs.getName(path),{false,false,kernel.current_user()}}
                    table.insert(mainTable,Table)
                    fs_store(path,mainTable)
                    mkdir(path)
                    store(path.."/fs.reg1",{{"fs.reg1",{false,false,"installer"}}})
                else
                    if fs.currentuser_isowner(fs.getDir(path))
                    then
                        local path2 = fs.getDir(path)
                        local mainTable = readfile(path2.."/fs.reg1")
                        local Table = {fs.getName(path),{false,false,kernel.current_user()}}
                        table.insert(mainTable,Table)
                        fs_store(path,mainTable)
                        mkdir(path)
                        store(path.."/fs.reg1",{{"fs.reg1",{false,false,"installer"}}})
                    else
                        error(kernel.current_user().." dose not own "..fs.getDir(path),0)
                    end
                end
            else
                error("can't make more then one directroy at a time",2)
            end
        else
            error("Permission denied,fs.mkdir",2)
        end
    end
    fs.move = function(orgin,dest)
        if Perms.isPermitted("fs") 
        then
            if not fs.exists(fs.getDir(dest))then
                error(dest.." does not exists")
            end
            if not fs.exists(orgin)
            then error(orgin.." dose not exists",2)
            end
            if not fs.currentuser_isowner(fs.getDir(dest))
            then
                error(kernel.current_user().." does not own "..dest)
            end
            if not fs.currentuser_isowner(orgin)
            then
                error(kernel.current_user().." does not own "..orgin)
            end
            local FS_dest = readfile(fs.getDir(dest).."/fs.reg1")
            local FS_orgin = readfile(fs.getDir(orgin).."/fs.reg1")
            local FS_orginTable,i = database.getTable(FS_orgin,orgin)
            table.remove(FS_orginTable,i)
            table.insert(FS_dest,FS_orginTable)
            store(fs.getDir(dest).."/fs.reg1",FS_dest)
            store(fs.getDir(orgin).."/fs.reg1",FS_orgin)
            return move(orgin,dest)
        else
            error("Permission denied , fs.move",2)
        end
    end
    fs.copy = function(file,dest)
        local root = fs.getDir(dest)
        if root == ""
        then
            root = dest
        end
        if Perms.isPermitted("fs")
        then
            if not fs.exists(root) 
            then error(root.." dose not exists",2)
            end
            if not fs.exists(file)
            then error(file.." dose not exists",2)
            end
            if not fs.currentuser_isowner(root) 
            then error(kernel.current_user().." dose not own "..root,0)
            end
            if not fs.currentuser_isowner(file)
            then error(kernel.current_user().." dose not own "..file,0)
            end
            copy(file,dest)
            
            return true
        else
            error("Permission denied, fs.copy",2)
        end
    end
    fs.listSubs = function (path)
        if Perms.isPermitted("fs") 
        then
            local Table = {tostring(path)}
            for i,v in pairs(Table) do
                local list = fs.find(Table[i].."/*")
                for a,b in pairs(list) do
                    if fs.isDir(list[a]) 
                    then
                        table.insert(Table,tostring(list[a]))
                    end
                end
            end
            local list = Table
            for i,v in pairs(list) do
                local temp = fs.find(Table[i].."/*")
                for a,b in pairs(temp) do
                    if not fs.isDir(temp[a])
                    then
                        table.insert(Table,tostring(temp[a]))
                    end
                end
            end
            return Table
        else
            error("Permission denied, fs.listSubs",2)
        end
        
    end
    

    -- patches some of the OS apis
    function os.run(_tEnv, _sPath, ...)
        expect(1, _tEnv, "table")
        expect(2, _sPath, "string")
    
        local tEnv = _tEnv
        setmetatable(tEnv, { __index = _G })

        if settings.get("bios.strict_globals", false) then
            -- load will attempt to set _ENV on this environment, which
            -- throws an error with this protection enabled. Thus we set it here first.
            tEnv._ENV = tEnv
            getmetatable(tEnv).__newindex = function(_, name)
              error("Attempt to create global " .. tostring(name), 2)
            end
        end
    
        local fnFile, err = loadfile(_sPath, nil, tEnv)
        if fnFile then
            local ok, err = pcall(fnFile, ...)
            if not ok then
                if err and err ~= "" then
                    printError(err)
                end
                return false
            end
            return true
        end
        if err and err ~= "" then
            printError(err)
        end
        return false
    end
    function os.loadAPI(_sPath)
    expect(1, _sPath, "string")
    local sName = fs.getName(_sPath)
    if sName:sub(-4) == ".lua" then
        sName = sName:sub(1, -5)
    end
    if tAPIsLoading[sName] == true then
        printError("API " .. sName .. " is already being loaded")
        return false
    end
    tAPIsLoading[sName] = true

    local tEnv = {}
    setmetatable(tEnv, { __index = _G })
    local fnAPI, err = loadfile(_sPath, nil, tEnv)
    if fnAPI then
        local ok, err = pcall(fnAPI)
        if not ok then
            tAPIsLoading[sName] = nil
            return error("Failed to load API " .. sName .. " due to " .. err, 1)
        end
    else
        tAPIsLoading[sName] = nil
        return error("Failed to load API " .. sName .. " due to " .. err, 1)
    end

    local tAPI = {}
    for k, v in pairs(tEnv) do
        if k ~= "_ENV" then
            tAPI[k] =  v
        end
    end

    _G[sName] = tAPI
    tAPIsLoading[sName] = nil
    return true
end
    os.shutdown = function(m)
        if Perms.isPermitted("shutdown") or Perms.isPermitted("kernel")
        then
            if m == "r"  or m == "R" 
            then
                natviereboot()
            elseif (m == "B"  or m == "b")
            then
                local handle = open("bootscreen.lua","w")
                handle.write()
                handle.close()
                natviereboot()
            else
                nativeshutdown()
            end
        else
            error("Permission denied, os.shutdown",2)
        end
    end
    os.reboot = function (m)
        if m == nil then 
            os.shutdown("r")
        end
        os.shutdown(m)
    end
    os.version = function ()
        return "GameOS"
    end

    
    local apis = fs.find("/gameplayOS/installation/apis/after/*/*")
    for i,v in pairs(apis)do
        if not string.find(apis[i],"fs.reg1")
        then
        os.loadAPI(apis[i])
        end
    end
    screen.clear(1,1)
    shell.run("gameplayOS/installation/usersENV/winlogon.lua")
--- Multishell allows multiple programs to be run at the same time.
--
-- When multiple programs are running, it displays a tab bar at the top of the
-- screen, which allows you to switch between programs. New programs can be
-- launched using the `fg` or `bg` programs, or using the @{shell.openTab} and
-- @{multishell.launch} functions.
--
-- Each process is identified by its ID, which corresponds to its position in
-- the tab list. As tabs may be opened and closed, this ID is _not_ constant
-- over a program's run. As such, be careful not to use stale IDs.
--
-- As with @{shell}, @{multishell} is not a "true" API. Instead, it is a
-- standard program, which launches a shell and injects its API into the shell's
-- environment. This API is not available in the global environment, and so is
-- not available to @{os.loadAPI|APIs}.
--
-- @module[module] multishell
-- @since 1.6

local expect = dofile("rom/modules/main/cc/expect.lua").expect

-- Setup process switching
local parentTerm = term.current()
local w, h = parentTerm.getSize()

local tProcesses = {}
local nCurrentProcess = nil
local nRunningProcess = nil
local bShowMenu = false
local bWindowsResized = false
local nScrollPos = 1
local bScrollRight = false

local function selectProcess(n)
    if nCurrentProcess ~= n then
        if nCurrentProcess then
            local tOldProcess = tProcesses[nCurrentProcess]
            tOldProcess.window.setVisible(false)
        end
        nCurrentProcess = n
        if nCurrentProcess then
            local tNewProcess = tProcesses[nCurrentProcess]
            tNewProcess.window.setVisible(true)
            tNewProcess.bInteracted = true
        end
    end
end

local function setProcessTitle(n, sTitle)
    tProcesses[n].sTitle = sTitle
end

local function resumeProcess(nProcess, sEvent, ...)
    local tProcess = tProcesses[nProcess]
    local sFilter = tProcess.sFilter
    if sFilter == nil or sFilter == sEvent or sEvent == "terminate" then
        local nPreviousProcess = nRunningProcess
        nRunningProcess = nProcess
        term.redirect(tProcess.terminal)
        CurrentProcess = tProcesses[nRunningProcess].sTitle
        local ok, result = coroutine.resume(tProcess.co, sEvent, ...)
        tProcess.terminal = term.current()
        if ok then
            tProcess.sFilter = result
        else
            printError(result)
        end
        nRunningProcess = nPreviousProcess
    end
end

local function launchProcess(bFocus, tProgramEnv, sProgramPath, ...)
    local tProgramArgs = table.pack(...)
    local nProcess = #tProcesses + 1
    local tProcess = {}
    tProcess.sTitle = fs.getName(sProgramPath)
    if bShowMenu then
        tProcess.window = window.create(parentTerm, 1, 2, w, h - 1, false)
    else
        tProcess.window = window.create(parentTerm, 1, 1, w, h, false)
    end
    tProcess.co = coroutine.create(function()
        os.run(tProgramEnv, sProgramPath, table.unpack(tProgramArgs, 1, tProgramArgs.n))
        if not multishell.getCount() == 1 
        then
            if not tProcess.bInteracted then
                term.setCursorBlink(false)
                print("Press any key to continue")
                os.pullEvent("char")
            end
        end
    end)
    tProcess.sFilter = nil
    tProcess.terminal = tProcess.window
    tProcess.bInteracted = false
    tProcesses[nProcess] = tProcess
    if bFocus then
        selectProcess(nProcess)
    end
    resumeProcess(nProcess)
    return nProcess
end

local function cullProcess(nProcess)
    local tProcess = tProcesses[nProcess]
    if coroutine.status(tProcess.co) == "dead" then
        if nCurrentProcess == nProcess then
            selectProcess(nil)
        end
        table.remove(tProcesses, nProcess)
        if nCurrentProcess == nil then
            if nProcess > 1 then
                selectProcess(nProcess - 1)
            elseif #tProcesses > 0 then
                selectProcess(1)
            end
        end
        if nScrollPos ~= 1 then
            nScrollPos = nScrollPos - 1
        end
        return true
    end
    return false
end

local function cullProcesses()
    local culled = false
    for n = #tProcesses, 1, -1 do
        culled = culled or cullProcess(n)
    end
    return culled
end

-- Setup the main menu
local menuMainTextColor, menuMainBgColor, menuOtherTextColor, menuOtherBgColor
if parentTerm.isColor() then
    menuMainTextColor, menuMainBgColor = colors.yellow, colors.black
    menuOtherTextColor, menuOtherBgColor = colors.black, colors.gray
else
    menuMainTextColor, menuMainBgColor = colors.white, colors.black
    menuOtherTextColor, menuOtherBgColor = colors.black, colors.gray
end

local function redrawMenu()
    if bShowMenu then
        -- Draw menu
        parentTerm.setCursorPos(1, 1)
        parentTerm.setBackgroundColor(menuOtherBgColor)
        parentTerm.clearLine()
        local nCharCount = 0
        local nSize = parentTerm.getSize()
        if nScrollPos ~= 1 then
            parentTerm.setTextColor(menuOtherTextColor)
            parentTerm.setBackgroundColor(menuOtherBgColor)
            parentTerm.write("<")
            nCharCount = 1
        end
        for n = nScrollPos, #tProcesses do
            if n == nCurrentProcess then
                parentTerm.setTextColor(menuMainTextColor)
                parentTerm.setBackgroundColor(menuMainBgColor)
            else
                parentTerm.setTextColor(menuOtherTextColor)
                parentTerm.setBackgroundColor(menuOtherBgColor)
            end
            parentTerm.write(" " .. tProcesses[n].sTitle .. " ")
            nCharCount = nCharCount + #tProcesses[n].sTitle + 2
        end
        if nCharCount > nSize then
            parentTerm.setTextColor(menuOtherTextColor)
            parentTerm.setBackgroundColor(menuOtherBgColor)
            parentTerm.setCursorPos(nSize, 1)
            parentTerm.write(">")
            bScrollRight = true
        else
            bScrollRight = false
        end

        -- Put the cursor back where it should be
        local tProcess = tProcesses[nCurrentProcess]
        if tProcess then
            tProcess.window.restoreCursor()
        end
    end
end

local function resizeWindows()
    local windowY, windowHeight
    if bShowMenu then
        windowY = 2
        windowHeight = h - 1
    else
        windowY = 1
        windowHeight = h
    end
    for n = 1, #tProcesses do
        local tProcess = tProcesses[n]
        local x, y = tProcess.window.getCursorPos()
        if y > windowHeight then
            tProcess.window.scroll(y - windowHeight)
            tProcess.window.setCursorPos(x, windowHeight)
        end
        tProcess.window.reposition(1, windowY, w, windowHeight)
    end
    bWindowsResized = true
end

local function setMenuVisible(bVis)
    if bShowMenu ~= bVis then
        bShowMenu = bVis
        resizeWindows()
        redrawMenu()
    end
end

local multishell = {} --- @export

--- Get the currently visible process. This will be the one selected on
-- the tab bar.
--
-- Note, this is different to @{getCurrent}, which returns the process which is
-- currently executing.
--
-- @treturn number The currently visible process's index.
-- @see setFocus
function multishell.getFocus()
    return nCurrentProcess
end

--- Change the currently visible process.
--
-- @tparam number n The process index to switch to.
-- @treturn boolean If the process was changed successfully. This will
-- return @{false} if there is no process with this id.
-- @see getFocus
function multishell.setFocus(n)
    expect(1, n, "number")
    if n >= 1 and n <= #tProcesses then
        selectProcess(n)
        redrawMenu()
        return true
    end
    return false
end

--- Get the title of the given tab.
--
function multishell.setTitle(n, title)
    expect(1, n, "number")
    expect(2, title, "string")
    if Perms.isPermitted("kernel")
    then
        if n >= 1 and n <= #tProcesses then
            setProcessTitle(n, title)
            redrawMenu()
        end
    end
end
-- This starts as the name of the program, but may be changed using
-- @{multishell.setTitle}.
-- @tparam number n The process index
-- @treturn string|nil The current process title, or @{nil} if th
-- process doesn't exist.
function multishell.getTitle(n)
    expect(1, n, "number")
    if n >= 1 and n <= #tProcesses then
        return tProcesses[n].sTitle
    end
    return nil
end

--- Set the title of the given process.
--
-- @tparam number n The process index.
-- @tparam string title The new process title.
-- @see getTitle
-- @usage Change the title of the current process
--
--- Get the index of the currently running process.
--
-- @treturn number The currently running process.
function multishell.getCurrent()
    return nRunningProcess
end


--- Start a new process, with the given environment, program and arguments.
--
-- The returned process index is not constant over the program's run. It can be
-- safely used immediately after launching (for instance, to update the title or
-- switch to that tab). However, after your program has yielded, it may no
-- longer be correct.
--
-- @tparam table tProgramEnv The environment to load the path under.
-- @tparam string sProgramPath The path to the program to run.
-- @param ... Additional arguments to pass to the program.
-- @treturn number The index of the created process.
-- @see os.run
-- @usage Run the "hello" program, and set its title to "Hello!"
--
--     local id = multishell.launch({}, "/rom/programs/fun/hello.lua")
--     multishell.setTitle(id, "Hello!")
function multishell.launch(tProgramEnv, sProgramPath, ...)
    expect(1, tProgramEnv, "table")
    expect(2, sProgramPath, "string")
    local previousTerm = term.current()
    setMenuVisible(#tProcesses + 1 >= 2)
    local nResult = launchProcess(false, tProgramEnv, sProgramPath, ...)
    redrawMenu()
    term.redirect(previousTerm)
    return nResult
end

--- Get the number of processes within this multishell.
--
-- @treturn number The number of processes.
function multishell.getCount()
    return #tProcesses
end

-- Begin
parentTerm.clear()
setMenuVisible(false)
launchProcess(true, {
    ["shell"] = shell,
    ["multishell"] = multishell,
    ["require"] = require,
    ["package"] = package,
}, "/gameplayOS/installation/usersENV/desktop.lua",...)

-- Run processes
while #tProcesses > 0 do
    -- Get the event
    local tEventData = table.pack(os.pullEventRaw())
    local sEvent = tEventData[1]
    if sEvent == "term_resize" then
        -- Resize event
        w, h = parentTerm.getSize()
        resizeWindows()
        redrawMenu()

    elseif sEvent == "char" or sEvent == "key" or sEvent == "key_up" or sEvent == "paste" or sEvent == "terminate" then
        -- Keyboard event
        -- Passthrough to current process
        resumeProcess(nCurrentProcess, table.unpack(tEventData, 1, tEventData.n))
        if cullProcess(nCurrentProcess) then
            setMenuVisible(#tProcesses >= 2)
            redrawMenu()
        end

    elseif sEvent == "mouse_click" then
        -- Click event
        local button, x, y = tEventData[2], tEventData[3], tEventData[4]
        if bShowMenu and y == 1 then
            -- Switch process
            if x == 1 and nScrollPos ~= 1 then
                nScrollPos = nScrollPos - 1
                redrawMenu()
            elseif bScrollRight and x == term.getSize() then
                nScrollPos = nScrollPos + 1
                redrawMenu()
            else
                local tabStart = 1
                if nScrollPos ~= 1 then
                    tabStart = 2
                end
                for n = nScrollPos, #tProcesses do
                    local tabEnd = tabStart + #tProcesses[n].sTitle + 1
                    if x >= tabStart and x <= tabEnd then
                        selectProcess(n)
                        redrawMenu()
                        break
                    end
                    tabStart = tabEnd + 1
                end
            end
        else
            -- Passthrough to current process
            resumeProcess(nCurrentProcess, sEvent, button, x, bShowMenu and y - 1 or y)
            if cullProcess(nCurrentProcess) then
                setMenuVisible(#tProcesses >= 2)
                redrawMenu()
            end
        end

    elseif sEvent == "mouse_drag" or sEvent == "mouse_up" or sEvent == "mouse_scroll" then
        -- Other mouse event
        local p1, x, y = tEventData[2], tEventData[3], tEventData[4]
        if bShowMenu and sEvent == "mouse_scroll" and y == 1 then
            if p1 == -1 and nScrollPos ~= 1 then
                nScrollPos = nScrollPos - 1
                redrawMenu()
            elseif bScrollRight and p1 == 1 then
                nScrollPos = nScrollPos + 1
                redrawMenu()
            end
        elseif not (bShowMenu and y == 1) then
            -- Passthrough to current process
            resumeProcess(nCurrentProcess, sEvent, p1, x, bShowMenu and y - 1 or y)
            if cullProcess(nCurrentProcess) then
                setMenuVisible(#tProcesses >= 2)
                redrawMenu()
            end
        end
        
    elseif sEvent == "_CCPC_mobile_keyboard_open" and settings.get("shell.mobile_resize_with_keyboard") then
        -- Resize event
        w, h = parentTerm.getSize(), tEventData[2]
        resizeWindows()
        redrawMenu()
    
    elseif sEvent == "_CCPC_mobile_keyboard_close" and settings.get("shell.mobile_resize_with_keyboard") then
        -- Resize event
        w, h = parentTerm.getSize()
        resizeWindows()
        redrawMenu()

    else
        -- Other event
        -- Passthrough to all processes
        local nLimit = #tProcesses -- Storing this ensures any new things spawned don't get the event
        for n = 1, nLimit do
            resumeProcess(n, table.unpack(tEventData, 1, tEventData.n))
        end
        if cullProcesses() then
            setMenuVisible(#tProcesses >= 2)
            redrawMenu()
        end
    end

    if bWindowsResized then
        -- Pass term_resize to all processes
        local nLimit = #tProcesses -- Storing this ensures any new things spawned don't get the event
        for n = 1, nLimit do
            resumeProcess(n, "term_resize")
        end
        bWindowsResized = false
        if cullProcesses() then
            setMenuVisible(#tProcesses >= 2)
            redrawMenu()
        end
    end
end

-- Shutdown
os.shutdown()
