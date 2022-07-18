local pull = os.pullEvent
os.pullEvent = os.pullEventRaw
local x,y = term.getSize()
screen.clearscreen(1,1,colors.blue,colors.white)
local users = fs.find("users/*")
for i,v in pairs(users) do
    if string.find(users[i],".reg1")
    then
        table.remove(users, i)
    end
end
local function menu(Table,promt)
    local running = true 
    local count = 0
    local sel = 1
    while running do  
        term.clear()
        term.setCursorPos(1,1)
        term.setTextColor(colors.white)
            print(promt)
            for i,v in pairs(Table) do 
                print("["..i.."]",Table[i])
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
local x,y = term.getSize()
if #users == 0
then
    local sel = menu({"no","yes"},"is this a public computer")
    if sel == 1
    then
        local Table = {}
        screen.clear(x/2-17,y/2-2)
        print("lets set up this computer shall we")
        term.setCursorPos(x/2-24,y/2-1)
        local password, username = nil
        print("first we will have to make a user file for you so lets go")
        sleep(5)
        screen.clear((x/2)-12,(y/2)-2)
        print("set your username")
        term.setCursorPos((x/2)-12,(y/2)-1)
        username = tostring(read())
        screen.clear((x/2)-12,(y/2)-2)
        print('now set your password')
        term.setCursorPos((x/2)-12,(y/2)-1)
        password = tostring(read())
        if password ~= nil
        then
        usersman.mkuser(username,true,enycript.enystring(tostring(password)))
        kernel.setuser(username)
        end
    else
        usersman.mkuser("public",true)
        kernel.setuser("public")
    end
end
screen.clearscreen(x/2-17,y/2-2,colors.blue,colors.white)
if kernel.current_user() == "installer"
then
    local a = true
    local username = ""
    local password = ""
    local running = true
    while a do 
        screen.clear((x/2)-12,(y/2)-2)
        print("username")
        term.setCursorPos((x/2)-12,(y/2)-1)
        username = tostring(read())
        if username == "public" and fs.exists("users/public")
        then
        kernel.setuser("public")
        break
        end
        screen.clear((x/2)-12,(y/2)-2)
        print("password")
        term.setCursorPos((x/2)-12,(y/2)-1)
        password = tostring(read())
        for i, v in pairs(users) do
            if users[i] == "users/"..username
            then
                if password ~= ""
                then
                    if enycript.enystring(password) == usersman.getpassword(username) 
                    then
                        kernel.setuser(username)
                        a = false
                    else
                        printError("incorrect  password")
                    end
                else
                    printError("invalid password")
                end
            else
                printError("users dose not exists")
            end
        end
    end
else
    error("all ready log on")
end
screen.clearscreen(1,1,colors.black,colors.white)
os.pullEvent = pull
