ElementDataDebug = {}
local settings = {
    funcs = {},
    blackImgPath = "images/black.png",
    blackImg = dxCreateTexture("images/black.png"),
    whitePath = "images/white.png",
    whiteImg = dxCreateTexture("images/white.png"),

    menuAlpha=0.5,

}

local screen = {guiGetScreenSize()}

local scaledValue = screen[2]/1080

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
    local matchCeguiSyntax = {[true] = "True", [false] = "False"}
    for _, child in ipairs(getElementChildren(menu)) do
        guiSetProperty(child, "InheritsAlpha", matchCeguiSyntax[state])
    end
end



function ElementDataDebug:constructor(element, x, y)
    self.type = getElementType(element) or "nil"
    local name
    if self.type == "player" then
        name = getPlayerName(element):gsub("_", " ") or getPlayerName(element)
    elseif self.type == "vehicle" then
        name = getVehicleName(element)
    else 
        name = getElementModel(element)
    end
    
    self.description = string.format("%s (%s) \n%s", name, self.type, tostring(element))
    
    self.element = element
    self.pos = {x=x, y=y}

    self:navigateMenu()
    
end
function ElementDataDebug:addSubMenu (pos, dataName, dataValue)
    local menu = {}
    menu.subMenu_offset = pos.y
    menu.window = guiCreateStaticImage(pos.x, pos.y, 250*scaledValue, 20*scaledValue, settings.blackImgPath, false)
    guiSetAlpha(menu.window, settings.menuAlpha)
    menu.offset_y = 0
    menu.spacing = 20 * scaledValue
    menu.extraSpacing  = 2 * scaledValue

    for k, v in pairs(dataValue) do
        self:addItem(menu, k, v)
    end
    
    self:setChildrenOfMenuInheritAlpha(menu.window, false)
    addEventHandler("onClientMouseLeave", menu.window, self.onSubMenuLeave)
    guiSetVisible(menu.window, false)
    table.insert(self.subMenus, menu)
    return menu.window
end
function ElementDataDebug:addItem(menu, dataName, dataValue)
    local data = string.format("%s: %s", tostring(dataName), tostring(dataValue))
    local row = guiCreateLabel(0, menu.offset_y, 250*scaledValue, 25*scaledValue, data, false, menu.window)
    addEventHandler("onClientMouseEnter", row, self.onItemEnter)
    addEventHandler("onClientMouseLeave", row, self.onItemLeave)
    addEventHandler("onClientGUIClick", row, self.onItemClicked)

    
    guiLabelSetVerticalAlign(row, "center")
    
    if type(dataValue) == "table" then
        local arrow = guiCreateStaticImage(230*scaledValue, 0, 20*scaledValue, 20*scaledValue, "images/nav.png", false, row)
        -- when I hover over the row it shows the sub menu
        local x, y = guiGetPosition(row, false)
        local subMenu = self:addSubMenu({x=x+self.pos.x+250*scaledValue, y=y+self.pos.y}, tostring(dataName), dataValue)
        setElementData(row, "menu", subMenu)
    end
    menu.offset_y = menu.offset_y + menu.spacing 

    local x, y = guiGetSize(menu.window, false)
    guiSetSize(menu.window, x, y+menu.spacing, false)
end
function ElementDataDebug:navigateMenu()
    local _, desc_h = dxGetTextSize(self.description, 0, 1, 1, "default-bold")
    
    
    
    self.menu = {}
    self.subMenus = {}
    self.menu.window = guiCreateStaticImage(self.pos.x, self.pos.y, 250*scaledValue, 0, settings.blackImgPath, false)
    self.menu.description = guiCreateLabel(0, 0, 250*scaledValue, 40*scaledValue, self.description, false, self.menu.window)
    self.menu.refresh = guiCreateStaticImage(230*scaledValue, 0, 20*scaledValue, 20*scaledValue, "images/refresh.png", false, self.menu.description)
    self.menu.close = guiCreateStaticImage(0, 0, 20*scaledValue, 20*scaledValue, "images/x.png", false, self.menu.description)
    setElementData(self.menu.window, "subMenus", self.subMenus)
    setElementData(self.menu.close, "subMenus", self.subMenus)

    addEventHandler("onClientMouseWheel", root, function (arg1)
        self:onMenuScroll(arg1)
    end)
    addEventHandler("onClientGUIClick", self.menu.close, function ()
        self:onDestroyMenu()
        
    end)
    addEventHandler("onClientGUIClick", self.menu.refresh, function ()
        self:onRefreshMenu()
        
    end)
    guiSetAlpha(self.menu.window, settings.menuAlpha)
    

    local seperator = guiCreateStaticImage(0, 40*scaledValue, 250*scaledValue, 1*scaledValue, settings.whitePath, false, self.menu.description)
    
    guiLabelSetHorizontalAlign(self.menu.description, "center")
    guiSetFont(self.menu.description, "default-bold")

    self.menu.offset_y = 40 * scaledValue
    self.menu.spacing = 20 * scaledValue
    self.menu.extraSpacing  = 2 * scaledValue
    local elementData = getAllElementData(self.element)
    for k, v in pairs(elementData) do
        self:addItem(self.menu, k, v)
    end

    self:setChildrenOfMenuInheritAlpha(self.menu.window, false)


