---------------------------------------------------------------
---------------------------------------------------------------
local RUBIKS = RUBIKS
local HELPER = RUBIKS.HELPER

local TYPE = { META = {} }
local META = TYPE.META

RUBIKS.TYPES["SKEWB"] = TYPE


----------------------------------------------------------------
local F = Vector(1, 0, 0)
local L = Vector(0, -1, 0)
local U = Vector(0, 0, 1)
local B = -F
local R = -L
local D = -U

local frac = 2/3

local function rotateAroundAxis(angle, axis, rot)
    local a = Angle(angle)
    a:RotateAroundAxis(axis, rot)
    return a
end

local function Shift(map)
    local cw = { map[2], map[3], map[1], map[4], map[6], map[7],  map[5] }
    local ccw = { map[3], map[1], map[2], map[4], map[7], map[5],  map[6] }
    return ccw, cw
end


----------------------------------------------------------------
function TYPE.GenerateData(size)
    local size   = 2
    local length = size*6

    local maxs = Vector(length, length, length)
    local mins = -maxs

    local hull = {
        Vector(-length, -length, -length),
        Vector(-length, -length, length),
        Vector(-length, length, -length),
        Vector(-length, length, length),
        Vector(length, -length, -length),
        Vector(length, -length, length),
        Vector(length, length, -length),
        Vector(length, length, length)
    }

    local data = {
        SIZE   = size,
        LENGTH = length,
        MAXS   = maxs,
        MINS   = mins,
        HULL   = hull,
        SEQ    = "FRFLBRBLRRRLLRLLURULDRDL.",
    }

    if CLIENT then
        data.MASTER = {
            fl = { dir = Vector(frac, -frac, frac):GetNormal(),   map = { 1, 3, 5,  7,  8, 10, 12 } },
            fr = { dir = -Vector(frac, frac, frac):GetNormal(),   map = { 1, 4, 5,  8,  7,  9, 11 } },
            bl = { dir = Vector(-frac, frac, frac):GetNormal(),   map = { 2, 4, 5, 11, 12, 14,  8 } },
            br = { dir = -Vector(-frac, -frac, frac):GetNormal(), map = { 2, 3, 5, 12, 11, 13,  7 } },
            ll = { dir = Vector(-frac, -frac, frac):GetNormal(),  map = { 3, 2, 5, 12,  7, 13, 11 } },
            lr = { dir = -Vector(frac, -frac, frac):GetNormal(),  map = { 3, 1, 5,  7, 12, 10,  8 } },
            rl = { dir = Vector(frac, frac, frac):GetNormal(),    map = { 4, 1, 5,  8, 11,  9,  7 } },
            rr = { dir = -Vector(-frac, frac, frac):GetNormal(),  map = { 4, 2, 5, 11,  8, 14, 12 } },
            ul = { dir = -Vector(frac, frac, -frac):GetNormal(),  map = { 5, 3, 2, 12, 11,  7, 13 } },
            ur = { dir = -Vector(-frac, frac, frac):GetNormal(),  map = { 5, 4, 2, 11, 12,  8, 14 } },
            dl = { dir = -Vector(-frac, frac, frac):GetNormal(),  map = { 6, 3, 1, 10,  9, 13,  7 } },
            dr = { dir = -Vector(frac, frac, -frac):GetNormal(),  map = { 6, 4, 1,  9, 10, 14,  8 } },
        }

        for k, v in pairs(data.MASTER) do
            v.ccw, v.cw = Shift(v.map)
        end

        data.CREATE = function()
            local puzzle = {
                [1] = {
                    model = "center",
                    ang   = F:Angle(),
                    sub   = { "f" },
                },
                [2] = {
                    model = "center",
                    ang   = B:Angle(),
                    sub   = { "b" },
                },
                [3] = {
                    model = "center",
                    ang   = L:Angle(),
                    sub   = { "l" },
                },
                [4] = {
                    model = "center",
                    ang   = R:Angle(),
                    sub   = { "r" },
                },
                [5] = {
                    model = "center",
                    ang   = U:Angle(),
                    sub   = { "u" },
                },
                [6] = {
                    model = "center",
                    ang   = D:Angle(),
                    sub   = { "d" },
                },
                [7] = {
                    model = "corner",
                    ang   = F:Angle(),
                    sub   = { "f", "l", "u" },
                },
                [8] = {
                    model = "corner",
                    ang   = rotateAroundAxis(F:Angle(), F, -90),
                    sub   = { "f", "u", "r" },
                },
                [9] = {
                    model = "corner",
                    ang   = rotateAroundAxis(F:Angle(), F, -180),
                    sub   = { "f", "r", "d" },
                },
                [10] = {
                    model = "corner",
                    ang   = rotateAroundAxis(F:Angle(), F, -270),
                    sub   = { "f", "d", "l" },
                },
                [11] = {
                    model = "corner",
                    ang   = B:Angle(),
                    sub   = { "b", "r", "u" },
                },
                [12] = {
                    model = "corner",
                    ang   = rotateAroundAxis(B:Angle(), B, -90),
                    sub   = { "b", "u", "l" },
                },
                [13] = {
                    model = "corner",
                    ang   = rotateAroundAxis(B:Angle(), B, -180),
                    sub   = { "b", "l", "d" },
                },
                [14] = {
                    model = "corner",
                    ang   = rotateAroundAxis(B:Angle(), B, -270),
                    sub   = { "b", "d", "r" },
                }
            }

            for k, v in ipairs(puzzle) do
                v.id = k
            end

            return puzzle
        end
    end

    return data
