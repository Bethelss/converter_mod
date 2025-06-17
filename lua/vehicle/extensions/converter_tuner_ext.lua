local M = {}

M.id = "converterTunerExtension"

function M.onVehicleSpawned(veh)
  local data = veh:getJBeamFilename() and veh.data or nil
  if not data or not data.powertrain then return end
  if not data.powertrain.torqueConverter then return end

  -- добавляем контроллер
  veh:queueGameEngineLua([[
    local v = be:getObjectByID(]] .. veh:getID() .. [[)
    if v and not v:hasController("converterTuner") then
      v:addController("converterTuner")
    end
  ]])
end

return M