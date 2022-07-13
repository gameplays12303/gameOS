local x,y = term.getSize()

local function desktopfolder()
   local list = fs.list("users/"..kernel.current_user().."/appadata/desktop/links/*")
   for i,v in ipairs(list) do
    if list[i] == "fs.reg1"
    then
        table.remove(list,i)
    end
   end
return list
end
local function desktop()
    local list = desktopfolder()
    return list
end
local function taskbar()

end
for i,v in pairs(desktop()) do 
print(desktop()[i])
end
