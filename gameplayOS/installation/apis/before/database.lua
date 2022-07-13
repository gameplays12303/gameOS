function getTable(base,ID) 
    for i,v in pairs(base) do
        if (base[i])[1] == ID
        then
            return base[i],i
        end
    end
end
function set(base,ID,num,data)
    for i,v in ipairs(base) do
        if (base[i])[1] == ID
        then
            if (#base[i] < num)
            then
                error("invalid table index",2)
            end
            (base[i])[num] = data
        end
    end
end
function insert(Base,ID,data)
    if ID == nil
    then
        error("no ID",2)
    end
    if data == nil then
        error("no data",2)
    end
    local Table = {ID,data}
    table.insert(Base,Table)
end