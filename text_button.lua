return function (text, fn)
  local s = {}
  local W, H = W, H

  s.x = 0
  s.y = 0

  local w, h = text:getDimensions()
  local scale = 1

  local held = false
  local inside = false

  s.press = function (x, y)
    if x >= s.x - w/2 and x <= s.x + w/2 and
       y >= s.y - w/2 and y <= s.y + h/2 then
      held = true
      inside = true
      return true
    else
      return false
    end
  end

  s.move = function (x, y)
    if not held then return false end
    inside =
      x >= s.x - w/2 and x <= s.x + w/2 and
      y >= s.y - w/2 and y <= s.y + h/2
    return true
  end

  s.release = function (x, y)
    if not held then return false end
    if inside then fn() end
    return true
  end

  s.update = function ()
    local target = (inside and 1.12 or 1)
    if math.abs(target - scale) <= 0.005 then
      scale = target
    else
      scale = scale + (target - scale) * 0.1
    end
  end

  s.draw = function ()
    love.graphics.draw(text, s.x - w/2 * scale, s.y - h/2 * scale, 0, scale)
  end

  return s
end
