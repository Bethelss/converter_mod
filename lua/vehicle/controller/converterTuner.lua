-- converterTuner.lua
local M = {}

-- начальные значения берём из jbeam, чтобы «из коробки» ничего не менялось
local baseDiameter   = v.data.powertrain.torqueConverter.converterDiameter   or 0.25
local baseStallRatio = v.data.powertrain.torqueConverter.stallTorqueRatio    or 1.75

local diameter = baseDiameter
local stall    = baseStallRatio

-- допустимые границы
local minD, maxD = 0.1, 0.5
local minS, maxS = 1.0, 5.0

-- ===== Вспомогательные функции =========================================
local function clamp(val, lo, hi) return math.min(hi, math.max(lo, val)) end
local function logVal(name,val)    log("I","convTuner", name..": "..string.format("%.2f",val)) end

-- ===== Bind клавиш ======================================================
local function bindKeys()
  input.bindAction("conv_increaseStall",  function() stall    = clamp(stall+0.1, minS, maxS); logVal("stall",stall) end)
  input.bindAction("conv_decreaseStall",  function() stall    = clamp(stall-0.1, minS, maxS); logVal("stall",stall) end)
  input.bindAction("conv_increaseDiam",   function() diameter = clamp(diameter+0.01,minD,maxD);logVal("diam",diameter) end)
  input.bindAction("conv_decreaseDiam",   function() diameter = clamp(diameter-0.01,minD,maxD);logVal("diam",diameter) end)
end

-- ===== Главный цикл =====================================================
local function updateGFX(dt)
  local eng  = powertrain.getDevice("mainEngine")
  local gbox = powertrain.getDevice("gearbox") -- первая найденная коробка
  if not eng or not gbox then return end

  -- разница оборотов (slip)
  local slip = math.max(0, eng.av - gbox.inputAV)

  -- виртуальный коэффициент = базовый * (текущий diameter ÷ базовый) * (текущий stall ÷ базовый)
  local virtRatio = (stall / baseStallRatio) * (diameter / baseDiameter)

  -- простая (но рабочая) формула усиления момента
  local torqueFactor = 1 + slip * 0.0005 * (virtRatio - 1)

  -- ограничим фактор, чтобы не улетало в бесконечность
  torqueFactor = math.min(torqueFactor, 5)

  -- отдаём момент в коробку
  local t = eng:getTorque() * torqueFactor
  gbox:setInputTorque(t)
end

-- ===== Инициализация ====================================================
function M.onInit() bindKeys() end
M.updateGFX = updateGFX
return M
