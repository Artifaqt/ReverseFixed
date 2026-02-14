if getgenv().MovementRewindCleanup then
   getgenv().MovementRewindCleanup()
end

print([[
   ___   ____  ______ ______ ______  ___   ____  ______
  / _ | / __ \/_  __//  _/ // __/ / / / | / __ \/_  __/
 / __ |/ /_/ / / /  _/ // _\ \/ /_/ /  | / /_/ / / /
/_/ |_|\_,__/ /_/  /___/  /_/ \____/_/|_|\____/ /_/
]])
print("Movement Rewind Script Loaded | Key: E")

local key = "E"
local flashbacklength = 60
local flashbackspeed = 1

local name = "MovementRewind_BindKey"
local frames,uis,LP,RS = {},game:GetService("UserInputService"),game:GetService("Players").LocalPlayer,game:GetService("RunService")

pcall(RS.UnbindFromRenderStep,RS,name)

local function getchar()
   return LP.Character
end

local function gethrp(c)
return c:FindFirstChild("HumanoidRootPart") or c.RootPart or c.PrimaryPart or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart")
end

local flashback = {lastinput=false,canrevert=true}

function flashback:Advance(char,hrp,hum,allowinput)

   if #frames>flashbacklength*60 then
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
   for i=1,flashbackspeed do
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

local function step()
   local char = getchar()
   if not char then return end
   local hrp = gethrp(char)
   if not hrp then return end
   local hum = char:FindFirstChildWhichIsA("Humanoid")
   if not hum then return end
   if uis:IsKeyDown(Enum.KeyCode[key]) then
       flashback:Revert(char,hrp,hum)
   else
       flashback:Advance(char,hrp,hum,true)
   end
end
RS:BindToRenderStep(name,1,step)

getgenv().MovementRewindCleanup = function()
   pcall(RS.UnbindFromRenderStep,RS,name)
   frames = {}
   flashback = {lastinput=false,canrevert=true}
   print("Movement Rewind Script Cleaned")
end
