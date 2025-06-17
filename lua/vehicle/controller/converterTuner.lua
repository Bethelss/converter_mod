local M = {}

--[[
  Контроллер позволяет в режиме реального времени изменять параметры
  гидротрансформатора коробки передач. Значения сохраняются в таблице
  param и каждый кадр переносятся в саму коробку.
--]]

-- значения по умолчанию из jbeam
local base  = {}
local param = {}

-- допустимые границы настроек
local ranges = {
  converterDiameter  = {0.1, 0.5},
  converterStiffness = {5, 40},
  couplingAVRatio    = {0.6, 1.5},
  stallTorqueRatio   = {1.0, 5.0},
}

-- шаг изменения параметров при нажатии клавиш
local step = {
  converterDiameter  = 0.01, -- сантиметры
  converterStiffness = 1,    -- условные единицы жёсткости
  couplingAVRatio    = 0.01, -- отношение оборотов
  stallTorqueRatio   = 0.1,  -- коэффициент усиления
}

-- ограничение значения по допустимому диапазону
local function clamp(name, val)
  local r = ranges[name]
  return math.min(r[2], math.max(r[1], val))
end

-- вывод значения в консоль для отладки
local function logVal(name, val)
  log("I", "convTuner", string.format("%s: %.3f", name, val))
end

-- применяем параметры к коробке
local function apply()
  local gbox = powertrain.getDevice("gearbox")
  if not gbox or not gbox.tc then return end
  for k, v in pairs(param) do
    gbox.tc[k] = v
  end
end

-- создаём функцию изменения конкретного параметра
local function makeAdjust(name, dir)
  return function()
    param[name] = clamp(name, param[name] + step[name] * dir)
    apply()
    logVal(name, param[name])
  end
end

-- привязка клавиш к настройке параметров
local function bindKeys()
  input.bindAction("conv_incDiam",  makeAdjust("converterDiameter",  1))
  input.bindAction("conv_decDiam",  makeAdjust("converterDiameter", -1))
  input.bindAction("conv_incStiff", makeAdjust("converterStiffness", 1))
  input.bindAction("conv_decStiff", makeAdjust("converterStiffness",-1))
  input.bindAction("conv_incCoupl", makeAdjust("couplingAVRatio",   1))
  input.bindAction("conv_decCoupl", makeAdjust("couplingAVRatio",  -1))
  input.bindAction("conv_incStall", makeAdjust("stallTorqueRatio",  1))
  input.bindAction("conv_decStall", makeAdjust("stallTorqueRatio", -1))
end

-- инициализация при загрузке автомобиля
local function onInit()
  local gbox = powertrain.getDevice("gearbox")
  if gbox and gbox.tc then
    base.converterDiameter  = gbox.tc.converterDiameter  or 0.25
    base.converterStiffness = gbox.tc.converterStiffness or 15
    base.couplingAVRatio    = gbox.tc.couplingAVRatio    or 0.9
    base.stallTorqueRatio   = gbox.tc.stallTorqueRatio   or 1.75

    -- копируем базовые значения в текущие
    for k, v in pairs(base) do
      param[k] = v
    end
  end
  bindKeys()
end

M.onInit    = onInit
M.updateGFX = apply -- обновляем значения каждый кадр
return M
