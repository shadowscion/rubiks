--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
ENT.Base      = "base_anim"
ENT.Spawnable = false
ENT.AdminOnly = false
ENT.RUBIKS    = true

local RUBIKS = RUBIKS
local HELPER = RUBIKS.HELPER


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
local function RegisterEntity(name, printname, type, size)
    local self = {
        Base      = "rubiks_cube",
        Author    = "shadowscion",
        Category  = "Puzzles",
        Spawnable = true,
        AdminOnly = false,
        PrintName = printname,
    }

    self.rubiks_name = string.lower(string.format("%s_%s", name, type))
    self.rubiks_size = math.Clamp(size, 2, 6)
    self.rubiks_sequence = "FBRLDU" .. self.rubiks_size

    if CLIENT then
        RUBIKS.RegisterPuzzle(self.rubiks_name, type, size)
    end

    scripted_ents.Register(self, self.rubiks_name)
end

RegisterEntity("2x2", "2x2 Cube", "Cube", 2)
RegisterEntity("3x3", "3x3 Cube", "Cube", 3)
RegisterEntity("4x4", "4x4 Cube", "Cube", 4)
RegisterEntity("5x5", "5x5 Cube", "Cube", 5)


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
function ENT:CanProperty(ply, prop)
    if not HELPER.IsOwner(ply, self) then return false end

    if prop == "rubiks_scramble" then
        return true
    end
    if prop == "rubiks_reset" then
        return true
    end

    return false
end


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
function ENT:SpawnFunction(ply, tr, className)
    if not tr.Hit then return end

    local ent = ents.Create(className)

    ent:SetPos(tr.HitPos + tr.HitNormal*50)
    ent:Spawn()
    ent:Activate()

    if IsValid(ply) then
        ply:AddCount("rubiks", ent)
        ply:AddCleanup("rubiks", ent)

        if SERVER then
            ent:SetNWInt("ownerid", ply:UserID())

            net.Start("RUBIKS.HINT")
                net.WriteString("cube")
            net.Send(ply)
        end
    end

    return ent
end


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
function ENT:Initialize()
    self:SetModel("models/hunter/blocks/cube025x025x025.mdl")
    self:DrawShadow(false)
    self:Rebuild()
end


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
function ENT:Rebuild()
    self.rubiks_length = self.rubiks_size*6
    self.rubiks_maxs = Vector(self.rubiks_length, self.rubiks_length, self.rubiks_length)
    self.rubiks_mins = -self.rubiks_maxs

    self:PhysicsInitConvex({
        Vector(-self.rubiks_length, -self.rubiks_length, -self.rubiks_length),
        Vector(-self.rubiks_length, -self.rubiks_length, self.rubiks_length),
        Vector(-self.rubiks_length, self.rubiks_length, -self.rubiks_length),
        Vector(-self.rubiks_length, self.rubiks_length, self.rubiks_length),
        Vector(self.rubiks_length, -self.rubiks_length, -self.rubiks_length),
        Vector(self.rubiks_length, -self.rubiks_length, self.rubiks_length),
        Vector(self.rubiks_length, self.rubiks_length, -self.rubiks_length),
        Vector(self.rubiks_length, self.rubiks_length, self.rubiks_length)
    })

    self:SetMoveType(MOVETYPE_CUSTOM)
    self:SetSolid(SOLID_VPHYSICS)
    self:EnableCustomCollisions(true)

    if CLIENT then
        self:SetRenderBounds(self.rubiks_mins, self.rubiks_maxs)
    end
end


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
function ENT:CubeTrace(trace)
    local hitpos = trace.HitPos
    local hitnorm = trace.HitNormal

    if trace.Entity ~= self then return false end

    local pos
    if self.rubiks_size % 2 == 0 then
        pos = HELPER.SnapVector(self:WorldToLocal(hitpos) - Vector(6, 6, 6), 12)/12
        if pos.x >= 0 then pos.x = pos.x + 1 end
        if pos.y >= 0 then pos.y = pos.y + 1 end
        if pos.z >= 0 then pos.z = pos.z + 1 end
    else
        pos = HELPER.SnapVector(self:WorldToLocal(hitpos), 12)/12
    end

    local half = math.floor(self.rubiks_size*0.5)
    pos.x = math.Clamp(pos.x, -half, half)
    pos.y = math.Clamp(pos.y, -half, half)
    pos.z = math.Clamp(pos.z, -half, half)

    local dir = HELPER.SnapVector(self:WorldToLocal(hitpos), self.rubiks_length*2)/(self.rubiks_length*2)

    return pos, dir
end


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
function ENT:CubeTraceSide(dir)
        if dir == Vector(1, 0, 0)  then return "f", 2, 3
    elseif dir == Vector(-1, 0, 0) then return "b", 2, 3
    elseif dir == Vector(0, 1, 0)  then return "r", 1, 3
    elseif dir == Vector(0, -1, 0) then return "l", 1, 3
    elseif dir == Vector(0, 0, 1)  then return "u", 2, 1
    elseif dir == Vector(0, 0, -1) then return "d", 2, 1
    end

    return false
end


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
function ENT:CubeTraceNeighbors(side)
        if side == "f" then return "l", "r", "d", "u"
    elseif side == "b" then return "l", "r", "d", "u"
    elseif side == "r" then return "b", "f", "d", "u"
    elseif side == "l" then return "b", "f", "d", "u"
    elseif side == "u" then return "l", "r", "b", "f"
    elseif side == "d" then return "l", "r", "b", "f"
    end

    return false
end


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
function ENT:CubeTraceLayers(pos, dir)
    local side, row, col = self:CubeTraceSide(dir)
    if not side then
        return false, false
    end

    row = pos[row]
    col = pos[col]

    local layer_row = false
    local layer_col = false

    local half = math.floor(self.rubiks_size*0.5)
    local nl, nr, nd, nu = self:CubeTraceNeighbors(side)

    if row ~= 0 then layer_row = string.Trim(string.rep(row < 0 and nl or nr, half - math.abs(row) + 1)) end
    if col ~= 0 then layer_col = string.Trim(string.rep(col < 0 and nd or nu, half - math.abs(col) + 1)) end

    local rneg = (row < 0) and (col > 0 and 1 or -1) or (col > 0 and -1 or 1)
    local cneg = (col > 0) and (row > 0 and 1 or -1) or (row > 0 and -1 or 1)

    if side == "r" or side == "u" or side == "b" then
        rneg = -rneg
        cneg = -cneg
    end

    return layer_row, layer_col, rneg, cneg
end
