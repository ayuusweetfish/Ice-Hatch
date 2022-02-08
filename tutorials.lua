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

  -- 1: hint (stopped)
  -- 2: wait for 1s (disabled)
  -- 3: hint (stopped)
  -- 4: wait for 0.5s
  -- 5: hint
  -- 6: hint, after fall

  local state = 1
  local text, tx, ty, tt, ttEnd
  text, tx, ty, tt, ttEnd = updateText(
    'The penguin lies face-down on ice.\nPress it and drag to start sliding.', 0.5, 0.3, 120)

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

  s.restart = function ()
    return false
  end

  s.update = function (phys)
    T = T + 1
    if state == 2 and T == tNextState then
      state = 3
      text, tx, ty, tt, ttEnd = updateText(
        'You can do this once every 1 second.\nDrag again now.', 0.5, textPos(phys), T)
    elseif state == 4 and T == tNextState then
      state = 5
      text, tx, ty, tt, ttEnd = updateText(
        'What if it stops moving?', 0.5, textPos(phys), T)
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
    elseif state == 5 and evt == 'fall' then
      state = 6
      text, tx, ty, tt, ttEnd = updateText(
        'The game ends when no penguin remains on the ice.\nPress anywhere to continue.', 0.5, 0.5, T)
    end
  end

  s.draw = function ()
    textDraw(T, text, tx, ty, tt, ttEnd)
  end

  s.next = function ()
    return _G['sceneGame'](0, 0, t2)
  end

  return s
end

t2 = function ()
  local s = {}
  local T = 0

  -- 1: hint (stopped)
  -- 2: after imp
  -- 3: hint, after hold egg
  -- 4: hint, after hatch (stopped)
  -- 5: after imp
  -- 6: hint, after grow up (disabled)

  local state = 1
  local text, tx, ty, tt, ttEnd
  text, tx, ty, tt, ttEnd = updateText(
    'Reach the egg and take care of it!', 0.5, 0.3, 120)

  local tNextState

  s.board = function (boardW, boardH, phys, ADULT_R, eggs)
    phys.addActor(ADULT_R, 0, boardH * 0.3, 0, -100, math.pi * 1.5, 0)
    eggs[#eggs + 1] = {x = 0, y = 0, created = 0}
  end

  s.stopped = function ()
    return (state == 1 or state == 4)
  end

  s.disabled = function ()
    return (T < 120 or state == 6)
  end

  s.restart = function ()
    return (state ~= 6)
  end

  s.update = function (phys)
    T = T + 1
  end

  s.on = function (evt, phys)
    if state == 1 and evt == 'imp' then
      state = 2
      ttEnd = T
    elseif state == 2 and evt == 'hold_egg' then
      state = 3
      --text, tx, ty, tt, ttEnd = updateText(
      --  'Don\'t stop moving.', 0.5, 0.65, T)
      --ttEnd = T + 600
    elseif state == 3 and evt == 'hatch' then
      state = 4
      text, tx, ty, tt, ttEnd = updateText(
        'Keep moving until the baby penguin grows up.', 0.5, textPos(phys), T)
    elseif state == 4 and evt == 'imp' then
      state = 5
      ttEnd = T
    elseif state == 5 and evt == 'grow' then
      state = 6
      text, tx, ty, tt, ttEnd = updateText(
        'Nice! Let\'s get to the game.\nPress anywhere to continue.', 0.5, 0.5, T)
    end
  end

  s.draw = function ()
    textDraw(T, text, tx, ty, tt, ttEnd)
  end

  s.next = function ()
    return _G['sceneGame'](T, 0, nil)
  end

  return s
end

return {t1, t2}
