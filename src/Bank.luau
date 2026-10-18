local Bank = {}
Bank.__index = Bank

local function release(item)
    if item == nil then
        return
    end

    local kind = typeof(item)

    if kind == "RBXScriptConnection" then
        item:Disconnect()
        return
    end

    if kind == "Instance" then
        item:Destroy()
        return
    end

    if kind == "function" then
        item()
        return
    end

    if type(item) == "table" then
        if type(item.Disconnect) == "function" then
            item:Disconnect()
        elseif type(item.Destroy) == "function" then
            item:Destroy()
        end
    end
end

function Bank.new()
    return setmetatable({ _registry = {} }, Bank)
end

function Bank:Attach(target, item)
    if item == nil or typeof(target) ~= "Instance" then
        return self
    end

    local bucket = self._registry[target]
    if not bucket then
        bucket = {}
        self._registry[target] = bucket
    end

    bucket[#bucket + 1] = item

    return self
end

Bank.Add = Bank.Attach

function Bank:Remove(target)
    local bucket = self._registry[target]
    if not bucket then
        return self
    end

    self._registry[target] = nil

    for _, item in ipairs(bucket) do
        release(item)
    end

    return self
end

function Bank:Update()
    for target, bucket in pairs(self._registry) do
        local ok, parent = pcall(function()
            return target.Parent
        end)

        if not ok or parent == nil then
            self._registry[target] = nil

            for _, item in ipairs(bucket) do
                release(item)
            end
        end
    end

    return self
end

Bank.Cleanup = Bank.Update

function Bank:Clear()
    local registry = self._registry
    self._registry = {}

    for _, bucket in pairs(registry) do
        for _, item in ipairs(bucket) do
            release(item)
        end
    end

    return self
end

Bank.Destroy = Bank.Clear

function Bank.__tostring(self)
    return "Bank"
end

return Bank