end


function ElementDataDebug:onItemEnter()
    local menu = getElementData(source, "menu")
    if menu then
        guiSetVisible(menu, true)
    end
    guiSetAlpha(source, 0.3)
end
function ElementDataDebug:onItemLeave()
    local menu = getElementData(source, "menu")
    if menu then
        if not isMouseOnGuiElement(menu) then
            guiSetVisible(menu, false)
        end
    end
    guiSetAlpha(source, 1)
end

function ElementDataDebug:onSubMenuLeave()
    local parent = getElementParent(source)
    if getElementType(parent) == "gui-staticimage" then
        if not isMouseOnGuiElement(parent) then
            guiSetVisible(parent, false)
        end
    end
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
end

function ElementDataDebug:onRefreshMenu()
    self:onDestroyMenu()
    self:navigateMenu()
end

-- when scrolling down or up the menu should move up or down
function ElementDataDebug:onMenuScroll(upOrDown)
    if self.menu.window and isElement(self.menu.window) then
        local row_space = 20* scaledValue
        local menu_offset = self.menu.offset_y
        -- we gonna start from the first row, re-position all children
        local children = getElementChildren(self.menu.window)
        local _, y = guiGetPosition(children[1], false)
        local offset = 0
        local scroll_distance = 1
        if upOrDown == 1 then -- up
            offset = offset + row_space*scroll_distance
        else
            offset = offset - row_space*scroll_distance
        end
        for k, v in ipairs(children) do
            local new_row_space = row_space
            if k == 1 then
                new_row_space = 40*scaledValue
                if y+offset > 10 then return end
            end
            local x, _ = guiGetPosition(v, false)
            guiSetPosition(v, x, y+offset, false)

            if getElementData(v, "menu") then -- set the submenu-y same
                local subMenu = getElementData(v, "menu")
                local x, _ = guiGetPosition(subMenu, false)
                -- x+self.pos.x+250*scaledValue, y=y+self.pos.y
                guiSetPosition(subMenu, x, (y+offset)+self.pos.y, false)
                for _, v in ipairs(getElementChildren(subMenu)) do
                    self:matchHeightSubMenu(v)
                end
            end
            offset = offset + new_row_space
        end

    end
end

function ElementDataDebug:matchHeightSubMenu(item)
    local menu = getElementData(item, "menu")
    if not menu then
        return
    else
        local parent = getElementParent(item)
        local p_x, p_y = guiGetPosition(parent, false)
        local x, y = guiGetPosition(item, false)
        guiSetPosition(menu, x+250*scaledValue+p_x, y+p_y, false)
        -- now check the item in the sub menu
        local children = getElementChildren(menu)
        for k, v in ipairs(children) do
            self:matchHeightSubMenu(v)
        end
    end
    
end




addEventHandler("onClientDoubleClick", root, function (button, absoluteX, absoluteY, worldX, worldY, worldZ, clickedWorld)
    if button == "left" and clickedWorld and isElement(clickedWorld) then
        ElementDataDebug:create(clickedWorld, absoluteX, absoluteY)
    end
end)
--local test = ElementDataDebug:create(localPlayer)
function isMouseOnGuiElement(guiElement,guiElementParent)
    if isCursorShowing() then
        local sx,sy = guiGetScreenSize()
        local x,y = getCursorPosition()
        local wx,wy = 0,0
        x,y = x*sx, y*sy
        if guiElementParent then
            wx,wy = guiGetPosition(guiElementParent,false)
        end
        local bx,by = guiGetPosition(guiElement,false)
        local ex,ey = guiGetSize(guiElement,false)
        if x >= wx+bx and x <= wx+bx+ex and y >= wy+by and y <= wy+by+ey then
            return true
        end
        return false
    end
end