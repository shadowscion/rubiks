---------------------------------------------------------------
---------------------------------------------------------------
local RUBIKS = RUBIKS
local HELPER = RUBIKS.HELPER


----------------------------------------------------------------
if SERVER then
    util.AddNetworkString("RUBIKS.SYNC")
    util.AddNetworkString("RUBIKS.MOVE")
    util.AddNetworkString("RUBIKS.HINT")

    hook.Add("KeyPress", "RUBIKS.KeyPress", function(ply, key)
        if not IsValid(ply) or not ply:Alive() then return end

        local weapon = ply:GetActiveWeapon()
        if not IsValid(weapon) then return end
        if weapon:GetClass() == "weapon_physgun" or weapon:GetClass() == "gmod_tool" then return end

        if key ~= IN_ATTACK and key ~= IN_ATTACK2 then return end

        local trace = ply:GetEyeTrace()
        if not trace.Entity.RUBIKS_TYPE or not trace.Entity.HandleInput then return end

        if not HELPER.IsOwner(ply, trace.Entity) then return end

        local data = trace.Entity:HandleInput(ply, trace)
        if data then trace.Entity:AddHistory(data) end
    end)

    net.Receive("RUBIKS.SYNC", function(len, ply)
        local self = net.ReadEntity()
        if not IsValid(self) or not self.RUBIKS_TYPE then return end

        self.RUBIKS_HISTORY = self.RUBIKS_HISTORY or {}

        net.Start("RUBIKS.SYNC")
            net.WriteEntity(self)
            net.WriteTable(self.RUBIKS_HISTORY)
        net.Send(ply)
    end)

    return
end


----------------------------------------------------------------
net.Receive("RUBIKS.MOVE", function()
    local self = net.ReadEntity()
    if not IsValid(self) or not self.RUBIKS_TYPE then return end

    local data = net.ReadTable() or {}
    for i, rotation in ipairs(data) do
        self:AddRotation(rotation)
    end
end)


----------------------------------------------------------------
net.Receive("RUBIKS.SYNC", function()
    local self = net.ReadEntity()
    if not IsValid(self) or not self.RUBIKS_TYPE then return end

    self:Reset()

    local data = net.ReadTable() or {}
    for i, rotation in ipairs(data) do
        self:AddRotation(rotation)
    end
end)


----------------------------------------------------------------
local hints = {
    ["CUBE"]     = { "Aim at a side and use Mouse1 or Mouse2 to rotate it", "Hold Shift for more advanced control." },
    ["TETRA"]    = { "Aim at a median and use Mouse1 or Mouse2 to rotate it." },
    ["MEGAMINX"] = { "Aim at a side and ouse Mouse1 or Mouse2 to rotate it." },
    ["SKEWB"]    = { "Aim at a corner and use Mouse1 to rotate it."},
}

net.Receive("RUBIKS.HINT", function()
    local msg = net.ReadString()

    if hints[msg] then
        notification.AddLegacy("Use the context menu (hold C) to reset or scramble the puzzle.", NOTIFY_HINT, 8)
        for i = #hints[msg], 1, -1 do
            notification.AddLegacy(hints[msg][i], NOTIFY_HINT, 8)
        end
    end
end)
