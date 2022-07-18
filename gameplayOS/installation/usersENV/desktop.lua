button.setMonitor(term.current())
function run(programpath) 
    if fs.exists(programpath)
    then
    multishell.launch({ ["shell"] = shell,["multishell"] = multishell, ["require"] = require, },programpath)
    else
        error("program or path dose not exists")
    end
end
local shellB = button.create("shell")
shellB.setPos(1,1)
shellB.onClick(function () multishell.launch({ ["shell"] = shell,["multishell"] = multishell,["require"] = require,["package"] = package,},"rom/programs/shell.lua")end)
local lua = button.create("lua")
lua.setPos(7,1)
lua.onClick(function () multishell.launch({ ["shell"] = shell,["multishell"] = multishell, ["require"] = require, ["package"] = package, },"rom/programs/lua.lua")end)
local menu = button.create("power")
menu.setPos(11,1)
menu.onClick(
    function () 
    local shutdown = button.create("shutdown")
    local reboot = button.create("reboot")
    shutdown.setPos(12,2)
    reboot.setPos(12,3)
    shutdown.onClick(function () multishell.launch({ ["shell"] = shell,["multishell"] = multishell, },"gameplayOS/installation/usersENV/shutdown.lua") end)
    reboot.onClick(function() multishell.launch({ ["shell"] = shell,["multishell"] = multishell, },"gameplayOS/installation/usersENV/reboot.lua")end)
    button.await(shutdown,reboot)
    end
)
local fileExplorer = button.create("fileExplorer")
fileExplorer.setPos(17,1)
fileExplorer.onClick(function() multishell.launch({ ["shell"] = shell,["multishell"] = multishell, ["require"] = require, },"gameplayOS/installation/usersENV/fileExplorer.lua")end)

while not kernel.shuttingdown() do
screen.clear(1,1)
button.await(shellB,lua,fileExplorer,menu)
end



