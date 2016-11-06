--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
local RUBIKS = RUBIKS

RUBIKS.TYPES = {}
RUBIKS.PUZZLES = {}


--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--/--
function RUBIKS.RegisterPuzzle(name, type, ...)
    RUBIKS.PUZZLES[name] = RUBIKS.TYPES[type](...)
end

function RUBIKS.GetPuzzle(name)
    return RUBIKS.PUZZLES[name]
end

