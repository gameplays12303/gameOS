
function overwrite(path,data)
    if path == nil or data == nil
    then
        return "use to overwrite/make a file"
    end
    local handle = fs.open(path,"w")
    handle.write(textutils.serialize(data))
    handle.close()
    handle = nil
    return true
end
function readAll(path)
    if path == nil
    then
        return "first please provided a path, second used to read from file properly "
    end
    local handle = fs.open(path,"r")
    local data = textutils.unserialise(handle.readAll())
    handle.close()
    handle = nil
    return data
end
function amend(path,data)
    if path == nil and data == nil
    then
        return "used to write to a file without clearing/overwriting it "
    end
    local handle = fs.open(path,"a")
    handle.write(textutils.serialize(data))
    handle.close()
    handle = nil
    return true

end
function delete(path)
    fs.delete(path)
end
function readline()
    print(
        "to use read line use the fs APi in instead as i can not put proper function in here ",
        "also make sure to close the file useing 'handle.close() or you will cause memory leaks'"
    )
end