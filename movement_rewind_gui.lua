if getgenv().MovementRewindCleanup then
   getgenv().MovementRewindCleanup()
end

print([[

  /$$$$$$              /$$     /$$  /$$$$$$                      /$$    
 /$$__  $$            | $$    |__/ /$$__  $$                    | $$    
| $$  \ $$  /$$$$$$  /$$$$$$   /$$| $$  \__//$$$$$$   /$$$$$$  /$$$$$$  
| $$$$$$$$ /$$__  $$|_  $$_/  | $$| $$$$   |____  $$ /$$__  $$|_  $$_/  
| $$__  $$| $$  \__/  | $$    | $$| $$_/    /$$$$$$$| $$  \ $$  | $$    
| $$  | $$| $$        | $$ /$$| $$| $$     /$$__  $$| $$  | $$  | $$ /$$
| $$  | $$| $$        |  $$$$/| $$| $$    |  $$$$$$$|  $$$$$$$  |  $$$$/
|__/  |__/|__/         \___/  |__/|__/     \_______/ \____  $$   \___/  
                                                          | $$          
                                                          | $$          
                                                          |__/        
]])

local HttpService = game:GetService("HttpService")
local configPath = "movement_rewind_config.json"

local defaultConfig = {
   key = "E",
   flashbacklength = 60,
   flashbackspeed = 1,
   enabled = true,
   guiKey = "RightShift"
}

local config = {}

local function loadConfig()
   if not isfile or not readfile then
       print("File functions not available, using default config")
       return defaultConfig
   end

   if isfile(configPath) then
       local success, result = pcall(function()
           local data = readfile(configPath)
           return HttpService:JSONDecode(data)
       end)

       if success and result then
           print("Config loaded from file")
           for k, v in pairs(defaultConfig) do
               if result[k] == nil then
                   result[k] = v
               end
           end
           return result
       else
           print("Failed to load config, using defaults")
           return defaultConfig
       end
   else
       print("No config file found, creating with defaults")
       return defaultConfig
   end
end

local function saveConfig()
   if not writefile then
       print("writefile not available, config not saved")
       return
   end

   local success, err = pcall(function()
       local json = HttpService:JSONEncode(config)
       writefile(configPath, json)
   end)

   if success then
       print("Config saved successfully")
   else
       warn("Failed to save config: " .. tostring(err))
   end
end

config = loadConfig()
print("Movement Rewind Script Loaded")

local name = "MovementRewind_BindKey"
local frames = {}
local uis = game:GetService("UserInputService")
local LP = game:GetService("Players").LocalPlayer
local RS = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

pcall(RS.UnbindFromRenderStep,RS,name)

if CoreGui:FindFirstChild("MovementRewindGUI") then
   CoreGui:FindFirstChild("MovementRewindGUI"):Destroy()
end

local function getchar()
   return LP.Character
end

local function gethrp(c)
   return c:FindFirstChild("HumanoidRootPart") or c.RootPart or c.PrimaryPart or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart")
end

local flashback = {lastinput=false,canrevert=true}

function flashback:Advance(char,hrp,hum,allowinput)
   if #frames>config.flashbacklength*60 then
       table.remove(frames,1)
   end

   if allowinput and not self.canrevert then
       self.canrevert = true
   end

   if self.lastinput then
       hum.PlatformStand = false
       self.lastinput = false
   end

   table.insert(frames,{
       hrp.CFrame,
       hrp.Velocity,
       hum:GetState(),
       hum.PlatformStand,
       char:FindFirstChildOfClass("Tool")
   })
end