end


----------------------------------------------------------------
function META:BuildPhysics()
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
function META:CubeTrace(trace)
    local hitpos = trace.HitPos
    local hitnorm = trace.HitNormal

    if trace.Entity ~= self then return false end

    local pos = HELPER.SnapVector(self:WorldToLocal(hitpos) - Vector(6, 6, 6), 12)/12
    if pos.x >= 0 then pos.x = pos.x + 1 end
    if pos.y >= 0 then pos.y = pos.y + 1 end
    if pos.z >= 0 then pos.z = pos.z + 1 end

    local half = math.floor(self.RUBIKS_DATA.SIZE*0.5)
    pos.x = math.Clamp(pos.x, -half, half)
    pos.y = math.Clamp(pos.y, -half, half)
    pos.z = math.Clamp(pos.z, -half, half)

    local dir = HELPER.SnapVector(self:WorldToLocal(hitpos), self.RUBIKS_DATA.LENGTH*2)/(self.RUBIKS_DATA.LENGTH*2)

    return pos, dir
end


----------------------------------------------------------------
function META:CubeTraceSide(dir)
        if dir == Vector(1, 0, 0)  then return "f", 2, 3
    elseif dir == Vector(-1, 0, 0) then return "b", 2, 3
    elseif dir == Vector(0, 1, 0)  then return "r", 1, 3
    elseif dir == Vector(0, -1, 0) then return "l", 1, 3
    elseif dir == Vector(0, 0, 1)  then return "u", 2, 1
    elseif dir == Vector(0, 0, -1) then return "d", 2, 1
    end
    return false
end


----------------------------------------------------------------
function META:CubeTraceNeighbors(side)
        if side == "f" then return "l", "r", "d", "u"
    elseif side == "b" then return "l", "r", "d", "u"
    elseif side == "r" then return "b", "f", "d", "u"
    elseif side == "l" then return "b", "f", "d", "u"
    elseif side == "u" then return "l", "r", "b", "f"
    elseif side == "d" then return "l", "r", "b", "f"
    end
    return false
end


----------------------------------------------------------------
function META:CubeTraceLayers(pos, dir)
    if not pos or not dir then return false end

    local side, row, col = self:CubeTraceSide(dir)
    if not side then return false end

    row = pos[row]
    col = pos[col]

    if side == "r" or side == "b" then row = -row end
    if side == "u" then col = -col end

    local map = row + col == 0 and "r" or "l"
    local dir = col > 0 and "cw" or "ccw"

    return string.Trim(side .. map), string.Trim(dir)
