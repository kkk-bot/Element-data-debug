ElementDataDebug = {}

ElementDataDebug.menus = {}
ElementDataDebug.moving_element = nil
local settings = {
    funcs = {},
    blackImgPath = "images/black.png",
    blackImg = dxCreateTexture("images/black.png"),
    whitePath = "images/white.png",
    whiteImg = dxCreateTexture("images/white.png"),

    menuAlpha = 0.5,
    menuSize = { w = 250, h = 0 },

}

local screen = { guiGetScreenSize() }

local scaledValue = screen[2] / 1080
scaledValue = math.max(0.8, scaledValue)

ElementDataDebug.__index = ElementDataDebug

function ElementDataDebug:create(element, x, y)
    local instance = {}
    setmetatable(instance, ElementDataDebug)
    if instance then
        instance:constructor(element, x, y)
    end

    -- Static variables
end

function ElementDataDebug:setChildrenOfMenuInheritAlpha(menu, state)
    local matchCeguiSyntax = { [true] = "True", [false] = "False" }
    for _, child in ipairs(getElementChildren(menu)) do
        guiSetProperty(child, "InheritsAlpha", matchCeguiSyntax[state])
    end
end

function ElementDataDebug:constructor(element, x, y)
    self.type = tostring(getElementType(element))
    local name
    if self.type == "player" then
        name = getPlayerName(element):gsub("_", " ") or getPlayerName(element)
    elseif self.type == "vehicle" then
        name = getVehicleName(element)
    else
        name = getElementModel(element)
    end
    name = tostring(name)

    self.description = string.format("%s (%s) \n%s", name, self.type, tostring(element))

    self.element = element
    self.pos = { x = x, y = y }

    -- element data, previous element data
    self.data = getAllElementData(self.element) or {}
    
    self.previous_data = self.data

    local menu = self:createMenu()
    self:setChildrenOfMenuInheritAlpha(menu.window, false)


    --self:refreshEvery(3000)
    --addEventHandler("onClientRender", root, self.onRender)
end

function ElementDataDebug:addSubMenu(pos, dataName, dataValue)
    local menu = {}
    menu.window = guiCreateStaticImage(pos.x, pos.y, settings.menuSize.w * scaledValue, 20,
        settings.blackImgPath, false)
    guiSetAlpha(menu.window, settings.menuAlpha)
    menu.offset_y     = 0
    menu.spacing      = 20 
    menu.extraSpacing = 2 

    for k, v in pairs(dataValue) do
        self:addItem(menu, k, v)
    end

    self:setChildrenOfMenuInheritAlpha(menu.window, false)
    addEventHandler("onClientMouseLeave", menu.window, self.onSubMenuLeave)
    guiSetVisible(menu.window, false)
    table.insert(self.subMenus, menu)
    return menu.window
end

function ElementDataDebug:addItem(menu, dataName, dataValue, color)
    color = color or {255, 255, 255}
    local data = string.format("%s: %s", tostring(dataName), tostring(dataValue))
    local row = guiCreateLabel(0, menu.offset_y, settings.menuSize.w * scaledValue, 25, data, false,
        menu.window)
    
    guiLabelSetColor(row, color[1], color[2], color[3])
    addEventHandler("onClientMouseEnter", row, self.onItemEnter)
    addEventHandler("onClientMouseLeave", row, self.onItemLeave)
    addEventHandler("onClientGUIClick", row, self.onItemClicked)


    guiLabelSetVerticalAlign(row, "center")

    if type(dataValue) == "table" then
        local arrow = guiCreateStaticImage((settings.menuSize.w - 20) * scaledValue, 0, 20, 20, "images/nav.png", false, row)
        -- when I hover over the row it shows the sub menu
        local x, y = guiGetPosition(row, false)
        local subMenu = self:addSubMenu({ x = x + self.pos.x + settings.menuSize.w * scaledValue, y = y + self.pos.y },
            tostring(dataName), dataValue)
        setElementData(row, "menu", subMenu)
    end
    menu.offset_y = menu.offset_y + menu.spacing 

    local x, y = guiGetSize(menu.window, false)
    guiSetSize(menu.window, x, y + menu.spacing + menu.extraSpacing, false)
    return row
