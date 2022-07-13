function mkuser(username,isadmin,password)
    if Perms.isPermitted("userman")
    then
        local path = "users/"..username
        if type(isadmin) ~= "boolean"
        then
            error("admin? must be a boolean")
        end
        local olduser = kernel.current_user()
        kernel.setuser("installer")
        fs.makeDir(path)
        fs.makeDir(path.."/documets")
        fs.makeDir(path.."/appadata")
        fs.makeDir(path.."/appadata/desktop")
        fs.setowner(path.."/documets",username)
        fs.setowner(path.."/appadata",username)
        fs.setowner(path.."/appadata/desktop",username)
        sys.makefile(path,username,isadmin,password)
        kernel.setuser(olduser)
    else
        error("not allowed to use users_system")
    end
end
function getpassword(username)
    if Perms.isPermitted("userman")
    then
        local Table = sys.getdata("users/"..username,username)
        return Table[2][2]
    else
        error("not allowed to use users_system")
    end

end

function setnewpassword(username,password,newpassword)
    if Perms.isPermitted("userman")
    then
        local Table = sys.getdata("users/"..username,username)
        if password
        then
            if Table[2][2] == enycript.enystring(tostring(password))
            then
                Table[2][2] = enycript.enystring(tostring(newpassword))
                sys.setData("users/"..username,username,Table)
            end
        end
    else
        error("not allowed to use users_system")
    end
end