---------------------------------------------------------------
---------------------------------------------------------------
AddCSLuaFile()

ENT.Base      = "base_anim"
ENT.Author    = "shadowscion"
ENT.Category  = "Rubiks Puzzles"
ENT.AdminOnly = false
ENT.Spawnable = false

function RUBIKS.RegisterEntity(type, name, printName, ...)
    if not RUBIKS.TYPES[type] then return end

    local ent = {
        Base       = "base_rubiks",
        PrintName  = printName,
        Author     = ENT.Author,
        Category   = ENT.Category,
        Spawnable  = true,
    }

    ent.RUBIKS_TYPE = type
    ent.RUBIKS_NAME = "rubiks_" .. name
    ent.RUBIKS_DATA = RUBIKS.TYPES[type].GenerateData(...)

    table.Merge(ent, RUBIKS.TYPES[type].META)

    scripted_ents.Register(ent, ent.RUBIKS_NAME)
end

--
RUBIKS.RegisterEntity("CUBE", "cube2x2", "2x2 Cube", 2)
RUBIKS.RegisterEntity("CUBE", "cube3x3", "3x3 Cube", 3)
RUBIKS.RegisterEntity("CUBE", "cube4x4", "4x4 Cube", 4)
RUBIKS.RegisterEntity("CUBE", "cube5x5", "5x5 Cube", 5)

--
RUBIKS.RegisterEntity("SKEWB", "skewb", "Skewb")

--
RUBIKS.RegisterEntity("TETRA", "pyraminx", "Pyraminx")
RUBIKS.RegisterEntity("MEGAMINX", "megaminx", "Megaminx")


----------------------------------------------------------------
function ENT:CanProperty(ply, prop)
    if not RUBIKS.HELPER.IsOwner(ply, self) then return false end

    if prop == "rubiks_scramble" then
        return true
    end
    if prop == "rubiks_reset" then
        return true
    end

    return false
end


----------------------------------------------------------------
function ENT:SpawnFunction(ply, tr, className)
    if not tr.Hit then return end

    local ent = ents.Create(className)

    ent:SetPos(tr.HitPos + tr.HitNormal*50)
    ent:Spawn()
    ent:Activate()

    ply:AddCount("rubiks_entity", ent)

    net.Start("RUBIKS.HINT")
        net.WriteString(ent.RUBIKS_TYPE)
    net.Send(ply)

    return ent
end


----------------------------------------------------------------
function ENT:Initialize()
    self:SetModel("models/hunter/blocks/cube025x025x025.mdl")
    self:DrawShadow(false)
    self:BuildPhysics()
end


----------------------------------------------------------------
function ENT:BuildPhysics()
    if not self.RUBIKS_DATA then return end

    self:PhysicsInitConvex(self.RUBIKS_DATA.HULL)
    self:SetMoveType(MOVETYPE_CUSTOM)
    self:SetSolid(SOLID_VPHYSICS)
    self:EnableCustomCollisions(true)

    if CLIENT then
        self:SetRenderBounds(self.RUBIKS_DATA.MINS, self.RUBIKS_DATA.MAXS)
    end
end


