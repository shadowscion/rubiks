--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
local RUBIKS = RUBIKS
local HELPER = RUBIKS.HELPER


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
RUBIKS.TYPES["Tetra"] = function()
    local self = {}

    self.Master = {
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

    for _, v in pairs(self.Master) do
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

    self.Create = function(scale)
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

        local scale = scale or 6
        for k, v in ipairs(puzzle) do
            v.pos = v.pos*scale
        end

        return puzzle
    end

    return self
end


/*
-- EVENTUALLY HOPE TO GET n-HEIGHT TETRAS WORKING INSTEAD OF THE ABOVE HARDCODED PUZZLE
-- THE GENERATION ALL WORKS EXCEPT, FOR THE INDEX-LAYER DETERMINATION


local function RotateAroundAxis(angle, axis, degrees)
    local ang = Angle(angle.p, angle.y, angle.r)
    local vec = axis:GetNormal()

    ang:RotateAroundAxis(vec, degrees)

    return ang
end

local truncation = 0.100

local xConstant = 2.121 - truncation
local yConstant = 2.449 - truncation
local zConstant = 2.000 - truncation

local rotationDirU = Vector(0, 0, 1)
local rotationDirF = Vector(1.41421, 0, 0.5):GetNormal()
local rotationDirR = Vector(-0.70711, 1.22474, 0.5):GetNormal()
local rotationDirL = Vector(-0.70711, -1.22474, 0.5):GetNormal()

local angleU = Angle(0, 0, 0)
local angleB = Angle(0, 180, 0)
local angleR = Angle(0, 120, 0)
local angleL = Angle(0, -120, 0)

local dirU = Vector(0, 0, 1)
local dirF = Vector(0.31427, 0, 0.11111):GetNormal()
local dirR = Vector(dirF):GetNormal()
local dirL = Vector(dirF):GetNormal()

dirR:Rotate(angleR)
dirL:Rotate(angleL)

local angleFlipF = RotateAroundAxis(angleU, dirF, 180)
local angleFlipR = RotateAroundAxis(angleU, dirR, 180)
local angleFlipL = RotateAroundAxis(angleU, dirL, 180)

local axisF = dirF:Cross(Vector(0, 1, 0)):GetNormal()

local function shiftl(t)
    table.insert(t, table.remove(t, 1))
end

local function shiftr(t)
    table.insert(t, 1, table.remove(t, #t))
end

local function PushRepKey(tbl, key, rep, value, odd)
    local key = string.rep(key, rep)
    tbl[key] = tbl[key] or { inner = {}, outer = {} }
    table.insert(tbl[key][odd and "inner" or "outer"], value)
end

function Tetrinator(height)
    local TETRA = {
        Master = {
            f = { inner = {}, outer = {}, axis = rotationDirF },
            r = { inner = {}, outer = {}, axis = rotationDirR },
            l = { inner = {}, outer = {}, axis = rotationDirL },
            u = { inner = {}, outer = {}, axis = rotationDirU },
        }
    }

    local index = 0

    for z = 0, height do
        for x = 0, height do
            local ylimit = z + z - x - x
            for y = 0, ylimit do
                local proceed = true
                if z > 0 and z < height then
                    if x > 0 and x < height then
                        if y > 0 and y < ylimit then
                            proceed = false
                        end
                    end
                end

                if proceed then
                    local Odd = y % 2 ~= 0
                    if Odd then
                        if x == 0 then
                            index = index + 1
                            index = index + 1
                            index = index + 1

                            if z < height then
                                local rep = z + 1
                                PushRepKey(TETRA.Master, "u", rep, index - 2, true)
                                PushRepKey(TETRA.Master, "u", rep, index - 1, true)
                                PushRepKey(TETRA.Master, "u", rep, index - 0, true)
                            end
                            if y > 1 and y < ylimit then
                                local rep = -(ylimit - y)*0.5 + height + 1

                                PushRepKey(TETRA.Master, "f", rep, index - 1, true)
                                PushRepKey(TETRA.Master, "r", rep, index - 0, true)
                                PushRepKey(TETRA.Master, "l", rep, index - 2, true)
                                print(rep)
                            end

                            if y > 0 and y < ylimit - 1 then
                                local rep = -y*0.5 + height + 1

                                PushRepKey(TETRA.Master, "f", rep, index - 0, true)
                                PushRepKey(TETRA.Master, "r", rep, index - 2, true)
                                PushRepKey(TETRA.Master, "l", rep, index - 1, true)
                            end
                        end

                        if z == height then
                            index = index + 1

                            if x > 0 then
                                PushRepKey(TETRA.Master, "f", height - x + 1, index, true)
                            end
                            if x < height and y > 0 and y < ylimit - 1 then
                                PushRepKey(TETRA.Master, "r", -y*0.5 + height + 1, index, true)
                            end
                            if x < height and y > 1 then
                                PushRepKey(TETRA.Master, "l", -(ylimit - y)*0.5 + height + 1, index, true)
                            end
                        end

                        proceed = false
                    end
                end

                if proceed then
                    index = index + 1

                    if z == 0 or z < height then
                        PushRepKey(TETRA.Master, "u", z + 1, index, false)
                    end
                    if x > 0 then
                        PushRepKey(TETRA.Master, "f", height - x + 1, index, false)
                    end
                    if y < ylimit - 1 then
                        PushRepKey(TETRA.Master, "r", -(ylimit - y)*0.5 + height + 1, index, false)
                    end
                    if y > 1 then
                        PushRepKey(TETRA.Master, "l", -y*0.5 + height + 1, index, false)
                    end
                end
            end
        end
    end

    TETRA.Puzzle = function()
        local puzzle = {}
        local origin = 0
        local index = 0

        for z = 0, height do
            for x = 0, height do
                local ylimit = z+z - x-x
                for y = 0, ylimit do
                    local proceed = true
                    if z > 0 and z < height then
                        if x > 0 and x < height then
                            if y > 0 and y < ylimit then
                                proceed = false
                            end
                        end
                    end

                    if proceed then
                        local Odd = y % 2 ~= 0
                        if Odd then
                            if x == 0 then
                                index = index + 1
                                index = index + 1
                                index = index + 1

                                local posF = Vector(xConstant*z*(1/3) - x*xConstant, yConstant*(y - z)*0.5, -z*zConstant) + axisF*(zConstant + truncation)*(1/3)
                                local posR = Vector(posF)
                                local posL = Vector(posF)

                                posR:Rotate(angleR)
                                posL:Rotate(angleL)

                                table.insert(puzzle, { id = index - 2, sub = { [1] = "f" }, pos = posF, ang = Angle(angleFlipF) })
                                table.insert(puzzle, { id = index - 1, sub = { [2] = "r" }, pos = posR, ang = Angle(angleFlipR) })
                                table.insert(puzzle, { id = index - 0, sub = { [3] = "l" }, pos = posL, ang = Angle(angleFlipL) })
                                -- local posF = Vector(xConstant*z*(1/3) - x*xConstant, yConstant*(y - z)*0.5, -z*zConstant) + axisF*(zConstant + truncation)*(1/3)
                                -- local posR = Vector(posF)
                                -- local posL = Vector(posF)

                                -- posR:Rotate(angleR)
                                -- posL:Rotate(angleL)

                                -- table.insert(tetramid, { id = #tetramid + 1, sub = { [1] = "f" }, pos = posF, ang = Angle(angleFlipF) }) -- #index - 2
                                -- table.insert(tetramid, { id = #tetramid + 1, sub = { [2] = "r" }, pos = posR, ang = Angle(angleFlipR) }) -- #index - 1
                                -- table.insert(tetramid, { id = #tetramid + 1, sub = { [3] = "l" }, pos = posL, ang = Angle(angleFlipL) }) -- #index - 0
                            end

                            if z == height then
                                index = index + 1

                                local pos = Vector(-xConstant*z*(1/3) + (xConstant*(height+height-1))*(1/3) - x*xConstant, yConstant*(y - z)*0.5 + x*yConstant*0.5, -z*zConstant)

                                table.insert(puzzle, { id = index, sub = { [4] = "d" }, pos = pos, ang = Angle(angleB) })
                                -- local pos = Vector(-xConstant*z*(1/3) + (xConstant*(height+height-1))*(1/3) - x*xConstant, yConstant*(y - z)*0.5 + x*yConstant*0.5, -z*zConstant)
                                -- table.insert(tetramid, { id = #tetramid + 1,  sub = { [4] = "d" }, pos = pos, ang = Angle(angleB) })
                            end

                            proceed = false
                        end
                    end

                    if proceed then
                        index = index + 1

                        local sub = {
                            [1] = x == 0      and "f" or nil,
                            [2] = y == ylimit and "r" or nil,
                            [3] = y == 0      and "l" or nil,
                            [4] = z == height and "d" or nil,
                        }

                        local pos = Vector(xConstant*z*(1/3) - x*xConstant, yConstant*(y - z + x)*0.5, -z*zConstant)

                        table.insert(puzzle, { id = index, sub = sub, pos = pos, ang = Angle(angleU) })

                        local corner = z == 0 or (z == height and (x == 0 and (y == 0 or y == ylimit)) or x == height)
                        if corner then
                            origin = origin + pos.z
                        end
                        -- local pos = Vector(xConstant*z*(1/3) - x*xConstant, yConstant*(y - z + x)*0.5, -z*zConstant)
                        -- table.insert(tetramid, { id = #tetramid + 1, sub = sub, pos = pos, ang = Angle(angleU) })
                    end
                end
            end
        end

        for k, v in ipairs(puzzle) do
            v.pos.z = v.pos.z - origin*0.25
            v.pos = v.pos
        end

        return puzzle, -origin*0.25
    end

    return TETRA
end

local function GetMap(tbl, key)
    local map = {}
    local rep = key

    while tbl[rep] do
        for k, v in ipairs(tbl[rep].outer) do
            map[v] = true
        end
        for k, v in ipairs(tbl[rep].inner) do
            map[v] = true
        end
        rep = string.sub(rep, 1, string.len(rep) - 1)
    end
    return map, tbl[string.sub(key, 1, 1)].axis
end

local TETRA = Tetrinator(2)
local PUZZLE, origin = TETRA.Puzzle()
*/
