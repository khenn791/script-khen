-- █▄░█ █ ▄▀▀░ ▄▀▀░ █▀ █▀▀▄
-- █░▀█ █ █░▀▌ █░▀▌ █▀ █▐█▀
-- ▀░░▀ ▀ ▀▀▀░ ▀▀▀░ ▀▀ ▀░▀▀



setfpscap(120) -- very troll lol



local Settings = {
    Accent = Color3.fromHex("#FF1493"),
    Font = Enum.Font.SourceSans,
    IsBackgroundTransparent = true,
    Rounded = false,
    Dim = false,
    
    ItemColor = Color3.fromRGB(67, 84, 147),
    BorderColor = Color3.fromRGB(50, 205, 50),
    MinSize = Vector2.new(430, 280),
    MaxSize = Vector2.new(430, 280)
}


local Menu = {}
local Tabs = {}
local Items = {}
local EventObjects = {} -- For updating items on menu property change
local Notifications = {}

local Scaling = {True = false, Origin = nil, Size = nil}
local Dragging = {Gui = nil, True = false}
local Draggables = {}
local ToolTip = {Enabled = false, Content = "", Item = nil}

local HotkeyRemoveKey = Enum.KeyCode.RightControl
local Selected = {
    Frame = nil,
    Item = nil,
    Offset = UDim2.new(),
    Follow = false
}
local SelectedTab
local SelectedTabLines = {}


local wait = task.wait
local delay = task.delay
local spawn = task.spawn
local protect_gui = function(Gui, Parent)
    if gethui and syn and syn.protect_gui then 
        Gui.Parent = gethui() 
    elseif not gethui and syn and syn.protect_gui then 
        syn.protect_gui(Gui)
        Gui.Parent = Parent 
    else 
        Gui.Parent = Parent 
    end
end

local CoreGui = game:GetService("CoreGui")
local UserInput = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")


local __Menu = {}
setmetatable(Menu, {
    __index = function(self, Key) return __Menu[Key] end,
    __newindex = function(self, Key, Value)
        __Menu[Key] = Value
        
        if Key == "Hue" or Key == "ScreenSize" then return end

        for _, Object in pairs(EventObjects) do Object:Update() end
        for _, Notification in pairs(Notifications) do Notification:Update() end
    end
})


Menu.Accent = Settings.Accent
Menu.Font = Settings.Font
Menu.IsBackgroundTransparent = Settings.IsBackgroundTransparent
Menu.Rounded = Settings.IsRounded
Menu.Dim = Settings.IsDim
Menu.ItemColor = Settings.ItemColor
Menu.BorderColor = Settings.BorderColor
Menu.MinSize = Settings.MinSize
Menu.MaxSize = Settings.MaxSize

Menu.Hue = 0
Menu.IsVisible = false
Menu.ScreenSize = Vector2.new()


local function AddEventListener(self: GuiObject, Update: any)
    table.insert(EventObjects, {
        self = self,
        Update = Update
    })
end





local function CreateCorner(Parent: Instance, Pixels: number): UICorner
    local UICorner = Instance.new("UICorner")
    UICorner.Name = "Corner"
    UICorner.Parent = Parent
    return UICorner
end


local function CreateStroke(Parent: Instance, Color: Color3, Thickness: number, Transparency: number): UIStroke
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Name = "Stroke"
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.LineJoinMode = Enum.LineJoinMode.Miter
    UIStroke.Color = Color or Color3.new()
    UIStroke.Thickness = Thickness or 1
    UIStroke.Transparency = Transparency or 0
    UIStroke.Enabled = true
    UIStroke.Parent = Parent
    return UIStroke
end 


local function CreateLine(Parent: Instance, Size: UDim2, Position: UDim2, Color: Color3): Frame
    local Line = Instance.new("Frame")
    Line.Name = "Line"
    Line.BackgroundColor3 = typeof(Color) == "Color3" and Color or Menu.Accent
    Line.BorderSizePixel = 0
    Line.Size = Size or UDim2.new(1, 0, 0, 1)
    Line.Position = Position or UDim2.new()
    Line.Parent = Parent

    if Line.BackgroundColor3 == Menu.Accent then
        AddEventListener(Line, function() Line.BackgroundColor3 = Menu.Accent end)
    end

    return Line
end


local function CreateLabel(Parent: Instance, Name: string, Text: string, Size: UDim2, Position: UDim2): TextLabel
    local Label = Instance.new("TextLabel")
    Label.Name = Name
    Label.BackgroundTransparency = 1
    Label.Size = Size or UDim2.new(1, 0, 0, 15)
    Label.Position = Position or UDim2.new()
    Label.Font = Enum.Font.SourceSans
    Label.Text = Text or ""
    Label.TextColor3 = Color3.new(1, 1, 1)
    Label.TextSize = 14
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Parent
    return Label
end


local function UpdateSelected(Frame: Instance, Item: Item, Offset: UDim2)
    local Selected_Frame = Selected.Frame
    if Selected_Frame then
        Selected_Frame.Visible = false
        Selected_Frame.Parent = nil
    end

    Selected = {}

    if Frame then
        if Selected_Frame == Frame then return end
        Selected = {
            Frame = Frame,
            Item = Item,
            Offset = Offset
        }

        Frame.ZIndex = 3
        Frame.Visible = true
        Frame.Parent = Menu.Screen
    end
end


local function SetDraggable(self: GuiObject)
    table.insert(Draggables, self)
    local DragOrigin
    local GuiOrigin

    local function startDragging(inputPosition)
        for _, v in ipairs(Draggables) do
            v.ZIndex = 1
        end
        self.ZIndex = 2

        Dragging = {Gui = self, True = true}
        DragOrigin = inputPosition
        GuiOrigin = self.Position
    end

    local function stopDragging()
        if Dragging.Gui == self then
            Dragging = {Gui = nil, True = false}
        end
    end

    local function updatePosition(inputPosition)
        if Dragging.Gui ~= self then return end
        if Dragging.True then
            local Delta = inputPosition - DragOrigin
            local ScreenSize = Menu.ScreenSize

            local ScaleX = (ScreenSize.X * GuiOrigin.X.Scale)
            local ScaleY = (ScreenSize.Y * GuiOrigin.Y.Scale)
            local OffsetX = math.clamp(GuiOrigin.X.Offset + Delta.X + ScaleX, 0, ScreenSize.X - self.AbsoluteSize.X)
            local OffsetY = math.clamp(GuiOrigin.Y.Offset + Delta.Y + ScaleY, -36, ScreenSize.Y - self.AbsoluteSize.Y)

            local Position = UDim2.fromOffset(OffsetX, OffsetY)
            self.Position = Position
        end
    end

    -- Mouse input
    self.InputBegan:Connect(function(Input: InputObject, Process: boolean)
        if (not Dragging.Gui and not Dragging.True) and (Input.UserInputType == Enum.UserInputType.MouseButton1) then
            startDragging(Vector2.new(Input.Position.X, Input.Position.Y))
        end
    end)

    UserInput.InputChanged:Connect(function(Input: InputObject, Process: boolean)
        if Input.UserInputType == Enum.UserInputType.MouseMovement then
            updatePosition(Vector2.new(Input.Position.X, Input.Position.Y))
        end
    end)

    UserInput.InputEnded:Connect(function(Input: InputObject, Process: boolean)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            stopDragging()
        end
    end)

    -- Touch input
    self.InputBegan:Connect(function(Input: InputObject, Process: boolean)
        if (not Dragging.Gui and not Dragging.True) and (Input.UserInputType == Enum.UserInputType.Touch) then
            local touchPosition = Input.Position
            startDragging(touchPosition)
        end
    end)

    UserInput.TouchMoved:Connect(function(Input: InputObject)
        if Input.UserInputType == Enum.UserInputType.Touch then
            updatePosition(Input.Position)
        end
    end)

    UserInput.TouchEnded:Connect(function(Input: InputObject)
        if Input.UserInputType == Enum.UserInputType.Touch then
            stopDragging()
        end
    end)
end


Menu.Screen = Instance.new("ScreenGui")
Menu.Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
protect_gui(Menu.Screen, CoreGui)
Menu.ScreenSize = Menu.Screen.AbsoluteSize

local Menu_Frame = Instance.new("Frame")
local MenuScaler_Button = Instance.new("TextButton")
local Title_Label = Instance.new("TextLabel")
local Icon_Image = Instance.new("ImageLabel")
local TabHandler_Frame = Instance.new("Frame")
local TabIndex_Frame = Instance.new("Frame")
local Tabs_Frame = Instance.new("Frame")

local Notifications_Frame = Instance.new("Frame")
local MenuDim_Frame = Instance.new("Frame")
local ToolTip_Label = Instance.new("TextLabel")
local Modal = Instance.new("TextButton")

Menu_Frame.Name = "Menu"
Menu_Frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
Menu_Frame.BorderColor3 = Color3.fromRGB(40, 40, 40)
Menu_Frame.BorderMode = Enum.BorderMode.Inset
Menu_Frame.Position = UDim2.new(0.5, -250, 0.5, -275)
Menu_Frame.Size = UDim2.new(0, 550, 0, 350)
Menu_Frame.Visible = false
Menu_Frame.Parent = Menu.Screen
CreateStroke(Menu_Frame, Color3.new(), 2)
CreateLine(Menu_Frame, UDim2.new(1, -8, 0, 1), UDim2.new(0, 4, 0, 15))
SetDraggable(Menu_Frame)

MenuScaler_Button.Name = "MenuScaler"
MenuScaler_Button.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MenuScaler_Button.BorderColor3 = Color3.fromRGB(40, 40, 40)
MenuScaler_Button.BorderSizePixel = 0
MenuScaler_Button.Position = UDim2.new(1, -15, 1, -15)
MenuScaler_Button.Size = UDim2.fromOffset(15, 15)
MenuScaler_Button.Font = Enum.Font.SourceSans
MenuScaler_Button.Text = ""
MenuScaler_Button.TextColor3 = Color3.new(1, 1, 1)
MenuScaler_Button.TextSize = 14
MenuScaler_Button.AutoButtonColor = false
MenuScaler_Button.Parent = Menu_Frame
MenuScaler_Button.InputBegan:Connect(function(Input, Process)
    if Process then return end
    if (Input.UserInputType == Enum.UserInputType.MouseButton1) then
        UpdateSelected()
        Scaling = {
            True = true,
            Origin = Vector2.new(Input.Position.X, Input.Position.Y),
            Size = Menu_Frame.AbsoluteSize - Vector2.new(0, 36)
        }
    end
end)
MenuScaler_Button.InputEnded:Connect(function(Input, Process)
    if (Input.UserInputType == Enum.UserInputType.MouseButton1) then
        UpdateSelected()
        Scaling = {
            True = false,
            Origin = nil,
            Size = nil
        }
    end
end)

Icon_Image.Name = "Icon"
Icon_Image.BackgroundTransparency = 1
Icon_Image.Position = UDim2.new(0, 5, 0, 0)
Icon_Image.Size = UDim2.fromOffset(15, 15)
Icon_Image.Image = "rbxassetid://18689675910"
Icon_Image.Visible = false
Icon_Image.Parent = Menu_Frame

Title_Label.Name = "Title"
Title_Label.BackgroundTransparency = 1
Title_Label.Position = UDim2.new(0, 5, 0, 0)
Title_Label.Size = UDim2.new(1, -10, 0, 15)
Title_Label.Font = Enum.Font.SourceSans
Title_Label.Text = ""
Title_Label.TextColor3 = Color3.new(1, 1, 1)
Title_Label.TextSize = 14
Title_Label.TextXAlignment = Enum.TextXAlignment.Left
Title_Label.RichText = true
Title_Label.Parent = Menu_Frame

TabHandler_Frame.Name = "TabHandler"
TabHandler_Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
TabHandler_Frame.BorderColor3 = Color3.fromRGB(40, 40, 40)
TabHandler_Frame.BorderMode = Enum.BorderMode.Inset
TabHandler_Frame.Position = UDim2.new(0, 4, 0, 19)
TabHandler_Frame.Size = UDim2.new(1, -8, 1, -25)
TabHandler_Frame.Parent = Menu_Frame
CreateStroke(TabHandler_Frame, Color3.new(), 2)

TabIndex_Frame.Name = "TabIndex"
TabIndex_Frame.BackgroundTransparency = 1
TabIndex_Frame.Position = UDim2.new(0, 1, 0, 1)
TabIndex_Frame.Size = UDim2.new(1, -2, 0, 20)
TabIndex_Frame.Parent = TabHandler_Frame

Tabs_Frame.Name = "Tabs"
Tabs_Frame.BackgroundTransparency = 1
Tabs_Frame.Position = UDim2.new(0, 1, 0, 26)
Tabs_Frame.Size = UDim2.new(1, -2, 1, -25)
Tabs_Frame.Parent = TabHandler_Frame

Notifications_Frame.Name = "Notifications"
Notifications_Frame.BackgroundTransparency = 1
Notifications_Frame.Size = UDim2.new(1, 0, 1, 36)
Notifications_Frame.Position = UDim2.fromOffset(0, -36)
Notifications_Frame.ZIndex = 5
Notifications_Frame.Parent = Menu.Screen

ToolTip_Label.Name = "ToolTip"
ToolTip_Label.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ToolTip_Label.BorderColor3 = Menu.BorderColor
ToolTip_Label.BorderMode = Enum.BorderMode.Inset
ToolTip_Label.AutomaticSize = Enum.AutomaticSize.XY
ToolTip_Label.Size = UDim2.fromOffset(0, 0, 0, 15)
ToolTip_Label.Text = ""
ToolTip_Label.TextSize = 14
ToolTip_Label.Font = Enum.Font.SourceSans
ToolTip_Label.TextColor3 = Color3.new(1, 1, 1)
ToolTip_Label.ZIndex = 5
ToolTip_Label.Visible = false
ToolTip_Label.Parent = Menu.Screen
CreateStroke(ToolTip_Label, Color3.new(), 1)
AddEventListener(ToolTip_Label, function()
    ToolTip_Label.BorderColor3 = Menu.BorderColor
end)

Modal.Name = "Modal"
Modal.BackgroundTransparency = 1
Modal.Modal = true
Modal.Text = ""
Modal.Parent = Menu_Frame


--SelectedTabLines.Top = CreateLine(nil, UDim2.new(1, 0, 0, 1), UDim2.new())
SelectedTabLines.Left = CreateLine(nil, UDim2.new(0, 1, 1, 0), UDim2.new(), Color3.new())
SelectedTabLines.Right = CreateLine(nil, UDim2.new(0, 1, 1, 0), UDim2.new(1, -1, 0, 0), Color3.new())
SelectedTabLines.Bottom = CreateLine(TabIndex_Frame, UDim2.new(), UDim2.new(0, 0, 1, 0), Color3.new())
SelectedTabLines.Bottom2 = CreateLine(TabIndex_Frame, UDim2.new(), UDim2.new(), Color3.new())


local function GetDictionaryLength(Dictionary: table)
    local Length = 0
    for _ in pairs(Dictionary) do
        Length += 1
    end
    return Length
end


local function UpdateSelectedTabLines(Tab: Tab)
    if not Tab then return end

    if (Tab.Button.AbsolutePosition.X > Tab.self.AbsolutePosition.X) then
        SelectedTabLines.Left.Visible = true
    else
        SelectedTabLines.Left.Visible = false
    end

    if (Tab.Button.AbsolutePosition.X + Tab.Button.AbsoluteSize.X < Tab.self.AbsolutePosition.X + Tab.self.AbsoluteSize.X) then
        SelectedTabLines.Right.Visible = true
    else
        SelectedTabLines.Right.Visible = false
    end

    --SelectedTabLines.Top.Parent = Tab.Button
    SelectedTabLines.Left.Parent = Tab.Button
    SelectedTabLines.Right.Parent = Tab.Button

    local FRAME_POSITION = Tab.self.AbsolutePosition
    local BUTTON_POSITION = Tab.Button.AbsolutePosition
    local BUTTON_SIZE = Tab.Button.AbsoluteSize
    local LENGTH = BUTTON_POSITION.X - FRAME_POSITION.X
    local OFFSET = (BUTTON_POSITION.X + BUTTON_SIZE.X) - FRAME_POSITION.X

    SelectedTabLines.Bottom.Size = UDim2.new(0, LENGTH + 1, 0, 1)
    SelectedTabLines.Bottom2.Size = UDim2.new(1, -OFFSET, 0, 1)
    SelectedTabLines.Bottom2.Position = UDim2.new(0, OFFSET, 1, 0)
end


local function UpdateTabs()
    for _, Tab in pairs(Tabs) do
        Tab.Button.Size = UDim2.new(1 / GetDictionaryLength(Tabs), 0, 1, 0)
        Tab.Button.Position = UDim2.new((1 / GetDictionaryLength(Tabs)) * (Tab.Index - 1), 0, 0, 0)
    end
    UpdateSelectedTabLines(SelectedTab)
end


local function GetTab(Tab_Name: string): Tab
    assert(Tab_Name, "NO TAB_NAME GIVEN")
    return Tabs[Tab_Name]
end

local function ChangeTab(Tab_Name: string)
    assert(Tabs[Tab_Name], "Tab \"" .. tostring(Tab_Name) .. "\" does not exist!")
    for _, Tab in pairs(Tabs) do
        Tab.self.Visible = false
        Tab.Button.BackgroundColor3 = Menu.ItemColor
        Tab.Button.TextColor3 = Color3.fromRGB(205, 205, 205)
    end
    local Tab = GetTab(Tab_Name)
    Tab.self.Visible = true
    Tab.Button.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Tab.Button.TextColor3 = Color3.new(1, 1, 1)

    SelectedTab = Tab
    UpdateSelected()
    UpdateSelectedTabLines(Tab)
end


local function GetContainer(Tab_Name: string, Container_Name: string): Container
    assert(Tab_Name, "NO TAB_NAME GIVEN")
    assert(Container_Name, "NO CONTAINER NAME GIVEN")
    return GetTab(Tab_Name)[Container_Name]
end