end

function ElementDataDebug:createMenu(pos)
    pos = pos or {}



    self.menu = {}
    self.subMenus = {}
    self.menu.offset_y     = 0
    self.menu.window = guiCreateStaticImage(0, 0, settings.menuSize.w * scaledValue,
        settings.menuSize.h * scaledValue, settings.blackImgPath, false)
    self.menu.description_window = guiCreateStaticImage(0, 0, settings.menuSize.w * scaledValue, 40, settings.blackImgPath, false)
    self.menu.description = guiCreateLabel(0, 0, settings.menuSize.w * scaledValue, 40, self.description,
        false, self.menu.description_window)
    bindKey("mouse3", "down", ElementDataDebug.onTitleMoved, self.menu)
    bindKey("mouse3", "up", ElementDataDebug.cancelTitleMoved, self.menu)
    self.menu.refresh = guiCreateStaticImage((settings.menuSize.w - 20) * scaledValue, 0, 20,
        20, "images/refresh.png", false, self.menu.description)
    self.menu.close = guiCreateStaticImage(0, 0, 20, 20, "images/x.png", false,
        self.menu.description)
    setElementData(self.menu.window, "subMenus", self.subMenus)
    setElementData(self.menu.close, "subMenus", self.subMenus)

    addEventHandler("onClientMouseWheel", self.menu.window, function(arg1)
        self:onMenuScroll(arg1)
    end)
    addEventHandler("onClientGUIClick", self.menu.close, function()
        self:onDestroyMenu()
    end)
    addEventHandler("onClientGUIClick", self.menu.refresh, function()
        self:onRefreshMenu()
    end)
    guiSetAlpha(self.menu.window, settings.menuAlpha)
    guiSetAlpha(self.menu.description_window, settings.menuAlpha)
    self:setChildrenOfMenuInheritAlpha(self.menu.description_window, false)


    local seperator = guiCreateStaticImage(0, 40-5, settings.menuSize.w * scaledValue, 1,
        settings.whitePath, false, self.menu.description)

    guiLabelSetHorizontalAlign(self.menu.description, "center")
    guiSetFont(self.menu.description, "default-bold")

    self.menu.spacing      = 20
    self.menu.extraSpacing = 2

    
    table.insert(ElementDataDebug.menus, self.menu)
    
    self:fillMenu(self.data)
    
    -- Set the y-pos back as default
    guiSetPosition(self.menu.window, pos.x or self.pos.x, (pos.y or self.pos.y)+40, false)
    guiSetPosition(self.menu.description_window, pos.x or self.pos.x, pos.y or self.pos.y, false)
    
    ElementDataDebug.computeMenuCoordinates(self.menu.window)

    return self.menu
end

function ElementDataDebug:fillMenu(data)
    self.data = data
    for k, v in pairs(self.data) do
        local item
        if type(v) ~= "table" then
            if v ~= self:previous_getDataValueFromKey(k) then
                item = self:addItem(self.menu, k, v, { 255, 0, 0 })
            else
                item = self:addItem(self.menu, k, v)
            end
        else
            item = self:addItem(self.menu, k, v)
        end
        setElementData(item, "key", k)
        setElementData(item, "value", v)
    end
end

function ElementDataDebug:previous_getDataValueFromKey(key)
    for k, v in pairs(self.previous_data) do
        if k == key then
            return v
        end
    end
end
function ElementDataDebug:onTitleMoved(state, menu)
    if isMouseOnGuiElement(menu.description_window) then
        ElementDataDebug.moving_element = menu
        addEventHandler("onClientRender", root, ElementDataDebug.onRender)
    end
    --if isMouseOnGuiElement(title, parent) then
    --end
end
function ElementDataDebug:cancelTitleMoved(state)
    ElementDataDebug.moving_element = nil
    removeEventHandler("onClientRender", root, ElementDataDebug.onRender)
end

function ElementDataDebug:onItemEnter()
    local menu = getElementData(source, "menu")
    if menu then
        guiSetVisible(menu, true)
        guiSetAlpha(menu, settings.menuAlpha)
    end
    guiSetAlpha(source, 0.3)
