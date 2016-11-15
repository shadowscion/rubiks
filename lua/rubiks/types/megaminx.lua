---------------------------------------------------------------
---------------------------------------------------------------
local RUBIKS = RUBIKS
local HELPER = RUBIKS.HELPER

local TYPE = { META = {} }
local META = TYPE.META

RUBIKS.TYPES["MEGAMINX"] = TYPE


----------------------------------------------------------------
function TYPE.GenerateData()
    local size   = 12
    local length = size*2.551947

    local maxs = Vector(length, length, length)
    local mins = -maxs

    local hull = {
        Vector(0.602455, 1.854102, 2.551947)*size,
        Vector(2.551947, 1.854102, -0.602455)*size,
        Vector(0.602455, -1.854102, 2.551947)*size,
        Vector(2.551947, -1.854102, -0.602455)*size,
        Vector(-2.551947, 1.854102, 0.602455)*size,
        Vector(-0.602455, 1.854102, -2.551947)*size,
        Vector(-2.551947, -1.854102, 0.602455)*size,
        Vector(-0.602455, -1.854102, -2.551947)*size,
        Vector(0.974764, 3.000000, 0.602426)*size,
        Vector(-0.974764, 3.000000, -0.602426)*size,
        Vector(0.974764, -3.000000, 0.602426)*size,
        Vector(-0.974764, -3.000000, -0.602426)*size,
        Vector(1.949539, 0.000000, 2.551936)*size,
        Vector(3.154392, 0.000000, 0.602408)*size,
        Vector(-3.154392, 0.000000, -0.602408)*size,
        Vector(-1.949539, 0.000000, -2.551936)*size,
        Vector(-1.577172, 1.145898, 2.551965)*size,
        Vector(-1.577172, -1.145898, 2.551965)*size,
        Vector(1.577172, 1.145898, -2.551965)*size,
        Vector(1.577172, -1.145898, -2.551965)*size,
    }

    local data = {
        SIZE   = size,
        LENGTH = length,
        MAXS   = maxs,
        MINS   = mins,
        HULL   = hull,
        SEQ    = "FaFbBaBbRaRbLaLbDaDbUaUb.",
    }

    if CLIENT then
        if TYPE.GenerateClientData then
            TYPE.GenerateClientData(data)
        else
            data.MASTER = {}

            data.CREATE = function()
                local puzzle = {}
                return puzzle
            end
        end
    end

    return data
end


----------------------------------------------------------------
if SERVER then
    function META:HandleInput(ply, trace)
        local side = self:GetMegaminxTrace(trace)
        if not side then return end

        local send = {
            key = side,
            rot = ply:KeyDown(IN_ATTACK) and 1 or -1,
        }

        if not send.key or not send.rot then return end

        net.Start("RUBIKS.MOVE")
            net.WriteEntity(self)
            net.WriteTable({ send })
        net.Broadcast()

        return send
    end
end


----------------------------------------------------------------
local face_dir = {
    ["0.000000 0.000000 1.000000"]    = "fa",
    ["0.000000 0.000000 -1.000000"]   = "fb",
    ["-0.300000 -0.900000 0.400000"]  = "ba",
    ["0.300000 0.900000 -0.400000"]   = "bb",
    ["0.700000 -0.500000 0.400000"]   = "la",
    ["-0.700000 0.500000 -0.400000"]  = "lb",
    ["0.700000 0.500000 0.400000"]    = "da",
    ["-0.700000 -0.500000 -0.400000"] = "db",
    ["-0.300000 0.900000 0.400000"]   = "ra",
    ["0.300000 -0.900000 -0.400000"]  = "rb",
    ["-0.900000 0.000000 0.400000"]   = "ua",
    ["0.900000 0.000000 -0.400000"]   = "ub",
}

