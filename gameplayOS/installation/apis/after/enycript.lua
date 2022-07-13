function enystring(input)
    local limit = #input
    local string = " "
    local Table = {}
    local i = 0
    repeat
        i = i+1
        string = string..string.char(string.byte(string.sub(input,i,#input))+10)
    until i == limit
    return string
end
function enynumbers(input)
    local i = 0
    repeat 
        i = i+1
        input = input + 2345676543245678
        sleep(.10)
    until i == 30
    return input
end