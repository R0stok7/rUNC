local cloneref = type(cloneref) == "function" and cloneref or function(obj)
    return obj
end

local HTTP = cloneref(game:GetService("HttpService"))

function load(module : string)
    loadstring(game:HttpGet("https://raw.githubusercontent.com/R0stok7/rUNC/refs/heads/main/src/"..module))
end

load("snapshot.luau")
getgenv().Bank = load("Bank.luau")
getgenv().ESP = load("ESPClass.luau")

--------------------------------------------------------------------------------------------
--- instantPrompt()
--------------------------------------------------------------------------------------------

function instantPrompt(proximityprompt : ProximityPrompt)
    if typeof(proximityprompt) == "Instance" then
        if proximityprompt.ClassName == "ProximityPrompt" then
            proximityprompt.HoldDuration = 0
            return
        end
    end
    error("instantPrompt: Targeted Object is not a ProximityPrompt")
end

getgenv().instantPrompt = instantPrompt


--------------------------------------------------------------------------------------------
--- getproperties()
--------------------------------------------------------------------------------------------

local API_DUMP_URL =
    "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json"

local classProps: {[string]: {string}} = {}
local classSuper: {[string]: string?} = {} 
local resolvedCache: {[string]: {string}} = {} 
local dumpLoaded = false

local function loadApiDump(): boolean
    if dumpLoaded then return true end

    local ok, raw = pcall(HTTP.GetAsync, HTTP, API_DUMP_URL)
    if not ok then
        warn("[getProperties] Failed to fetch API dump:", raw)
        return false
    end

    local ok2, data = pcall(HTTP.JSONDecode, HTTP, raw)
    if not ok2 or type(data) ~= "table" then
        warn("[getProperties] Failed to decode API dump")
        return false
    end

    for _, class in ipairs(data.Classes) do
        classSuper[class.Name] = class.Superclass
        local props = {}
        for _, member in ipairs(class.Members) do
            if member.MemberType == "Property" then
                table.insert(props, member.Name)
            end
        end
        classProps[class.Name] = props
    end

    dumpLoaded = true
    return true
end

local function resolvePropertyNames(className: string): {string}
    local cached = resolvedCache[className]
    if cached then return cached end

    local names, seen = {}, {}
    local current: string? = className
    while current and current ~= "<<<ROOT>>>" do
        for _, name in ipairs(classProps[current] or {}) do
            if not seen[name] then
                seen[name] = true
                table.insert(names, name)
            end
        end
        current = classSuper[current]
    end

    resolvedCache[className] = names
    return names
end

local function getProperties(instance: Instance): {[string]: any}
    local ok, native = pcall(function()
        return (instance :: any):GetProperties()
    end)
    if ok and type(native) == "table" then
        return native
    end

    if not loadApiDump() then
        error("[getProperties] Unable to load property list (API dump unavailable)", 2)
    end

    local result = {}
    for _, name in ipairs(resolvePropertyNames(instance.ClassName)) do
        local success, value = pcall(function()
            return (instance :: any)[name]
        end)
        if success then
            result[name] = value
        end
    end
    result.isSnapshot = instance
    return result
end


getgenv().getProperties = getProperties
