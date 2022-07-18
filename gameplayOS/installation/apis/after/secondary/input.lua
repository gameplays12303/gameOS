
function prompt(message,clear,x,y,symbol)
    if x or y 
    then
        screen.clear(x,y)
    end
    print(message)
    return read(symbol)
end
function menu(Table,promt)
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
function buttions(Table)
    if type(Table) ~= "table" 
    then 
        error("table must be a 'table' ")
    end
    for i,v in pairs(Table) do 
        for a,v in pairs(Table[i]) do
            





        end
    end
    
end