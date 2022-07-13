function clearscreen(x,y,BC,TC)
    term.setBackgroundColor(BC)
    term.setTextColor(TC)
    term.clear()
    term.setCursorPos(x,y)
end
function clear(x,y)
    BC = term.getBackgroundColor()
    TC = term.getTextColor()
    term.setBackgroundColor(BC)
    term.setTextColor(TC)
    term.clear()
    term.setCursorPos(x,y)
end