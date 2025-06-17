local M = {}

--[[
  Расширение автоматически подключает контроллер converterTuner к
  любому автомобилю, где в powertrain присутствует гидротрансформатор.
--]]

-- идентификатор модуля совпадает с именем файла
M.id = "converter_tuner_ext"

-- добавляет контроллер к указанному автомобилю
local function addController(veh)
  veh:queueGameEngineLua(string.format([[local v = be:getObjectByID(%d)
if v and not v:hasController("converterTuner") then
  v:addController("converterTuner")
end]], veh:getID()))
end

-- вызывается при появлении автомобиля в мире
function M.onVehicleSpawned(veh)
  local data = veh:getJBeamFilename() and veh.data or nil
  if not data or not data.powertrain or not data.powertrain.torqueConverter then return end
  addController(veh)
end

return M -- обязательный возврат модуля
