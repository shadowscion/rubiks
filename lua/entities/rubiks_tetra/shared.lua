--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
ENT.Base      = "base_anim"
ENT.Spawnable = false
ENT.AdminOnly = false
ENT.RUBIKS    = true

local RUBIKS = RUBIKS
local HELPER = RUBIKS.HELPER


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
local function RegisterEntity(name, printname, type, ...)
    local self = {
        Base      = "rubiks_tetra",
        Author    = "shadowscion",
        Category  = "Puzzles",
        Spawnable = true,
        AdminOnly = false,
        PrintName = printname,
    }

    self.rubiks_name = string.lower(string.format("%s_%s", name, type))
    self.rubiks_size = 3
    self.rubiks_sequence = "FRLU" .. (self.rubiks_size + 1)

    if CLIENT then
        RUBIKS.RegisterPuzzle(self.rubiks_name, type, ...)
    end

    scripted_ents.Register(self, self.rubiks_name)
end

RegisterEntity("Pyraminx", "Pyraminx", "Tetra")


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
                net.WriteString("tetra")
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
    self.rubiks_length = self.rubiks_size*6 -- 0.5
    self.rubiks_maxs = Vector(self.rubiks_length, self.rubiks_length, self.rubiks_length)*2
    self.rubiks_mins = -self.rubiks_maxs

    self.convexes = {
        Vector(0, 0, 1.5)*self.rubiks_length,
        Vector(-1.414, 0, -0.5)*self.rubiks_length,
        Vector(0.707, 1.22474, -0.5)*self.rubiks_length,
        Vector(0.707, -1.22474, -0.5)*self.rubiks_length,
    }

    self:PhysicsInitConvex(self.convexes)
    self:SetMoveType(MOVETYPE_CUSTOM)
    self:SetSolid(SOLID_VPHYSICS)
    self:EnableCustomCollisions(true)

    if CLIENT then
        self:SetRenderBounds(self.rubiks_mins, self.rubiks_maxs)
    end
end


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
local face_dirs = {
    f = Vector(0.9428, 0, 0.3333)*3,        // ugly hardcoded hack
    r = Vector(-0.4714, 0.8165, 0.3333)*3,  // but it will have to do
    l = Vector(-0.4714, -0.8165, 0.3333)*3,
    u = Vector(0, 0, -1)*3,
}

function ENT:GetTetraSide(dir)
    if dir == Vector(1, 0, 0)  then return "f", face_dirs.f end
    if dir == Vector(0, 1, 0)  then return "r", face_dirs.r end
    if dir == Vector(0, -1, 0) then return "l", face_dirs.l end
    if dir == Vector(0, 0, -1) then return "u", face_dirs.u end
    return false
end


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
function ENT:GetTetraNeighbors(side)
    if side == "f" then return "l", "r", "u" end
    if side == "l" then return "f", "r", "u" end
    if side == "r" then return "l", "f", "u" end
    if side == "u" then return "l", "r", "f" end
    return false
end


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
local face_neg = {
    f = { r =  1, l =  1, u =  1 },
    r = { f = -1, l = -1, u =  1 },
    l = { r = -1, f =  1, u =  1 },
    u = { r = -1, l = -1, f = -1 },
}

function ENT:GetTetraTrace(trace)
    if trace.Entity ~= self then
        return false
    end

    local hitpos = trace.HitPos
    local hitnorm = trace.HitNormal

    local lpos = self:WorldToLocal(hitpos)
    local lnrm = self:WorldToLocal(hitnorm + self:GetPos())

    lnrm.x = math.Round(lnrm.x)
    lnrm.y = math.Round(lnrm.y)
    lnrm.z = math.Round(lnrm.z)

    local side, normal = self:GetTetraSide(lnrm)
    if not side then
        return false
    end

    local side_pos = normal*self.rubiks_size -- self.rubiks.master[side].dir * self.rubiks_size * 3
    local side_dir = (lpos - side_pos) / 12
    local side_dist = 2 - math.min(1, math.floor(side_dir:Length()))

    local nl, nr, nu = self:GetTetraNeighbors(side)
    local key = (side == "u" and side_dir.x < 0 or side_dir.z > 0) and nu or (side_dir.y > 0 and nl or nr)

    return string.rep(key, side_dist), face_neg[side][key], side_pos, normal
end
