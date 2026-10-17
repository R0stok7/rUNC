local cloneref = type(cloneref) == "function" and cloneref or function(obj)
    return obj
end

local Workspace = cloneref(game:GetService("Workspace"))
local RunService = cloneref(game:GetService("RunService"))

local ESP = {}
ESP.__index = ESP

local function getBounds(object)
    if not object then return nil end
    if object:IsA("Player") then
        object = object.Character
        if not object then return nil end
    end
    if object:IsA("Model") then
        local ok, cf, size = pcall(object.GetBoundingBox, object)
        if not ok then return nil end
        return cf, size
    elseif object:IsA("BasePart") then
        return object.CFrame, object.Size
    elseif object:IsA("Attachment") then
        return object.WorldCFrame, Vector3.new(0.5, 0.5, 0.5)
    elseif object:IsA("Bone") then
        return object.TransformedWorldCFrame, Vector3.new(0.5, 0.5, 0.5)
    end
    return nil
end

local function cornersFromBounds(cf, size)
    local half = size * 0.5
    local corners = table.create(8)
    local i = 1
    for xi = -1, 1, 2 do
        for yi = -1, 1, 2 do
            for zi = -1, 1, 2 do
                corners[i] = (cf * CFrame.new(half.X * xi, half.Y * yi, half.Z * zi)).Position
                i += 1
            end
        end
    end
    return corners
end

local function projectCorners(cam, corners)
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local any = false
    for i = 1, #corners do
        local sp = cam:WorldToViewportPoint(corners[i])
        if sp.Z > 0 then
            any = true
            if sp.X < minX then minX = sp.X end
            if sp.Y < minY then minY = sp.Y end
            if sp.X > maxX then maxX = sp.X end
            if sp.Y > maxY then maxY = sp.Y end
        end
    end
    if not any then return nil end
    return minX, minY, maxX, maxY
end

-- constructor -----------------------------------------------------

function ESP.new(object, options)
    options = options or {}

    local self = setmetatable({}, ESP)

    self.Object      = object
    self.Name        = options.Name or (object and object.Name) or "ESP"
    self.Color       = options.Color       or Color3.fromRGB(255, 255, 255)
    self.TextColor   = options.TextColor   or self.Color
    self.Thickness   = options.Thickness   or 1
    self.TextSize    = options.TextSize    or 14
    self.TextOffset  = options.TextOffset  or 4
    self.Enabled     = options.Enabled     ~= false
    self.ShowBox     = options.ShowBox     ~= false
    self.ShowText    = options.ShowText    ~= false
    self.DistanceScale = options.DistanceScale or false
    self.MinDistance = options.MinDistance or 10
    self.MaxDistance = options.MaxDistance or 500
    self.Format      = options.Format

    self._baseTextSize  = self.TextSize
    self._baseThickness = self.Thickness

    if self.ShowBox then
        self._box = Drawing.new("Square")
        self._box.Filled    = false
        self._box.Color     = self.Color
        self._box.Thickness = self.Thickness
        self._box.Visible   = false
    end

    if self.ShowText then
        self._label = Drawing.new("Text")
        self._label.Center  = true
        self._label.Outline = true
        self._label.Color   = self.TextColor
        self._label.Size    = self.TextSize
        self._label.Text    = self.Name
        self._label.Visible = false
    end

    return self
end

-- setters ---------------------------------------------------------

function ESP:SetColor(c)
    self.Color = c
    if self._box then self._box.Color = c end
    return self
end

function ESP:SetTextColor(c)
    self.TextColor = c
    if self._label then self._label.Color = c end
    return self
end

function ESP:SetName(n)
    self.Name = n
    return self
end

function ESP:SetEnabled(e)
    self.Enabled = e
    if not e then self:_hide() end
    return self
end

function ESP:_hide()
    if self._box then self._box.Visible = false end
    if self._label then self._label.Visible = false end
end

-- update ----------------------------------------------------------

function ESP:Update()
    if not self.Enabled then return end

    local cam = Workspace.CurrentCamera
    if not cam then self:_hide() return end

    local cf, size = getBounds(self.Object)
    if not cf then self:_hide() return end

    if size.Magnitude < 0.01 then
        size = Vector3.new(0.5, 0.5, 0.5)
    end

    local corners = cornersFromBounds(cf, size)
    local minX, minY, maxX, maxY = projectCorners(cam, corners)
    if not minX then self:_hide() return end

    local w, h = maxX - minX, maxY - minY
    if w < 1 or h < 1 then self:_hide() return end

    local dist = (cam.CFrame.Position - cf.Position).Magnitude

    local scale = 1
    if self.DistanceScale then
        scale = math.clamp(self.MinDistance / math.max(dist, self.MinDistance), 0.5, 1.5)
    end

    if self._box then
        self._box.Position  = Vector2.new(minX, minY)
        self._box.Size      = Vector2.new(w, h)
        self._box.Thickness = self._baseThickness * scale
        self._box.Visible   = true
    end

    if self._label then
        local text = self.Name
        if self.Format then
            local ok, formatted = pcall(self.Format, self.Name, dist)
            if ok and formatted then text = formatted end
        end
        self._label.Text     = text
        self._label.Size     = math.floor(self._baseTextSize * scale)
        self._label.Position = Vector2.new(minX + w * 0.5, minY - self._label.Size - self.TextOffset)
        self._label.Visible  = true
    end
end

function ESP:Destroy()
    self.Enabled = false
    if self._box   then self._box:Remove()   self._box   = nil end
    if self._label then self._label:Remove() self._label = nil end
end

getgenv().ESP = ESP
