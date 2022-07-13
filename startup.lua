local old  = os.pullEvent
os.pullEvent = os.pullEventRaw
--clears screen
term.clear()
term.setCursorPos(1,1)
--decares vars and filters 
local list1 = fs.list("")
local isOs = {}
--declares functions

function menu(table,promt)
local running = true 
local count = 0
local sel = 1
while running do  
    term.clear()
    term.setCursorPos(1,1)
    term.setTextColor(colors.white)
        print(promt)
        for i,v in pairs(table) do 
            print("["..i.."]",table[i])
            count = i
        end
    print("selected option","["..sel.."]")
    local event, key = os.pullEvent("key")
        if key == keys.up
            then 
                if sel > 1 
                    then
                        sel = sel - 1
                end
            end
        if key == keys.down
        then 
            if sel < count 
                then 
             sel = sel + 1 
            end
        end
        if key == keys.enter
            then
            return sel
        end
    end
end

function clearterm()
    term.setBackgroundColour(colours.black)
    term.setTextColor(colours.white)
    term.clear()
    term.setCursorPos(1,1)
end


local function store(table,file)
local myfile = fs.open("boot/"..file,"w")
myfile.write(textutils.serialize(table))
myfile.close()
end 

local function readfile(file)
local temp = ""
local datafile = fs.open("boot/"..file,"r")
if datafile 
then
temp = datafile.readAll()
datafile.close()
datafile = nil
end
return temp
end

--draws boot img
if (not term.isColor())
then
error("requires advance computer")
end
local x,y = term.getSize()
term.setCursorPos(x/2.56,1)
term.write("boot manager")
sleep(.10)
paintutils.drawImage(paintutils.loadImage("boot/img.jepg"),1,1)
sleep(1)
-- main

if (not fs.exists("bootscreen.lua")) and (fs.exists(readfile("autoload.settings")) and readfile("autoload.settings") ~= "")
then
clearterm()
list1 = nil
isOs = nil
os.pullEvent = old
shell.run(readfile("autoload.settings"))
else
    if fs.exists("bootscreen.lua")
    then
    fs.delete("bootscreen.lua")
    end
    for I,value in pairs(list1) do 
        if I-1 ~= 0 
            then
            if fs.isDir(list1[I])  
                then 
                if fs.exists(list1[I].."/installation/kernel/kernel.lua")
                then
                    table.insert(isOs,list1[I])                 
                end
            end
        end
    end
clearterm()
table.insert(isOs,"CraftOs")
local choice = menu(isOs,"select OS")
local choice2 = nil
if isOs[choice] ~= "CraftOs"
then
 choice2 = menu({"yes","no"},"autoload program?")
else
    choice2 = 2
end
clearterm()
if choice2 == 1
then 
store(isOs[choice].."/installation/kernel/kernel.lua","autoload.settings")
choice2 = nil
end
if isOs[choice] == "CraftOs"
then
   list1 = nil
   isOs = nil
   choice = nil
   return
else
list1 = nil
print(isOs[choice].."/installation/kernel/kernel.lua")
os.pullEvent = old
shell.run(isOs[choice].."/installation/kernel/kernel.lua")
end
end

