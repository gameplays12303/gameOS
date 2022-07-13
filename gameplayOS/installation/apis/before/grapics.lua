
function draw_asset(Table)
    for i,v in pairs(Table)do
        local x = Table[i][1]
        local y = Table [i][2]
        local img = paintutils.loadImage(Table[i][3])
        print(img)
        paintutils.drawImage(img,x,y)
    end
end

function drawCircle(r, x, y, c)
	if (r == nil) or (x == nil) or (y == nil) then
        error("Some params are empty")
    end
	local dX, dY, dYC = 0, 0, 0
	local cN = tonumber(c)
	while dY <= dX do
		dX = math.sqrt(r * r - dY * dY)
		dYC = dY / 1.5
		paintutils.drawPixel(x + dX, y - dYC, cN)
		paintutils.drawPixel(x + dX, y + dYC, cN)
		paintutils.drawPixel(x - dX, y - dYC, cN)
		paintutils.drawPixel(x - dX, y + dYC, cN)
		dY = dY + 1
	end
	dX, dY = 0, 0
	while dX <= dY do
		dY = math.sqrt(r * r - dX * dX)
		dYC = dY / 1.5
		paintutils.drawPixel(x + dX, y - dYC, cN)
		paintutils.drawPixel(x + dX, y + dYC, cN)
		paintutils.drawPixel(x - dX, y - dYC, cN)
		paintutils.drawPixel(x - dX, y + dYC, cN)
		dX = dX + 1
	end
end

function drawsquare(x,y,filledBox)
    if type(filledBox) ~= "boolean"
    then
        error("3#argument expected boolean")
    end
    if filledBox 
    then
        paintutils.drawFilledBox(x,y)
    else
        paintutils.drawBox(x,y)
    end
end