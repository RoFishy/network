local Utils = script.Utils
local Remote = require(Utils.Remote)

local Network = {
    Remotes = {}
}

function Network.new(Name : string, Type: "RemoteEvent" | "RemoteFunction"?)
    if Network.Remotes[Name] then
        return Network.Remotes[Name]
    else
        Network.Remotes[Name] = Remote.new(Type)
        return Network.Remotes[Name]
    end
end

function Network:Cleanup()
    for _, Event in self.Remotes do
        Event:Cleanup()
    end
end

return Network