----------------------------------------------------------------
function ENT:GetScramble(len, pattern)
    local sequence = self.RUBIKS_DATA.SEQ
    local match = string.lower(string.match(sequence, "%a+"))
    local size = math.floor(tonumber(string.match(sequence, "%d+") or 2)*0.5)

    if not size or size < 1 then size = 1 end

    local pattern = pattern or string.match(sequence, "%.+")
    if pattern then
        pattern = "%a" .. pattern
    end

    local moves = {}
    for i in string.gmatch(match, pattern or "%a") do
        for j = 1, size do
            table.insert(moves, string.rep(i, j))
            table.insert(moves, string.rep(i, j) .. "'")
            table.insert(moves, string.rep(i, j) .. "2")
        end
    end

    local len = len or 30
    local scramble = ""
    local prev_move = ""

    local move_list = {}
    for i = 1, len do
        local next_move = moves[math.floor(math.random(1, #moves))]
        while string.match(next_move, "%a+") == string.match(prev_move, "%a+") do
            next_move = moves[math.floor(math.random(1, #moves))]
        end

        local move = {
            key = string.match(next_move, "%a+"),
            rot = string.match(next_move, "'") and 1 or -1,
        }

        if string.match(next_move, "2") then
            table.insert(move_list, move)
            table.insert(move_list, move)

            scramble = scramble .. move.key .. " "
            scramble = scramble .. move.key .. " "
        else
            table.insert(move_list, move)
            scramble = scramble .. next_move .. " "
        end

        prev_move = next_move
    end

    return move_list, string.Trim(scramble)
end


----------------------------------------------------------------
if SERVER then
    function ENT:ReverseHistory()
        self.RUBIKS_HISTORY = self.RUBIKS_HISTORY or {}

        local tbl = table.Reverse(table.Copy(self.RUBIKS_HISTORY))
        for i, v in ipairs(tbl) do
            v.rot = -v.rot
        end

        return tbl
    end

    function ENT:AddHistory(data)
        self.RUBIKS_HISTORY = self.RUBIKS_HISTORY or {}
        table.insert(self.RUBIKS_HISTORY, data)
    end

    return
end


----------------------------------------------------------------
function ENT:HandleQueue()
    if not self.RUBIKS_TASK then
        if not self.RUBIKS_QUEUE then
            self.RUBIKS_QUEUE = {}
            return
        elseif #self.RUBIKS_QUEUE == 0 then
            return
        else
            self:GetRotation()
        end
    else
        self:DoRotation()
    end
end


----------------------------------------------------------------
function ENT:AddRotation(data)
    self.RUBIKS_QUEUE = self.RUBIKS_QUEUE or {}
    table.insert(self.RUBIKS_QUEUE, data)
end


----------------------------------------------------------------
function ENT:GetRotation()
    self.RUBIKS_TASK = table.remove(self.RUBIKS_QUEUE, 1)
end


----------------------------------------------------------------
function ENT:DoRotation()
    self.RUBIKS_TASK = nil
end


----------------------------------------------------------------
function ENT:GetAnimationSpeed()
    return math.min(#self.RUBIKS_QUEUE + (RUBIKS.ANIM_SPEED or 1) + 1, 10)
end


----------------------------------------------------------------
function ENT:Reset()
    self.RUBIKS_PUZZLE = self.RUBIKS_DATA.CREATE()
    self.RUBIKS_QUEUE = {}
    self.RUBIKS_TASK = nil
end


----------------------------------------------------------------
function ENT:Synchronized()
    if not self.RUBIKS_DATA then return false end
    if not self.RUBIKS_DATA.MASTER then return false end
    if not self.RUBIKS_DATA.CREATE then return false end

    if not self.RUBIKS_PUZZLE then
        self.RUBIKS_PUZZLE = {}
        self.RUBIKS_QUEUE = {}
        self.RUBIKS_TASK = nil

        net.Start("RUBIKS.SYNC")
            net.WriteEntity(self)
        net.SendToServer()

        return false
    end

    return true
end


----------------------------------------------------------------
function ENT:Think()
    if not IsValid(self:GetPhysicsObject()) then self:BuildPhysics() end
    if not self:Synchronized() then return end

    self:HandleQueue()
end


----------------------------------------------------------------
function ENT:Draw()
    if not IsValid(LocalPlayer()) or not LocalPlayer():Alive() then return end

    if self.DrawPuzzle then
        if halo.RenderedEntity() == self then return end

        if not RUBIKS.RENDER or not self.RUBIKS_PUZZLE then
            if self.Debug then self:Debug() else self:DrawModel() end
            return
        end

        self:DrawPuzzle(RUBIKS.RENDER)
    else
        self:DrawModel()
    end
end