local function CheckItemIndex(Item_Index: number, Method: string)
    assert(typeof(Item_Index) == "number", "invalid argument #1 to '" .. Method .. "' (number expected, got " .. typeof(Item_Index) .. ")")
    assert(Item_Index <= #Items and Item_Index > 0, "invalid argument #1 to '" .. Method .. "' (index out of range")
end


function Menu:GetItem(Index: number): Item
    CheckItemIndex(Index, "GetItem")
    return Items[Index]
end


function Menu:FindItem(Tab_Name: string, Container_Name: string, Class_Name: string, Name: string): Item
    local Result
    for Index, Item in ipairs(Items) do
        if Item.Tab == Tab_Name and Item.Container == Container_Name then
            if Item.Name == Name and (Item.Class == Class_Name) then
                Result = Index
                break
            end
        end
    end

    if Result then
        return Menu:GetItem(Result)
    else
        return error("Item " .. tostring(Name) .. " was not found")
    end
end


function Menu:SetTitle(Name: string)
    Title_Label.Text = tostring(Name)
end


function Menu:SetIcon(Icon: string)
    if typeof(Icon) == "string" or typeof(Icon) == "number" then
        Title_Label.Position = UDim2.fromOffset(20, 0)
        Title_Label.Size = UDim2.new(1, -40, 0, 15)
        Icon_Image.Image = "rbxassetid://" .. string.gsub(tostring(Icon), "rbxassetid://", "")
        Icon_Image.Visible = true
    else
        Title_Label.Position = UDim2.fromOffset(5, 0)
        Title_Label.Size = UDim2.new(1, -10, 0, 15)
        Icon_Image.Image = ""
        Icon_Image.Visible = false
    end
end


function Menu:SetSize(Size: UDim2)
    local Size = typeof(Size) == "Vector2" and Size or typeof(Size) == "UDim2" and Vector2.new(Size.X, Size.Y) or Menu.MinSize
    local X = Size.X
    local Y = Size.Y

    if (X > Menu.MinSize.X and X < Menu.MaxSize.X) then
        X = math.clamp(X, Menu.MinSize.X, Menu.MaxSize.X)
    end
    if (Y > Menu.MinSize.Y and Y < Menu.MaxSize.Y) then
        Y = math.clamp(Y, Menu.MinSize.Y, Menu.MaxSize.Y)
    end

    Menu_Frame.Size = UDim2.fromOffset(X, Y)
    UpdateTabs()
end


function Menu:SetVisible(Visible: boolean)
    local IsVisible = typeof(Visible) == "boolean" and Visible
    Menu_Frame.Visible = IsVisible
    Menu.IsVisible = IsVisible
    if IsVisible == false then
        UpdateSelected()
    end
end


function Menu:SetTab(Tab_Name: string)
    ChangeTab(Tab_Name)
end


-- this function should be private
function Menu:SetToolTip(Enabled: boolean, Content: string, Item: Instance)
    ToolTip = {
        Enabled = Enabled,
        Content = Content,
        Item = Item
    }

    ToolTip_Label.Visible = Enabled
end


function Menu.Line(Parent: Instance, Size: UDim2, Position: UDim2): Line
    local Line = {self = CreateLine(Parent, Size, Position)}
    Line.Class = "Line"
    return Line
end


function Menu.Tab(Tab_Name: string): Tab
    assert(Tab_Name and typeof(Tab_Name) == "string", "TAB_NAME REQUIRED")
    if Tabs[Tab_Name] then return error("TAB_NAME '" .. tostring(Tab_Name) .. "' ALREADY EXISTS") end
    local Frame = Instance.new("Frame")
    local Button = Instance.new("TextButton")

    local Tab = {self = Frame, Button = Button}
    Tab.Class = "Tab"
    Tab.Index = GetDictionaryLength(Tabs) + 1


    local function CreateSide(Side: string)
        local Frame = Instance.new("ScrollingFrame")
        local ListLayout = Instance.new("UIListLayout")

        Frame.Name = Side
        Frame.Active = true
        Frame.BackgroundTransparency = 1
        Frame.BorderSizePixel = 0
        Frame.Size = Side == "Middle" and UDim2.new(1, -10, 1, -10) or UDim2.new(0.5, -10, 1, -10)
        Frame.Position = (Side == "Left" and UDim2.fromOffset(5, 5)) or (Side == "Right" and UDim2.new(0.5, 5, 0, 5) or Side == "Middle" and UDim2.fromOffset(5, 5))
        Frame.CanvasSize = UDim2.new(0, 0, 0, -10)
        Frame.ScrollBarThickness = 2
        Frame.ScrollBarImageColor3 = Menu.Accent
        Frame.Parent = Tab.self
        AddEventListener(Frame, function()
            Frame.ScrollBarImageColor3 = Menu.Accent
        end)
        Frame:GetPropertyChangedSignal("CanvasPosition"):Connect(UpdateSelected)

        ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ListLayout.Padding = UDim.new(0, 10)
        ListLayout.Parent = Frame
    end


    Button.Name = "Button"
    Button.BackgroundColor3 = Menu.ItemColor
    Button.BorderSizePixel = 0
    Button.Font = Enum.Font.SourceSans
    Button.Text = Tab_Name
    Button.TextColor3 = Color3.fromRGB(205, 205, 205)
    Button.TextSize = 14
    Button.Parent = TabIndex_Frame
    AddEventListener(Button, function()
        if Button.TextColor3 == Color3.fromRGB(205, 205, 205) then
            Button.BackgroundColor3 = Menu.ItemColor
        end
        Button.BackgroundColor3 = Menu.ItemColor
        Button.BorderColor3 = Menu.BorderColor
    end)
    Button.MouseButton1Click:Connect(function()
        ChangeTab(Tab_Name)
    end)
    
    Frame.Name = Tab_Name .. "Tab"
    Frame.BackgroundTransparency = 1
    Frame.Size = UDim2.new(1, 0, 1, 0)
    Frame.Visible = false
    Frame.Parent = Tabs_Frame

    CreateSide("Middle")
    CreateSide("Left")
    CreateSide("Right")

    Tabs[Tab_Name] = Tab

    ChangeTab(Tab_Name)
    UpdateTabs()
    return Tab
end


function Menu.Container(Tab_Name: string, Container_Name: string, Side: string): Container
    local Tab = GetTab(Tab_Name)
    assert(typeof(Tab_Name) == "string", "TAB_NAME REQUIRED")
    if Tab[Container_Name] then return error("CONTAINER_NAME '" .. tostring(Container_Name) .. "' ALREADY EXISTS") end
    local Side = Side or "Left"

    local Frame = Instance.new("Frame")
    local Label = CreateLabel(Frame, "Title", Container_Name, UDim2.fromOffset(206, 15),  UDim2.fromOffset(5, 0))
    local Line = CreateLine(Frame, UDim2.new(1, -10, 0, 1), UDim2.fromOffset(5, 15))

    local Container = {self = Frame, Height = 0}
    Container.Class = "Container"
    Container.Visible = true

    function Container:SetLabel(Name: string)
        Label.Text = tostring(Name)
    end

    function Container:SetVisible(Visible: boolean)
        if typeof(Visible) ~= "boolean" then return end
        if self.Visible == Visible then return end
        
        Frame.Visible = Visible
        self.Visible = Visible
        self:UpdateSize(Visible and 25 or -25, Frame)
    end

    function Container:UpdateSize(Height: float, Item: GuiObject)
        self.Height += Height
        Frame.Size += UDim2.fromOffset(0, Height)
        Tab.self[Side].CanvasSize += UDim2.fromOffset(0, Height)

        if Item then
            local ItemY = Item.AbsolutePosition.Y
            if math.sign(Height) == 1 then
                ItemY -= 1
            end

            for _, item in ipairs(Frame:GetChildren()) do
                if (item == Label or item == Line or item == Stroke or Item == item) then continue end -- exlude these
                local item_y = item.AbsolutePosition.Y
                if item_y > ItemY then
                    item.Position += UDim2.fromOffset(0, Height)
                end
            end
        end
    end

    function Container:GetHeight(): number
        return self.Height
    end


    Frame.Name = "Container"
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Frame.BorderColor3 = Color3.new()
    Frame.BorderMode = Enum.BorderMode.Inset
    Frame.Size = UDim2.new(1, -6, 0, 0)
    Frame.Parent = Tab.self[Side]

    Container:UpdateSize(25)
    Tab.self[Side].CanvasSize += UDim2.fromOffset(0, 10)
    Tab[Container_Name] = Container
    return Container
end


function Menu.Label(Tab_Name: string, Container_Name: string, Name: string, ToolTip: string): Label
    local Container = GetContainer(Tab_Name, Container_Name)
    local GuiLabel = CreateLabel(Container.self, "Label", Name, nil, UDim2.fromOffset(20, Container:GetHeight()))

    GuiLabel.MouseEnter:Connect(function()
        if ToolTip then
            Menu:SetToolTip(true, ToolTip, GuiLabel)
        end
    end)
    GuiLabel.MouseLeave:Connect(function()
        if ToolTip then
            Menu:SetToolTip(false)
        end
    end)

    local Label = {self = Label}
    Label.Name = Name
    Label.Class = "Label"
    Label.Index = #Items + 1
    Label.Tab = Tab_Name
    Label.Container = Container_Name

    function Label:SetLabel(Name: string)
        GuiLabel.Text = tostring(Name)
    end

    function Label:SetVisible(Visible: boolean)
        if typeof(Visible) ~= "boolean" then return end
        if GuiLabel.Visible == Visible then return end
        
        GuiLabel.Visible = Visible
        Container:UpdateSize(Visible and 20 or -20, GuiLabel)
    end

    Container:UpdateSize(20)
    table.insert(Items, Label)
    return #Items
end


function Menu.Button(Tab_Name: string, Container_Name: string, Name: string, Callback: any, ToolTip: string): Button
    local Container = GetContainer(Tab_Name, Container_Name)
    local GuiButton = Instance.new("TextButton")

    local Button = {self = GuiButton}
    Button.Name = Name
    Button.Class = "Button"
    Button.Tab = Tab_Name
    Button.Container = Container_Name
    Button.Index = #Items + 1
    Button.Callback = typeof(Callback) == "function" and Callback or function() end

    
    function Button:SetLabel(Name: string)
        GuiButton.Text = tostring(Name)
    end

    function Button:SetVisible(Visible: boolean)
        if typeof(Visible) ~= "boolean" then return end
        if GuiButton.Visible == Visible then return end
        
        GuiButton.Visible = Visible
        Container:UpdateSize(Visible and 25 or -25, GuiButton)
    end


    GuiButton.Name = "Button"
    GuiButton.BackgroundColor3 = Menu.ItemColor
    GuiButton.BorderColor3 = Menu.BorderColor
    GuiButton.BorderMode = Enum.BorderMode.Inset
    GuiButton.Position = UDim2.fromOffset(20, Container:GetHeight())
    GuiButton.Size = UDim2.new(1, -50, 0, 20)
    GuiButton.Font = Enum.Font.SourceSansSemibold
    GuiButton.Text = Name
    GuiButton.TextColor3 = Color3.new(1, 1, 1)
    GuiButton.TextSize = 14
    GuiButton.TextTruncate = Enum.TextTruncate.AtEnd
    GuiButton.Parent = Container.self
    CreateStroke(GuiButton, Color3.new(), 1)
    AddEventListener(GuiButton, function()
        GuiButton.BackgroundColor3 = Menu.ItemColor
        GuiButton.BorderColor3 = Menu.BorderColor
    end)
    GuiButton.MouseButton1Click:Connect(function()
        Button.Callback()
    end)
    GuiButton.MouseEnter:Connect(function()
        if ToolTip then
            Menu:SetToolTip(true, ToolTip, GuiButton)
        end
    end)
    GuiButton.MouseLeave:Connect(function()
        Menu:SetToolTip(false)
    end)

    Container:UpdateSize(25)
    table.insert(Items, Button)
    return #Items
end


function Menu.TextBox(Tab_Name: string, Container_Name: string, Name: string, Value: string, Callback: any, ToolTip: string): TextBox
    local Container = GetContainer(Tab_Name, Container_Name)
    local Label = CreateLabel(Container.self, "TextBox", Name, nil, UDim2.fromOffset(20, Container:GetHeight()))
    local GuiTextBox = Instance.new("TextBox")

    local TextBox = {self = GuiTextBox}
    TextBox.Name = Name
    TextBox.Class = "TextBox"
    TextBox.Tab = Tab_Name
    TextBox.Container = Container_Name
    TextBox.Index = #Items + 1
    TextBox.Value = typeof(Value) == "string" and Value or ""
    TextBox.Callback = typeof(Callback) == "function" and Callback or function() end


    function TextBox:SetLabel(Name: string)
        Label.Text = tostring(Name)
    end

    function TextBox:SetVisible(Visible: boolean)
        if typeof(Visible) ~= "boolean" then return end
        if Label.Visible == Visible then return end
        
        Label.Visible = Visible
        Container:UpdateSize(Visible and 45 or -45, Label)
    end

    function TextBox:GetValue(): string
        return self.Value
    end

    function TextBox:SetValue(Value: string)
        self.Value = tostring(Value)
        GuiTextBox.Text = self.Value
    end


    GuiTextBox.Name = "TextBox"
    GuiTextBox.BackgroundColor3 = Menu.ItemColor
    GuiTextBox.BorderColor3 = Menu.BorderColor
    GuiTextBox.BorderMode = Enum.BorderMode.Inset
    GuiTextBox.Position = UDim2.fromOffset(0, 20)
    GuiTextBox.Size = UDim2.new(1, -50, 0, 20)
    GuiTextBox.Font = Enum.Font.SourceSansSemibold
    GuiTextBox.Text = TextBox.Value
    GuiTextBox.TextColor3 = Color3.new(1, 1, 1)
    GuiTextBox.TextSize = 14
    GuiTextBox.ClearTextOnFocus = false
    GuiTextBox.ClipsDescendants = true
    GuiTextBox.Parent = Label
    CreateStroke(GuiTextBox, Color3.new(), 1)
    AddEventListener(GuiTextBox, function()
        GuiTextBox.BackgroundColor3 = Menu.ItemColor
        GuiTextBox.BorderColor3 = Menu.BorderColor
    end)
    GuiTextBox.FocusLost:Connect(function()
        TextBox.Value = GuiTextBox.Text
        TextBox.Callback(GuiTextBox.Text)
    end)
    GuiTextBox.MouseEnter:Connect(function()
        if ToolTip then
            Menu:SetToolTip(true, ToolTip, GuiTextBox)
        end
    end)
    GuiTextBox.MouseLeave:Connect(function()
        if ToolTip then
            Menu:SetToolTip(false)
        end
    end)

    Container:UpdateSize(45)
    table.insert(Items, TextBox)
    return #Items
end


function Menu.CheckBox(Tab_Name: string, Container_Name: string, Name: string, Boolean: boolean, Callback: any, ToolTip: string): CheckBox
    local Container = GetContainer(Tab_Name, Container_Name)
    local Label = CreateLabel(Container.self, "CheckBox", Name, nil, UDim2.fromOffset(20, Container:GetHeight()))
    local Button = Instance.new("TextButton")
    
    local CheckBox = {self = Label}
    CheckBox.Name = Name
    CheckBox.Class = "CheckBox"
    CheckBox.Tab = Tab_Name
    CheckBox.Container = Container_Name
    CheckBox.Index = #Items + 1
    CheckBox.Value = typeof(Boolean) == "boolean" and Boolean or false
    CheckBox.Callback = typeof(Callback) == "function" and Callback or function() end


    function CheckBox:Update(Value: boolean)
        self.Value = typeof(Value) == "boolean" and Value
        Button.BackgroundColor3 = self.Value and Menu.Accent or Menu.ItemColor
    end

    function CheckBox:SetLabel(Name: string)
        Label.Text = tostring(Name)
    end

    function CheckBox:SetVisible(Visible: boolean)
        if typeof(Visible) ~= "boolean" then return end
        if Label.Visible == Visible then return end
        
        Label.Visible = Visible
        Container:UpdateSize(Visible and 20 or -20, Label)
    end

    function CheckBox:GetValue(): boolean
        return self.Value
    end

    function CheckBox:SetValue(Value: boolean)
        self:Update(Value)
    end


    Label.MouseEnter:Connect(function()
        if ToolTip then
            Menu:SetToolTip(true, ToolTip, Label)
        end
    end)
    Label.MouseLeave:Connect(function()
        if ToolTip then
            Menu:SetToolTip(false)
        end
    end)

    Button.BackgroundColor3 = Menu.ItemColor
    Button.BorderColor3 = Color3.new()
    Button.Position = UDim2.fromOffset(-14, 4)
    Button.Size = UDim2.fromOffset(8, 8)
    Button.Text = ""
    Button.Parent = Label
    AddEventListener(Button, function()
        Button.BackgroundColor3 = CheckBox.Value and Menu.Accent or Menu.ItemColor
    end)
    Button.MouseButton1Click:Connect(function()
        CheckBox:Update(not CheckBox.Value)
        CheckBox.Callback(CheckBox.Value)
    end)

    CheckBox:Update(CheckBox.Value)
    Container:UpdateSize(20)
    table.insert(Items, CheckBox)
    return #Items
end


function Menu.Hotkey(Tab_Name: string, Container_Name: string, Name: string, Key:EnumItem, Callback: any, ToolTip: string): Hotkey
    local Container = GetContainer(Tab_Name, Container_Name)
    local Label = CreateLabel(Container.self, "Hotkey", Name, nil, UDim2.fromOffset(20, Container:GetHeight()))
    local Button = Instance.new("TextButton")
    local Selected_Hotkey = Instance.new("Frame")
    local HotkeyToggle = Instance.new("TextButton")
    local HotkeyHold = Instance.new("TextButton")

    local Hotkey = {self = Label}
    Hotkey.Name = Name
    Hotkey.Class = "Hotkey"
    Hotkey.Tab = Tab_Name
    Hotkey.Container = Container_Name
    Hotkey.Index = #Items + 1
    Hotkey.Key = typeof(Key) == "EnumItem" and Key or nil
    Hotkey.Callback = typeof(Callback) == "function" and Callback or function() end
    Hotkey.Editing = false
    Hotkey.Mode = "Toggle"


    function Hotkey:Update(Input: EnumItem, Mode: string)
        Button.Text = Input and string.format("[%s]", Input.Name) or "[None]"

        self.Key = Input
        self.Mode = Mode or "Toggle"
        self.Editing = false
    end

    function Hotkey:SetLabel(Name: string)
        Label.Text = tostring(Name)
    end

    function Hotkey:SetVisible(Visible: boolean)
        if typeof(Visible) ~= "boolean" then return end
        if Label.Visible == Visible then return end
        
        Label.Visible = Visible
        Container:UpdateSize(Visible and 20 or -20, Label)
    end

    function Hotkey:GetValue(): EnumItem--, string
        return self.Key, self.Mode
    end

    function Hotkey:SetValue(Key: EnumItem, Mode: string)
        self:Update(Key, Mode)
    end


    Label.MouseEnter:Connect(function()
        if ToolTip then
            Menu:SetToolTip(true, ToolTip, Label)
        end
    end)
    Label.MouseLeave:Connect(function()
        if ToolTip then
            Menu:SetToolTip(false)
        end
    end)

    Button.Name = "Hotkey"
    Button.BackgroundTransparency = 1
    Button.Position = UDim2.new(1, -100, 0, 4)
    Button.Size = UDim2.fromOffset(75, 8)
    Button.Font = Enum.Font.SourceSans
    Button.Text = Key and "[" .. Key.Name .. "]" or "[None]"
    Button.TextColor3 = Color3.new(1, 1, 1)
    Button.TextSize = 12
    Button.TextXAlignment = Enum.TextXAlignment.Right
    Button.Parent = Label

    Selected_Hotkey.Name = "Selected_Hotkey"
    Selected_Hotkey.Visible = false
    Selected_Hotkey.BackgroundColor3 = Menu.ItemColor
    Selected_Hotkey.BorderColor3 = Menu.BorderColor
    Selected_Hotkey.Position = UDim2.fromOffset(200, 100)
    Selected_Hotkey.Size = UDim2.fromOffset(100, 30)
    Selected_Hotkey.Parent = nil
    CreateStroke(Selected_Hotkey, Color3.new(), 1)
    AddEventListener(Selected_Hotkey, function()
        Selected_Hotkey.BackgroundColor3 = Menu.ItemColor
        Selected_Hotkey.BorderColor3 = Menu.BorderColor
    end)

    HotkeyToggle.Parent = Selected_Hotkey
    HotkeyToggle.BackgroundColor3 = Menu.ItemColor
    HotkeyToggle.BorderColor3 = Color3.new()
    HotkeyToggle.BorderSizePixel = 0
    HotkeyToggle.Position = UDim2.new()
    HotkeyToggle.Size = UDim2.new(1, 0, 0, 13)
    HotkeyToggle.Font = Enum.Font.SourceSans
    HotkeyToggle.Text = "Toggle"
    HotkeyToggle.TextColor3 = Menu.Accent
    HotkeyToggle.TextSize = 14
    AddEventListener(HotkeyToggle, function()
        HotkeyToggle.BackgroundColor3 = Menu.ItemColor
        if Hotkey.Mode == "Toggle" then
            HotkeyToggle.TextColor3 = Menu.Accent
        end
    end)
    HotkeyToggle.MouseButton1Click:Connect(function()
        Hotkey:Update(Hotkey.Key, "Toggle")
        HotkeyToggle.TextColor3 = Menu.Accent
        HotkeyHold.TextColor3 = Color3.new(1, 1, 1)
        UpdateSelected()
        Hotkey.Callback(Hotkey.Key, Hotkey.Mode)
    end)

    HotkeyHold.Parent = Selected_Hotkey
    HotkeyHold.BackgroundColor3 = Menu.ItemColor
    HotkeyHold.BorderColor3 = Color3.new()
    HotkeyHold.BorderSizePixel = 0
    HotkeyHold.Position = UDim2.new(0, 0, 0, 15)
    HotkeyHold.Size = UDim2.new(1, 0, 0, 13)
    HotkeyHold.Font = Enum.Font.SourceSans
    HotkeyHold.Text = "Hold"
    HotkeyHold.TextColor3 = Color3.new(1, 1, 1)
    HotkeyHold.TextSize = 14
    AddEventListener(HotkeyHold, function()
        HotkeyHold.BackgroundColor3 = Menu.ItemColor
        if Hotkey.Mode == "Hold" then
            HotkeyHold.TextColor3 = Menu.Accent
        end
    end)
    HotkeyHold.MouseButton1Click:Connect(function()
        Hotkey:Update(Hotkey.Key, "Hold")
        HotkeyHold.TextColor3 = Menu.Accent
        HotkeyToggle.TextColor3 = Color3.new(1, 1, 1)
        UpdateSelected()
        Hotkey.Callback(Hotkey.Key, Hotkey.Mode)
    end)

    Button.MouseButton1Click:Connect(function()
        Button.Text = "..."
        Hotkey.Editing = true
        if UserInput:IsKeyDown(HotkeyRemoveKey) and Key ~= HotkeyRemoveKey then
            Hotkey:Update()
            Hotkey.Callback(nil, Hotkey.Mode)
        end
    end)
    Button.MouseButton2Click:Connect(function()
        UpdateSelected(Selected_Hotkey, Button, UDim2.fromOffset(100, 0))
    end)

    UserInput.InputBegan:Connect(function(Input)
        if Hotkey.Editing then
            local Key = Input.KeyCode
            if Key == Enum.KeyCode.Unknown then
                local InputType = Input.UserInputType
                Hotkey:Update(InputType)
                Hotkey.Callback(InputType, Hotkey.Mode)
            else
                Hotkey:Update(Key)
                Hotkey.Callback(Key, Hotkey.Mode)
            end
        end
    end)

    Container:UpdateSize(20)
    table.insert(Items, Hotkey)
    return #Items
end


function Menu.Slider(Tab_Name: string, Container_Name: string, Name: string, Min: number, Max: number, Value: number, Unit: string, Scale: number, Callback: any, ToolTip: string): Slider
    local Container = GetContainer(Tab_Name, Container_Name)
    local Label = CreateLabel(Container.self, "Slider", Name, UDim2.new(1, -10, 0, 15), UDim2.fromOffset(20, Container:GetHeight()))
    local Button = Instance.new("TextButton")
    local ValueBar = Instance.new("TextLabel")
    local ValueBox = Instance.new("TextBox")
    local ValueLabel = Instance.new("TextLabel")

    local Slider = {}
    Slider.Name = Name
    Slider.Class = "Slider"
    Slider.Tab = Tab_Name
    Slider.Container = Container_Name
    Slider.Index = #Items + 1
    Slider.Min = typeof(Min) == "number" and math.clamp(Min, Min, Max) or 0
    Slider.Max = typeof(Max) == "number" and Max or 100
    Slider.Value = typeof(Value) == "number" and Value or 100
    Slider.Unit = typeof(Unit) == "string" and Unit or ""
    Slider.Scale = typeof(Scale) == "number" and Scale or 0
    Slider.Callback = typeof(Callback) == "function" and Callback or function() end


    local function UpdateSlider(Percentage: number)
        local Percentage = typeof(Percentage == "number") and math.clamp(Percentage, 0, 1) or 0
        local Value = Slider.Min + ((Slider.Max - Slider.Min) * Percentage)
        local Scale = (10 ^ Slider.Scale)
        Slider.Value = math.round(Value * Scale) / Scale

        ValueBar.Size = UDim2.new(Percentage, 0, 0, 5)
        ValueBox.Text = "[" .. Slider.Value .. "]"
        ValueLabel.Text = Slider.Value .. Slider.Unit
    end


    function Slider:Update(Percentage: number)
        UpdateSlider(Percentage)
    end

    function Slider:SetLabel(Name: string)
        Label.Text = tostring(Name)
    end

    function Slider:SetVisible(Visible: boolean)
        if typeof(Visible) ~= "boolean" then return end
        if Label.Visible == Visible then return end
        
        Label.Visible = Visible
        Container:UpdateSize(Visible and 30 or -30, Label)
    end

    function Slider:GetValue(): number
        return self.Value
    end

    function Slider:SetValue(Value: number)
        self.Value = typeof(Value) == "number" and math.clamp(Value, self.Min, self.Max) or self.Min
        local Percentage = (self.Value - self.Min) / (self.Max - self.Min)
        self:Update(Percentage)
    end

    Slider.self = Label

    Label.MouseEnter:Connect(function()
        if ToolTip then
            Menu:SetToolTip(true, ToolTip, Label)
        end
    end)
    Label.MouseLeave:Connect(function()
        Menu:SetToolTip(false)
    end)

    Button.Name = "Slider"
    Button.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Button.BorderColor3 = Color3.new()
    Button.Position = UDim2.fromOffset(0, 20)
    Button.Size = UDim2.new(1, -40, 0, 5)
    Button.Text = ""
    Button.AutoButtonColor = false
    Button.Parent = Label

    ValueBar.Name = "ValueBar"
    ValueBar.BackgroundColor3 = Menu.Accent
    ValueBar.BorderSizePixel = 0
    ValueBar.Size = UDim2.fromScale(1, 1)
    ValueBar.Text = ""
    ValueBar.Parent = Button
    AddEventListener(ValueBar, function()
        ValueBar.BackgroundColor3 = Menu.Accent
    end)
    
    ValueBox.Name = "ValueBox"
    ValueBox.BackgroundTransparency = 1
    ValueBox.Position = UDim2.new(1, -65, 0, 5)
    ValueBox.Size = UDim2.fromOffset(50, 10)
    ValueBox.Font = Enum.Font.SourceSans
    ValueBox.Text = ""
    ValueBox.TextColor3 = Color3.new(1, 1, 1)
    ValueBox.TextSize = 12
    ValueBox.TextXAlignment = Enum.TextXAlignment.Right
    ValueBox.ClipsDescendants = true
    ValueBox.Parent = Label
    ValueBox.FocusLost:Connect(function()
        Slider.Value = tonumber(ValueBox.Text) or 0
        local Percentage = (Slider.Value - Slider.Min) / (Slider.Max - Slider.Min)
        Slider:Update(Percentage)
        Slider.Callback(Slider.Value)
    end)

    ValueLabel.Name = "ValueLabel"
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Position = UDim2.new(1, 0, 0, 2)
    ValueLabel.Size = UDim2.new(0, 0, 1, 0)
    ValueLabel.Font = Enum.Font.SourceSansBold
    ValueLabel.Text = ""
    ValueLabel.TextColor3 = Color3.new(1, 1, 1)
    ValueLabel.TextSize = 14
    ValueLabel.Parent = ValueBar

Button.InputBegan:Connect(function(Input: InputObject, Process: boolean)
    if (not Dragging.Gui and not Dragging.True) and (Input.UserInputType == Enum.UserInputType.Touch) then
        Dragging = {Gui = Button, True = true}
        local InputPosition = Vector2.new(Input.Position.X, Input.Position.Y)
        local Percentage = (InputPosition - Button.AbsolutePosition) / Button.AbsoluteSize
        Slider:Update(Percentage.X)
        Slider.Callback(Slider.Value)
    end
end)

    UserInput.InputChanged:Connect(function(Input: InputObject, Process: boolean)
        if Dragging.Gui ~= Button then return end
        if not (UserInput.TouchEnabled) then
            Dragging = {Gui = nil, True = false}
        return
    end
    if (Input.UserInputType == Enum.UserInputType.Touch) then
        local InputPosition = Vector2.new(Input.Position.X, Input.Position.Y)
            local Percentage = (InputPosition - Button.AbsolutePosition) / Button.AbsoluteSize
            Slider:Update(Percentage.X)
            Slider.Callback(Slider.Value)
        end
    end)

    Slider:SetValue(Slider.Value)
    Container:UpdateSize(30)
    table.insert(Items, Slider)
    return #Items
end


function Menu.ColorPicker(Tab_Name: string, Container_Name: string, Name: string, Color: Color3, Alpha: number, Callback: any, ToolTip: string): ColorPicker
    local Container = GetContainer(Tab_Name, Container_Name)
    local Label = CreateLabel(Container.self, "ColorPicker", Name, UDim2.new(1, -10, 0, 15), UDim2.fromOffset(20, Container:GetHeight()))
    local Button = Instance.new("TextButton")
    local Selected_ColorPicker = Instance.new("Frame")
    local HexBox = Instance.new("TextBox")
    local Saturation = Instance.new("ImageButton")
    local Alpha = Instance.new("ImageButton")
    local Hue = Instance.new("ImageButton")
    local SaturationCursor = Instance.new("Frame")
    local AlphaCursor = Instance.new("Frame")
    local HueCursor = Instance.new("Frame")
    local CopyButton = Instance.new("TextButton") -- rbxassetid://9090721920
    local PasteButton = Instance.new("TextButton") -- rbxassetid://9090721063
    local AlphaColorGradient = Instance.new("UIGradient")

    local ColorPicker = {self = Label}
    ColorPicker.Name = Name
    ColorPicker.Tab = Tab_Name
    ColorPicker.Class = "ColorPicker"
    ColorPicker.Container = Container_Name
    ColorPicker.Index = #Items + 1
    ColorPicker.Color = typeof(Color) == "Color3" and Color or Color3.new(1, 1, 1)
    ColorPicker.Saturation = {0, 0} -- no i'm not going to use ColorPicker.Value that would confuse people with ColorPicker.Color
    ColorPicker.Alpha = typeof(Alpha) == "number" and Alpha or 0
    ColorPicker.Hue = 0
    ColorPicker.Callback = typeof(Callback) == "function" and Callback or function() end


    local function UpdateColor()
        ColorPicker.Color = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Saturation[1], ColorPicker.Saturation[2])

        HexBox.Text = "#" .. string.upper(ColorPicker.Color:ToHex()) .. string.upper(string.format("%X", ColorPicker.Alpha * 255))
        Button.BackgroundColor3 = ColorPicker.Color
        Saturation.BackgroundColor3 = ColorPicker.Color
        AlphaColorGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(1, ColorPicker.Color)}

        SaturationCursor.Position = UDim2.fromScale(math.clamp(ColorPicker.Saturation[1], 0, 0.95), math.clamp(1 - ColorPicker.Saturation[2], 0, 0.95))
        AlphaCursor.Position = UDim2.fromScale(0, math.clamp(ColorPicker.Alpha, 0, 0.98))
        HueCursor.Position = UDim2.fromScale(0, math.clamp(ColorPicker.Hue, 0, 0.98))

        ColorPicker.Callback(ColorPicker.Color, ColorPicker.Alpha)
    end


    function ColorPicker:Update()
        UpdateColor()
    end

    function ColorPicker:SetLabel(Name: string)
        Label.Text = tostring(Name)
    end

    function ColorPicker:SetVisible(Visible: boolean)
        if typeof(Visible) ~= "boolean" then return end
        if Label.Visible == Visible then return end
        
        Label.Visible = Visible
        Container:UpdateSize(Visible and 20 or -20, Label)
    end

    function ColorPicker:SetValue(Color: Color3, Alpha: number)
        self.Color, self.Alpha = typeof(Color) == "Color3" and Color or Color3.new(), typeof(Alpha) == "number" and Alpha or 0
        self.Hue, self.Saturation[1], self.Saturation[2] = self.Color:ToHSV()
        self:Update()
    end

    function ColorPicker:GetValue(): Color3--, number
        return self.Color, self.Alpha
    end


    Label.MouseEnter:Connect(function()
        if ToolTip then
            Menu:SetToolTip(true, ToolTip, Label)
        end
    end)
    Label.MouseLeave:Connect(function()
        if ToolTip then
            Menu:SetToolTip(false)
        end
    end)

    Button.Name = "ColorPicker"
    Button.BackgroundColor3 = ColorPicker.Color
    Button.BorderColor3 = Color3.new()
    Button.Position = UDim2.new(1, -35, 0, 4)
    Button.Size = UDim2.fromOffset(20, 8)
    Button.Font = Enum.Font.SourceSans
    Button.Text = ""
    Button.TextColor3 = Color3.new(1, 1, 1)
    Button.TextSize = 12
    Button.Parent = Label
    Button.MouseButton1Click:Connect(function()
        UpdateSelected(Selected_ColorPicker, Button, UDim2.fromOffset(20, 20))
    end)

    Selected_ColorPicker.Name = "Selected_ColorPicker"
    Selected_ColorPicker.Visible = false
    Selected_ColorPicker.BackgroundColor3 = Menu.ItemColor
    Selected_ColorPicker.BorderColor3 = Menu.BorderColor
    Selected_ColorPicker.BorderMode = Enum.BorderMode.Inset
    Selected_ColorPicker.Position = UDim2.new(0, 200, 0, 170)
    Selected_ColorPicker.Size = UDim2.new(0, 190, 0, 180)
    Selected_ColorPicker.Parent = nil
    CreateStroke(Selected_ColorPicker, Color3.new(), 1)
    AddEventListener(Selected_ColorPicker, function()
        Selected_ColorPicker.BackgroundColor3 = Menu.ItemColor
        Selected_ColorPicker.BorderColor3 = Menu.BorderColor
    end)

    HexBox.Name = "Hex"
    HexBox.BackgroundColor3 = Menu.ItemColor
    HexBox.BorderColor3 = Menu.BorderColor
    HexBox.BorderMode = Enum.BorderMode.Inset
    HexBox.Size = UDim2.new(1, -10, 0, 20)
    HexBox.Position = UDim2.fromOffset(5, 150)
    HexBox.Text = "#" .. string.upper(ColorPicker.Color:ToHex())
    HexBox.Font = Enum.Font.SourceSansSemibold
    HexBox.TextSize = 14
    HexBox.TextColor3 = Color3.new(1, 1, 1)
    HexBox.ClearTextOnFocus = false
    HexBox.ClipsDescendants = true
    HexBox.Parent = Selected_ColorPicker
    CreateStroke(HexBox, Color3.new(), 1)
    HexBox.FocusLost:Connect(function()
        pcall(function()
            local Color, Alpha = string.sub(HexBox.Text, 1, 7), string.sub(HexBox.Text, 8, #HexBox.Text)
            ColorPicker.Color = Color3.fromHex(Color)
            ColorPicker.Alpha = tonumber(Alpha, 16) / 255
            ColorPicker.Hue, ColorPicker.Saturation[1], ColorPicker.Saturation[2] = ColorPicker.Color:ToHSV()
            ColorPicker:Update()
        end)
    end)
    AddEventListener(HexBox, function()
        HexBox.BackgroundColor3 = Menu.ItemColor
        HexBox.BorderColor3 = Menu.BorderColor
    end)

    Saturation.Name = "Saturation"
    Saturation.BackgroundColor3 = ColorPicker.Color
    Saturation.BorderColor3 = Menu.BorderColor
    Saturation.Position = UDim2.new(0, 4, 0, 4)
    Saturation.Size = UDim2.new(0, 150, 0, 140)
    Saturation.Image = "rbxassetid://8180999986"
    Saturation.ImageColor3 = Color3.new()
    Saturation.AutoButtonColor = false
    Saturation.Parent = Selected_ColorPicker
    CreateStroke(Saturation, Color3.new(), 1)
    AddEventListener(Saturation, function()
        Saturation.BorderColor3 = Menu.BorderColor
    end)
    
    Alpha.Name = "Alpha"
    Alpha.BorderColor3 = Menu.BorderColor
    Alpha.Position = UDim2.new(0, 175, 0, 4)
    Alpha.Size = UDim2.new(0, 10, 0, 140)
    Alpha.Image = "rbxassetid://8181003956"--"rbxassetid://8181003956"
    Alpha.ScaleType = Enum.ScaleType.Crop
    Alpha.AutoButtonColor = false
    Alpha.Parent = Selected_ColorPicker
    CreateStroke(Alpha, Color3.new(), 1)
    AddEventListener(Alpha, function()
        Alpha.BorderColor3 = Menu.BorderColor
    end)

    Hue.Name = "Hue"
    Hue.BackgroundColor3 = Color3.new(1, 1, 1)
    Hue.BorderColor3 = Menu.BorderColor
    Hue.Position = UDim2.new(0, 160, 0, 4)
    Hue.Size = UDim2.new(0, 10, 0, 140)
    Hue.Image = "rbxassetid://8180989234"
    Hue.ScaleType = Enum.ScaleType.Crop
    Hue.AutoButtonColor = false
    Hue.Parent = Selected_ColorPicker
    CreateStroke(Hue, Color3.new(), 1)
    AddEventListener(Hue, function()
        Hue.BorderColor3 = Menu.BorderColor
    end)

    SaturationCursor.Name = "Cursor"
    SaturationCursor.BackgroundColor3 = Color3.new(1, 1, 1)
    SaturationCursor.BorderColor3 = Color3.new()
    SaturationCursor.Size = UDim2.fromOffset(5, 5)
    SaturationCursor.Parent = Saturation

    AlphaCursor.Name = "Cursor"
    AlphaCursor.BackgroundColor3 = Color3.new(1, 1, 1)
    AlphaCursor.BorderColor3 = Color3.new()
    AlphaCursor.Size = UDim2.new(1, 0, 0, 2)
    AlphaCursor.Parent = Alpha

    HueCursor.Name = "Cursor"
    HueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
    HueCursor.BorderColor3 = Color3.new()
    HueCursor.Size = UDim2.new(1, 0, 0, 2)
    HueCursor.Parent = Hue

    AlphaColorGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(1, ColorPicker.Color)}
    AlphaColorGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 0.20), NumberSequenceKeypoint.new(1, 0.2)}
    AlphaColorGradient.Offset = Vector2.new(0, -0.1)
    AlphaColorGradient.Rotation = -90
    AlphaColorGradient.Parent = Alpha

    local function UpdateSaturation(PercentageX: number, PercentageY: number)
        local PercentageX = typeof(PercentageX == "number") and math.clamp(PercentageX, 0, 1) or 0
        local PercentageY = typeof(PercentageY == "number") and math.clamp(PercentageY, 0, 1) or 0
        ColorPicker.Saturation[1] = PercentageX
        ColorPicker.Saturation[2] = 1 - PercentageY
        ColorPicker:Update()
    end

    local function UpdateAlpha(Percentage: number)
        local Percentage = typeof(Percentage == "number") and math.clamp(Percentage, 0, 1) or 0
        ColorPicker.Alpha = Percentage
        ColorPicker:Update()
    end

    local function UpdateHue(Percentage: number)
        local Percentage = typeof(Percentage == "number") and math.clamp(Percentage, 0, 1) or 0
        ColorPicker.Hue = Percentage
        ColorPicker:Update()
    end

    Saturation.InputBegan:Connect(function(Input: InputObject, Process: boolean)
        if (not Dragging.Gui and not Dragging.True) and (Input.UserInputType == Enum.UserInputType.Touch) then
            Dragging = {Gui = Saturation, True = true}
            local InputPosition = Vector2.new(Input.Position.X, Input.Position.Y)
            local Percentage = (InputPosition - Saturation.AbsolutePosition) / Saturation.AbsoluteSize
            UpdateSaturation(Percentage.X, Percentage.Y)
        end
    end)

    Alpha.InputBegan:Connect(function(Input: InputObject, Process: boolean)
        if (not Dragging.Gui and not Dragging.True) and (Input.UserInputType == Enum.UserInputType.Touch) then
            Dragging = {Gui = Alpha, True = true}
            local InputPosition = Vector2.new(Input.Position.X, Input.Position.Y)
            local Percentage = (InputPosition - Alpha.AbsolutePosition) / Alpha.AbsoluteSize
            UpdateAlpha(Percentage.Y)
        end
    end)

    Hue.InputBegan:Connect(function(Input: InputObject, Process: boolean)
        if (not Dragging.Gui and not Dragging.True) and (Input.UserInputType == Enum.UserInputType.Touch) then
            Dragging = {Gui = Hue, True = true}
            local InputPosition = Vector2.new(Input.Position.X, Input.Position.Y)
            local Percentage = (InputPosition - Hue.AbsolutePosition) / Hue.AbsoluteSize
            UpdateHue(Percentage.Y)
        end
    end)

    UserInput.InputChanged:Connect(function(Input: InputObject, Process: boolean)
        if (Dragging.Gui ~= Saturation and Dragging.Gui ~= Alpha and Dragging.Gui ~= Hue) then return end
        if not (UserInput:IsMouseButtonPressed(Enum.UserInputType.Touch)) then
            Dragging = {Gui = nil, True = false}
            return
        end

        local InputPosition = Vector2.new(Input.Position.X, Input.Position.Y)
        if (Input.UserInputType == Enum.UserInputType.Touch) then
            if Dragging.Gui == Saturation then
                local Percentage = (InputPosition - Saturation.AbsolutePosition) / Saturation.AbsoluteSize
                UpdateSaturation(Percentage.X, Percentage.Y)
            end
            if Dragging.Gui == Alpha then
                local Percentage = (InputPosition - Alpha.AbsolutePosition) / Alpha.AbsoluteSize
                UpdateAlpha(Percentage.Y)
            end
            if Dragging.Gui == Hue then
                local Percentage = (InputPosition - Hue.AbsolutePosition) / Hue.AbsoluteSize
                UpdateHue(Percentage.Y)
            end
        end
    end)
    
    
    ColorPicker.Hue, ColorPicker.Saturation[1], ColorPicker.Saturation[2] = ColorPicker.Color:ToHSV()
    ColorPicker:Update()
    Container:UpdateSize(20)
    table.insert(Items, ColorPicker)
    return #Items
