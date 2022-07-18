local open = fs.open
local mkdir = fs.mkdir
local delete = fs.delete
local string = "system/systemlog"
function write(path,name,data)
   if fs.exists(string.."/"..path.."/"..name..".log") 
   then
    local logs = open(string.."/"..path.."/"..name..".log","a")
    logs.writeLine(" "..os.day()..data.." ; ")
    logs.close()
    logs = nil
   else
    if not fs.exists(path)
    then
        mkdir(path)
    end
    local logs = open(string.."/"..path.."/"..name..".log","w")
    logs.writeLine(" "..os.day()..data.." ; ")
   logs.close()
   logs = nil
   end
end
function read(path,name)
    if fs.exists(string.."/"..path.."/"..name..".log")
    then
    local logs = open(string.."/"..path.."/"..name..".log","r")
    local data = textutils.unserialise(logs.readAll())
    logs.close()
    logs = nil
    return data
    else
    return "no logs"
    end
end
function deletelog(path,name)
    delete(string.."/"..path.."/"..name..".log")
    return true
end

function deletepath(path)
    delete(string.."/"..path)
end