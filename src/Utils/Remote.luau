export type Remote = typeof(setmetatable({}, {})) & {
    Remote : RemoteEvent | RemoteFunction,
    Fire : (Data : any?) -> (),
    OnServerEvent : (Callback : (Player : Player, any) -> ()) -> (),
    OnClientEvent : (Callback : (any) -> ()) -> ()
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage.Packages
local Janitor = require(Packages.Janitor)
local Promise = require(Packages.Promise)

local Remote = {}

function Remote.new(Type : string) : Remote
    local self : Remote = setmetatable({} :: any, Remote)
    self._janitor = Janitor.new()
    self.Remote = self._janitor:Add(Instance.new(Type))
    self.Remote.Parent = script

    return self
end

function Remote:Fire(Data : any?)
    if self.Remote:IsA("RemoteEvent") then
        if RunService:IsServer() then
            self.Remote:FireClient()
        else
            self.Remote:FireServer()
        end
    elseif self.Remote:IsA("RemoteFunction") then
        if RunService:IsServer() then
            return Promise.new(function (Resolve, Reject)
                local ok, result = self.Remote:InvokeClient(Data or nil)

                if ok then
                    Resolve(result)
                else
                    Reject(result)
                end
            end)
        else
            return Promise.new(function (Resolve, Reject)
                local ok, result = self.Remote:InvokeServer(Data or nil)

                if ok then
                    Resolve(result)
                else
                    Reject(result)
                end
            end)     
        end
    end
end

function Remote:OnServerEvent(Callback : (Player : Player, any) -> ())
    if self.Remote:IsA("RemoteFunction") then
        self.Remote.OnServerInvoke = Callback
    else
        self._janitor:Add(
            self.Remote.OnServerEvent:Connect(Callback)
        )
    end
end

function Remote:OnClientEvent(Callback : (any) -> ())
    if self.Remote:IsA("RemoteFunction") then
        self.Remote.OnClientInvoke = Callback
    else
        self._janitor:Add(
            self.Remote.OnClientEvent:Connect(Callback)
        )
    end
end

function Remote:Cleanup()
    self.Remote:Destroy()
    self._janitor:Cleanup()
end

return Remote