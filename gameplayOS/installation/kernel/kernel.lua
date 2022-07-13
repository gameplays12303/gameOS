local apis = fs.find("gameplayOS/installation/apis/before/*")
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
        local Table = readfile("gameplayOS/data/perms.reg1")
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
    Perms.setPerms = function(fullpath,giveperm)
        if Perms.isPermitted("full")
        then
           local mainTable = readfile("gameplayOS/data/perms.reg1")
           local Table,i = database.getTable(mainTable,fullpath)
           table.insert(mainTable[i][2],tostring(giveperm))
           store("gameplayOS/data/perms.reg1",mainTable)
           return mainTable
        else
            error("Permission denied",2)
        end
    end
    Perms.remPerms = function(ID,perm)
        if Perms.isPermitted("full")
        then
            local mainTable = readfile("gameplayOS/data/perms.reg1")
            local Table,i = database.getTable(mainTable,ID)
            for b,v in pairs(mainTable[i][2]) do
                if mainTable[i][2][b] == perm
                then
                table.remove(mainTable[i][2],b)
                end
            end
            store("gameplayOS/data/perms.reg1",mainTable)
        else
            error("Permission denied",2)
        end  
    end
    Perms.mkPerms = function(ID,...)
        if Perms.isPermitted("full") 
        then
            local mainTable = readfile("gameplayOS/data/perms.reg1")
            sleep(3)
            local Table = {ID,{...}}
            table.insert(mainTable,Table)
            store("gameplayOS/data/perms.reg1",mainTable)
            Table = nil
            ID = nil
            return true
        else
            error("Permission denied",2)
        end

    end
    -- starts the kernel apis
    kernel.shutingdown = function (boolean)
        if boolean ~= nil
        then
            if Perms.isPermitted("kernel") or Perms.isPermitted("shutdown")
            then
                core_registry[1][2] = boolean 
            else
                error("Permission denied",2)
            end
        else
            return core_registry[1][2]
        end
    end
    kernel.current_user = function()
       return  core_registry[2][2] 
    end
    kernel.setuser = function (user)
        if Perms.isPermitted("kernel")
        then
            if kernel.current_user() == "installer"
            then
            core_registry[2][2] = user
            return 
            end
            local Table = sys.getdata("users/"..kernel.current_user(),kernel.current_user())
            Table = Table[2][1]
            if Table
            then
                core_registry[2][2] = user
            else
                error("Permission denied "..kernel.current_user().." is not a admin",2)
            end
        else
            error("Permission denied",2)
        end
    end   


    -- starts the sys_registry APis
    local function sys_initialization(path,ID)
        local mainTable = readfile(path.."/sys.reg1")
        local Table,i = database.getTable(mainTable,ID)
        return Table,mainTable,i
    end
    
    sys.getdata = function(path,ID)
        if Perms.isPermitted("sys")
        then
           local Table,mainTable,i = sys_initialization(path,ID)
            return Table,mainTable,i
        else
            error("Permission denied",2)
        end
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
            error("Permission denied",2)
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
            error("Permission denied",2)
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
            error("Permission denied",2)
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
            error("Permission denied",2)
        end
    end



    -- starts the fs APis
    local function fs_initialization(fullpath)
        local path = fs.getDir(fullpath) 
        if path == ".."
        then
            path = ""
        end
        local name  = fs.getName(fullpath)
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
            error("Permission denied",2)
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
            error("Permission denied",2)
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
            error("Permission denied",2)
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
                local Table,mainTable,i = fs_initialization(path)
                Table = nil
                table.remove(mainTable,i)
                fs_store(path,mainTable)
                delete(path)
            else
                error(kernel.current_user().." dose not own, "..fs.getName(path),0)
            end
        else
            error("Permission denied",2)
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
            error("Permission denied",2)
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
            error("Permission denied",2)
        end
    end
    fs.listSubs = function (path)
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

    
    local apis = fs.find("/gameplayOS/installation/apis/after/*")
    for i,v in pairs(apis)do
        if not string.find(apis[i],"fs.reg1")
        then
        os.loadAPI(apis[i])
        end
    end
    screen.clear(1,1)
    CurrentProcess = "winlogon"
    shell.run("gameplayOS/installation/usersENV/winlogon.lua")
    CurrentProcess = "kernel"
    