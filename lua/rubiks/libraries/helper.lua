--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
local RUBIKS = RUBIKS
local HELPER = {}

RUBIKS.HELPER = HELPER


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
function HELPER.IsOwner(ply, ent)
    if CLIENT then return true end

    if game.SinglePlayer() then return true end

    if CPPI then return ent:CPPIGetOwner() == ply end

    for k, v in pairs(g_SBoxObjects) do
        for b, j in pairs(v) do
            for _, e in pairs(j) do
                if e == ent and k == ply:UniqueID() then return true end
            end
        end
    end

    return false
end


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
function HELPER.SnapVector(vec, snap)
    vec = vec/snap
    vec = Vector(math.Round(vec.x), math.Round(vec.y), math.Round(vec.z))
    return vec*snap
end


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
function HELPER.Scrambler(sequence, len)
    local match = string.lower(string.match(sequence, "%a+"))
    local size = math.floor(tonumber(string.match(sequence, "%d+"))*0.5)
    local len = len or 30

    local moves = {}
    for i in string.gmatch(match, "%a") do
        for j = 1, size do
            table.insert(moves, string.rep(i, j))
            table.insert(moves, string.rep(i, j) .. "'")
            table.insert(moves, string.rep(i, j) .. "2")
        end
    end

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


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
if SERVER then return end


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
function HELPER.ShiftL(t)
    table.insert(t, table.remove(t, 1))
end

function HELPER.ShiftR(t)
    table.insert(t, 1, table.remove(t, #t))
end


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
function HELPER.SmoothStep(t)
    return t*t*t*(t*(t*6 - 15) + 10)
end


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
local pi = math.pi
local rad2deg = 180 / pi
local deg2rad = pi / 180

function HELPER.RotateVectorAroundAxis(vec, axis, degrees)
    local ca, sa = math.cos(degrees*deg2rad), math.sin(degrees*deg2rad)
    local x,y,z = axis.x, axis.y, axis.z
    local length = (x*x+y*y+z*z)^0.5
    x,y,z = x/length, y/length, z/length

    local tx,ty,tz = vec.x,vec.y,vec.z

    vec.x = (ca + (x^2)*(1-ca)) * tx + (x*y*(1-ca) - z*sa) * ty + (x*z*(1-ca) + y*sa) * tz
    vec.y = (y*x*(1-ca) + z*sa) * tx + (ca + (y^2)*(1-ca)) * ty + (y*z*(1-ca) - x*sa) * tz
    vec.z = (z*x*(1-ca) - y*sa) * tx + (z*y*(1-ca) + x*sa) * ty + (ca + (z^2)*(1-ca)) * tz
end