function flashback:Revert(char,hrp,hum)
   local num = #frames
   if num==0 or not self.canrevert then
       self.canrevert = false
       self:Advance(char,hrp,hum)
       return
   end
   for i=1,config.flashbackspeed do
       if num > 1 then
           table.remove(frames,num)
           num=num-1
       end
   end
   if num < 1 then return end
   self.lastinput = true
   local lastframe = frames[num]
   table.remove(frames,num)
   hrp.CFrame = lastframe[1]
   hrp.Velocity = -lastframe[2]
   hum:ChangeState(lastframe[3])
   hum.PlatformStand = lastframe[4]
   local currenttool = char:FindFirstChildOfClass("Tool")
   if lastframe[5] then
       if not currenttool then
           hum:EquipTool(lastframe[5])
       end
   else
       hum:UnequipTools()
   end
end

local gui = Instance.new("ScreenGui")
gui.Name = "MovementRewindGUI"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 350, 0, 380)
mainFrame.Position = UDim2.new(0.5, -175, 0.5, -190)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Visible = false
mainFrame.Parent = gui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = mainFrame

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 40)
topBar.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
topBar.BorderSizePixel = 0
topBar.Active = true
topBar.Parent = mainFrame

local dragStart = nil
local startPos = nil
local dragging = false

topBar.InputBegan:Connect(function(input)
   if input.UserInputType == Enum.UserInputType.MouseButton1 then
       dragging = true
       dragStart = input.Position
       startPos = mainFrame.Position
   end
end)

topBar.InputChanged:Connect(function(input)
   if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
       local delta = input.Position - dragStart
       mainFrame.Position = UDim2.new(
           startPos.X.Scale,
           startPos.X.Offset + delta.X,
           startPos.Y.Scale,
           startPos.Y.Offset + delta.Y
       )
   end
end)

topBar.InputEnded:Connect(function(input)
   if input.UserInputType == Enum.UserInputType.MouseButton1 then
       dragging = false
   end
end)

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 8)
topCorner.Parent = topBar

local bottomFix = Instance.new("Frame")
bottomFix.Size = UDim2.new(1, 0, 0, 8)
bottomFix.Position = UDim2.new(0, 0, 1, -8)
bottomFix.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
bottomFix.BorderSizePixel = 0
bottomFix.Parent = topBar

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -100, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "ARTIFAQT | Movement Rewind"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = topBar

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 14
closeButton.BorderSizePixel = 0
closeButton.Parent = topBar

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 6)
closeBtnCorner.Parent = closeButton

closeButton.MouseButton1Click:Connect(function()
   mainFrame.Visible = false
end)

local listeningConnection = nil

