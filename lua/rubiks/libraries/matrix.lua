---------------------------------------------------------------
---------------------------------------------------------------
local RUBIKS = RUBIKS
local MATRIX = {}

RUBIKS.MATRIX = MATRIX


---------------------------------------------------------------
function MATRIX.FromTable(tbl)
    local length = math.sqrt(#tbl)
    local index = 0
    local mat = {}

    for row = 1, length do
        mat[row] = {}
        for col = 1, length do
            index = index + 1
            mat[row][col] = tbl[index]
        end
    end

    return mat
end


---------------------------------------------------------------
function MATRIX.ToTable(mat)
    local tbl = {}
    local length = #mat
    for row = 1, length do
        for col = 1, length do
            tbl[#tbl + 1] = mat[row][col]
        end
    end
    return tbl
end


---------------------------------------------------------------
function MATRIX.Transpose(mat)
    local length = #mat
    for row = 1, length do
        for col = row + 1, length do
            local temp = mat[row][col]
            mat[row][col] = mat[col][row]
            mat[col][row] = temp
        end
    end
    return mat
end


---------------------------------------------------------------
function MATRIX.ReverseRows(mat)
    local length = #mat
    for row = 1, length do
        for col = 1, length/2 do
            local temp = mat[row][col]
            mat[row][col] = mat[row][length - col + 1]
            mat[row][length - col + 1] = temp
        end
    end
    return mat
end


---------------------------------------------------------------
function MATRIX.ReverseColumns(mat)
    local length = #mat
    for col = 1, length do
        for row = 1, length/2 do
            local temp = mat[row][col]
            mat[row][col] = mat[length - row + 1][col]
            mat[length - row + 1][col] = temp
        end
    end
    return mat
end
