--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
local RUBIKS = RUBIKS
local HELPER = RUBIKS.HELPER


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
if SERVER then
    util.AddNetworkString("RUBIKS.SYNC")
    util.AddNetworkString("RUBIKS.MOVE")
    util.AddNetworkString("RUBIKS.HINT")

    hook.Add("KeyPress", "RUBIKS.KeyPress", function(ply, key)
        local weapon = ply:GetActiveWeapon():GetClass()
        if weapon == "weapon_physgun" or weapon == "gmod_tool" then return end

        if key ~= IN_ATTACK and key ~= IN_ATTACK2 then return end

        local trace = ply:GetEyeTrace()
        if not trace.Entity.RUBIKS or not trace.Entity.HandleInput then return end

        if not HELPER.IsOwner(ply, trace.Entity) then return end

        trace.Entity:HandleInput(ply, trace)
    end)

    net.Receive("RUBIKS.SYNC", function(len, ply)
        local self = net.ReadEntity()
        if not IsValid(self) or not self.RUBIKS then return end

        self.rubiks_history = string.Trim(self.rubiks_history or "")

        local send = {}
        for i in string.gmatch(self.rubiks_history, "%S+") do
            table.insert(send, {
                key = string.match(i, "%a+"),
                rot = string.match(i, "'") and 1 or -1,
            })
        end

        net.Start("RUBIKS.SYNC")
            net.WriteEntity(self)
            net.WriteTable(send)
        net.Send(ply)
    end)

    return
end


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
net.Receive("RUBIKS.MOVE", function()
    local self = net.ReadEntity()
    if not IsValid(self) or not self.RUBIKS then return end

    local data = net.ReadTable() or {}
    for i, rotation in ipairs(data) do
        self:AddRotation(rotation)
    end
end)


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
net.Receive("RUBIKS.SYNC", function()
    local self = net.ReadEntity()
    if not IsValid(self) or not self.RUBIKS then return end

    self:ResetRubiks()

    local data = net.ReadTable() or {}
    for i, rotation in ipairs(data) do
        self:AddRotation(rotation)
    end
end)


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
local hints = {
    ["cube"] = { "Aim at a side and use Mouse1 or Mouse2 to rotate it", "Hold Shift for more advanced control." },
    ["tetra"] = { "Aim at a median and use Mouse1 or Mouse2 to rotate it." },
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