end


function Menu.ComboBox(Tab_Name: string, Container_Name: string, Name: string, Value: string, Value_Items: table, Callback: any, ToolTip: string): ComboBox
    local Container = GetContainer(Tab_Name, Container_Name)
    local Label = CreateLabel(Container.self, "ComboBox", Name, UDim2.new(1, -10, 0, 15), UDim2.fromOffset(20, Container:GetHeight()))
    local Button = Instance.new("TextButton")
    local Symbol = Instance.new("TextLabel")
    local List = Instance.new("ScrollingFrame")
    local ListLayout = Instance.new("UIListLayout")

    local ComboBox = {}
    ComboBox.Name = Name
    ComboBox.Class = "ComboBox"
    ComboBox.Tab = Tab_Name
    ComboBox.Container = Container_Name
    ComboBox.Index = #Items + 1
    ComboBox.Callback = typeof(Callback) == "function" and Callback or function() end
    ComboBox.Value = typeof(Value) == "string" and Value or ""
    ComboBox.Items = typeof(Value_Items) == "table" and Value_Items or {}

    local function UpdateValue(Value: string)
        ComboBox.Value = tostring(Value)
        Button.Text = ComboBox.Value or "[...]"
    end

    local ItemObjects = {}
    local function AddItem(Name: string)
        local Button = Instance.new("TextButton")
        Button.BackgroundColor3 = Menu.ItemColor
        Button.BorderColor3 = Color3.new()
        Button.BorderSizePixel = 0
        Button.Size = UDim2.new(1, 0, 0, 15)
        Button.Font = Enum.Font.SourceSans
        Button.Text = tostring(Name)
        Button.TextColor3 = ComboBox.Value == Button.Text and Menu.Accent or Color3.new(1, 1, 1)
        Button.TextSize = 14
        Button.TextTruncate = Enum.TextTruncate.AtEnd
        Button.Parent = List
        Button.MouseButton1Click:Connect(function()
            for _, v in ipairs(List:GetChildren()) do
                if v:IsA("GuiButton") then
                    if v == Button then continue end
                    v.TextColor3 = Color3.new(1, 1, 1)
                end
            end
            Button.TextColor3 = Menu.Accent
            UpdateValue(Button.Text)
            UpdateSelected()
            ComboBox.Callback(ComboBox.Value)
        end)
        AddEventListener(Button, function()
            Button.BackgroundColor3 = Menu.ItemColor
            if ComboBox.Value == Button.Text then
                Button.TextColor3 = Menu.Accent
            else
                Button.TextColor3 = Color3.new(1, 1, 1)
            end
        end)
        
        if #ComboBox.Items >= 6 then
            List.CanvasSize += UDim2.fromOffset(0, 15)
        end
        table.insert(ItemObjects, Button)
    end


    function ComboBox:Update(Value: string, Items: any)
        UpdateValue(Value)
        if typeof(Items) == "table" then
            for _, Button in ipairs(ItemObjects) do
                Button:Destroy()
            end
            table.clear(ItemObjects)

            List.CanvasSize = UDim2.new()
            List.Size = UDim2.fromOffset(Button.AbsoluteSize.X, math.clamp(#self.Items * 15, 15, 90))
            for _, Item in ipairs(self.Items) do
                AddItem(tostring(Item))
            end
        else
            for _, Button in ipairs(ItemObjects) do
                Button.TextColor3 = self.Value == Button.Text and Menu.Accent or Color3.new(1, 1, 1)
            end
        end
    end

    function ComboBox:SetLabel(Name: string)
        Label.Text = tostring(Name)
    end

    function ComboBox:SetVisible(Visible: boolean)
        if typeof(Visible) ~= "boolean" then return end
        if Label.Visible == Visible then return end
        
        Label.Visible = Visible
        Container:UpdateSize(Visible and 40 or -40, Label)
    end

    function ComboBox:GetValue(): table
        return self.Value
    end

    function ComboBox:SetValue(Value: string, Items: any)
        if typeof(Items) == "table" then
            self.Items = Items
        end
        self:Update(Value, self.Items)
    end


    Label.MouseEnter:Connect(function()
        if ToolTip then
            Menu:SetToolTip(true, ToolTip, Label)
        end
    end)
    Label.MouseLeave:Connect(function()
        if ToolTip then
            Menu:SetToolTip(false)
        end
    end)

    Button.Name = "Button"
    Button.BackgroundColor3 = Menu.ItemColor
    Button.BorderColor3 = Color3.new()
    Button.Position = UDim2.new(0, 0, 0, 20)
    Button.Size = UDim2.new(1, -40, 0, 15)
    Button.Font = Enum.Font.SourceSans
    Button.Text = ComboBox.Value
    Button.TextColor3 = Color3.new(1, 1, 1)
    Button.TextSize = 14
    Button.TextTruncate = Enum.TextTruncate.AtEnd
    Button.Parent = Label
    Button.MouseButton1Click:Connect(function()
        UpdateSelected(List, Button, UDim2.fromOffset(0, 15))
        List.Size = UDim2.fromOffset(Button.AbsoluteSize.X, math.clamp(#ComboBox.Items * 15, 15, 90))
    end)
    AddEventListener(Button, function()
        Button.BackgroundColor3 = Menu.ItemColor
    end)

    Symbol.Name = "Symbol"
    Symbol.Parent = Button
    Symbol.BackgroundColor3 = Color3.new(1, 1, 1)
    Symbol.BackgroundTransparency = 1
    Symbol.Position = UDim2.new(1, -10, 0, 0)
    Symbol.Size = UDim2.new(0, 5, 1, 0)
    Symbol.Font = Enum.Font.SourceSans
    Symbol.Text = "-"
    Symbol.TextColor3 = Color3.new(1, 1, 1)
    Symbol.TextSize = 14

    List.Visible = false
    List.BackgroundColor3 = Menu.ItemColor
    List.BorderColor3 = Menu.BorderColor
    List.BorderMode = Enum.BorderMode.Inset
    List.Size = UDim2.fromOffset(Button.AbsoluteSize.X, math.clamp(#ComboBox.Items * 15, 15, 90))
    List.Position = UDim2.fromOffset(20, 30)
    List.CanvasSize = UDim2.new()
    List.ScrollBarThickness = 4
    List.ScrollBarImageColor3 = Menu.Accent
    List.Parent = Label
    CreateStroke(List, Color3.new(), 1)
    AddEventListener(List, function()
        List.BackgroundColor3 = Menu.ItemColor
        List.BorderColor3 = Menu.BorderColor
        List.ScrollBarImageColor3 = Menu.Accent
    end)

    ListLayout.Parent = List

    ComboBox:Update(ComboBox.Value, ComboBox.Items)
    Container:UpdateSize(40)
    table.insert(Items, ComboBox)
    return #Items
end


function Menu.MultiSelect(Tab_Name: string, Container_Name: string, Name: string, Value_Items: table, Callback: any, ToolTip: string): MultiSelect
    local Container = GetContainer(Tab_Name, Container_Name)
    local Label = CreateLabel(Container.self, "MultiSelect", Name, UDim2.new(1, -10, 0, 15), UDim2.fromOffset(20, Container:GetHeight()))
    local Button = Instance.new("TextButton")
    local Symbol = Instance.new("TextLabel")
    local List = Instance.new("ScrollingFrame")
    local ListLayout = Instance.new("UIListLayout")

    local MultiSelect = {self = Label}
    MultiSelect.Name = Name
    MultiSelect.Class = "MultiSelect"
    MultiSelect.Tab = Tab_Name
    MultiSelect.Container = Container_Name
    MultiSelect.Index = #Items + 1
    MultiSelect.Callback = typeof(Callback) == "function" and Callback or function() end
    MultiSelect.Items = typeof(Value_Items) == "table" and Value_Items or {}
    MultiSelect.Value = {}


    local function GetSelectedItems(): table
        local Selected = {}
        for k, v in pairs(MultiSelect.Items) do
            if v == true then table.insert(Selected, k) end
        end
        return Selected
    end

    local function UpdateValue()
        MultiSelect.Value = GetSelectedItems()
        Button.Text = #MultiSelect.Value > 0 and table.concat(MultiSelect.Value, ", ") or "[...]"
    end

    local ItemObjects = {}
    local function AddItem(Name: string, Checked: boolean)
        local Button = Instance.new("TextButton")
        Button.BackgroundColor3 = Menu.ItemColor
        Button.BorderColor3 = Color3.new()
        Button.BorderSizePixel = 0
        Button.Size = UDim2.new(1, 0, 0, 15)
        Button.Font = Enum.Font.SourceSans
        Button.Text = Name
        Button.TextColor3 = Checked and Menu.Accent or Color3.new(1, 1, 1)
        Button.TextSize = 14
        Button.Parent = List
        Button.TextTruncate = Enum.TextTruncate.AtEnd
        Button.MouseButton1Click:Connect(function()
            MultiSelect.Items[Name] = not MultiSelect.Items[Name]
            Button.TextColor3 = MultiSelect.Items[Name] and Menu.Accent or Color3.new(1, 1, 1)
            UpdateValue()
            MultiSelect.Callback(MultiSelect.Items) -- don't send value
        end)
        AddEventListener(Button, function()
            Button.BackgroundColor3 = Menu.ItemColor
            Button.TextColor3 = table.find(GetSelectedItems(), Button.Text) and Menu.Accent or Color3.new(1, 1, 1)
        end)

        if GetDictionaryLength(MultiSelect.Items) >= 6 then
            List.CanvasSize += UDim2.fromOffset(0, 15)
        end
        table.insert(ItemObjects, Button)
    end


    function MultiSelect:Update(Value: any)
        if typeof(Value) == "table" then
            self.Items = Value
            UpdateValue()

            for _, Button in ipairs(ItemObjects) do
                Button:Destroy()
            end
            table.clear(ItemObjects)

            List.CanvasSize = UDim2.new()
            List.Size = UDim2.fromOffset(Button.AbsoluteSize.X, math.clamp(GetDictionaryLength(self.Items) * 15, 15, 90))
            for Name, Checked in pairs(self.Items) do
                AddItem(tostring(Name), Checked)
            end
        else
            local Selected = GetSelectedItems()
            for _, Button in ipairs(ItemObjects) do
                local Checked = table.find(Selected, Button.Text)
                Button.TextColor3 = Checked and Menu.Accent or Color3.new(1, 1, 1)
            end
        end
    end

    function MultiSelect:SetLabel(Name: string)
        Label.Text = tostring(Name)
    end

    function MultiSelect:SetVisible(Visible: boolean)
        if typeof(Visible) ~= "boolean" then return end
        if Label.Visible == Visible then return end
        
        Label.Visible = Visible
        Container:UpdateSize(Visible and 40 or -40, Label)
    end

    function MultiSelect:GetValue(): table
        return self.Items
    end

    function MultiSelect:SetValue(Value: any)
        self:Update(Value)
    end


    Label.MouseEnter:Connect(function()
        if ToolTip then
            Menu:SetToolTip(true, ToolTip, Label)
        end
    end)
    Label.MouseLeave:Connect(function()
        if ToolTip then
            Menu:SetToolTip(false)
        end
    end)

    Button.BackgroundColor3 = Menu.ItemColor
    Button.BorderColor3 = Color3.new()
    Button.Position = UDim2.new(0, 0, 0, 20)
    Button.Size = UDim2.new(1, -40, 0, 15)
    Button.Font = Enum.Font.SourceSans
    Button.Text = "[...]"
    Button.TextColor3 = Color3.new(1, 1, 1)
    Button.TextSize = 14
    Button.TextTruncate = Enum.TextTruncate.AtEnd
    Button.Parent = Label
    Button.MouseButton1Click:Connect(function()
        UpdateSelected(List, Button, UDim2.fromOffset(0, 15))
        List.Size = UDim2.fromOffset(Button.AbsoluteSize.X, math.clamp(GetDictionaryLength(MultiSelect.Items) * 15, 15, 90))
    end)
    AddEventListener(Button, function()
        Button.BackgroundColor3 = Menu.ItemColor
    end)

    Symbol.Name = "Symbol"
    Symbol.BackgroundTransparency = 1
    Symbol.Position = UDim2.new(1, -10, 0, 0)
    Symbol.Size = UDim2.new(0, 5, 1, 0)
    Symbol.Font = Enum.Font.SourceSans
    Symbol.Text = "-"
    Symbol.TextColor3 = Color3.new(1, 1, 1)
    Symbol.TextSize = 14
    Symbol.Parent = Button

    List.Visible = false
    List.BackgroundColor3 = Menu.ItemColor
    List.BorderColor3 = Menu.BorderColor
    List.BorderMode = Enum.BorderMode.Inset
    List.Size = UDim2.fromOffset(Button.AbsoluteSize.X, math.clamp(GetDictionaryLength(MultiSelect.Items) * 15, 15, 90))
    List.Position = UDim2.fromOffset(20, 30)
    List.CanvasSize = UDim2.new()
    List.ScrollBarThickness = 4
    List.ScrollBarImageColor3 = Menu.Accent
    List.Parent = Label
    CreateStroke(List, Color3.new(), 1)
    AddEventListener(List, function()
        List.BackgroundColor3 = Menu.ItemColor
        List.BorderColor3 = Menu.BorderColor
        List.ScrollBarImageColor3 = Menu.Accent
    end)

    ListLayout.Parent = List

    MultiSelect:Update(MultiSelect.Items)
    Container:UpdateSize(40)
    table.insert(Items, MultiSelect)
    return #Items
end


function Menu.ListBox(Tab_Name: string, Container_Name: string, Name: string, Multi: boolean, Value_Items: table, Callback: any, ToolTip: string): ListBox
    local Container = GetContainer(Tab_Name, Container_Name)
    local List = Instance.new("ScrollingFrame")
    local ListLayout = Instance.new("UIListLayout")

    local ListBox = {self = Label}
    ListBox.Name = Name
    ListBox.Class = "ListBox"
    ListBox.Tab = Tab_Name
    ListBox.Container = Container_Name
    ListBox.Index = #Items + 1
    ListBox.Method = Multi and "Multi" or "Default"
    ListBox.Items = typeof(Value_Items) == "table" and Value_Items or {}
    ListBox.Value = {}
    ListBox.Callback = typeof(Callback) == "function" and Callback or function() end

    local ItemObjects = {}

    local function GetSelectedItems(): table
        local Selected = {}
        for k, v in pairs(ListBox.Items) do
            if v == true then table.insert(Selected, k) end
        end
        return Selected
    end

    local function UpdateValue(Value: any)
        if ListBox.Method == "Default" then
            ListBox.Value = tostring(Value)
        else
            ListBox.Value = GetSelectedItems()
        end
    end

    local function AddItem(Name: string, Checked: boolean)
        local Button = Instance.new("TextButton")
        Button.BackgroundColor3 = Menu.ItemColor
        Button.BorderColor3 = Color3.new()
        Button.BorderSizePixel = 0
        Button.Size = UDim2.new(1, 0, 0, 15)
        Button.Font = Enum.Font.SourceSans
        Button.Text = Name
        Button.TextSize = 14
        Button.TextXAlignment = Enum.TextXAlignment.Left
        Button.TextTruncate = Enum.TextTruncate.AtEnd
        Button.Parent = List
        if ListBox.Method == "Default" then
            Button.TextColor3 = ListBox.Value == Button.Text and Menu.Accent or Color3.new(1, 1, 1)
            Button.MouseButton1Click:Connect(function()
                for _, v in ipairs(List:GetChildren()) do
                    if v:IsA("GuiButton") then
                        if v == Button then continue end
                        v.TextColor3 = Color3.new(1, 1, 1)
                    end
                end
                Button.TextColor3 = Menu.Accent
                UpdateValue(Button.Text)
                UpdateSelected()
                ListBox.Callback(ListBox.Value)
            end)
            AddEventListener(Button, function()
                Button.BackgroundColor3 = Menu.ItemColor
                if ListBox.Value == Button.Text then
                    Button.TextColor3 = Menu.Accent
                else
                    Button.TextColor3 = Color3.new(1, 1, 1)
                end
            end)
            
            if #ListBox.Items >= 6 then
                List.CanvasSize += UDim2.fromOffset(0, 15)
            end
        else
            Button.TextColor3 = Checked and Menu.Accent or Color3.new(1, 1, 1)
            Button.MouseButton1Click:Connect(function()
                ListBox.Items[Name] = not ListBox.Items[Name]
                Button.TextColor3 = ListBox.Items[Name] and Menu.Accent or Color3.new(1, 1, 1)
                UpdateValue()
                UpdateSelected()
                ListBox.Callback(ListBox.Value)
            end)
            AddEventListener(Button, function()
                Button.BackgroundColor3 = Menu.ItemColor
                if table.find(ListBox.Value, Name) then
                    Button.TextColor3 = Menu.Accent
                else
                    Button.TextColor3 = Color3.new(1, 1, 1)
                end
            end)
            
            if GetDictionaryLength(ListBox.Items) >= 10 then
                List.CanvasSize += UDim2.fromOffset(0, 15)
            end
        end
        table.insert(ItemObjects, Button)
    end


    function ListBox:Update(Value: string, Items: any)
        if self.Method == "Default" then
            UpdateValue(Value)
        end
        if typeof(Items) == "table" then
            if self.Method == "Multi" then
                self.Items = Value
                UpdateValue()
            end
            for _, Button in ipairs(ItemObjects) do
                Button:Destroy()
            end
            table.clear(ItemObjects)

            List.CanvasSize = UDim2.new()
            List.Size = UDim2.new(1, -50, 0, 150)
            if self.Method == "Default" then
                for _, Item in ipairs(self.Items) do
                    AddItem(tostring(Item))
                end
            else
                for Name, Checked in pairs(self.Items) do
                    AddItem(tostring(Name), Checked)
                end
            end
        else
            if self.Method == "Default" then
                for _, Button in ipairs(ItemObjects) do
                    Button.TextColor3 = self.Value == Button.Text and Menu.Accent or Color3.new(1, 1, 1)
                end
            else
                local Selected = GetSelectedItems()
                for _, Button in ipairs(ItemObjects) do
                    local Checked = table.find(Selected, Button.Text)
                    Button.TextColor3 = Checked and Menu.Accent or Color3.new(1, 1, 1)
                end
            end
        end
    end

    function ListBox:SetVisible(Visible: boolean)
        if typeof(Visible) ~= "boolean" then return end
        if List.Visible == Visible then return end
        
        List.Visible = Visible
        Container:UpdateSize(Visible and 155 or -155, List)
    end

    function ListBox:SetValue(Value: string, Items: any)
        if self.Method == "Default" then
            if typeof(Items) == "table" then
                self.Items = Items
            end
            self:Update(Value, self.Items)
        else
            self:Update(Value)
        end
    end

    function ListBox:GetValue(): table
        return self.Value
    end


    List.Name = "List"
    List.Active = true
    List.BackgroundColor3 = Menu.ItemColor
    List.BorderColor3 = Color3.new()
    List.Position = UDim2.fromOffset(20, Container:GetHeight())
    List.Size = UDim2.new(1, -50, 0, 150)
    List.CanvasSize = UDim2.new()
    List.ScrollBarThickness = 4
    List.ScrollBarImageColor3 = Menu.Accent
    List.Parent = Container.self
    List.MouseEnter:Connect(function()
        if ToolTip then
            Menu:SetToolTip(true, ToolTip, List)
        end
    end)
    List.MouseLeave:Connect(function()
        if ToolTip then
            Menu:SetToolTip(false)
        end
    end)
    CreateStroke(List, Color3.new(), 1)
    AddEventListener(List, function()
        List.BackgroundColor3 = Menu.ItemColor
        List.ScrollBarImageColor3 = Menu.Accent
    end)

    ListLayout.Parent = List

    if ListBox.Method == "Default" then
        ListBox:Update(ListBox.Value, ListBox.Items)
    else
        ListBox:Update(ListBox.Items)
    end
    Container:UpdateSize(155)
    table.insert(Items, ListBox)
    return #Items
end


function Menu.Notify(Content: string, Delay: number)
    assert(typeof(Content) == "string", "missing argument #1, (string expected got " .. typeof(Content) .. ")")
    local Delay = typeof(Delay) == "number" and Delay or 3

    local Text = Instance.new("TextLabel")
    local Notification = {
        self = Text,
        Class = "Notification"
    }

    Text.Name = "Notification"
    Text.BackgroundTransparency = 1
    Text.Position = UDim2.new(0.5, -100, 1, -150 - (GetDictionaryLength(Notifications) * 15))
    Text.Size = UDim2.new(0, 0, 0, 15)
    Text.Text = Content
    Text.Font = Enum.Font.SourceSans
    Text.TextSize = 17
    Text.TextColor3 = Color3.new(1, 1, 1)
    Text.TextStrokeTransparency = 0.2
    Text.TextTransparency = 1
    Text.RichText = true
    Text.ZIndex = 4
    Text.Parent = Notifications_Frame

    local function CustomTweenOffset(Offset: number)
        spawn(function()
            local Steps = 33
            for i = 1, Steps do
                Text.Position += UDim2.fromOffset(Offset / Steps, 0)
                RunService.RenderStepped:Wait()
            end
        end)
    end

    function Notification:Update()
        
    end

    function Notification:Destroy()
        Notifications[self] = nil
        Text:Destroy()

        local Index = 1
        for _, v in pairs(Notifications) do
            local self = v.self
            self.Position += UDim2.fromOffset(0, 15)
            Index += 1
        end
    end

    Notifications[Notification] = Notification
    
    local TweenIn  = TweenService:Create(Text, TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0), {TextTransparency = 0})
    local TweenOut = TweenService:Create(Text, TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0), {TextTransparency = 1})
    
    TweenIn:Play()
    CustomTweenOffset(100)
    
    TweenIn.Completed:Connect(function()
        delay(Delay, function()
            TweenOut:Play()
            CustomTweenOffset(100)

            TweenOut.Completed:Connect(function()
                Notification:Destroy()
            end)
        end)
    end)
end


function Menu.Prompt(Message: string, Callback: any, ...)
    do
        local Prompt = Menu.Screen:FindFirstChild("Prompt")
        if Prompt then Prompt:Destroy() end
    end

    local Prompt = Instance.new("Frame")
    local Title = Instance.new("TextLabel")

    local Height = -20
    local function CreateButton(Text, Callback, ...)
        local Arguments = {...}

        local Callback = typeof(Callback) == "function" and Callback or function() end
        local Button = Instance.new("TextButton")
        Button.Name = "Button"
        Button.BorderSizePixel = 0
        Button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        Button.Size = UDim2.fromOffset(100, 20)
        Button.Position = UDim2.new(0.5, -50, 0.5, Height)
        Button.Text = Text
        Button.TextStrokeTransparency = 0.8
        Button.TextSize = 14
        Button.Font = Enum.Font.SourceSans
        Button.TextColor3 = Color3.new(1, 1, 1)
        Button.Parent = Prompt
        Button.MouseButton1Click:Connect(function() Prompt:Destroy() Callback(unpack(Arguments)) end)
        CreateStroke(Button, Color3.new(), 1)
        Height += 25
    end

    CreateButton("OK", Callback, ...)
    CreateButton("Cancel", function() Prompt:Destroy() end)


    Title.Name = "Title"
    Title.BackgroundTransparency = 1
    Title.Size = UDim2.new(1, 0, 0, 15)
    Title.Position = UDim2.new(0, 0, 0.5, -100)
    Title.Text = Message
    Title.TextSize = 14
    Title.Font = Enum.Font.SourceSans
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.Parent = Prompt

    Prompt.Name = "Prompt"
    Prompt.BackgroundTransparency = 0.5
    Prompt.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Prompt.BorderSizePixel = 0
    Prompt.Size = UDim2.new(1, 0, 1, 36)
    Prompt.Position = UDim2.fromOffset(0, -36)
    Prompt.Parent = Menu.Screen
end


function Menu.Spectators(): Spectators
    local Frame = Instance.new("Frame")
    local Title = Instance.new("TextLabel")
    local List = Instance.new("Frame")
    local ListLayout = Instance.new("UIListLayout")
    local Spectators = {self = Frame}
    Spectators.List = {}
    Menu.Spectators = Spectators


    Frame.Name = "Spectators"
    Frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    Frame.BorderColor3 = Color3.fromRGB(40, 40, 40)
    Frame.BorderMode = Enum.BorderMode.Inset
    Frame.Size = UDim2.fromOffset(250, 50)
    Frame.Position = UDim2.fromOffset(Menu.ScreenSize.X - Frame.Size.X.Offset, -36)
    Frame.Visible = false
    Frame.Parent = Menu.Screen
    CreateStroke(Frame, Color3.new(), 1)
    CreateLine(Frame, UDim2.new(0, 240, 0, 1), UDim2.new(0, 5, 0, 20))
    SetDraggable(Frame)
    
    Title.Name = "Title"
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 5, 0, 5)
    Title.Size = UDim2.new(0, 240, 0, 15)
    Title.Font = Enum.Font.SourceSansSemibold
    Title.Text = "Spectators"
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.TextSize = 14
    Title.Parent = Frame

    List.Name = "List"
    List.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    List.BorderColor3 = Color3.fromRGB(40, 40, 40)
    List.BorderMode = Enum.BorderMode.Inset
    List.Position = UDim2.new(0, 4, 0, 30)
    List.Size = UDim2.new(0, 240, 0, 10)
    List.Parent = Frame

    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Parent = List


    local function UpdateFrameSize()
        local Height = ListLayout.AbsoluteContentSize.Y + 5
        Spectators.self:TweenSize(UDim2.fromOffset(250, math.clamp(Height + 50, 50, 5000)), nil, nil, 0.3, true)
        Spectators.self.List:TweenSize(UDim2.fromOffset(240, math.clamp(Height, 10, 5000)), nil, nil, 0.3, true)
    end


    function Spectators.Add(Name: string, Icon: string)
        Spectators.Remove(Name)
        local Object = Instance.new("Frame")
        local NameLabel = Instance.new("TextLabel")
        local IconImage = Instance.new("ImageLabel")
        local Spectator = {self = Object}

        Object.Name = "Object"
        Object.BackgroundTransparency = 1
        Object.Position = UDim2.new(0, 5, 0, 30)
        Object.Size = UDim2.new(0, 240, 0, 15)
        Object.Parent = List

        NameLabel.Name = "Name"
        NameLabel.BackgroundTransparency = 1
        NameLabel.Position = UDim2.new(0, 20, 0, 0)
        NameLabel.Size = UDim2.new(0, 230, 1, 0)
        NameLabel.Font = Enum.Font.SourceSans
        NameLabel.Text = tostring(Name)
        NameLabel.TextColor3 = Color3.new(1, 1, 1)
        NameLabel.TextSize = 14
        NameLabel.TextXAlignment = Enum.TextXAlignment.Left
        NameLabel.Parent = Object

        IconImage.Name = "Icon"
        IconImage.BackgroundTransparency = 1
        IconImage.Image = Icon or ""
        IconImage.Size = UDim2.new(0, 15, 0, 15)
        IconImage.Position = UDim2.new(0, 2, 0, 0)
        IconImage.Parent = Object

        Spectators.List[Name] = Spectator
        UpdateFrameSize()
    end


    function Spectators.Remove(Name: string)
        if Spectators.List[Name] then
            Spectators.List[Name].self:Destroy()
            Spectators.List[Name] = nil
        end
        UpdateFrameSize()
    end


    function Spectators:SetVisible(Visible: boolean)
        self.self.Visible = Visible
    end


    return Spectators
end


function Menu.Keybinds(): Keybinds
    local Frame = Instance.new("Frame")
    local Title = Instance.new("TextLabel")
    local List = Instance.new("Frame")
    local ListLayout = Instance.new("UIListLayout")
    local Keybinds = {self = Frame}
    Keybinds.List = {}
    Menu.Keybinds = Keybinds


    Frame.Name = "Keybinds"
    Frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    Frame.BorderColor3 = Color3.fromRGB(40, 40, 40)
    Frame.BorderMode = Enum.BorderMode.Inset
    Frame.Size = UDim2.fromOffset(250, 45)
    Frame.Position = UDim2.fromOffset(Menu.ScreenSize.X - Frame.Size.X.Offset, -36)
    Frame.Visible = false
    Frame.Parent = Menu.Screen
    CreateStroke(Frame, Color3.new(), 1)
    CreateLine(Frame, UDim2.new(0, 240, 0, 1), UDim2.new(0, 5, 0, 20))
    SetDraggable(Frame)

    Title.Name = "Title"
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 5, 0, 5)
    Title.Size = UDim2.new(0, 240, 0, 15)
    Title.Font = Enum.Font.SourceSansSemibold
    Title.Text = "Key binds"
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.TextSize = 14
    Title.Parent = Frame

    List.Name = "List"
    List.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    List.BorderColor3 = Color3.fromRGB(40, 40, 40)
    List.BorderMode = Enum.BorderMode.Inset
    List.Position = UDim2.new(0, 4, 0, 30)
    List.Size = UDim2.new(0, 240, 0, 10)
    List.Parent = Frame

    ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Padding = UDim.new(0, 3)
    ListLayout.Parent = List

    local function UpdateFrameSize()
        local Height = ListLayout.AbsoluteContentSize.Y + 5
        Keybinds.self:TweenSize(UDim2.fromOffset(250, math.clamp(Height + 45, 45, 5000)), nil, nil, 0.3, true)
        Keybinds.self.List:TweenSize(UDim2.fromOffset(240, math.clamp(Height, 10, 5000)), nil, nil, 0.3, true)
    end

    function Keybinds.Add(Name: string, State: string): Keybind
        Keybinds.Remove(Name)
        local Object = Instance.new("Frame")
        local NameLabel = Instance.new("TextLabel")
        local StateLabel = Instance.new("TextLabel")
        local Keybind = {self = Object}

        Object.Name = "Object"
        Object.BackgroundTransparency = 1
        Object.Position = UDim2.new(0, 5, 0, 30)
        Object.Size = UDim2.new(0, 230, 0, 15)
        Object.Parent = List

        NameLabel.Name = "Indicator"
        NameLabel.BackgroundTransparency = 1
        NameLabel.Position = UDim2.new(0, 5, 0, 0)
        NameLabel.Size = UDim2.new(0, 180, 1, 0)
        NameLabel.Font = Enum.Font.SourceSans
        NameLabel.Text = Name
        NameLabel.TextColor3 = Color3.new(1, 1, 1)
        NameLabel.TextSize = 14
        NameLabel.TextXAlignment = Enum.TextXAlignment.Left
        NameLabel.Parent = Object

        StateLabel.Name = "State"
        StateLabel.BackgroundTransparency = 1
        StateLabel.Position = UDim2.new(0, 190, 0, 0)
        StateLabel.Size = UDim2.new(0, 40, 1, 0)
        StateLabel.Font = Enum.Font.SourceSans
        StateLabel.Text = "[" .. tostring(State) .. "]"
        StateLabel.TextColor3 = Color3.new(1, 1, 1)
        StateLabel.TextSize = 14
        StateLabel.TextXAlignment = Enum.TextXAlignment.Right
        StateLabel.Parent = Object

        
        function Keybind:Update(State: string)
            StateLabel.Text = "[" .. tostring(State) .. "]"
        end

        function Keybind:SetVisible(Visible: boolean)
            if typeof(Visible) ~= "boolean" then return end
            if Object.Visible == Visible then return end
        
            Object.Visible = Visible
            UpdateFrameSize()
        end

        
        Keybinds.List[Name] = Keybind
        UpdateFrameSize()

        return Keybind
    end

    function Keybinds.Remove(Name: string)
        if Keybinds.List[Name] then
            Keybinds.List[Name].self:Destroy()
            Keybinds.List[Name] = nil
        end
        UpdateFrameSize()
    end

    function Keybinds:SetVisible(Visible: boolean)
        self.self.Visible = Visible
    end

    function Keybinds:SetPosition(Position: UDim2)
        self.self.Position = Position
    end

    return Keybinds
end


function Menu.Indicators(): Indicators
    local Frame = Instance.new("Frame")
    local Title = Instance.new("TextLabel")
    local List = Instance.new("Frame")
    local ListLayout = Instance.new("UIListLayout")

    local Indicators = {self = Frame}
    Indicators.List = {}
    Menu.Indicators = Indicators

    Frame.Name = "Indicators"
    Frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    Frame.BorderColor3 = Color3.fromRGB(40, 40, 40)
    Frame.BorderMode = Enum.BorderMode.Inset
    Frame.Size = UDim2.fromOffset(250, 45)
    Frame.Position = UDim2.fromOffset(Menu.ScreenSize.X - Frame.Size.X.Offset, -36)
    Frame.Visible = false
    Frame.Parent = Menu.Screen
    CreateStroke(Frame, Color3.new(), 1)
    CreateLine(Frame, UDim2.new(0, 240, 0, 1), UDim2.new(0, 5, 0, 20))
    SetDraggable(Frame)

    Title.Name = "Title"
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 5, 0, 5)
    Title.Size = UDim2.new(0, 240, 0, 15)
    Title.Font = Enum.Font.SourceSansSemibold
    Title.Text = "Indicators"
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.TextSize = 14
    Title.Parent = Frame

    List.Name = "List"
    List.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    List.BorderColor3 = Color3.fromRGB(40, 40, 40)
    List.BorderMode = Enum.BorderMode.Inset
    List.Position = UDim2.new(0, 4, 0, 30)
    List.Size = UDim2.new(0, 240, 0, 10)
    List.Parent = Frame

    ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Padding = UDim.new(0, 3)
    ListLayout.Parent = List

    local function UpdateFrameSize()
        local Height = ListLayout.AbsoluteContentSize.Y + 12
        Indicators.self:TweenSize(UDim2.fromOffset(250, math.clamp(Height + 45, 45, 5000)), nil, nil, 0.3, true)
        Indicators.self.List:TweenSize(UDim2.fromOffset(240, math.clamp(Height, 10, 5000)), nil, nil, 0.3, true)
    end

    function Indicators.Add(Name: string, Type: string, Value: string, ...): Indicator
        Indicators.Remove(Name)
        local Object = Instance.new("Frame")
        local NameLabel = Instance.new("TextLabel")
        local StateLabel = Instance.new("TextLabel")

        local Indicator = {self = Object}
        Indicator.Type = Type
        Indicator.Value = Value

        Object.Name = "Object"
        Object.BackgroundTransparency = 1
        Object.Size = UDim2.new(0, 230, 0, 30)
        Object.Parent = Indicators.self.List
        
        NameLabel.Name = "Indicator"
        NameLabel.BackgroundTransparency = 1
        NameLabel.Position = UDim2.new(0, 5, 0, 0)
        NameLabel.Size = UDim2.new(0, 130, 0, 15)
        NameLabel.Font = Enum.Font.SourceSans
        NameLabel.Text = Name
        NameLabel.TextColor3 = Color3.new(1, 1, 1)
        NameLabel.TextSize = 14
        NameLabel.TextXAlignment = Enum.TextXAlignment.Left
        NameLabel.Parent = Indicator.self
    
        StateLabel.Name = "State"
        StateLabel.BackgroundTransparency = 1
        StateLabel.Position = UDim2.new(0, 180, 0, 0)
        StateLabel.Size = UDim2.new(0, 40, 0, 15)
        StateLabel.Font = Enum.Font.SourceSans
        StateLabel.Text = "[" .. tostring(Value) .. "]"
        StateLabel.TextColor3 = Color3.new(1, 1, 1)
        StateLabel.TextSize = 14
        StateLabel.TextXAlignment = Enum.TextXAlignment.Right
        StateLabel.Parent = Indicator.self


        if Type == "Bar" then
            local ObjectBase = Instance.new("Frame")
            local ValueLabel = Instance.new("TextLabel")

            ObjectBase.Name = "Bar"
            ObjectBase.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            ObjectBase.BorderColor3 = Color3.new()
            ObjectBase.Position = UDim2.new(0, 0, 0, 20)
            ObjectBase.Size = UDim2.new(0, 220, 0, 5)
            ObjectBase.Parent = Indicator.self
    
            ValueLabel.Name = "Value"
            ValueLabel.BorderSizePixel = 0
            ValueLabel.BackgroundColor3 = Menu.Accent
            ValueLabel.Text = ""
            ValueLabel.Parent = ObjectBase
            AddEventListener(ValueLabel, function()
                ValueLabel.BackgroundColor3 = Menu.Accent
            end)
        else
            Object.Size = UDim2.new(0, 230, 0, 15)
        end


        function Indicator:Update(Value: string, ...)
            if Indicators.List[Name] then
                if Type == "Text" then
                    self.Value = Value
                    Object.State.Text = Value
                elseif Type == "Bar" then
                    local Min, Max = select(1, ...)
                    self.Min = typeof(Min) == "number" and Min or self.Min
                    self.Max = typeof(Max) == "number" and Max or self.Max

                    local Scale = (self.Value - self.Min) / (self.Max - self.Min)
                    Object.State.Text = "[" .. tostring(self.Value) .. "]"
                    Object.Bar.Value.Size = UDim2.new(math.clamp(Scale, 0, 1), 0, 0, 5)
                end
                self.Value = Value
            end
        end


        function Indicator:SetVisible(Visible: boolean)
            if typeof(Visible) ~= "boolean" then return end
            if Object.Visible == Visible then return end
            
            Object.Visible = Visible
            UpdateFrameSize()
        end

        
        Indicator:Update(Indicator.Value, ...)
        Indicators.List[Name] = Indicator
        UpdateFrameSize()
        return Indicator
    end


    function Indicators.Remove(Name: string)
        if Indicators.List[Name] then
            Indicators.List[Name].self:Destroy()
            Indicators.List[Name] = nil
        end
        UpdateFrameSize()
    end


    function Indicators:SetVisible(Visible: boolean)
        self.self.Visible = Visible
    end

    function Indicators:SetPosition(Position: UDim2)
        self.self.Position = Position
    end


    return Indicators
end


function Menu.Watermark(): Watermark
    local Watermark = {}
    Watermark.Frame = Instance.new("Frame")
    Watermark.Title = Instance.new("TextLabel")
    Menu.Watermark = Watermark

    Watermark.Frame.Name = "Watermark"
    Watermark.Frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    Watermark.Frame.BorderColor3 = Color3.fromRGB(40, 40, 40)
    Watermark.Frame.BorderMode = Enum.BorderMode.Inset
    Watermark.Frame.Size = UDim2.fromOffset(250, 20)
    Watermark.Frame.Position = UDim2.fromOffset((Menu.ScreenSize.X - Watermark.Frame.Size.X.Offset) - 50, -25)
    Watermark.Frame.Visible = false
    Watermark.Frame.Parent = Menu.Screen
    CreateStroke(Watermark.Frame, Color3.new(), 1)
    CreateLine(Watermark.Frame, UDim2.new(0, 245, 0, 1), UDim2.new(0, 2, 0, 15))
    SetDraggable(Watermark.Frame)

    Watermark.Title.Name = "Title"
    Watermark.Title.BackgroundTransparency = 1
    Watermark.Title.Position = UDim2.new(0, 5, 0, -1)
    Watermark.Title.Size = UDim2.new(0, 240, 0, 15)
    Watermark.Title.Font = Enum.Font.SourceSansSemibold
    Watermark.Title.Text = ""
    Watermark.Title.TextColor3 = Color3.new(1, 1, 1)
    Watermark.Title.TextSize = 14
    Watermark.Title.RichText = true
    Watermark.Title.Parent = Watermark.Frame

    function Watermark:Update(Text: string)
        self.Title.Text = tostring(Text)
    end

    function Watermark:SetVisible(Visible: boolean)
        self.Frame.Visible = Visible
    end

    return Watermark
end


function Menu:Init()
    UserInput.InputBegan:Connect(function(Input: InputObject, Process: boolean) end)
    UserInput.InputEnded:Connect(function(Input: InputObject)
        if (Input.UserInputType == Enum.UserInputType.Touch) then
            Dragging = {Gui = nil, True = false}
        end
    end)
    RunService.RenderStepped:Connect(function(Step: number)
        local Menu_Frame = Menu.Screen.Menu
        Menu_Frame.Position = UDim2.fromOffset(
            math.clamp(Menu_Frame.AbsolutePosition.X,   0, math.clamp(Menu.ScreenSize.X - Menu_Frame.AbsoluteSize.X, 0, Menu.ScreenSize.X    )),
            math.clamp(Menu_Frame.AbsolutePosition.Y, -36, math.clamp(Menu.ScreenSize.Y - Menu_Frame.AbsoluteSize.Y, 0, Menu.ScreenSize.Y - 36))
        )
        local Selected_Frame = Selected.Frame
        local Selected_Item = Selected.Item
        if (Selected_Frame and Selected_Item) then
            local Offset = Selected.Offset or UDim2.fromOffset()
            local Position = UDim2.fromOffset(Selected_Item.AbsolutePosition.X, Selected_Item.AbsolutePosition.Y)
            Selected_Frame.Position = Position + Offset
        end
    
        if Scaling.True then
            MenuScaler_Button.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            local Origin = Scaling.Origin
            local Size = Scaling.Size
    
            if Origin and Size then
                local Location = UserInput:GetMouseLocation()
                local NewSize = Location + (Size - Origin)
    
                Menu:SetSize(Vector2.new(
                    math.clamp(NewSize.X, Menu.MinSize.X, Menu.MaxSize.X),
                    math.clamp(NewSize.Y, Menu.MinSize.Y, Menu.MaxSize.Y)
                ))
            end
        else
            MenuScaler_Button.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        end
    
        Menu.Hue += math.clamp(Step / 100, 0, 1)
        if Menu.Hue >= 1 then Menu.Hue = 0 end
    
        if ToolTip.Enabled == true then
            ToolTip_Label.Text = ToolTip.Content
            ToolTip_Label.Position = UDim2.fromOffset(ToolTip.Item.AbsolutePosition.X, ToolTip.Item.AbsolutePosition.Y + 25)
        end
    end)
    Menu.Screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        Menu.ScreenSize = Menu.Screen.AbsoluteSize
    end)