function META:GetMegaminxTrace(trace)
    if trace.Entity ~= self then return false end

    local hitpos = trace.HitPos
    local hitnorm = trace.HitNormal

    local lpos = self:WorldToLocal(hitpos)
    local lnrm = self:WorldToLocal(hitnorm + self:GetPos())

    lnrm.x = math.Round(lnrm.x,1)
    lnrm.y = math.Round(lnrm.y,1)
    lnrm.z = math.Round(lnrm.z,1)

    local side = face_dir[tostring(lnrm)]
    if not side then return false end

    return side
end


----------------------------------------------------------------
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
    local new = MASTER[TASK.key][TASK.rot == 1 and "ccw" or "cw"]

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

    local rate = self:GetAnimationSpeed() or 1
    TASK.tween = math.min(TASK.tween + FrameTime()*rate, 1)

    local rotation = HELPER.SmoothStep(TASK.tween)*72
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
local modelpath = "models/rubiks/megaminx_"
local materialpath = "rubiks/color_"

local nullify = false
if not file.Exists("models/rubiks/megaminx_center.mdl", "GAME") then nullify = true end
if not file.Exists("models/rubiks/megaminx_corner.mdl", "GAME") then nullify = true end
if not file.Exists("models/rubiks/megaminx_edge.mdl", "GAME") then nullify = true end

local textPos = {
    ["center"] = Vector(0.5*1, 0, 2.7)*6.25,
    ["corner"] = Vector(-1.57717, -1.14590, 2.55197)*6.25,
    ["edge"] = Vector(-1.57717, 0, 2.55197)*6.25,
}

function META:DrawPuzzle(RENDER)
    if nullify then self:Debug() return end

    self:GetMegaminxTrace(LocalPlayer():GetEyeTrace())

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
    render.SetColorMaterial()

    local hull = self.RUBIKS_DATA.HULL
    for i = 1, #hull do
        render.DrawSphere(self:LocalToWorld(hull[i]), 1, 6, 6, Color(0, 255, 255), true)
    end

    cam.Start2D()
        local pos = self:GetPos():ToScreen()
        draw.SimpleText(self, "TargetIDSmall", pos.x, pos.y, Color(255, 255, 255), 1)
    cam.End2D()
end


----------------------------------------------------------------
local keys_a = { "fa", "la", "ua", "ra", "da", "ba" }
local keys_b = { "fb", "lb", "ub", "rb", "db", "bb" }

local subMatCenter = { "f", "l", "u", "r", "d", "b" }
local subMatCorner = {
    ["d"] = { "f", "l", "u", "l", "u", "b" },
    ["l"] = { "f", "b", "r", "b", "r", "u" },
    ["b"] = { "f", "u", "d", "u", "d", "r" },
    ["u"] = { "f", "r", "l", "r", "l", "d" },
    ["r"] = { "f", "d", "b", "d", "b", "l" },
}
local subMatEdge = {
    ["f"] = { "u", "r", "d", "l", "b" },
    ["l"] = { false, false, "u", "r", "b" },
    ["b"] = { false, false, "r", "d", "u" },
    ["u"] = { false, false, "d", "l", "r" },
    ["r"] = { false, false, "l", "b", "d" },
    ["d"] = { false, false, "b", "u", "l" },
}

local function rotateAroundAxis(angle, axis, rot)
    local a = Angle(angle)
    a:RotateAroundAxis(axis, rot)
    return a
end

local function Shift(map)
    local ccw = { map[1], map[4], map[5], map[6], map[7], map[8], map[9], map[10], map[11], map[2], map[3] }
    local cw = { map[1], map[10], map[11], map[2], map[3], map[4], map[5], map[6], map[7], map[8], map[9] }
    return ccw, cw
end