local function createSetting(name, yPos, settingType, defaultValue, minVal, maxVal)
   local settingFrame = Instance.new("Frame")
   settingFrame.Name = name.."Setting"
   settingFrame.Size = UDim2.new(1, -30, 0, 50)
   settingFrame.Position = UDim2.new(0, 15, 0, yPos)
   settingFrame.BackgroundTransparency = 1
   settingFrame.Parent = mainFrame

   local label = Instance.new("TextLabel")
   label.Name = "Label"
   label.Size = UDim2.new(1, -70, 0, 20)
   label.Position = UDim2.new(0, 0, 0, 0)
   label.BackgroundTransparency = 1
   label.Text = name
   label.TextColor3 = Color3.fromRGB(220, 220, 220)
   label.TextXAlignment = Enum.TextXAlignment.Left
   label.Font = Enum.Font.Gotham
   label.TextSize = 13
   label.Parent = settingFrame

   if settingType == "toggle" then
       local toggleBack = Instance.new("Frame")
       toggleBack.Name = "ToggleBack"
       toggleBack.Size = UDim2.new(0, 50, 0, 26)
       toggleBack.Position = UDim2.new(1, -50, 0.5, -13)
       toggleBack.BackgroundColor3 = defaultValue and Color3.fromRGB(40, 180, 100) or Color3.fromRGB(60, 60, 65)
       toggleBack.BorderSizePixel = 0
       toggleBack.Parent = settingFrame

       local toggleCorner = Instance.new("UICorner")
       toggleCorner.CornerRadius = UDim.new(1, 0)
       toggleCorner.Parent = toggleBack

       local toggleButton = Instance.new("Frame")
       toggleButton.Name = "ToggleButton"
       toggleButton.Size = UDim2.new(0, 20, 0, 20)
       toggleButton.Position = defaultValue and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
       toggleButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
       toggleButton.BorderSizePixel = 0
       toggleButton.Parent = toggleBack

       local btnCorner = Instance.new("UICorner")
       btnCorner.CornerRadius = UDim.new(1, 0)
       btnCorner.Parent = toggleButton

       local clickDetector = Instance.new("TextButton")
       clickDetector.Size = UDim2.new(1, 0, 1, 0)
       clickDetector.BackgroundTransparency = 1
       clickDetector.Text = ""
       clickDetector.Parent = toggleBack

       clickDetector.MouseButton1Click:Connect(function()
           defaultValue = not defaultValue
           config[name:lower():gsub(" ", "")] = defaultValue
           saveConfig()

           toggleBack.BackgroundColor3 = defaultValue and Color3.fromRGB(40, 180, 100) or Color3.fromRGB(60, 60, 65)
           toggleButton:TweenPosition(
               defaultValue and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10),
               Enum.EasingDirection.Out,
               Enum.EasingStyle.Quad,
               0.15,
               true
           )
       end)

   elseif settingType == "keybind" then
       local bindButton = Instance.new("TextButton")
       bindButton.Name = "BindButton"
       bindButton.Size = UDim2.new(0, 100, 0, 30)
       bindButton.Position = UDim2.new(1, -100, 0.5, -15)
       bindButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
       bindButton.Text = tostring(defaultValue)
       bindButton.TextColor3 = Color3.fromRGB(255, 255, 255)
       bindButton.Font = Enum.Font.Gotham
       bindButton.TextSize = 12
       bindButton.BorderSizePixel = 0
       bindButton.Parent = settingFrame

       local bindCorner = Instance.new("UICorner")
       bindCorner.CornerRadius = UDim.new(0, 6)
       bindCorner.Parent = bindButton

       local isListening = false

       bindButton.MouseButton1Click:Connect(function()
           if isListening then return end
           isListening = true
           bindButton.Text = "Press a key..."
           bindButton.BackgroundColor3 = Color3.fromRGB(60, 100, 180)

           if listeningConnection then
               listeningConnection:Disconnect()
           end

           listeningConnection = uis.InputBegan:Connect(function(input)
               if input.UserInputType == Enum.UserInputType.Keyboard then
                   local keyName = input.KeyCode.Name
                   config[name == "Rewind Key" and "key" or "guiKey"] = keyName
                   bindButton.Text = keyName
                   bindButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                   saveConfig()
                   isListening = false
                   if listeningConnection then
                       listeningConnection:Disconnect()
                       listeningConnection = nil
                   end
               end
           end)
       end)

   elseif settingType == "slider" then
       settingFrame.Size = UDim2.new(1, -30, 0, 80)

       local valueDisplay = Instance.new("TextBox")
       valueDisplay.Name = "ValueDisplay"
       valueDisplay.Size = UDim2.new(0, 60, 0, 25)
       valueDisplay.Position = UDim2.new(1, -60, 0, 0)
       valueDisplay.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
       valueDisplay.Text = tostring(defaultValue)
       valueDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
       valueDisplay.Font = Enum.Font.GothamBold
       valueDisplay.TextSize = 12
       valueDisplay.ClearTextOnFocus = false
       valueDisplay.BorderSizePixel = 0
       valueDisplay.Parent = settingFrame

       local displayCorner = Instance.new("UICorner")
       displayCorner.CornerRadius = UDim.new(0, 4)
       displayCorner.Parent = valueDisplay

       local sliderBg = Instance.new("Frame")
       sliderBg.Name = "SliderBg"
       sliderBg.Size = UDim2.new(1, -30, 0, 8)
       sliderBg.Position = UDim2.new(0, 15, 0, 40)
       sliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
       sliderBg.BorderSizePixel = 0
       sliderBg.Parent = settingFrame

       local sliderBgCorner = Instance.new("UICorner")
       sliderBgCorner.CornerRadius = UDim.new(1, 0)
       sliderBgCorner.Parent = sliderBg

       local sliderFill = Instance.new("Frame")
       sliderFill.Name = "SliderFill"
       sliderFill.Size = UDim2.new((defaultValue - minVal) / (maxVal - minVal), 0, 1, 0)
       sliderFill.BackgroundColor3 = Color3.fromRGB(60, 100, 180)
       sliderFill.BorderSizePixel = 0
       sliderFill.Parent = sliderBg

       local sliderFillCorner = Instance.new("UICorner")
       sliderFillCorner.CornerRadius = UDim.new(1, 0)
       sliderFillCorner.Parent = sliderFill

       local minBox = Instance.new("TextBox")
       minBox.Size = UDim2.new(0, 35, 0, 20)
       minBox.Position = UDim2.new(0, 0, 0, 55)
       minBox.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
       minBox.Text = tostring(minVal)
       minBox.TextColor3 = Color3.fromRGB(150, 150, 150)
       minBox.Font = Enum.Font.Gotham
       minBox.TextSize = 10
       minBox.ClearTextOnFocus = false
       minBox.BorderSizePixel = 0
       minBox.Parent = settingFrame

       local minCorner = Instance.new("UICorner")
       minCorner.CornerRadius = UDim.new(0, 4)
       minCorner.Parent = minBox

       local maxBox = Instance.new("TextBox")
       maxBox.Size = UDim2.new(0, 35, 0, 20)
       maxBox.Position = UDim2.new(1, -35, 0, 55)
       maxBox.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
       maxBox.Text = tostring(maxVal)
       maxBox.TextColor3 = Color3.fromRGB(150, 150, 150)
       maxBox.Font = Enum.Font.Gotham
       maxBox.TextSize = 10
       maxBox.ClearTextOnFocus = false
       maxBox.BorderSizePixel = 0
       maxBox.Parent = settingFrame

       local maxCorner = Instance.new("UICorner")
       maxCorner.CornerRadius = UDim.new(0, 4)
       maxCorner.Parent = maxBox

       local function updateSlider(value)
           local clamped = math.clamp(value, minVal, maxVal)
           local percent = (maxVal - minVal) ~= 0 and (clamped - minVal) / (maxVal - minVal) or 0
           sliderFill:TweenSize(UDim2.new(percent, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true)
           valueDisplay.Text = tostring(math.floor(clamped))
           config[name:lower():gsub(" ", "")] = math.floor(clamped)
           saveConfig()
       end

       minBox.FocusLost:Connect(function()
           local newMin = tonumber(minBox.Text)
           if newMin and newMin < maxVal then
               minVal = newMin
               minBox.Text = tostring(minVal)
               local configKey = name:lower():gsub(" ", "") .. "Min"
               config[configKey] = minVal
               saveConfig()
               local currentValue = config[name:lower():gsub(" ", "")]
               if currentValue < minVal then
                   updateSlider(minVal)
               else
                   updateSlider(currentValue)
               end
           else
               minBox.Text = tostring(minVal)
           end
       end)

       maxBox.FocusLost:Connect(function()
           local newMax = tonumber(maxBox.Text)
           if newMax and newMax > minVal then
               maxVal = newMax
               maxBox.Text = tostring(maxVal)
               local configKey = name:lower():gsub(" ", "") .. "Max"
               config[configKey] = maxVal
               saveConfig()
               local currentValue = config[name:lower():gsub(" ", "")]
               if currentValue > maxVal then
                   updateSlider(maxVal)
               else
                   updateSlider(currentValue)
               end
           else
               maxBox.Text = tostring(maxVal)
           end
       end)

       local dragging = false
       sliderBg.InputBegan:Connect(function(input)
           if input.UserInputType == Enum.UserInputType.MouseButton1 then
               dragging = true
               local mousePos = input.Position.X
               local sliderPos = sliderBg.AbsolutePosition.X
               local sliderSize = sliderBg.AbsoluteSize.X
               local percent = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
               local value = minVal + (maxVal - minVal) * percent
               updateSlider(value)
           end
       end)

       sliderBg.InputEnded:Connect(function(input)
           if input.UserInputType == Enum.UserInputType.MouseButton1 then
               dragging = false
           end
       end)

       sliderBg.InputChanged:Connect(function(input)
           if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
               local mousePos = input.Position.X
               local sliderPos = sliderBg.AbsolutePosition.X
               local sliderSize = sliderBg.AbsoluteSize.X
               local percent = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
               local value = minVal + (maxVal - minVal) * percent
               updateSlider(value)
           end
       end)

       valueDisplay.FocusLost:Connect(function()
           local value = tonumber(valueDisplay.Text)
           if value then
               updateSlider(value)
           else
               valueDisplay.Text = tostring(config[name:lower():gsub(" ", "")])
           end
       end)

   elseif settingType == "textbox" then
       local textBox = Instance.new("TextBox")
       textBox.Name = "ValueBox"
       textBox.Size = UDim2.new(0, 100, 0, 30)
       textBox.Position = UDim2.new(1, -100, 0.5, -15)
       textBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
       textBox.Text = tostring(defaultValue)
       textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
       textBox.Font = Enum.Font.Gotham
       textBox.TextSize = 12
       textBox.ClearTextOnFocus = false
       textBox.BorderSizePixel = 0
       textBox.Parent = settingFrame

       local boxCorner = Instance.new("UICorner")
       boxCorner.CornerRadius = UDim.new(0, 6)
       boxCorner.Parent = textBox

       textBox.FocusLost:Connect(function()
           local value = textBox.Text
           if tonumber(value) then
               local num = tonumber(value)
               if minVal and num < minVal then num = minVal end
               if maxVal and num > maxVal then num = maxVal end
               textBox.Text = tostring(num)
               config[name:lower():gsub(" ", "")] = num
               saveConfig()
           end
       end)
   end
end

createSetting("Enabled", 55, "toggle", config.enabled)
createSetting("Rewind Key", 110, "keybind", config.key)
createSetting("GUI Key", 165, "keybind", config.guiKey)
createSetting("Flashback Length", 220, "textbox", config.flashbacklength, 1, 300)
createSetting("Flashback Speed", 275, "slider", config.flashbackspeed, 0, 10)

local function step()
   if not config.enabled then return end
   local char = getchar()
   if not char then return end
   local hrp = gethrp(char)
   if not hrp then return end
   local hum = char:FindFirstChildWhichIsA("Humanoid")
   if not hum then return end
   if uis:IsKeyDown(Enum.KeyCode[config.key]) then
       flashback:Revert(char,hrp,hum)
   else
       flashback:Advance(char,hrp,hum,true)
   end
end
RS:BindToRenderStep(name,1,step)

local guiConnection = uis.InputBegan:Connect(function(input, gameProcessed)
   if input.KeyCode == Enum.KeyCode[config.guiKey] then
       mainFrame.Visible = not mainFrame.Visible
   end
end)

getgenv().MovementRewindCleanup = function()
   pcall(RS.UnbindFromRenderStep,RS,name)
   if guiConnection then pcall(function() guiConnection:Disconnect() end) end
   if listeningConnection then pcall(function() listeningConnection:Disconnect() end) end
   if gui then pcall(function() gui:Destroy() end) end
   frames = {}
   flashback = {lastinput=false,canrevert=true}
   print("Movement Rewind Script Cleaned")
end

print("Press "..config.guiKey.." to open settings GUI")