end


-- // Typing Title Example \\ --


 loadstring(game:HttpGet("https://raw.githubusercontent.com/Pixeluted/adoniscries/main/Source.lua",true))()

--Enum.EasingStyle.Elastic , Enum.EasingDirection.InOut

local SkibidiHook = {
   Target_Lock = {
     Enabled = false,
     Method = "Namecall",
     Prediction = 0.1603,
     JumpPrediction = 0.11777,
     JumpOffset = 0,
     WallCheck = false,
     Resolver = {
       Enabled = false,
       Type = "LookVector",
     },
     AutoJumpPrediction = {
       Enabled = false,
         Numerator = 0.0005,
         Precision = 2,
     },
     AutoJumpOffset = {
       Enabled = false,
     },
     AutoPrediction = {
       Enabled = false,
       Type = "Math", --Normal, Math, Set Based
       Set_Based_Config = {
         OriginalPing = 85,
         Method = "A",
         Precision = 6,
       },
       Math_Config = {
         Numerator = 0.000507,
         Precision = 5,
       },
     },
   },
   Self_Bot = { --unfinished
     Enabled = false,
     Type = "HvH", -- Tryhard, HvH
     FollowTarget = false,
   },
   Hit_Detection = {
       Enabled = true,
       Color = Color3.fromRGB(255,255,255),
       HitSound = true,
       Sound = "Bubble",
   },
   Variables = {
     Vect3 = Vector3.new,
     Vect2 = Vector2.new,
   },
   Camera_Lock = {
     Enabled = false,
     Prediction = 7.5,
     Smoothness = 1,
     Resolver = {
       Enabled = false,
       Type = "LookVector",
     },
     AutoPrediction = {
       Enabled = false,
       Type = "Math", --Normal, Math, Set Based
       Math_Config = {
         Numerator = 0.00067369,
         Precision = 5,
       },
     },
    },
}



