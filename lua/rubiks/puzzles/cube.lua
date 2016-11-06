--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
local RUBIKS = RUBIKS
local MATRIX = RUBIKS.MATRIX

--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
local keys = {
    f = { id = 1, dir = Vector(1, 0, 0) },
    b = { id = 2, dir = Vector(-1, 0, 0) },
    r = { id = 3, dir = Vector(0, 1, 0) },
    l = { id = 4, dir = Vector(0, -1, 0) },
    d = { id = 5, dir = Vector(0, 0, -1) },
    u = { id = 6, dir = Vector(0, 0, 1) },
}


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
RUBIKS.TYPES["Cube"] = function(size)
    local self = {}

    self.Master = {}

    local size_f = math.floor(size*0.5)
    local size_c = math.ceil(size*0.5)

    -- build puzzle master
    for k, side in pairs(keys) do
        for l = 1, size_f do
            local key = string.rep(k, l)

            self.Master[key] = {
                map = {},
                ccw = {},
                cw  = {},
                dir = side.dir,
            }

            if l == 1 then
                self.Master[key].id = side.id
            end
        end
    end

    local index = 0
    for x = 1, size do
        for z = 1, size do
            for y = 1, size do
                local ignore = (x > 1 and x < size) and (z > 1 and z < size) and (y > 1 and y < size)

                index = index + 1
                for key, _ in pairs(keys) do
                    local xyz = (key == "f" and x or key == "b" and -x or key == "u" and z or key == "d" and -z or key == "l" and y or key == "r" and -y)
                    local abs = math.abs(xyz)

                    if xyz > 0 and abs <= size_f then
                        local id = string.rep(key, xyz)
                        table.insert(self.Master[id].map, ignore and 0 or index)
                    end
                    if xyz < 0 and abs > size_c then
                        local id = string.rep(key, size + xyz + 1)
                        table.insert(self.Master[id].map, ignore and 0 or index)
                    end
                end
            end
        end
    end

    for key, layer in pairs(self.Master) do
        local mat = MATRIX.FromTable(layer.map)
        local side = string.sub(key, 1, 1)

            if side == "b" then MATRIX.ReverseRows(mat)
        elseif side == "u" then MATRIX.ReverseColumns(mat)
        elseif side == "r" then MATRIX.Transpose(mat)
        elseif face == "l" then
            MATRIX.Transpose(mat)
            MATRIX.ReverseRows(mat)
        end

        local ccw = table.Copy(mat)
              MATRIX.Transpose(ccw)
              MATRIX.ReverseColumns(ccw)

        local cw = table.Copy(mat)
              MATRIX.Transpose(cw)
              MATRIX.ReverseRows(cw)

        layer.map = MATRIX.ToTable(mat)
        layer.ccw = MATRIX.ToTable(ccw)
        layer.cw = MATRIX.ToTable(cw)
    end

    -- build default puzzle table
    self.Create = function()
        local puzzle = {}

        local index = 0
        for x = 1, size do
            for z = 1, size do
                for y = 1, size do
                    local ignore = (x > 1 and x < size) and (z > 1 and z < size) and (y > 1 and y < size)

                    index = index + 1
                    if ignore then
                        puzzle[index] = false
                    else
                        puzzle[index] = {
                            id = index,
                            sub = {},
                            pos = Vector(-x*2 + size + 1, y*2 - size - 1, -z*2 + size + 1) * 6,
                            ang = Angle()
                        }
                    end
                end
            end
        end

        for key, layer in pairs(self.Master) do
            if not layer.id then continue end
            for _, id in ipairs(layer.map) do
                puzzle[id].sub[layer.id] = key
            end
        end

        return puzzle
    end

    return self
end