end


----------------------------------------------------------------
if SERVER then
    function META:HandleInput(ply, trace)
        local pos, dir = self:CubeTrace(trace)
        if not pos or not dir then return end

        local side, dir = self:CubeTraceLayers(pos, dir)
        if not side or not dir then return end

        local send = {
            key = side,
            rot = dir == "ccw" and -1 or 1,
        }

        net.Start("RUBIKS.MOVE")
            net.WriteEntity(self)
            net.WriteTable({ send })
        net.Broadcast()

        return send
    end
end


----------------------------------------------------------------
if SERVER then return end


----------------------------------------------------------------
function META:GetRotation()
    self.RUBIKS_TASK = table.remove(self.RUBIKS_QUEUE, 1)

    local MASTER = self.RUBIKS_DATA.MASTER
    local PUZZLE = self.RUBIKS_PUZZLE
    local TASK = self.RUBIKS_TASK

    if not MASTER[TASK.key] then self.RUBIKS_TASK = nil return end

    local old = MASTER[TASK.key].map
    local new = MASTER[TASK.key][TASK.rot == -1 and "ccw" or "cw"]

    local copy = {}
    for i = 1, #old do
        local old_index = old[i]
        copy[old_index] = table.Copy(PUZZLE[old_index])
        PUZZLE[old_index] = nil
    end

    for i = 1, #new do
        PUZZLE[old[i]] = copy[new[i]]
    end

    TASK.transform_axis = MASTER[TASK.key].dir*TASK.rot
    TASK.transform_ang = {}

    for i = 1, #old do
        if not PUZZLE[old[i]] then continue end
        TASK.transform_ang[i] = PUZZLE[old[i]].ang
    end

    TASK.old = old
    TASK.tween = 0
end


----------------------------------------------------------------
function META:DoRotation()
    local PUZZLE = self.RUBIKS_PUZZLE
    local TASK = self.RUBIKS_TASK

    local rate = math.min(#self.RUBIKS_QUEUE + (RUBIKS.ANIM_SPEED or 1) + 1, 6)
    TASK.tween = math.min(TASK.tween + FrameTime()*rate, 1)

    local rotation = HELPER.SmoothStep(TASK.tween)*120
    for i = 1, #TASK.old do
        if not PUZZLE[TASK.old[i]] then continue end

        local ang = Angle(TASK.transform_ang[i])
        ang:RotateAroundAxis(TASK.transform_axis, rotation)

        PUZZLE[TASK.old[i]].ang = ang
    end

    if TASK.tween == 1 then
        self.RUBIKS_TASK = nil
    end
end


----------------------------------------------------------------
local modelpath = "models/rubiks/skewb_"
local materialpath = "rubiks/color_"

local nullify = false
if not file.Exists("models/rubiks/skewb_center.mdl", "GAME") then nullify = true end
if not file.Exists("models/rubiks/skewb_corner.mdl", "GAME") then nullify = true end

function META:DrawPuzzle(RENDER)
    if nullify then self:Debug() return end

    RENDER:SetRenderOrigin(self:GetPos())
    RENDER:SetModelScale(1, 0)

    for i, part in ipairs(self.RUBIKS_PUZZLE) do
        RENDER:SetModel(modelpath .. part.model .. ".mdl")
        for s, sub in ipairs(part.sub) do
            RENDER:SetSubMaterial(s, materialpath .. sub)
        end

        RENDER:SetRenderAngles(self:LocalToWorldAngles(part.ang))
        RENDER:SetupBones()
        RENDER:DrawModel()
    end
end


----------------------------------------------------------------
function META:Debug()
    render.DrawWireframeBox(self:GetPos(), self:GetAngles(), self.RUBIKS_DATA.MINS, self.RUBIKS_DATA.MAXS, Color(0, 255, 255), true)

    cam.Start2D()
        local pos = self:GetPos():ToScreen()
        draw.SimpleText(self, "TargetIDSmall", pos.x, pos.y, Color(255, 255, 255), 1)
    cam.End2D()
end