----------------------------------------------------------------
function TYPE.GenerateClientData(data)
    data.MASTER = {
        fa = { dir = Vector(0, 0, 2.55195):GetNormal(),               map = { 1, 47, 5, 17, 6, 57, 2, 27, 3, 37, 4 } },
        ua = { dir = Vector(-2.28253, 0, 1.14129):GetNormal(),        map = { 23, 29, 25, 28, 26, 27, 2, 57, 56, 58, 24 } },
        ra = { dir = Vector(-0.70533, 2.17082, 1.14127):GetNormal(),  map = { 33, 39, 35, 38, 36, 37, 3, 27, 26, 28, 34 } },
        da = { dir = Vector(1.84662, 1.34164, 1.14125):GetNormal(),   map = { 43, 49, 45, 48, 46, 47, 4, 37, 36, 38, 44 } },
        la = { dir = Vector(1.84662, -1.34164, 1.14125):GetNormal(),  map = { 13, 19, 15, 18, 16, 17, 5, 47, 46, 48, 14 } },
        ba = { dir = Vector(-0.70533, -2.17082, 1.14127):GetNormal(), map = { 53, 59, 55, 58, 56, 57, 6, 17, 16, 18, 54 } },

        fb = { dir = Vector(0, 0, -2.55195):GetNormal(),               map = { 7, 10, 51, 9, 41, 8, 31, 12, 61, 11, 21 } },
        ub = { dir = Vector(2.28253, 0, -1.14129):GetNormal(),         map = { 30, 48, 45, 49, 62, 12, 31, 8, 32, 19, 14 } },
        rb = { dir = Vector(0.70533, -2.17082, -1.14127):GetNormal(),  map = { 40, 18, 15, 19, 32, 8, 41, 9, 42, 59, 54 } },
        db = { dir = Vector(-1.84662, -1.34164, -1.14125):GetNormal(), map = { 50, 58, 55, 59, 42, 9, 51, 10, 52, 29, 24 } },
        lb = { dir = Vector(-1.84662, 1.34164, -1.14125):GetNormal(),  map = { 20, 28, 25, 29, 52, 10, 21, 11, 22, 39, 34 } },
        bb = { dir = Vector(0.70533, 2.17082, -1.14127):GetNormal(),   map = { 60, 38, 35, 39, 22, 11, 61, 12, 62, 49, 44 } },
    }

    for k, v in pairs(data.MASTER) do
        v.ccw, v.cw = Shift(v.map)
    end

    data.CREATE = function()
        local puzzle = {}
        local index = 0

        for i = 1, 6 do
            local subkey = subMatCenter[i]

            local dir = data.MASTER[keys_a[i]].dir
            local ang = dir:Angle() + Angle(90, 0, 0)

            index = index + 1
            puzzle[index] = { id = index, ang = ang, model = "center", sub = { subkey } }

            for j = (i == 1 and 0 or 2), 4 do
                index = index + 1
                puzzle[index] = {
                    id = index,
                    ang = rotateAroundAxis(ang, dir, -72*j),
                    model = "edge",
                    sub = {
                        subkey,
                        subMatEdge[subkey][j + 1]
                    }
                }
            end
            if i ~= 1 then
                for j = 0, 2 do
                    index = index + 1
                    puzzle[index] = {
                        id = index,
                        ang = rotateAroundAxis(ang, dir, 72*j),
                        model = "corner",
                        sub = {
                            subkey,
                            subMatCorner[subkey][j + 1],
                            subMatCorner[subkey][j + 4],
                        }
                    }
                end
            end

            local dir = data.MASTER[keys_b[i]].dir
            local ang = dir:Angle() + Angle(90, 0, 0)

            if i ~= 1 then ang:RotateAroundAxis(dir, 180) end

            index = index + 1
            puzzle[index] = { id = index, ang = ang, model = "center", sub = { subkey } }

            for j = 0, 1 do
                if i == 1 then continue end
                index = index + 1
                puzzle[index] = {
                    id = index,
                    ang = rotateAroundAxis(ang, dir, -72*j),
                    model = "edge",
                    sub = {
                        subkey,
                        subMatCorner[subkey][j + 1]
                    }
                }
            end

            if i == 1 then
                for j = 0, 4 do
                    index = index + 1
                    puzzle[index] = {
                        id = index,
                        ang = rotateAroundAxis(ang, dir, 72*j),
                        model = "corner",
                        sub = {
                            subkey,
                            subMatEdge[subkey][j + 1],
                            subMatEdge[subkey][j == 4 and 1 or j + 2],
                        }
                    }
                end
            end
        end

        return puzzle
    end
end