end

function ElementDataDebug.isMouseHoveringOnSubMenu(item)
    local subMenu = getElementData(item, "menu")
    if not subMenu then
        return false
    else
        if isMouseOnGuiElement(subMenu) then
            return true
        end
        for _, v in ipairs(getElementChildren(subMenu)) do
            local sub = getElementData(v, "menu")
            if sub then
                return ElementDataDebug.isMouseHoveringOnSubMenu(sub)
            end
        end
    end
end
function ElementDataDebug:onItemLeave()
    -- when I leave, but the mouse hovering on it's sub menus, don't hide it
    local menu = getElementData(source, "menu")
    if menu then
        -- it has a SUB MENU

        -- check if the mouse is hovering on the sub menu
        if ElementDataDebug.isMouseHoveringOnSubMenu(source) then
            return
        end
        

        -- if is's parent is a menu then disable it
        local parent = getElementParent(source)
        local grandparent = getElementParent(parent)
        if not grandparent and parent then
            guiSetVisible(parent, false)
        end

        guiSetVisible(menu, false)
    end
    local soureType = getElementType(source)
    if soureType == "gui-label" then
        guiSetAlpha(source, 1)
    else
        guiSetAlpha(source, settings.menuAlpha)
    end
end

function ElementDataDebug:onSubMenuLeave()
    --local parent = getElementParent(source)
    --if getElementType(parent) == "gui-staticimage" then
    --    if not isMouseOnGuiElement(parent) then
    --        guiSetVisible(parent, false)
    --    end
    --end
end

function ElementDataDebug:onItemClicked()
    local text = guiGetText(source) or ""
    setClipboard(text)
    outputChatBox(text)
end

function ElementDataDebug:onDestroyMenu()
    local menu = self.menu.window
    local subMenus = self.subMenus

    for _, v in pairs(subMenus) do
        removeEventHandler("onClientMouseLeave", v.window, self.onSubMenuLeave)
        destroyElement(v.window)
    end
    
    destroyElement(menu)
    destroyElement(self.menu.description_window)
end

function ElementDataDebug:onRefreshMenu()
    local x, y = guiGetPosition(self.menu.description_window, false)
    self.data = getAllElementData(self.element) or {}
    self:onDestroyMenu()
    self:createMenu({ x = x, y = y })
    self:setChildrenOfMenuInheritAlpha(self.menu.window, false)


    self.previous_data = self.data
end

function ElementDataDebug:refreshEvery(timeToRefresh) -- in ms
    setTimer(function ()
        self:onRefreshMenu()
    end, timeToRefresh, 0)
end

function ElementDataDebug:onRender()
    if ElementDataDebug.moving_element then
        ElementDataDebug:moveMenu()
    end
end
function ElementDataDebug:moveMenu()
    if isCursorShowing() and ElementDataDebug.moving_element.description_window and ElementDataDebug.moving_element.window and isElement(ElementDataDebug.moving_element.description_window) and isElement(ElementDataDebug.moving_element.window) then
        local sx, sy = getCursorPosition()
        local x, y = sx * screen[1], sy * screen[2]
        local padding_x = settings.menuSize.w / 2
        local padding_y = -40 / 2
        local padding_y_description = 40 / 2
        guiSetPosition(ElementDataDebug.moving_element.description_window, x - padding_x, y - padding_y_description, false)
        guiSetPosition(ElementDataDebug.moving_element.window,             x - padding_x, y - padding_y , false)
    
        ElementDataDebug.computeMenuCoordinates(ElementDataDebug.moving_element.window)
    end
end

