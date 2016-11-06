--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
local RUBIKS = RUBIKS
local HELPER = RUBIKS.HELPER


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
properties.Add( "rubiks_scramble", {
    Order     = 1,
    MenuLabel = "Scramble",
    MenuIcon  = "icon16/rubiks_scramble16.png",

    Filter = function(self, ent, ply)
        if not IsValid(ent) or not ent.RUBIKS then return false end
        if not gamemode.Call("CanProperty", ply, "rubiks_scramble", ent) then return false end
        return true
    end,

    Action = function(self, ent)
        self:MsgStart()
            net.WriteEntity(ent)
        self:MsgEnd()
    end,

    Receive = function(self, len, ply)
        local ent = net.ReadEntity()
        if not self:Filter(ent, ply) then return end

        local move_list, scramble = HELPER.Scrambler(ent.rubiks_sequence)
        ent.rubiks_history = string.Trim((ent.rubiks_history or "") .. scramble) .. " "

        net.Start("RUBIKS.MOVE")
            net.WriteEntity(ent)
            net.WriteTable(move_list)
        net.Broadcast()
    end
})


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
properties.Add( "rubiks_reset", {
    Order     = 2,
    MenuLabel = "Reset",
    MenuIcon  = "icon16/rubiks_reset16.png",

    Filter = function(self, ent, ply)
        if not IsValid(ent) or not ent.RUBIKS then return false end
        if not gamemode.Call("CanProperty", ply, "rubiks_reset", ent) then return false end
        return true
    end,

    Action = function(self, ent)
        self:MsgStart()
            net.WriteEntity(ent)
        self:MsgEnd()
    end,

    Receive = function(self, len, ply)
        local ent = net.ReadEntity()
        if not self:Filter(ent, ply) then return end

        ent.rubiks_history = ""

        net.Start("RUBIKS.SYNC")
            net.WriteEntity(ent)
            net.WriteTable({})
        net.Send(ply)
    end
})