local AutoReload = false

while AutoReload == true and game:GetService("RunService").Heartbeat:Wait() do
if game:GetService("Players").LocalPlayer.Character:FindFirstChildWhichIsA("Tool") then
            if game:GetService("Players").LocalPlayer.Character:FindFirstChildWhichIsA("Tool"):FindFirstChild("Ammo") then
                if game:GetService("Players").LocalPlayer.Character:FindFirstChildWhichIsA("Tool"):FindFirstChild("Ammo").Value <= 0 then
                    game:GetService("ReplicatedStorage").MainEvent:FireServer("Reload", game:GetService("Players").LocalPlayer.Character:FindFirstChildWhichIsA("Tool")) 
                    wait(1)
                end
            end
        end
end


local ProMode = workspace.CurrentCamera.ViewportSize * 0.5
getgenv().ShakeX = 0
getgenv().ShakeY = 0
getgenv().LookAt = false
getgenv().SmoothnessEnabled = false
getgenv().RealJumpOffset = nil
getgenv().CAMPREDICTION = SkibidiHook.Camera_Lock.Prediction
getgenv().Smoothness = SkibidiHook.Camera_Lock.Smoothness
getgenv().JUMPOFFSET = SkibidiHook.Target_Lock.JumpOffset
getgenv().SelectedPart = "HumanoidRootPart"
getgenv().CamSelectedPart = "HumanoidRootPart"
getgenv().PREDICTION = SkibidiHook.Target_Lock.Prediction
getgenv().JUMPPREDICTION = SkibidiHook.Target_Lock.JumpPrediction
local ResolverMethodPlaceholder = {
    "None",
    "Delta Time",
    "MoveDirection",
    "LookVector",
}
local setprecisiontthing = string.len(PREDICTION)-2
local Settings_visuals = { 
    Dot = { 
        Size = Vector3.new(0.9, 1.2, 0.9),
    },
    Tracer = { 
        TracerThickness = 3.5,
        TracerTransparency = 1,
        TracerColor = Color3.fromRGB(0, 218, 0)
    }
}
local function CaclulateDeltaAssemblyLinearVelocity(TargetHitBone)
        local HitboxPart = TargetHitBone
        local CurrentPosition = HitboxPart.Position
        local CurrentTime = tick() 
        task.wait() 
        local NewPosition = HitboxPart.Position
        local NewTime = tick()
        local DistanceTravelled = (NewPosition - CurrentPosition)
        local TimeInterval = NewTime - currentTime
        local AssemblyLinearVelocity = DistanceTravelled / TimeInterval
        CurrentPosition = NewPosition
        CurrentTime = NewTime
        return AssemblyLinearVelocity
end
local Ranges = {
        Close = 30,
        Mid = 100
}
local NotificationHolder = loadstring(game:HttpGet("https://raw.githubusercontent.com/BocusLuke/UI/main/STX/Module.Lua"))()
local Notification = loadstring(game:HttpGet("https://raw.githubusercontent.com/BocusLuke/UI/main/STX/Client.Lua"))()

function SendNotification(text)
    Notification:Notify(
        {Title = "khen.cc", Description = "Lock - "..text},
        {OutlineColor = Color3.fromRGB(143, 48, 167),Time = 3, Type = "image"},
        {Image = "http://www.roblox.com/asset/?id=6023426923", ImageColor = Color3.fromRGB(143, 48, 167)}
    )
end

--// Change Prediction,  AutoPrediction Must Be Off
    local lPlr = game.Players.LocalPlayer
    local AnchorCount = 0
    local MaxAnchor = 50
    local CC = game:GetService"Workspace".CurrentCamera
    local Plr;
    local LocalPlayer = game.Players.LocalPlayer
local Line = Drawing.new("Line")
local Inset = game:GetService("GuiService"):GetGuiInset().Y
local Mouse = LocalPlayer:GetMouse()
local CurrentCamera = workspace.CurrentCamera 
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
    local enabled = false
    local mouse = game.Players.LocalPlayer:GetMouse()
    local placemarker = Instance.new("Part", game.Workspace)
    _G.Types = {
        Ball = Enum.PartType.Ball,
        Block = Enum.PartType.Block, 
        Cylinder = Enum.PartType.Cylinder
    }
 -- parent is workspace :GHASP:
local Dot = Instance.new("Part", game.Workspace)

Dot.Size = Settings_visuals.Dot.Size
Dot.CanCollide = false
Dot.Anchored = true
Dot.Shape = Enum.PartType.Ball 
Dot.Name = "LorisKJiggaboo"


function CheckWall(head)
   if v == LocalPlayer then return false end
       local castPoints = {LocalPlayer.Character.Head.Position, head.Position}
       local ignoreList = {LocalPlayer.Character,head.Parent}
       a = workspace.CurrentCamera:GetPartsObscuringTarget(castPoints, ignoreList)
       if #a == 0 then return false end

   return true
end
spawn(function()
    RunService.Stepped:Connect(function()
        Dot.Material = Enum.Material.Neon
    end)
end)

local function DrawLine(p, vec_1, vec_2)
	local m = (vec_1 - vec_2).Magnitude
	p.Size = Vector3.new(p.Size.X, p.Size.Y,  m)
	p.CFrame = CFrame.new(
		vec_1:Lerp(vec_2, 0.6),
		vec_2
	)
	return part
end


local TargetLine = Instance.new("Part")
TargetLine.Parent = workspace
TargetLine.Anchored = true
TargetLine.Size = Vector3.new(0.1,0.1,0.1)
TargetLine.Color = Color3.fromRGB(255,255,255)
TargetLine.Material = "Neon"
TargetLine.CanCollide = false
TargetLine.Transparency = 0

