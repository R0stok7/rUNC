function snapshot(instance : Instance)
    if instance == nil then
        error("snapshot: Expected instance, got nil")
    end

    return getproperties(instance)
end

getgenv().snapshot = snapshot

function diff(snapshot_1, snapshot_2)
    if snapshot_1 == nil or snapshot_2 == nil then
        error(`diff: Expected 2 snapshots, got {(snapshot_1 ~= nil and 1 or 0) + (snapshot_2 ~= nil and 1 or 0)}`)
    end

    if snapshot_1.isSnapshot == snapshot_2.isSnapshot and snapshot_1.isSnapshot ~= nil then
        local isChanged = {}

        for property, value in pairs(snapshot_1) do
            if property ~= "isSnapshot" then
                isChanged[property] = not(snapshot_2[property] == value)
            end
        end
        
        return isChanged
    else
        error("comparesnapshot: Trying to compare two different snapshots-type")
    end
end

getgenv().diffsnapshot = diff

function applysnapshot(instance : Instance, snapshot)
    if instance == nil or snapshot == nil then
        error("applysnapshot: No instance or snapshot given")
    end

    if snapshot.isSnapshot and snapshot.isSnapshot.ClassName == instance.ClassName then
        for property, value in pairs(snapshot) do
            instance[property] = value
        end
    end
end

getgenv().applysnapshot = applysnapshot
