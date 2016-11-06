--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
function ENT:HandleInput(ply, trace)
    local side, dir = self:GetTetraTrace(trace)
    local send = {
        key = side,
        rot = ply:KeyDown(IN_ATTACK) and dir or -dir,
    }

    if not send.key or not send.rot then return end

    local addmove = send.key .. (send.rot == 1 and "'" or "")
    self.rubiks_history = string.Trim((self.rubiks_history or "") .. " " .. addmove)

    net.Start("RUBIKS.MOVE")
        net.WriteEntity(self)
        net.WriteTable({ send })
    net.Broadcast()
end


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
function ENT:PreEntityCopy()
    duplicator.ClearEntityModifier(self, "rubiks_dupe_info")
    duplicator.StoreEntityModifier(self, "rubiks_dupe_info", { history = string.Trim(self.rubiks_history or "") })
end


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
function ENT:PostEntityPaste(ply, ent, createdEntities)
    if IsValid(ply) then
        ply:AddCount("rubiks", self)
        ply:AddCleanup("rubiks", self)

        ent:SetNWInt("ownerid", ply:UserID())
    end

    timer.Simple(1, function()
        if not IsValid(ply) or not IsValid(ent) then return end

        if not ent.EntityMods then return end
        if not ent.EntityMods.rubiks_dupe_info then return end
        if not ent.EntityMods.rubiks_dupe_info.history then return end

        local history = ent.EntityMods.rubiks_dupe_info.history
        ent.rubiks_history = history

        local send = {}
        for i in string.gmatch(history, "%S+") do
            table.insert(send, {
                key = string.match(i, "%a+"),
                rot = string.match(i, "'") and 1 or -1,
            })
        end

        net.Start("RUBIKS.SYNC")
            net.WriteEntity(ent)
            net.WriteTable(send)
        net.Broadcast()
    end)
end