spawn(function()
    RunService.Heartbeat:Connect(function()
--[[
if getgenv().Settings.RageBot.Enabled then 
    if game:GetService("Players").LocalPlayer.Character:FindFirstChildWhichIsA("Tool") ~= nil then
        if game:GetService("Players").LocalPlayer.Character:FindFirstChildWhichIsA("Tool"):FindFirstChild("Ammo") then
            if game:GetService("Players").LocalPlayer.Character:FindFirstChildWhichIsA("Tool"):FindFirstChild("Ammo").Value <= 0 then
                game:GetService("ReplicatedStorage").MainEvent:FireServer(
                "Reload",
                game:GetService("Players").LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
                )
            end
        end
    end
  for _,q in pairs (game:GetService("Players"):GetPlayers()) do 
    if q ~= LocalPlayer and q and q.Character  then
        local RageBotD = (LocalPlayer.Character.HumanoidRootPart.Position - q.Character.HumanoidRootPart.Position).Magnitude
        if getgenv().Settings.RageBot.Distance > RageBotD and not CheckWall(q.Character.Head) then
            if q.Character.Humanoid.Health  > 5 then
                getgenv().RBTarget = q
                    if getgenv().RBTarget ~= nil then 
                        LocalPlayer.Character:FindFirstChildOfClass("Tool"):Activate()
                    end 
                end 
            end
        end
    end
end
if getgenv().RBTarget ~= nil and LocalPlayer.Character:FindFirstChildWhichIsA("Tool") ~= nil then  
    if LocalPlayer.Information.Armory[tostring(LocalPlayer.Character:FindFirstChildWhichIsA("Tool"))].Ammo.Normal.Value > 0 and getgenv().RBTarget ~= nil then 
    if getgenv().RBTarget ~= nil then 
    LocalPlayer.Character:FindFirstChildOfClass("Tool"):Activate()
end 
end
end
if getgenv().Settings.RageBot.LookAt and getgenv().RBTarget ~= nil then 
            local OldCframe = LocalPlayer.Character.PrimaryPart
            local NearestRoot = getgenv().RBTarget.Character.HumanoidRootPart
            local NearestPos = CFrame.new(LocalPlayer.Character.PrimaryPart.Position, Vector3.new(NearestRoot.Position.X, OldCframe.Position.Y, NearestRoot.Position.Z))
            LocalPlayer.Character:SetPrimaryPartCFrame(NearestPos)
            LocalPlayer.Character.Humanoid.AutoRotate = false 
end 
]]
        if SkibidiHook.Target_Lock.Enabled and enabled then
            Dot.Transparency = 0
        else
            Dot.Transparency = 1 
        end
    
        if SkibidiHook.Target_Lock.Enabled and enabled and Plr then
       Dot.CFrame = CFrame.new(Plr.Character[getgenv().SelectedPart].Position+SkibidiHook.Variables.Vect3(0,RealJumpOffset,0)+(SkibidiHook.Variables.Vect3(Plr.Character.HumanoidRootPart.AssemblyLinearVelocity.X*getgenv().PREDICTION,math.clamp(Plr.Character.HumanoidRootPart.AssemblyLinearVelocity.Y*getgenv().JUMPPREDICTION,-1,10),Plr.Character.HumanoidRootPart.AssemblyLinearVelocity.Z*getgenv().PREDICTION)))
        end
        Dot.Color = Color3.fromRGB(143, 48, 167)
        if SkibidiHook.Target_Lock.Enabled and enabled and Plr then
            local heyloris = CurrentCamera:WorldToViewportPoint(Plr.Character[getgenv().SelectedPart].Position+SkibidiHook.Variables.Vect3(0,RealJumpOffset,0)+(SkibidiHook.Variables.Vect3(Plr.Character.HumanoidRootPart.AssemblyLinearVelocity.X*getgenv().PREDICTION,math.clamp(Plr.Character.HumanoidRootPart.AssemblyLinearVelocity.Y*getgenv().JUMPPREDICTION,-1,10),Plr.Character.HumanoidRootPart.AssemblyLinearVelocity.Z*getgenv().PREDICTION)))
            Line.Color = Color3.fromRGB(143, 48, 167)
            Line.Thickness = Settings_visuals.Tracer.TracerThickness
            Line.From = ProMode
            Line.To = Vector2.new(heyloris.X, heyloris.Y)
            Line.Visible = true
        else
            Line.Visible = false
        end
        end)
end)

local Target = nil



mouse.KeyDown:Connect(function(k)
    if k ~= "c" then return end
if SkibidiHook.Target_Lock.Enabled then
            if enabled == true then
                enabled = false
                Plr = LockToPlayer()
                Target = nil
     SendNotification("Unlocked")
            else
                Plr = LockToPlayer()
                Target = Plr
                enabled = true
SendNotification(Plr.Character.Humanoid.DisplayName)
            end
   else
  SendNotification("Target not enabled!")
        end
end)



mouse.KeyDown:Connect(function(k)
  if k ~= "c" then return end
if SkibidiHook.Camera_Lock.Enabled then
            if Cenabled == true then
                Cenabled = false
                PlrC = LockToPlayer()
                TargetAimassist = nil
     SendNotification("Unlocked")
            else
                PlrC = LockToPlayer()
                TargetAimassist = PlrC
                enabled = true
SendNotification(PlrC.Character.Humanoid.DisplayName)
            end
   else
  SendNotification("Camlock not enabled!")
        end
end)

function LockToPlayer()
        local closestPlayer
        local shortestDistance = math.huge
        for i, v in pairs(game.Players:GetPlayers()) do
            if v ~= game.Players.LocalPlayer and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health ~= 0 and v.Character:FindFirstChild("HumanoidRootPart") then
                local pos = CC:WorldToViewportPoint(v.Character.PrimaryPart.Position)
                local magnitude = (SkibidiHook.Variables.Vect2(pos.X, pos.Y) - SkibidiHook.Variables.Vect2(mouse.X, mouse.Y)).magnitude
                if magnitude < shortestDistance then
                    closestPlayer = v
                    shortestDistance = magnitude
                end
            end
        end
        return closestPlayer
end

function GetClosestPlr()
        local cloosestPlayer
        local shoortestDistance = math.huge
        for i, v in pairs(game.Players:GetPlayers()) do
            if v ~= game.Players.LocalPlayer and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health ~= 0 and v.Character:FindFirstChild("HumanoidRootPart") then
                local poos = CC:WorldToViewportPoint(v.Character.PrimaryPart.Position)
                local maagnitude = (SkibidiHook.Variables.Vect2(poos.X, poos.Y) - ProMode).magnitude
                if maagnitude < shoortestDistance then
                    cloosestPlayer = v
                    shoortestDistance = maagnitude
                end
            end
        end
        return cloosestPlayer
end



        local function wallCheck(destination, ignore)
            if SkibidiHook.Target_Lock.WallCheck then
                local origin = Camera.CFrame.p
                local checkRay = Ray.new(origin, destination - origin)
                local hit = workspace:FindPartOnRayWithIgnoreList(checkRay, ignore)
                return hit == nil
            else
                return true
            end
        end

local TargetAimassist = nil 

game:GetService"RunService".Stepped:connect(function()
    if Cenabled then
        if PlrC ~= nil and PlrC.Character then
            local shakeOffset = SkibidiHook.Variables.Vect3(
                math.random(-getgenv().ShakeX, getgenv().ShakeX),
                math.random(-getgenv().ShakeY, getgenv().ShakeY),
                math.random(-getgenv().ShakeX, getgenv().ShakeX)) * 0.1
if SmoothnessEnabled then
local LookPosition = CFrame.new(CC.CFrame.p, PlrC.Character[getgenv().CamSelectedPart].Position+(SkibidiHook.Variables.Vect3(PlrC.Character.HumanoidRootPart.AssemblyLinearVelocity.X/CAMPREDICTION,math.clamp(PlrC.Character.HumanoidRootPart.AssemblyLinearVelocity.Y/CAMPREDICTION,-1,10),PlrC.Character.HumanoidRootPart.AssemblyLinearVelocity.Z/CAMPREDICTION))+shakeOffset)
     CC.CFrame = CC.CFrame:Lerp(LookPosition, Smoothness,Enum.EasingStyle.Elastic, Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
else
     CC.CFrame = CFrame.new(CC.CFrame.p, PlrC.Character[getgenv().CamSelectedPart].Position+(SkibidiHook.Variables.Vect3(PlrC.Character.HumanoidRootPart.AssemblyLinearVelocity.X/CAMPREDICTION,math.clamp(PlrC.Character.HumanoidRootPart.AssemblyLinearVelocity.Y/CAMPREDICTION,-1,10),PlrC.Character.HumanoidRootPart.AssemblyLinearVelocity.Z/CAMPREDICTION))+shakeOffset)
      end
    end
end
end)

            local lastStutterTime = 0
            local stutterAmount = 0
            local stutterEnabled = false
            

game:GetService"RunService".Stepped:connect(function()
                if PlrC ~= nil then
                    local currentTime = tick()
                    if stutterEnabled and currentTime - lastStutterTime < stutterAmount then
                        return
                    end
                    lastStutterTime = currentTime
                end
            end)

 
local Stats = game:GetService("Stats")
    getgenv().UnlockOnDeath = false
    local pingvalue = nil;
    local split = nil;
    local ping = nil;
local LocalHL = Instance.new("Highlight") 
local BUr = Instance.new("Highlight")
    game:GetService"RunService".Stepped:connect(function()
if getgenv().LookAt == true and enabled  and Plr then
    local Char = game.Players.LocalPlayer.Character
    local PrimaryPartOfChar = game.Players.LocalPlayer.Character.PrimaryPart
    local NearestChar = Plr.Character
    local NearestRoot = Plr.Character.HumanoidRootPart
    local NearestPos = CFrame.new(PrimaryPartOfChar.Position, Vector3.new(NearestRoot.Position.X, Cha.Position.Y, NearestRoot.Position.Z))
    Char:SetPrimaryPartCFrame(NearestPos)
end
if getgenv().UnlockOnDeath == true and Plr and Plr.Character:FindFirstChild("Humanoid") then
        if Plr.Character.Humanoid.Health < 5 then
            Plr = nil
            Dot.Transparency = 1 
            Line.Visible = false
            enabled = false
        end
end
--[[
if Plr and enabled then
local player = Plr
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local function onAssemblyLinearVelocityIntersected()
    print("AssemblyLinearVelocity Intersected HumanoidRootPart")
end

local function isInsideRootPart(position, rootPartPosition, rootPartSize)
    return position.X >= rootPartPosition.X - rootPartSize.X / 2 and
           position.X <= rootPartPosition.X + rootPartSize.X / 2 and
           position.Y >= rootPartPosition.Y - rootPartSize.Y / 2 and
           position.Y <= rootPartPosition.Y + rootPartSize.Y / 2 and
           position.Z >= rootPartPosition.Z - rootPartSize.Z / 2 and
           position.Z <= rootPartPosition.Z + rootPartSize.Z / 2
end

local lastInside = false

function SetIntersectionalFix()
    local rootPartPosition = humanoidRootPart.Position
    local rootPartSize = humanoidRootPart.Size
    local characterPosition = humanoidRootPart.Position + (SkibidiHook.Variables.Vect3(humanoidRootPart.AssemblyLinearVelocity.X * PREDICTION,0,humanoidRootPart.AssemblyLinearVelocity.Z * PREDICTION))
    local characterAssemblyLinearVelocity = humanoidRootPart.AssemblyLinearVelocity
    local oldPREDICTON = PREDICTION
    local isInside = isInsideRootPart(characterPosition, rootPartPosition, rootPartSize)
    if isInside and not lastInside then
        AdjustedPrediction = PREDICTION*0.78
      return AdjustedPrediction
      else
      return oldPREDICTON
    end
    lastInside = isInside
end
PREDICTION = SetIntersectionalFix()
end]]
        if SkibidiHook.Target_Lock.Enabled and Plr and Plr.Character ~= nil and Plr.Character:FindFirstChild("HumanoidRootPart") and enabled and Plr.Character ~= nil then
if getgenv().Prediction == "Normal" then
  DrawLine(TargetLine,Plr.Character.HumanoidRootPart.Position,Plr.Character[getgenv().SelectedPart].Position+(SkibidiHook.Variables.Vect3(Plr.Character.HumanoidRootPart.AssemblyLinearVelocity.X,math.clamp(Plr.Character.HumanoidRootPart.AssemblyLinearVelocity.Y,0,5),Plr.Character.HumanoidRootPart.AssemblyLinearVelocity.Z)*getgenv().PREDICTION))
  TargetLine.Transparency = 0
end
LocalHL.Parent = Plr.Character
LocalHL.FillTransparency = 0.2
LocalHL.FillColor = Color3.fromRGB(143, 48, 167)
LocalHL.OutlineColor = Color3.fromRGB(143, 48, 167)
        else
  TargetLine.Transparency = 100
    LocalHL.Parent = nil
  end
pingvalue = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString()
split = string.split(pingvalue,'(')
ping = tonumber(split[1])
if SkibidiHook.Camera_Lock.AutoPrediction.Enabled then
    if ping < 30 then
        CAMPREDICTION = 7.758
    elseif ping < 40 then
        CAMPREDICTION = 7.364
    elseif ping < 50 then
        CAMPREDICTION = 7.456 
    elseif ping < 60 then
        CAMPREDICTION = 7.217
    elseif ping < 70 then
        CAMPREDICTION = 6.972 
    elseif ping < 80 then
        CAMPREDICTION = 6.782
    elseif ping < 90 then
        CAMPREDICTION = 6.597 
    elseif ping < 100 then
        CAMPREDICTION = 3.88
    elseif ping < 110 then
        CAMPREDICTION = 6.099
    end
end
if SkibidiHook.Target_Lock.AutoPrediction.Enabled then
    if SkibidiHook.Target_Lock.AutoPrediction.Type == "Normal" then
        if ping > 150 then
        PREDICTION = math.floor((0.1+(ping*SkibidiHook.Target_Lock.AutoPrediction.Math_Config.Numerator)) * 10^SkibidiHook.Target_Lock.AutoPrediction.Math_Config.Precision) / 10^SkibidiHook.Target_Lock.AutoPrediction.Math_Config.Precision;
        elseif ping < 150 then
            PREDICTION = 0.169873582
        elseif ping < 140 then
            PREDICTION = 0.1692643
        elseif ping < 130 then
            PREDICTION = 0.16875864
        elseif ping < 120 then
            PREDICTION = 0.16683943
        elseif ping < 110 then
            PREDICTION = 0.16362652
        elseif ping < 100 then
            PREDICTION = 0.161987
        elseif ping < 90 then
            PREDICTION = 0.161987
        elseif ping < 80 then
            PREDICTION = 0.149340
        elseif ping < 70 then
            PREDICTION = 0.14533
        elseif ping < 65 then
            PREDICTION = 0.1264236
        elseif ping < 50 then
            PREDICTION = 0.13544
        elseif ping < 30 then
            PREDICTION = 0.11252476
        elseif ping < 25 then
            PREDICTION = 0.105728
        end
    elseif SkibidiHook.Target_Lock.AutoPrediction.Type == "Math" then
        getgenv().PREDICTION = math.floor((0.1+(ping*SkibidiHook.Target_Lock.AutoPrediction.Math_Config.Numerator)) * 10^SkibidiHook.Target_Lock.AutoPrediction.Math_Config.Precision) / 10^SkibidiHook.Target_Lock.AutoPrediction.Math_Config.Precision;
	elseif SkibidiHook.Target_Lock.AutoPrediction.Type == "Set Based" then
	if SkibidiHook.Target_Lock.AutoPrediction.Set_Based_Config.Method == "A" then
   getgenv().PREDICTION = math.floor((((SkibidiHook.Target_Lock.Prediction + (620 - (555+65)))*0.5) + (ping*SkibidiHook.Target_Lock.Prediction/(SkibidiHook.Target_Lock.AutoPrediction.Set_Based_Config.OriginalPing*2)))*10^setprecisiontthing)/10^setprecisiontthing;
		elseif SkibidiHook.Target_Lock.AutoPrediction.Set_Based_Config.Method == "B" then
      getgenv().PREDICTION = math.floor((((SkibidiHook.Target_Lock.Prediction + (620 - (555+65)))*-1) + (ping*SkibidiHook.Target_Lock.Prediction/(SkibidiHook.Target_Lock.AutoPrediction.Set_Based_Config.OriginalPing*2)))*10^SkibidiHook.Target_Lock.AutoPrediction.Set_Based_Config.Precision)/10^SkibidiHook.Target_Lock.AutoPrediction.Set_Based_Config.Precision;
        end
  end
end
if SkibidiHook.Target_Lock.AutoJumpOffset.Enabled then
getgenv().JUMPOFFSET = math.floor(((ping*0.0010001)) * 10^3) / 10^3
--10001
end
if SkibidiHook.Target_Lock.AutoJumpPrediction.Enabled then
  getgenv().JUMPPREDICTION = math.floor((0.1+(ping*SkibidiHook.Target_Lock.AutoJumpPrediction.Numerator)) * 10^SkibidiHook.Target_Lock.AutoJumpPrediction.Precision) / 10^SkibidiHook.Target_Lock.AutoJumpPrediction.Precision
end
if SkibidiHook.Target_Lock.Resolver.Enabled and Plr ~= nil then
if ResolverMethodPlaceholder == "Delta Time" then
                Plr.Character[getgenv().SelectedPart].AssemblyLinearVelocity = CaclulateDeltaAssemblyLinearVelocity(Plr.Character[getgenv().SelectedPart])
                Plr.Character[getgenv().SelectedPart].AssemblyLinearVelocity = CaclulateDeltaAssemblyLinearVelocity(Plr.Character[getgenv().SelectedPart])
end
end
    end)


-- Connect new players
game.Players.PlayerAdded:Connect(setupHitMarker)
--

    local mt = getrawmetatable(game)
    local old = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(...)
        local args = {...}
        local vap = {"UpdateMousePos", "GetMousePos", "MousePos", "MOUSE", "MousePosUpdate", "mouse", "Mouse"}
        if enabled and getnamecallmethod() == "FireServer" and table.find(vap, args[2]) and SkibidiHook.Target_Lock.Enabled and Plr.Character ~= nil and SkibidiHook.Target_Lock.Method == "Namecall" then
      if getgenv().Prediction == "Normal" then
      if SkibidiHook.Target_Lock.Resolver.Enabled == false then
            args[3] = Plr.Character[getgenv().SelectedPart].Position+SkibidiHook.Variables.Vect3(0,RealJumpOffset,0)+(SkibidiHook.Variables.Vect3(Plr.Character.HumanoidRootPart.AssemblyLinearVelocity.X*getgenv().PREDICTION,math.clamp(Plr.Character.HumanoidRootPart.AssemblyLinearVelocity.Y*getgenv().JUMPPREDICTION,-2,10),Plr.Character.HumanoidRootPart.AssemblyLinearVelocity.Z*getgenv().PREDICTION))
      elseif SkibidiHook.Target_Lock.Resolver.Enabled == true and SkibidiHook.Target_Lock.Resolver.Method == "MoveDirection" then
     args[3] = Plr.Character[getgenv().SelectedPart].Position + (Plr.Character.Humanoid.MoveDirection * Plr.Character.Humanoid.WalkSpeed * getgenv().PREDICTION)
      elseif SkibidiHook.Target_Lock.Resolver.Enabled == true and SkibidiHook.Target_Lock.Resolver.Method == "LookVector" then
     args[3] = Plr.Character[getgenv().SelectedPart].Position + (Plr.Character[getgenv().SelectedPart].CFrame.LookVector * getgenv().PREDICTION*1.5)
     end
            else
            args[3] = Plr.Character[SelectedPart].Position
            end
            return old(unpack(args))
        end
        return old(...)
    end)






local Hooks = {}
local Client = game:GetService("Players").LocalPlayer
Hooks[1] = hookmetamethod(Client:GetMouse(), "__index", newcclosure(function(self, index)
    if index == "Hit" and SkibidiHook.Target_Lock.Method == "Index" and enabled and Plr.Character ~= nil and SkibidiHook.Target_Lock.Enabled then
        
            local position = CFrame.new(Plr.Character[getgenv().SelectedPart].Position+SkibidiHook.Variables.Vect3(0,RealJumpOffset,0)+(SkibidiHook.Variables.Vect3(Plr.Character.HumanoidRootPart.AssemblyLinearVelocity.X*getgenv().PREDICTION,math.clamp(Plr.Character.HumanoidRootPart.AssemblyLinearVelocity.Y*getgenv().JUMPPREDICTION,-2,10),Plr.Character.HumanoidRootPart.AssemblyLinearVelocity.Z*getgenv().PREDICTION)))
            
            return position
    end
    return Hooks[1](self, index)
end))

getgenv().crosshair = {
    enabled = false,
    refreshrate = 0,
    mode = 'center', -- center, mouse, custom
    position = Vector2.new(0,0), -- custom position

    width = 1.5,
    length = 10,
    radius = 11,
    color = Color3.fromRGB(143, 48, 167),

    spin = true, -- animate the rotation
    spin_speed = 150,
    spin_max = 340,
    spin_style = Enum.EasingStyle.Circular, -- Linear for normal smooth spin

    resize = true, -- animate the length
    resize_speed = 150,
    resize_min = 5,
    resize_max = 22,

}

local old; old = hookfunction(Drawing.new, function(class, properties)
    local drawing = old(class)
    for i,v in next, properties or {} do
        drawing[i] = v
    end
    return drawing
end)

local runservice = game:GetService('RunService')
local inputservice = game:GetService('UserInputService')
local tweenservice = game:GetService('TweenService')
local camera = workspace.CurrentCamera

local last_render = 0

local drawings = {
    crosshair = {},
    text = {
        Drawing.new('Text', {Size = 13, Font = 2, Outline = true, Text = 'khen', Color = Color3.new(255, 255,255)}),
        Drawing.new('Text', {Size = 13, Font = 2, Outline = true, Text = ".cc", Color = Color3.new(255, 130,9)}),
	
    }
}

for idx = 1, 4 do
    drawings.crosshair[idx] = Drawing.new('Line')
    drawings.crosshair[idx + 4] = Drawing.new('Line')
end

function solve(angle, radius)
    return Vector2.new(
        math.sin(math.rad(angle)) * radius,
        math.cos(math.rad(angle)) * radius
    )