-- when scrolling down or up the menu should move up or down
function ElementDataDebug:onMenuScroll(upOrDown)
    if self.menu.window and isElement(self.menu.window) then
        local row_space = 20
        -- we gonna start from the first row, re-position all children
        local children = getElementChildren(self.menu.window)
        local _, y = guiGetPosition(children[1], false)
        local offset = 0
        local scroll_distance = 1
        -- if last element position less than the menu height, return
        local last_x, last_y = guiGetPosition(children[#children], false)
        local last_w, last_h = guiGetSize(children[#children], false)
        if upOrDown == -1 and last_y + last_h + last_h/2 <= screen[2] then
            return
        end
        if last_y + last_h <= settings.menuSize.h * scaledValue then
            return
        end


        if upOrDown == 1 then -- up
            offset = offset + row_space * scroll_distance
        else
            offset = offset - row_space * scroll_distance
        end
        for k, v in ipairs(children) do
            if k == 1 then
                if y+offset >= 20 then return end

            end
            local x, _ = guiGetPosition(v, false)
            guiSetPosition(v, x, y + offset, false)

            if getElementData(v, "menu") then -- set the submenu-y same
                local subMenu = getElementData(v, "menu")
                local x, _ = guiGetPosition(subMenu, false)
                local _, parent_y = guiGetPosition(self.menu.window, false)
                -- x+self.pos.x+settings.menuSize.w*scaledValue, y=y+self.pos.y
                guiSetPosition(subMenu, x, (y + offset) + parent_y, false)
                ElementDataDebug.computeMenuCoordinates(subMenu)
            end
            offset = offset + row_space
        end
    end
end

function ElementDataDebug.matchHeightSubMenu(item)
    local menu = getElementData(item, "menu")
    if not menu then
        return
    else
        local parent = getElementParent(item)
        local p_x, p_y = guiGetPosition(parent, false)
        local x, y = guiGetPosition(item, false)
        guiSetPosition(menu, x + settings.menuSize.w * scaledValue + p_x, y + p_y, false)
        -- now check the item in the sub menu
        local children = getElementChildren(menu)
        for k, v in ipairs(children) do
            ElementDataDebug.matchHeightSubMenu(v)
        end
    end
end

function ElementDataDebug.computeMenuCoordinates(menu)
    for _, item in ipairs(getElementChildren(menu)) do
        if getElementData(item, "menu") then
            ElementDataDebug.matchHeightSubMenu(item)
        end
    end
    guiSetAlpha(menu, settings.menuAlpha)
    ElementDataDebug.setChildrenOfMenuInheritAlpha(nil, menu, false)
end

addEventHandler("onClientDoubleClick", root,
    function(button, absoluteX, absoluteY, worldX, worldY, worldZ, clickedWorld)
        if button == "left" and clickedWorld and isElement(clickedWorld) then
            ElementDataDebug:create(clickedWorld, absoluteX, absoluteY)
        end
    end)
--local test = ElementDataDebug:create(localPlayer)


local debug_interiors = true
addCommandHandler("debug_interiors", function()
    debug_interiors = not debug_interiors
end)
-- INTERIORS DEBUG
-- FOR OWLGAMING Gamemode only.
addEventHandler("onClientRender", root, function ()
    if not debug_interiors then return end
    local onMouseClick = isCursorShowing() and getKeyState("mouse1") or false
    local pos = Vector3(getElementPosition(localPlayer))
    local int = getElementInterior(localPlayer)
    local dim = getElementDimension(localPlayer)
    for i, intElement in ipairs(getElementsByType("interior")) do
        local entrance = getElementData(intElement, "entrance")
        if entrance then
            local distance = 20
            local distanceBetweenPoints = getDistanceBetweenPoints3D(pos.x, pos.y, pos.z, entrance.x,entrance.y,entrance.z)
            if distanceBetweenPoints <= distance then
                local heightOffset = 1
                local px,py,pz = getScreenFromWorldPosition(entrance.x,entrance.y,entrance.z+heightOffset,0.05)
                if px and py then
                    if isMouseInPosition(px, py, 100, 50) then
                        dxDrawTextOnRectangle("DEBUG Element Data ", px, py, 100, 50, "arial", "center", "center", tocolor(0,0,0,50), false)
                        if onMouseClick then
                            ElementDataDebug:create(intElement, px, py)
                        end
                    else
                        dxDrawTextOnRectangle("DEBUG Element Data ", px, py, 100, 50, "arial", "center", "center", tocolor(0,0,0,100), false)
                    end
                end

            end
        
        end
    end
end)
