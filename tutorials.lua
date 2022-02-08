local t1, t2
local W, H = W, H
local font = _G['font_VarelaR'][28]

local updateText = function (str, x, y, T)
  local text = love.graphics.newText(font, str)
  return
    text,
    W * x - text:getWidth() / 2,
    H * y - text:getHeight() / 2,
    T,
    nil
end

-- Determine where to show the text depending on the penguin's position
local textPos = function (phys)
  local ty = 0.3
  phys.eachActor(function (o, r, x, y, w, vx, vy)
    if y < 0 then ty = 0.65 end
  end)
  return ty
end

local textDraw = function (T, text, tx, ty, tt, ttEnd)
  if T >= tt and (ttEnd == nil or T < ttEnd + 120) then
    local alpha = 1
    if T < tt + 120 then
      local t = (T - tt) / 120
      alpha = 1 - (1 - t) * math.exp(-3 * t)
    elseif ttEnd ~= nil and T >= ttEnd then
      local t = (T - ttEnd) / 120
      alpha = (1 - t) * math.exp(-3 * t)
    end
    local margin = 20
    love.graphics.setColor(1, 1, 1, 0.5 * alpha)
    love.graphics.rectangle('fill',
      tx - margin, ty - margin,
      text:getWidth() + margin * 2,
      text:getHeight() + margin * 2)
    love.graphics.setColor(0.2, 0.2, 0.2, alpha)
    love.graphics.draw(text, tx, ty)
  end
end

t1 = function ()
  local s = {}
  local T = 0

  local state = 1
  local text, tx, ty, tt, ttEnd
  text, tx, ty, tt, ttEnd = updateText(
    'Press the penguin, and drag to set it off', 0.5, 0.3, 120)

  local tNextState

  s.board = function (boardW, boardH, phys, ADULT_R, eggs)
    phys.addActor(ADULT_R, 0, boardH * 0.2, 0, -100, math.pi * 1.5, 0)
  end

  s.stopped = function ()
    return (state == 1 or state == 3)
  end

  s.disabled = function ()
    return (T < 120 or state == 2)
  end

  s.update = function (phys)
    T = T + 1
    if state == 2 and T == tNextState then
      state = 3
      text, tx, ty, tt, ttEnd = updateText(
        'You can do this once every 1 second.\nTry again now', 0.5, textPos(phys), T)
    elseif state == 4 and T == tNextState then
      text, tx, ty, tt, ttEnd = updateText(
        'The ice is thin.\nStop moving for 2 seconds and you shall know...', 0.5, textPos(phys), T)
    end
  end

  s.on = function (evt, phys)
    if state == 1 and evt == 'imp' then
      state = 2
      ttEnd = T
      tNextState = T + 280
    elseif state == 3 and evt == 'imp' then
      state = 4
      ttEnd = T
      tNextState = T + 120
    end
  end

  s.draw = function ()
    textDraw(T, text, tx, ty, tt, ttEnd)
  end

  s.next = function ()
    return _G['sceneGame'](0, 0, t2())
  end

  return s
end

t2 = function ()
end

return {t1, t2}