end

runservice.PostSimulation:Connect(function()

    local _tick = tick()

    if _tick - last_render > crosshair.refreshrate then
        last_render = _tick

        local position = (
            crosshair.mode == 'center' and camera.ViewportSize / 2 or
            crosshair.mode == 'mouse' and inputservice:GetMouseLocation() or
            crosshair.position
        )

        local text_1 = drawings.text[1]
        local text_2 = drawings.text[2]

        text_1.Visible = crosshair.enabled
        text_2.Visible = crosshair.enabled

        if crosshair.enabled then

            local text_x = text_1.TextBounds.X + text_2.TextBounds.X

            text_1.Position = position + Vector2.new(-text_x / 2, crosshair.radius + (crosshair.resize and crosshair.resize_max or crosshair.length) + 15)
            text_2.Position = text_1.Position + Vector2.new(text_1.TextBounds.X)
            text_2.Color = crosshair.color
            
            for idx = 1, 4 do
                local outline = drawings.crosshair[idx]
                local inline = drawings.crosshair[idx + 4]
    
                local angle = (idx - 1) * 90
                local length = crosshair.length
    
                if crosshair.spin then
                    local spin_angle = -_tick * crosshair.spin_speed % crosshair.spin_max
                    angle = angle + tweenservice:GetValue(spin_angle / 360, crosshair.spin_style, Enum.EasingDirection.InOut) * 360
                end
    
                if crosshair.resize then
                    local resize_length = tick() * crosshair.resize_speed % 180
                    length = crosshair.resize_min + math.sin(math.rad(resize_length)) * crosshair.resize_max
                end
    
                inline.Visible = true
                inline.Color = crosshair.color
                inline.From = position + solve(angle, crosshair.radius)
                inline.To = position + solve(angle, crosshair.radius + length)
                inline.Thickness = crosshair.width
    
                outline.Visible = true
                outline.From = position + solve(angle, crosshair.radius - 1)
                outline.To = position + solve(angle, crosshair.radius + length + 1)
                outline.Thickness = crosshair.width + 1.5    
            end
        else
            for idx = 1, 4 do
                drawings.crosshair[idx].Visible = false
                drawings.crosshair[idx + 4].Visible = false
            end
        end

    end
end)

local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local TextButton = Instance.new("TextButton")
local UITextSizeConstraint = Instance.new("UITextSizeConstraint")

--Properties:

ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

Frame.Parent = ScreenGui
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.BackgroundTransparency = 0
Frame.Position = UDim2.new(1, -120, 0, 0)
Frame.Size = UDim2.new(0, 100, 0, 50)

TextButton.Parent = Frame
TextButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextButton.BackgroundTransparency = 1.000
TextButton.Size = UDim2.new(1, 0, 1, 0)
TextButton.Font = Enum.Font.Code
TextButton.Text = "love nini"
TextButton.TextColor3 = Color3.fromRGB(143, 48, 167)
TextButton.TextScaled = true
TextButton.TextSize = 30
TextButton.TextStrokeColor3 = Color3.fromRGB(143, 48, 167)
TextButton.TextStrokeTransparency = 0.000
TextButton.TextWrapped = true
    
TextButton.MouseButton1Down:Connect(function()
    Menu_Frame.Visible = not Menu_Frame.Visible
end)


UITextSizeConstraint.Parent = TextButton
UITextSizeConstraint.MaxTextSize = 30

local player = game.Players.LocalPlayer

-- Function to show the GUI when the character respawns
local function onCharacterAdded(character)
    ScreenGui.Parent = player.PlayerGui
end

-- Function to connect character respawn event
local function connectCharacterAdded()
    player.CharacterAdded:Connect(onCharacterAdded)
end

-- Connect the CharacterAdded event
connectCharacterAdded()

-- Keep the GUI visible when the character dies
player.CharacterRemoving:Connect(function()
    ScreenGui.Parent = nil
end) 

Menu:SetSize(360, 280)
Menu.Tab("Main")
Menu.Tab("Configuration")
Menu.Tab("Skibidi")

local function MenuNameUpdate()
        while (task.wait()) do
            local Name, PlaceHolder = 'khen', ''
            for i = 1, #Name do --try
                local Character = string.sub(Name, i, i)
                PlaceHolder = PlaceHolder .. Character
                Menu:SetTitle(PlaceHolder .. '<font color="#' .. tostring(Menu.Accent:ToHex()) .. '">.cc</font>')
                task.wait(.40)
            end
        end
    end
  
task.spawn(MenuNameUpdate)


Menu.Watermark()
Menu.Watermark:Update('IM FROM <font color="#' .. tostring(Menu.Accent:ToHex()) .. '">VIETNAM</font>') -- please fix this and we can add a variable for a color.

  --\\ Setting Stuff Function
  Menu.Watermark:SetVisible(true)
  Menu:SetVisible(true)
  Menu:Init()
  
-- u can add the changing text by skidding from gamesneeze or tyrisware text changer

-- also use the source for a better understanding on how to add toggles, dropdowns, keybinds and more

Menu.Container("Main", "Killbot", "Left")
Menu.Container("Main", "Configure", "Left")
Menu.Container("Configuration", "Config", "Left")
Menu.Container("Main", "Cframe Desync", "Right")
Menu.Container("Main", "Visuals", "Right")
Menu.Container("Skibidi", "Owner by khen", "Left")



Menu.CheckBox("Main", "Killbot", "Enabled", false, function(x) 
SkibidiHook.Target_Lock.Enabled = x
end)

Menu.CheckBox("Main", "Killbot", "Camlock", false, function(x) 
SkibidiHook.Camera_Lock.Enabled = x
end)

Menu.Button("Main", "Killbot", "Load Tool", function(x)
 if getgenv().CheckIfScriptLoaded == true then
  SendNotification("Tool Already Loaded!")
    return
end
    
getgenv().CheckIfScriptLoaded = true
local Tool = Instance.new("Tool")
Tool.RequiresHandle = false
Tool.Name = "Target Tool"
Tool.Parent = game.Players.LocalPlayer.Backpack
local player = game.Players.LocalPlayer
local function connectCharacterAdded()
    player.CharacterAdded:Connect(onCharacterAdded)
end
connectCharacterAdded()
player.CharacterRemoving:Connect(function()
Tool.Parent = game.Players.LocalPlayer.Backpack
end)
Tool.Activated:Connect(function()
if SkibidiHook.Target_Lock.Enabled then
            if enabled == true then
                enabled = false
                Plr = LockToPlayer()
                Target = nil
     SendNotification("Unlocked")
            else
                Plr = LockToPlayer()
                Target = Plr
                enabled = true
SendNotification(Plr.Character.Humanoid.DisplayName)
            end
   else
  SendNotification("Target not enabled!")
        end
end)
end)



Menu.Button("Main", "Killbot", "Load Button", function(x)
if getgenv().ChikmeckIfScriptLoaded == true then
  SendNotification("Toggle-Button Already Loaded!")
    return
end

getgenv().ChjkmeckIfScriptLoaded = true
local BlaadLock = Instance.new("ScreenGui")
BlaadLock.Name = "BlaadLock"
BlaadLock.Parent = game.CoreGui
BlaadLock.ZIndexBehavior = Enum.ZIndexBehavior.Global
BlaadLock.ResetOnSpawn = false

local Fraame = Instance.new("Frame")
Fraame.Parent = BlaadLock
Fraame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Fraame.BorderColor3 = Color3.fromRGB(0, 0, 0)
Fraame.BorderSizePixel = 0
Fraame.Position = UDim2.new(0.133798108, 0, 0.20107238, 0)
Fraame.Size = UDim2.new(0, 80, 0, 70)
Fraame.Active = true
Fraame.Draggable = true

local Loogo = Instance.new("ImageLabel")
Loogo.Name = "Loogo"
Loogo.Parent = Fraame
Loogo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Loogo.BackgroundTransparency = 5.000
Loogo.BorderColor3 = Color3.fromRGB(0, 0, 0)
Loogo.BorderSizePixel = 0
Loogo.Position = UDim2.new(0.326732665, 0, 0, 0)
Loogo.Size = UDim2.new(0, 43, 0, 43)
Loogo.Image = "rbxassetid://YOUR_IMAGE_ID" -- Replace YOUR_IMAGE_ID
Loogo.ImageTransparency = 0.200

local TeextButton = Instance.new("TextButton")
TeextButton.Parent = Fraame
TeextButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TeextButton.BackgroundTransparency = 5.000
TeextButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
TeextButton.BorderSizePixel = 0
TeextButton.Position = UDim2.new(0.0792079195, 0, 0.18571429, 0)
TeextButton.Size = UDim2.new(0, 80, 0, 44)
TeextButton.Font = Enum.Font.SourceSansSemibold
TeextButton.Text = "Enable khen.cc"
TeextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TeextButton.TextScaled = true
TeextButton.TextSize = 14.000
TeextButton.TextWrapped = true

local UIICorner = Instance.new("UICorner")
UIICorner.Parent = Fraame

local staate = true
TeextButton.MouseButton1Click:Connect(function()
if SkibidiHook.Target_Lock.Enabled then
    if enabled == true then
          enabled = false
         Plr = GetClosestPlr()
         Target = nil
         TeextButton.Text = "Aimlock Off"
     SendNotification("Unlocked")
           else
      Plr = GetClosestPlr()
      Target = Plr
     enabled = true
     TeextButton.Text = "Aimlock On"
   SendNotification(Plr.Character.Humanoid.DisplayName)
            end
   else
  SendNotification("Target not enabled!")
        end
end)

local UIICorner2 = Instance.new("UICorner")
UIICorner2.Parent = TeextButton
end)



Menu.CheckBox("Main", "Killbot", "WallCheck", false, function(x) 
   SkibidiHoook.Target_Lock.WallCheck = x
end)

Menu.CheckBox("Main", "Killbot", "Highlight", false, function(x) 
Menu.Notify("Already On khen.cc", 5)
end)

Menu.CheckBox("Main", "Killbot", "Auto Fire", false, function(x) 
Menu.Notify("wip", 5)
end)



         local Line = {
                Enabled = true,
                Circle = true,
                Visible = true,
                Color = MainColor,
                Transparency = 1,
                Thickness = 2,
            }
            
        local BackTrack = {
                Enabled = true,
                Material = 'ForceField',
                Color = MainColor,
                Delay = 0.1,
                Transparency = 0,
            }

if Line.Circle and Plr ~= nil and enabled then
        TargetCircle.Visible  = true
        TargetCircle.Position = Plr.Character.UpperTorso.Position
        TargetCircle.Color    = MainColor
        TargetCircle.Radius   = 2
        TargetCircle.Sides    = 2

 end
    

Menu.CheckBox("Main", "Killbot", "Resolver", false, function(x) 
ResolverMethodPlaceholder = x
end)

Menu.ComboBox("Main", "Killbot", "Resolver Type", "LookVector", {"MoveDirection", "Delta Time", "LookVector"}, function(x)
    SkibidiHook.Target_Lock.Resolver.Enabled = x                                                                                                           
end)

Menu.ComboBox("Main", "Configure", "Hit Part", "HumanoidRootPart", {"HumanoidRootPart", "Head", "UpperTorso", "LowerTorso"}, function(x)
    getgenv().SelectedPart = x                                                                                                           
end)


Menu.TextBox("Main", "Configure", "Prediction", "0.135", function(x)
    getgenv().PREDICTION = x
end)

Menu.TextBox("Main", "Configure", "Jump Prediction", "0.135", function(x)
    getgenv().JUMPPREDICTION = x
end)

Menu.Button("Main", "Killbot", "Load Cam Tool", function(x)
 if getgenv().ChieckIfScriptLoaded == true then
  SendNotification("Tool Already Loaded!")
    return
end

getgenv().ChjeckIfScriptLoaded = true
local CamTool = Instance.new("Tool")
CamTool.RequiresHandle = false
CamTool.Name = "Camlock Tool"
CamTool.Parent = game.Players.LocalPlayer.Backpack
local player = game.Players.LocalPlayer
local function connectCharacterAdded()
    player.CharacterAdded:Connect(onCharacterAdded)
end
connectCharacterAdded()
player.CharacterRemoving:Connect(function()
CamTool.Parent = game.Players.LocalPlayer.Backpack
end)
CamTool.Activated:Connect(function()
if SkibidiHook.Camera_Lock.Enabled then
            if Cenabled == true then
                Cenabled = false
                PlrC = LockToPlayer()
                TargetAimassist = nil
     SendNotification("Unlocked")
            else
                PlrC = LockToPlayer()
                TargetAimassist = PlrC
                Cenabled = true
SendNotification(PlrC.Character.Humanoid.DisplayName)
            end
   else
  SendNotification("Camlock not enabled!")
        end
end)
end)

Menu.Button("Main", "Killbot", "Load Cam Button", function(x)
if getgenv().ChikeckIfScriptLoaded == true then
  SendNotification("Toggle-Button Already Loaded!")
    return
end

getgenv().ChjkeckIfScriptLoaded = true
local BlaaadLock = Instance.new("ScreenGui")
BlaaadLock.Name = "BlaaadLock"
BlaaadLock.Parent = game.CoreGui
BlaaadLock.ZIndexBehavior = Enum.ZIndexBehavior.Global
BlaaadLock.ResetOnSpawn = false
local Frame = Instance.new("Frame")
Frame.Parent = BlaaadLock
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
Frame.BorderSizePixel = 0
Frame.Position = UDim2.new(0.133798108, 0, 0.20107238, 0)
Frame.Size = UDim2.new(0, 80, 0, 70)
Frame.Active = true
Frame.Draggable = true

local Logo = Instance.new("ImageLabel")
Logo.Name = "Logo"
Logo.Parent = Frame
Logo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Logo.BackgroundTransparency = 5.000
Logo.BorderColor3 = Color3.fromRGB(0, 0, 0)
Logo.BorderSizePixel = 0
Logo.Position = UDim2.new(0.326732665, 0, 0, 0)
Logo.Size = UDim2.new(0, 43, 0, 43)
Logo.Image = "rbxassetid://YOUR_IMAGE_ID" -- Replace YOUR_IMAGE_ID
Logo.ImageTransparency = 0.200

local TextButton = Instance.new("TextButton")
TextButton.Parent = Frame
TextButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextButton.BackgroundTransparency = 5.000
TextButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextButton.BorderSizePixel = 0
TextButton.Position = UDim2.new(0.0792079195, 0, 0.18571429, 0)
TextButton.Size = UDim2.new(0, 80, 0, 44)
TextButton.Font = Enum.Font.SourceSansSemibold
TextButton.Text = "Enable khen.cc"
TextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TextButton.TextScaled = true
TextButton.TextSize = 14.000
TextButton.TextWrapped = true

local UICorner = Instance.new("UICorner")
UICorner.Parent = Frame

local state = true
TextButton.MouseButton1Click:Connect(function()
if SkibidiHook.Camera_Lock.Enabled then
    if Cenabled == true then
          Cenabled = false
         PlrC = GetClosestPlr()
         TextButton.Text = "Camlock Off"
     SendNotification("Unlocked")
           else
      PlrC = GetClosestPlr()
     Cenabled = true
     TextButton.Text = "Camlock On"
   SendNotification(PlrC.Character.Humanoid.DisplayName)
            end
   else
  SendNotification("Camlock not enabled!")
        end
end)

local UICorner2 = Instance.new("UICorner")
UICorner2.Parent = TextButton
end)

Menu.CheckBox("Main", "Configure", "FrameSkip", false, function(x) 
    stutterEnabled = x
end)

Menu.Slider("Main", "Configure", "Stutter", 1, 1, 0, "", 1, function(hi)
   stutterAmount = hi
end, "")

Menu.TextBox("Main", "Configure", "Prediction", "0.135", function(x)
    getgenv().CAMPREDICTION = x
end)

Menu.CheckBox("Main", "Configure", "Use Smoothness", false, function(x) 
SmoothnessEnabled = x
end)

Menu.Slider("Main", "Configure", "Smoothness", 0.2, 1, 0, "", 1, function(hi)
 Smoothness = hi
end, "")

Menu.Slider("Main", "Configure", "Shake X", 5, 100, 0, "", 1, function(hi)
  getgenv().ShakeX = hi
 end, "")

Menu.Slider("Main", "Configure", "Shake Y", 5, 100, 0, "", 1, function(hi) 
  getgenv().ShakeY = hi
end, "")

Menu.Slider("Main", "Configure", "Shake Z", 5, 100, 0, "", 1, function(hi) 
 getgenv().ShakeZ = hi
end, "")

getgenv().CFrameDesync = {
           Enabled = false,
           AnglesEnabled = false,
           Type = "Target Strafe",
           Visualize = true,
           VisualizeColor = Color3.fromRGB(143, 48, 167),
           Random = {
               X = 5,
               Y = 5,
               Z = 5,
               AnglesX = 5,
               AnglesY = 5,
               AnglesZ = 5,
               },
           Custom = {
               X = 5,
               Y = 5,
               Z = 5,
               AnglesX = 5,
               AnglesY = 5,
               AnglesZ = 5,
               },
           TargetStrafe = {
               X = 10,
               Y = 10,
               Z = 7,
               },
}
local straight = {
         Visuals = {},
         Desync = {},
         Hooks = {},
         Connections = {}
}
local RunService = game:GetService("RunService")

task.spawn(function()
straight.Visuals["R6Dummy"] = game:GetObjects("rbxassetid://9474737816")[1]; straight.Visuals["R6Dummy"].Head.Face:Destroy(); for i, v in pairs(straight.Visuals["R6Dummy"]:GetChildren()) do v.Transparency = v.Name == "HumanoidRootPart" and 1 or 0.70; v.Material = "Neon"; v.Color = Color3.fromRGB(143, 48, 167) v.CanCollide = false; v.Anchored = false end
end)

