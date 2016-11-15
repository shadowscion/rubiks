---------------------------------------------------------------
---------------------------------------------------------------
local RUBIKS = RUBIKS
local HELPER = RUBIKS.HELPER

local TYPE = { META = {} }
local META = TYPE.META

RUBIKS.TYPES["TETRA"] = TYPE


----------------------------------------------------------------
function TYPE.GenerateData(size)
    local size   = 3
    local length = size*6

    local maxs = Vector(length, length, length)*2
    local mins = -maxs

    local hull = {
        Vector(0, 0, 1.5)*length,
        Vector(-1.414, 0, -0.5)*length,
        Vector(0.707, 1.22474, -0.5)*length,
        Vector(0.707, -1.22474, -0.5)*length,
    }

    local data = {
        SIZE   = size,
        LENGTH = length,
        MAXS   = maxs,
        MINS   = mins,
        HULL   = hull,
        SEQ    = "FRLU4",
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
        local side, dir = self:GetTetraTrace(trace)
        if not side or not dir then return end

        local send = {
            key = side,
            rot = ply:KeyDown(IN_ATTACK) and dir or -dir,
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
local face_dirs = {
    f = Vector(0.9428, 0, 0.3333)*3,        // ugly hardcoded hack
    r = Vector(-0.4714, 0.8165, 0.3333)*3,  // but it will have to do
    l = Vector(-0.4714, -0.8165, 0.3333)*3,
    u = Vector(0, 0, -1)*3,
}

function META:GetTetraSide(dir)
    if dir == Vector(1, 0, 0)  then return "f", face_dirs.f end
    if dir == Vector(0, 1, 0)  then return "r", face_dirs.r end
    if dir == Vector(0, -1, 0) then return "l", face_dirs.l end
    if dir == Vector(0, 0, -1) then return "u", face_dirs.u end
    return false
end


----------------------------------------------------------------
function META:GetTetraNeighbors(side)
    if side == "f" then return "l", "r", "u" end
    if side == "l" then return "f", "r", "u" end
    if side == "r" then return "l", "f", "u" end
    if side == "u" then return "l", "r", "f" end
    return false
end


----------------------------------------------------------------
local face_neg = {
    f = { r =  1, l =  1, u =  1 },
    r = { f = -1, l = -1, u =  1 },
    l = { r = -1, f =  1, u =  1 },
    u = { r = -1, l = -1, f = -1 },
}

function META:GetTetraTrace(trace)
    if trace.Entity ~= self then return false end

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

    local side_pos = normal*self.RUBIKS_DATA.SIZE
    local side_dir = (lpos - side_pos) / 12
    local side_dist = 2 - math.min(1, math.floor(side_dir:Length()))

    local nl, nr, nu = self:GetTetraNeighbors(side)
    local key = (side == "u" and side_dir.x < 0 or side_dir.z > 0) and nu or (side_dir.y > 0 and nl or nr)

    return string.rep(key, side_dist), face_neg[side][key], side_pos, normal
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

    local old = {}
    local new = {}

    local key = TASK.key
    local rkey = TASK.rot == 1 and "ccw" or "cw"

    for n = string.len(key), 1, -1 do
        local tbl = MASTER[string.rep(string.sub(key, 1, 1), n)]
        if not tbl then continue end

        local num = #tbl.outer
        local rot = tbl["outer_" .. rkey]
        for i = 1, num do
            table.insert(old, tbl.outer[i])
            if rot then
                table.insert(new, rot[i])
            end
        end

        local num = #tbl.inner
        local rot = tbl["inner_" .. rkey]
        for i = 1, num do
            table.insert(old, tbl.inner[i])
            if rot then
                table.insert(new, rot[i])
            end
        end
    end

    local copy = {}
    for i = 1, #old do
        if not new[i] then continue end
        local old_index = old[i]
        copy[old_index] = table.Copy(PUZZLE[old_index])
        PUZZLE[old_index] = nil
    end

    for i = 1, #new do
        PUZZLE[old[i]] = copy[new[i]]
    end

    TASK.transform_axis = MASTER[TASK.key].dir*TASK.rot
    TASK.transform_pos = {}
    TASK.transform_ang = {}

    for i = 1, #old do
        if not PUZZLE[old[i]] then continue end
        TASK.transform_pos[i] = PUZZLE[old[i]].pos
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

    local rotation = HELPER.SmoothStep(TASK.tween)*120
    for i = 1, #TASK.old do
        if not PUZZLE[TASK.old[i]] then continue end

        local ang = Angle(TASK.transform_ang[i])
        local pos = Vector(TASK.transform_pos[i])

        ang:RotateAroundAxis(TASK.transform_axis, rotation)
        HELPER.RotateVectorAroundAxis(pos, TASK.transform_axis, rotation)

        PUZZLE[TASK.old[i]].ang = ang
        PUZZLE[TASK.old[i]].pos = pos
    end

    if TASK.tween == 1 then
        self.RUBIKS_TASK = nil
    end
end


----------------------------------------------------------------
local nullify = not file.Exists("models/rubiks/tetra_core.mdl", "GAME")

function META:DrawPuzzle(RENDER)
    if nullify then self:Debug() return end

    RENDER:SetModel("models/rubiks/tetra_core.mdl")
    RENDER:SetModelScale(1, 0)

    for i, part in ipairs(self.RUBIKS_PUZZLE) do
        if not part then continue end
        for j = 1, 4 do
            RENDER:SetSubMaterial(j, part.sub[j] and ("rubiks/color_" .. part.sub[j]) or "rubiks/border")
        end

        RENDER:SetRenderOrigin(self:LocalToWorld(part.pos))
        RENDER:SetRenderAngles(self:LocalToWorldAngles(part.ang))
        RENDER:SetupBones()
        RENDER:DrawModel()
    end
end


----------------------------------------------------------------
function META:Debug()
    local hull = self.RUBIKS_DATA.HULL
    for i = 1, #hull do
        for j = i, #hull do
            render.DrawLine(self:LocalToWorld(hull[i]), self:LocalToWorld(hull[j]), Color(0, 255, 255), true)
        end
    end

    cam.Start2D()
        local pos = self:GetPos():ToScreen()
        draw.SimpleText(self, "TargetIDSmall", pos.x, pos.y, Color(255, 255, 255), 1)
    cam.End2D()
end


----------------------------------------------------------------
function TYPE.GenerateClientData(data)
    data.MASTER = {
        f = {
            inner = {  },
            outer = { 22 },
            dir   = -Vector(0.9428, 0, 0.3333),
        },
        ff = {
            inner = { 11, 15, 20 },
            outer = { 7, 19, 21 },
            dir   = -Vector(0.9428, 0, 0.3333),
        },
        l = {
            inner = {  },
            outer = { 18 },
            dir   = Vector(-0.4714, -0.8165, 0.3333),
        },
        ll = {
            inner = { 10, 14, 17 },
            outer = { 6, 13, 21 },
            dir   = Vector(-0.4714, -0.8165, 0.3333),
        },
        r = {
            inner = {  },
            outer = { 8 },
            dir   = -Vector(-0.4714, 0.8165, 0.3333),
        },
        rr = {
            inner = { 9, 12, 16 },
            outer = { 2, 13, 19 },
            dir   = -Vector(-0.4714, 0.8165, 0.3333),
        },
        u = {
            inner = {  },
            outer = { 1 },
            dir   = Vector(0, 0, -1),
        },
        uu = {
            inner = { 3, 4, 5 },
            outer = { 2, 6, 7 },
            dir   = Vector(0, 0, -1),
        },
    }

    for _, v in pairs(data.MASTER) do
        if #v.inner > 0 then
            v.inner_ccw = table.Copy(v.inner)
            v.inner_cw  = table.Copy(v.inner)

            HELPER.ShiftL(v.inner_ccw)
            HELPER.ShiftR(v.inner_cw)
        end
        if #v.outer > 1 then
            v.outer_ccw = table.Copy(v.outer)
            v.outer_cw  = table.Copy(v.outer)

            HELPER.ShiftL(v.outer_ccw)
            HELPER.ShiftR(v.outer_cw)
        end
    end

    data.CREATE = function()
        local puzzle = {
            [1] = {
                id = 1,
                pos = Vector(0, 0, 2.85),
                ang = Angle(0, 0, 0),
                sub = { [1] = "f", [2] = "r", [3] = "l",  },
            },
            [2] = {
                id = 2,
                pos = Vector(0.6737, -1.1745, 0.95),
                ang = Angle(0, 0, 0),
                sub = { [1] = "f", [3] = "l",  },
            },
            [3] = {
                id = 3,
                pos = Vector(0.4514, 0, 1.5785),
                ang = Angle(-38.942, 0, -180),
                sub = { [1] = "f",  },
            },
            [4] = {
                id = 4,
                pos = Vector(-0.2257, 0.391, 1.5785),
                ang = Angle(18.3166, -125.8174, 145.014),
                sub = { [2] = "r",  },
            },
            [5] = {
                id = 5,
                pos = Vector(-0.2257, -0.391, 1.5785),
                ang = Angle(18.3166, 125.8174, -145.014),
                sub = { [3] = "l",  },
            },
            [6] = {
                id = 6,
                pos = Vector(0.6737, 1.1745, 0.95),
                ang = Angle(0, 0, 0),
                sub = { [1] = "f", [2] = "r",  },
            },
            [7] = {
                id = 7,
                pos = Vector(-1.3473, 0, 0.95),
                ang = Angle(0, 0, 0),
                sub = { [2] = "r", [3] = "l",  },
            },
            [8] = {
                id = 8,
                pos = Vector(1.3473, -2.349, -0.95),
                ang = Angle(0, 0, 0),
                sub = { [1] = "f", [3] = "l", [4] = "d" },
            },
            [9] = {
                id = 9,
                pos = Vector(1.1251, -1.1745, -0.3215),
                ang = Angle(-38.942, 0, -180),
                sub = { [1] = "f",  },
            },
            [10] = {
                id = 10,
                pos = Vector(0.4546, 1.5616, -0.3215),
                ang = Angle(18.3166, -125.8174, 145.014),
                sub = { [2] = "r",  },
            },
            [11] = {
                id = 11,
                pos = Vector(-1.5797, -0.3871, -0.3215),
                ang = Angle(18.3166, 125.8174, -145.014),
                sub = { [3] = "l",  },
            },
            [12] = {
                id = 12,
                pos = Vector(0.6737, -1.1745, -0.95),
                ang = Angle(0, 180, 0),
                sub = { [4] = "d" },
            },
            [13] = {
                id = 13,
                pos = Vector(1.3473, 0, -0.95),
                ang = Angle(0, 0, 0),
                sub = { [1] = "f", [4] = "d" },
            },
            [14] = {
                id = 14,
                pos = Vector(1.1251, 1.1745, -0.3215),
                ang = Angle(-38.942, 0, -180),
                sub = { [1] = "f",  },
            },
            [15] = {
                id = 15,
                pos = Vector(-1.5797, 0.3871, -0.3215),
                ang = Angle(18.3166, -125.8174, 145.014),
                sub = { [2] = "r",  },
            },
            [16] = {
                id = 16,
                pos = Vector(0.4546, -1.5616, -0.3215),
                ang = Angle(18.3166, 125.8174, -145.014),
                sub = { [3] = "l",  },
            },
            [17] = {
                id = 17,
                pos = Vector(0.6737, 1.1745, -0.95),
                ang = Angle(0, 180, 0),
                sub = { [4] = "d" },
            },
            [18] = {
                id = 18,
                pos = Vector(1.3473, 2.349, -0.95),
                ang = Angle(0, 0, 0),
                sub = { [1] = "f", [2] = "r", [4] = "d" },
            },
            [19] = {
                id = 19,
                pos = Vector(-0.6737, -1.1745, -0.95),
                ang = Angle(0, 0, 0),
                sub = { [3] = "l", [4] = "d" },
            },
            [20] = {
                id = 20,
                pos = Vector(-1.3473, 0, -0.95),
                ang = Angle(0, 180, 0),
                sub = { [4] = "d" },
            },
            [21] = {
                id = 21,
                pos = Vector(-0.6737, 1.1745, -0.95),
                ang = Angle(0, 0, 0),
                sub = { [2] = "r", [4] = "d" },
            },
            [22] = {
                id = 22,
                pos = Vector(-2.6947, 0, -0.95),
                ang = Angle(0, 0, 0),
                sub = { [2] = "r", [3] = "l", [4] = "d" },
            },
        }

        local scale = 6
        for k, v in ipairs(puzzle) do
            v.pos = v.pos*scale
        end

        return puzzle
    end
end
