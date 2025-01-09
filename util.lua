local screen = {guiGetScreenSize()}
function isMouseInPosition(x, y, width, height, ...)
	if not isCursorShowing() then
		return false
	end
	
	local cx, cy = getCursorPosition()
	local cursorX, cursorY = cx * screen[1], cy * screen[2]
	
	local targetX, targetY = x, y
	local targetWidth, targetHeight = width, height
	
	if cursorX >= targetX and cursorX <= targetX + targetWidth and cursorY >= targetY and cursorY <= targetY + targetHeight then
		return true
	else
		return false
	end
end

function dxDrawTextOnRectangle(texto, posX, posY, width, height, fuente, alignX, alignY, color, posGui)
	dxDrawRectangle( posX, posY, width, height, color, posGui or false )
	dxDrawText(texto, posX, posY, width+posX, height+posY, tocolor(255,255,255,255), 1, fuente or "arial", alignX or "center", alignY or "center", false, true, posGui or false, false, false)
end
function isMouseOnGuiElement(guiElement, guiElementParent)
    if isCursorShowing() and isElement(guiElement) then
        local sx, sy = guiGetScreenSize()
        local x, y = getCursorPosition()
        local wx, wy = 0, 0
        x, y = x * sx, y * sy
        if guiElementParent and isElement(guiElementParent) then
            wx, wy = guiGetPosition(guiElementParent, false)
        end
        local bx, by = guiGetPosition(guiElement, false)
        local ex, ey = guiGetSize(guiElement, false)
        if x >= wx + bx and x <= wx + bx + ex and y >= wy + by and y <= wy + by + ey then
            return true
        end
        return false
    end
end