local Utility = {}

    function Utility:Connection(connectionType, connectionCallback)
        local connection = connectionType:Connect(connectionCallback)
        straight.Connections[#straight.Connections + 1] = connection
        return connection
    end

Utility:Connection(RunService.PostSimulation, function()
if getgenv().CFrameDesync.AnglesEnabled or getgenv().CFrameDesync.Enabled then
        straight.Desync[1] = lPlr.Character.HumanoidRootPart.CFrame
        local cframe = lPlr.Character.HumanoidRootPart.CFrame
        if getgenv().CFrameDesync.Enabled then
            if getgenv().CFrameDesync.Type == "Random" then
                cframe = cframe * CFrame.new(math.random(-getgenv().CFrameDesync.Random.X, getgenv().CFrameDesync.Random.X), math.random(-getgenv().CFrameDesync.Random.Y, getgenv().CFrameDesync.Random.Y), math.random(-getgenv().CFrameDesync.Random.Z, getgenv().CFrameDesync.Random.Z))
            elseif getgenv().CFrameDesync.Type == "Custom" then
                cframe = cframe * CFrame.new(getgenv().CFrameDesync.Custom.X, getgenv().CFrameDesync.Custom.Y, getgenv().CFrameDesync.Custom.Z)
            elseif getgenv().CFrameDesync.Type == "Mouse" then
                cframe = CFrame.new(lPlr:GetMouse().Hit.Position)
            elseif getgenv().CFrameDesync.Type == "Target Strafe" then
            if enabled and Plr ~= nil then
                cframe = CFrame.new(Plr.Character[getgenv().SelectedPart].Position) * CFrame.new(math.random(-getgenv().CFrameDesync.Random.X, getgenv().CFrameDesync.Random.X), math.random(-getgenv().CFrameDesync.Random.Y, getgenv().CFrameDesync.Random.Y), math.random(-getgenv().CFrameDesync.Random.Z, getgenv().CFrameDesync.Random.Z))
            elseif getgenv().CFrameDesync.Type == "Local Strafe" then
                local currentTime = tick() 
                cframe = CFrame.new(lPlr.Character.HumanoidRootPart.Position) * CFrame.Angles(0, 2 * math.pi * currentTime * getgenv().CFrameDesync.TargetStrafe.Speed % (2 * math.pi), 0) * CFrame.new(0, getgenv().CFrameDesync.TargetStrafe.Height, getgenv().CFrameDesync.TargetStrafe.Distance)
                end
      end

        if getgenv().CFrameDesync.Visualize then
            straight.Visuals["R6Dummy"].Parent = workspace
            straight.Visuals["R6Dummy"].HumanoidRootPart.AssemblyLinearVelocity = Vector3.new()
            straight.Visuals["R6Dummy"]:SetPrimaryPartCFrame(cframe)
            for i, v in pairs(straight.Visuals["R6Dummy"]:GetChildren()) do v.Transparency = v.Name == "HumanoidRootPart" and 1 or 0.70; v.Material = "Neon"; v.Color = getgenv().CFrameDesync.VisualizeColor; v.CanCollide = false; v.Anchored = false end
        else
            straight.Visuals["R6Dummy"].Parent = nil
        end

        if getgenv().CFrameDesync.AnglesEnabled then
            if getgenv().CFrameDesync.Type == "Target Strafe" and enabled then
                cframe = CFrame.new(Plr.Character[getgenv().SelectedPart].Position) * CFrame.Angles(math.rad(math.random(-getgenv().CFrameDesync.Random.X,getgenv().CFrameDesync.Random.X)), math.rad(math.random(-getgenv().CFrameDesync.Random.Y,getgenv().CFrameDesync.Random.Y)), math.rad(math.random(-getgenv().CFrameDesync.Random.Z,getgenv().CFrameDesync.Random.Z)))
            elseif getgenv().CFrameDesync.Type == "Custom" then
                cframe = cframe * CFrame.Angles(math.rad(getgenv().CFrameDesync.Custom.AnglesX), math.rad(getgenv().CFrameDesync.Custom.AnglesY), math.rad(getgenv().CFrameDesync.Custom.AnglesZ))
            end
        end
        lPlr.Character.HumanoidRootPart.CFrame = cframe
        RunService.RenderStepped:Wait()
        lPlr.Character.HumanoidRootPart.CFrame = straight.Desync[1]
    else
        if straight.Visuals["R6Dummy"].Parent ~= nil then
            straight.Visuals["R6Dummy"].Parent = nil
        end
    end
end
end)

--// Hooks
local MainHookingFunctionsTick = tick()
--
straight.Hooks[1] = hookmetamethod(game, "__index", newcclosure(function(self, key)
    if not checkcaller() then
        if key == "CFrame" and straight.Desync[1] and (getgenv().CFrameDesync.AnglesEnabled or getgenv().CFrameDesync.Enabled) and lPlr.Character and lPlr.Character:FindFirstChild("HumanoidRootPart") and lPlr.Character:FindFirstChild("Humanoid") and lPlr.Character:FindFirstChild("Humanoid").Health > 0 then
            if self == lPlr.Character.HumanoidRootPart then
                return straight.Desync[1] or CFrame.new()
            elseif self == lPlr.Character.Head then
                return straight.Desync[1] and straight.Desync[1] + Vector3.new(0, lPlr.Character.HumanoidRootPart.Size / 2 + 0.5, 0) or CFrame.new()
            end
        end
    end
    return straight.Hooks[1](self, key)
end))

Menu.CheckBox("Main", "Cframe Desync", "Enabled", false, function(x) 
CFrameDesync.Enabled = x
end)

local skibidibuhhalls = {
     viewtarg = true
}

if enabled and skibidibuhhalls.viewtarg then
        Workspace.CurrentCamera.CameraSubject = Plr.Character.HumanoidRootPart
else
        Workspace.CurrentCamera.CameraSubject = game.Players.LocalPlayer.Character.Humanoid
end

Menu.CheckBox("Main", "Cframe Desync", "View Target", false, function(x) 
   skibidibuhhalls.viewtarg = x
end)

Menu.Slider("Main", "Cframe Desync", "X", 5, 100, 0, "", 1, function(slider)
     CFrameDesync.TargetStrafe.X = slider
   CFrameDesync.Random.X = slider
end, "")

Menu.Slider("Main", "Cframe Desync", "Y", 5, 100, 0, "", 1, function(slider)
     CFrameDesync.TargetStrafe.Y = slider
   CFrameDesync.Random.Y = slider
end, "")

Menu.Slider("Main", "Cframe Desync", "Y", 5, 100, 0, "", 1, function(slider)
     CFrameDesync.TargetStrafe.Z = slider
   CFrameDesync.Random.Z = slider
end, "")


local yo = Instance.new("ScreenGui")
local TextButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")
local ImageLabel = Instance.new("ImageLabel")
local StarterGui = game:GetService("StarterGui")

-- Properties:

yo.Parent = nil
yo.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

TextButton.Parent = yo
TextButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TextButton.BackgroundTransparency = 0.4
TextButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextButton.BorderSizePixel = 0
TextButton.Position = UDim2.new(0.681249976, 0, 0.294444442, 0)
TextButton.Size = UDim2.new(0, 90, 0, 30)
TextButton.Font = Enum.Font.SourceSans
TextButton.Text = "Macro"
TextButton.TextColor3 = Color3.fromRGB(0, 0, 0)
TextButton.TextSize = 25
TextButton.TextXAlignment = Enum.TextXAlignment.Right

UICorner.CornerRadius = UDim.new(0, 6)
UICorner.Parent = TextButton

ImageLabel.Parent = TextButton
ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ImageLabel.BackgroundTransparency = 1.000
ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
ImageLabel.BorderSizePixel = 0
ImageLabel.Position = UDim2.new(-0.00296074059, 0, 0.00555547094, 0)
ImageLabel.Size = UDim2.new(0, 29, 0, 30)
ImageLabel.Image = "http://www.roblox.com/asset/?id=111095683894090"
ImageLabel.ImageColor3 = Color3.fromRGB(0, 0, 0)

-- Make the button draggable on mobile:

local UserInputService = game:GetService("UserInputService")

local dragging
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    TextButton.Position =
        UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

TextButton.InputBegan:Connect(
    function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = TextButton.Position

            input.Changed:Connect(
                function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end
            )
        end
    end
)

TextButton.InputChanged:Connect(
    function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end
)

UserInputService.InputChanged:Connect(
    function(input)
        if dragging and input == dragInput then
            update(input)
        end
    end
)

local toggled = false
local function diddyparty223()
    local dicks = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not dicks then
        return
    end

    RunService.RenderStepped:Connect(
        function()
            if toggled then
                local camera = workspace.CurrentCamera
                local cameraLook = camera.CFrame.LookVector
                dicks.CFrame = CFrame.new(dicks.Position, dicks.Position + Vector3.new(cameraLook.X, 0, cameraLook.Z))
            end
        end
    )
end

TextButton.MouseButton1Click:Connect(
    function()
        toggled = not toggled
        diddyparty223()
    end
)

player.CharacterAdded:Connect(
    function()
        diddyparty223()
    end
)


    

Menu.Button("Main", "Visuals", "Macro Gui", function(x) 
    yo.Parent = game:GetService("CoreGui")
end)

Menu.CheckBox("Main", "Visuals", "Visualize Target", false, function(x) 
    getgenv().CFrameDesync.Visualize = x
end)

Menu.CheckBox("Main", "Visuals", "Crosshair", false, function(x) 
  crosshair.enabled = x
end)

Menu.Slider("Main", "Visuals", "Crosshair Width", 5, 100, 0, "", 1, function(x)
     crosshair.width = slider
end, "")

Menu.Slider("Main", "Visuals", "Crosshair Length", 5, 100, 0, "", 1, function(x)
     crosshair.length = slider
end, "")

Menu.Slider("Main", "Visuals", "Crosshair Radius", 5, 100, 0, "", 1, function(x)
     crosshair.radius = slider
end, "")

Menu.ComboBox("Main", "Visuals", "Crosshair Mode", "center", {"center", "mouse"}, function(x)
    crosshair.mode = x                                                                                                           
end)

Menu.CheckBox("Main", "Visuals", "Hit Detection", false, function(x) 
   SkibidiHook.Hit_Detection.Enabled = x
end)

local networkpos = false 
local originalRate

if networkpos then
    local RunService = game:GetService("RunService")
    originalRate = getfflag("S2PhysicsSenderRate") -- Store the original value
    setfflag("S2PhysicsSenderRate", 1)
else
    if originalRate then
        setfflag("S2PhysicsSenderRate", originalRate) -- Restore the original value
    end
end

Menu.CheckBox("Main", "Visuals", "Network Position( Buggy A Little )", false, function(x) 
   networkpos = x
end)

Menu.CheckBox("Main", "Visuals", "Hit Sound ( Buggy )", false, function(x) 
   SkibidiHook.Hit_Detection.HitSound = x
end)

Menu.ComboBox("Main", "Visuals", "Hit Sound", "Bubble", {"Bubble", "Rust", "Pop", "Tick"}, function(x)
    SkibidiHook.Hit_Detection.Sound = x                                                                                                           
end)

Menu.ColorPicker("Main", "Visuals", "HitMarker Color", Color3.fromRGB(143, 48, 167), 2, function(x)
    SkibidiHook.Hit_Detection.Color = x
end, "Color Of HitMarker")


local oldOutdoorAmbient = game.Lighting.OutdoorAmbient

local Ambient = {
    Enabled = false
}


local typeshii = game.Lighting.OutdoorAmbient


local function uhhnc()
    if Ambient.Enabled then
        game.Lighting.OutdoorAmbient = Color3.fromRGB(143, 48, 167)
    else
        game.Lighting.OutdoorAmbient = typeshii
    end
end


uhhnc()


Menu.CheckBox("Main", "Visuals", "Environment", false, function(x) 
    Ambient.Enabled = x
    uhhnc()
end)

Menu.Hotkey("Configuration", "Config", "Menu Keybind", false, function(x) -- making a togglekey, again replace Main and Target Aimbot with your tab and section name.
    Skibidi.MenuKeybind = x
end)

local SelfEspSettings = {
            ForcefieldBodyEnabled = false,
            ForcefieldToolsEnabled = false,
            ForcefieldHatsEnabled = false,
            ForcefieldBodyColor = Color3.fromRGB(255, 255, 255),
            ForcefieldToolsColor = Color3.fromRGB(255, 255, 255),
}

        local function applyForcefieldToBody()
            if SelfEspSettings.ForcefieldBodyEnabled then
                for _, part in pairs(game.Players.LocalPlayer.Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.Material = Enum.Material.ForceField
                        part.Color = SelfEspSettings.ForcefieldBodyColor
                    end
                end
            else
                for _, part in pairs(game.Players.LocalPlayer.Character:GetChildren()) do
                    if part:IsA("BasePart") and part.Material == Enum.Material.ForceField then
                        part.Material = Enum.Material.Plastic
                    end
                end
            end
        end
        
        Menu.CheckBox("Main", "Visuals", "Character Chams", false, function(x) 
SelfEspSettings.ForcefieldBodyEnabled = x
applyForcefieldToBody()
end)

        local function applyForcefieldToTools()
            for _, tool in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
                if tool:IsA("Tool") then
                    for _, part in pairs(tool:GetChildren()) do
                        if part:IsA("BasePart") then
                            if SelfEspSettings.ForcefieldToolsEnabled then
                                part.Material = Enum.Material.ForceField
                                part.Color = SelfEspSettings.ForcefieldToolsColor
                            else
                                part.Material = Enum.Material.Plastic
                            end
                        end
                    end
                end
            end
        end

Menu.CheckBox("Main", "Visuals", "Gun Chams", false, function(x) 
SelfEspSettings.ForcefieldToolsColor = x
applyForcefieldToTools()
end)

local textures = {
    enabled = false, -- // Global Switch
    material = Enum.Material.Pavement, -- // Map Texture You Wanna Use
    
    usecolor = false, -- // Changes Map Color With Texture
    color = Color3.fromRGB(0, 0, 0), -- // Color Of Your Choice
}

local OriginalMaterials = {}
local OriginalColors = {}

local function changeParts(model, applyChanges)
    for _, part in ipairs(model:GetChildren()) do
        if part:IsA("BasePart") then
            local isPlayerCharacter = false
            for _, player in ipairs(game.Players:GetPlayers()) do
                if part:IsDescendantOf(player.Character) then
                    isPlayerCharacter = true
                    break
                end
            end

            if not isPlayerCharacter then
                if applyChanges then
                    if not OriginalMaterials[part] then
                        OriginalMaterials[part] = part.Material
                        OriginalColors[part] = part.Color
                    end

                    part.Material = textures.material
                    if textures.usecolor then
                        part.Color = textures.color
                    end
                else
                    if OriginalMaterials[part] then
                        part.Material = OriginalMaterials[part]
                        part.Color = OriginalColors[part]
                    end
                end
            end
        end
        changeParts(part, applyChanges)
    end
end

Menu.CheckBox("Main", "Visuals", "Textures", false, function(x)
    textures.enabled = x
    changeParts(game.Workspace, x)
end)

Menu.ComboBox("Main", "Visuals", "Material", "Pavement", {"Brick", "Sand", "Ice", "Grass", "Pavement"}, function(x)
    textures.material = Enum.Material[x] -- Convert string to Enum.Material
    if textures.enabled then
        changeParts(game.Workspace, true)
    end
end)


 for i = 1, 3 do
    task.wait(0.5)
    Menu.Notify("khen.cc Has Loaded ...", 5)
end

getgenv().SkibidiSolutions = { 
    ["Start Up"] = { 
        -- // We Getting BackDoored For A Circle Chain
        Loader = false, -- // Shows An Intro 
        Build = 'V1', -- // Designations: V1, V2, V3
        AdonisBypasser = true, -- // WOULD RECOMMEND

        Optimize = false, -- // For Lower FPS, Wouldn't Recommend
        GUI = true, -- // To Configure Your Items On Live Action also is with V2
    },

    ["Select Electronic"] = {
        MobileDevice = true, -- // TouchPad
        DesktopComputer = false, -- // Keyboard And Mouse
    },

    ["BulletRedirection"] = {
        Keybind = Enum.KeyCode.C, -- // To Start Targeting
        Enabled = true, -- // Global Switch

        ImpactPart = "HumanoidRootPart", -- // Hit Certain PART
        AerialPart = "Head", -- // Part For AirShots

        PredictionAccuracy = 0.12654, -- // Prediction 
        NotificationAlerts = true, -- // Notifies You On Unlock Or Locks
        
        KOCheck = true, -- // Unlocks On TargetedPlayer Death.
    },
    
    ["SilentAim"] = {
        Enabled = true, -- // Global Switch
        AntiCurve = false,
        
        ImpactPart = "HumanoidRootPart", -- // Hit Certain PART
        AerialPart = "Head", -- // Part For AirShots

        PredictionAccuracy = 0.12654, -- // Prediction 
        NotificationAlerts = true, -- // Notifies You On Unlock Or Locks
    },

    ["Drawings"] = {
        ["Field Of View"] = {
            Visible = true,
            Radius = 85,
            Filled = false,
            Thickness = 1,
            Transparency = 0.25,
            Color = Color3.fromRGB(255, 0, 0)
        },
        
        ["Tracer"] = { 
            Visible = false, -- // Visibility Of The Tracer, Global Switch
            Thickness = 1, -- // Thickness Of The Tracer
            Transparency = 1, -- // Transparency Of The Tracer
            Color = Color3.fromRGB(255, 0, 0) -- // Color Tracer
        },
        
        ["Hit Detection"] = {
            Enabled = true,
            Color = Color3.fromRGB(255, 0, 0),
            
            Sound = "Bubble" -- // Rust, Bruh, Minecraft, Bonk, Fatality, Neverlose, Skeet, Bameware, Bell, Pop, much more though
        },
    },
    
    ["Trigger Bot"] = {
        Enabled = true, -- // Global Switch
        FieldOfView_Color = Color3.fromRGB(255, 0, 0),
        
        FieldOfView_Size = 90, -- // We gon' hit 'em w/ a blackagan :silly:
        ClickDelay = 0.05, -- // 0.05 Is Recommended
        
        ActivationDelay = 1, -- // How Fast To Turn The TB On
        AutoFire = true, -- // Would Recommend
        
        IgnoreFriends = false, -- // If You Don't Wanna Shoot Your Friends.
        Prediction = 0.134, -- // Future Prediction Of Target, Really Doesn't Work
        
        FOVCircle = hi, -- // Circle, Square, Triangle, Rectangle, Hexagon
        TargetPart = "HumanoidRootPart", -- // Not useful, it goes with the lock
        
        ShowFieldOfView = false, -- // Nah Don't Show It Or Skibidi Touch
    },
     
    ["AutoPrediction"] = {
        Enabled = false, -- // Global Switch
        Ping_20 = 0.135, -- // Switches Prediction For Your Ping Of YOUR Choice
        Ping_30 = 0.145, -- // Switches Prediction For Your Ping Of YOUR Choice
        Ping_40 = 0.155, -- // Switches Prediction At Ping 40 For Your Ping Of YOUR Choice
        Ping_50 = 0.165, -- // Switches Prediction 50 For Your Ping Of YOUR Choice
        Ping_60 = 0.175, -- // Switches Prediction 60 For Your Ping Of YOUR Choice
        Ping_70 = 0.185, -- // Switches Prediction 70 For Your Ping Of YOUR Choice
        Ping_80 = 0.195, -- // Switches Prediction 80 For Your Ping Of YOUR Choice
        Ping_90 = 0.1, -- // Switches Prediction 90 For Your Ping Of YOUR Choice
        Ping_100 = 0.131, -- // Switches Prediction 100 For Your Ping Of YOUR Choice
    },

["Animations"] = {
    Enabled = false, -- // Use Animation Changer
    Running = "http://www.roblox.com/asset/?id=616168032", -- // Changes Local Player Running Animation
    
    Walking = "http://www.roblox.com/asset/?id=616168032", -- // Changes Local Player Walking Animation
    Jumping = "http://www.roblox.com/asset/?id=1083218792", -- // Changes Local Player Jumping Animation
    
    Falling = "http://www.roblox.com/asset/?id=707829716", -- // Changes Local Player Falling Animation
    Idle = "http://www.roblox.com/asset/?id=616160636" -- // Changes Local Player Idle Animation
},

    ["CameraNavigation"] = { 
        Enabled = true, -- // Global Switch
        TargetingPart = "HumanoidRootPart", -- // Aims At CERTAIN PART

        Stability = 0.03, -- // Smoothness
        PredictionFactor = 0.3, -- // Prediction 

        JitterMagnitude = 0.5, -- // Shake Effect
        AutomaticPrediction = false, -- // Auto Predicting

        ImpactPart = "HumanoidRootPart", -- // Aims At This Part In Air
        EasingFunction = Enum.EasingStyle.Quad, -- // Change this to use different easing styles Good for clips No cap
        -- // Available easing styles:
        -- // Linear, Exponential, Elastic, Bounce, Quad, Cubic, Quart, Quint, Sine
        EasingMode = Enum.EasingDirection.InOut, -- // In, Out, InOut, Most I Know Right Now
    },

    ["Checks"] = {
        KnockOutDetection = true, -- // Checks If Target Is On The Floor With Low Health
        DeathDetection = true, -- // Checks If Stomped Target
    },
    
    ["RotateCamera"] = {
        Enabled = false, -- // To Use Rotating Camera
        RotationSpeed = 4900, -- // Rotation Speed Very Obvious And Self Explanatory
        
        RotationDegrees = 360, -- // How Far To Spin
        Keybind = Enum.KeyCode.V, -- // Keybind
    },
    
    ["Macro"] = {
        Enabled = true, -- // Global Switch
        Active = false, -- // If It's Currently Active
        
        Keybind = Enum.KeyCode.Z, -- // Keybind
        Mode = "Fake", -- // Legit (Not Added), Fake, Looks Fake On Your Screen Not Theirs
    },

    ["Selections"] = {
        Headless = false, -- // Disappear Your Head If True
        Korblox = false, -- // Turns Right Leg Into Korblox DeathSpeaker
    },

    ["TargetOutlierCircle"] = { 
        Enabled = false, -- // To Show A Circle Fake HitBox Around Target
        Color = Color3.fromRGB(255, 255, 255), -- // Color Of Outlier Circle
        
        Size = Vector3.new(14, 14, 14), -- // Size Of Outlier Circle
        Material = Enum.Material.ForceField, -- // Material Of Outlier Circle
    },
    
    ["Visuals"] = {
        Selfcham = false, -- // Turns You Into A Cham
        Ambient = false, -- // Changed Map Ambience
        
        Nebula_Sky = false, -- // Turns SkyBox Into A Nebula Sky (Doesn't Work)
    },
    
    ["ConsoleClear"] = {
        Enabled = true, -- // Use Console Clearer
        Minimum = 600, -- // Minimum Of Clearing Roblox Console
        
        Maximum = 950, -- // Maximum Of Clearing Roblox Console
    },
   
    ["OtherGames"] = {
        ["Anarchy"] = {
            Enabled = false, -- // Global Switch
            HitboxExpander = {
                Enabled = false, -- // Use Hitbox Expander
                Color = Color3.fromRGB(0, 0, 0), -- // Hitbox Expander Color Of Your Choice (R, G, B)
                
                Transparency = 0, -- // Hitbox Expander Transparency: 0 is lowest, 1 is highest
                Size = {
                    X = 5, -- // Hitbox Expander Size Horizontally
                    Y = 5, -- // Hitbox Expander Size Vertically
                    Z = 5, -- // Hitbox Expander Size Depth
                }
            }
        },
        
        ["Arsenal"] = {
            Enabled = false, -- // Use SilentAim/BulletRedirection In Arsenal
            FOV = false, -- // Show Field Of View

            Size = 60, -- // Size Of The Field Of View
            Color = Color3.fromRGB(0, 0, 0), -- // Color Of Field Of View
        },
        
        ["Basketball Stars"] = {
            Enabled = false, -- // To Use Basketball Stars Support
            ShotAccuracy = 100, -- // Accuracy Of Ball Flowing Through The Net

            AutomaticallyGreens = false, -- // Turns Your Late Shots Into Accurate Shots
        },
    },
    
    ["TargetOutlierSquare"] = {
        -- // Fiction Hitbox Just A Box
        Enabled = false, -- // Use Fake Square Outlier Hitbox
        Color = Color3.fromRGB(255, 255, 255), -- // Color Of Square Outlier
        
        Size = Vector3.new(5, 5, 5), -- // Size Of The Square Outlier
        Material = Enum.Material.ForceField, -- // Material Of The Outlier 
    },
    
    ["Textures"] = {
        Enabled = false, -- // Global Switch
        Material = Enum.Material.Pavement, -- // Map Texture You Wanna Use
        
        UseColor = false, -- // Changes Map Color With Texture
        Color = Color3.fromRGB(0, 0, 0), -- // Color Of Your Choice
    },

    ["ExecutorCompatibility"] = { 
        -- Compatibility matrix for various execution environments
        Wave = false, -- // Recommended
        Solara = false, -- // Decent

        Synz = false, -- // Ass, Only Crashes
        Fluxus = false, -- // Recommended (Android)

        Delta = false, -- // Recommended (Android)
        Cubix = false, -- // Recommended (iOS)

        Verification = true -- // Wouldn't Use
    }
}

if getgenv().SkibidiSolutions.Animations.Enabled then
    local function setAnimationIds()
        local animate = game.Players.LocalPlayer.Character:WaitForChild("Animate")
        animate.run.RunAnim.AnimationId =
            "http://www.roblox.com/asset/?id=" .. getgenv().SkibidiSolutions.Animations.Running
        animate.walk.WalkAnim.AnimationId =
            "http://www.roblox.com/asset/?id=" .. getgenv().SkibidiSolutions.Animations.Walking
        animate.jump.JumpAnim.AnimationId =
            "http://www.roblox.com/asset/?id=" .. getgenv().SkibidiSolutions.Animations.Jumping
        animate.fall.FallAnim.AnimationId =
            "http://www.roblox.com/asset/?id=" .. getgenv().SkibidiSolutions.Animations.Falling
        animate.idle.Animation1.AnimationId =
            "http://www.roblox.com/asset/?id=" .. getgenv().SkibidiSolutions.Animations.Idle
        animate.idle.Animation2.AnimationId =
            "http://www.roblox.com/asset/?id=" .. getgenv().SkibidiSolutions.Animations.Idle
    end

    game.Players.LocalPlayer.CharacterAdded:Connect(
        function(character)
            setAnimationIds()
        end
    )

    setAnimationIds() -- Initial run
end


