---------------------------------------------------------------
---------------------------------------------------------------
local RUBIKS = RUBIKS
local HELPER = RUBIKS.HELPER


----------------------------------------------------------------
properties.Add( "rubiks_scramble", {
    Order     = 1,
    MenuLabel = "Scramble",
    MenuIcon  = "icon16/rubiks_scramble16.png",

    Filter = function(self, ent, ply)
        if not IsValid(ent) or not ent.RUBIKS_TYPE then return false end
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

        local move_list, scramble = ent:GetScramble()

        ent.RUBIKS_HISTORY = ent.RUBIKS_HISTORY or {}
        for _, move in ipairs(move_list) do
            table.insert(ent.RUBIKS_HISTORY, move)
        end

        net.Start("RUBIKS.MOVE")
            net.WriteEntity(ent)
            net.WriteTable(move_list)
        net.Broadcast()
    end
})


----------------------------------------------------------------
properties.Add( "rubiks_reset", {
    Order     = 2,
    MenuLabel = "Reset",
    MenuIcon  = "icon16/rubiks_reset16.png",

    Filter = function(self, ent, ply)
        if not IsValid(ent) or not ent.RUBIKS_TYPE then return false end
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

        ent.RUBIKS_HISTORY = {}

        net.Start("RUBIKS.SYNC")
            net.WriteEntity(ent)
            net.WriteTable({})
        net.Broadcast()
    end
})
