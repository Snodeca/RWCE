-- This code should be loaded with loadfile() from the top-level script.
-- The reason this is not in the top-level script itself is just to keep that
-- script as lean as possible.
-- RWCEMainDirectory, RWCEExtraDirectories, and RWCEOptions must be globals.

if package.loaded.runner == nil then
  -- First run, need to add paths
  local directories = {RWCEMainDirectory}

  if RWCEExtraDirectories then
    for _, directory in pairs(RWCEExtraDirectories) do
      table.insert(directories, directory)
    end
  end

  for _, directory in pairs(directories) do
    package.path = package.path .. ';' .. directory .. [[/?.lua]]
    package.path = package.path .. ';' .. directory .. [[/games/?.lua]]
    package.path = package.path .. ';' .. directory .. [[/layouts/?.lua]]
  end
end

package.loaded.runner = nil
local runner = require('runner')

-- global variables for games/sa2b.lua
originalTotalRings = 0
curRank = 14
aRankReq = 10000

runner.start(RWCEOptions)
