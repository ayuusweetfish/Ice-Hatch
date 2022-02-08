local drawUtils = require 'draw_utils'

return function ()
  local s = {}
  local W, H = W, H
  local font = _G['font_VarelaR']

  local t1 = love.graphics.newText(font[120], 'ICE')
  local t2 = love.graphics.newText(font[120], 'HATCH')
  local w1 = t1:getWidth()
  local w2 = t2:getWidth()
  local t3 = love.graphics.newText(font[40], 'Press anywhere')
  local w3 = t3:getWidth()

  s.press = function (x, y)
  end

  s.hover = function (x, y)
  end

  s.move = function (x, y)
  end

  s.release = function (x, y)
    _G['replaceScene'](_G['sceneGame'](0, 0, require('tutorials')[1]), 'snowwind')
  end

  s.update = function ()
  end

  s.draw = function ()
    love.graphics.setColor(1, 1, 1)
    drawUtils.img('intro_bg', W / 2, H / 2)
    love.graphics.setColor(67/255, 177/255, 221/255)
    love.graphics.draw(t1, W - w1 - 60 - w2 - 38, 42)
    love.graphics.setColor(191/255, 237/255, 255/255)
    love.graphics.draw(t1, W - w1 - 60 - w2 - 40, 40)
    love.graphics.setColor(219/255, 202/255, 119/255)
    love.graphics.draw(t2, W - w2 - 38, 42)
    love.graphics.setColor(249/255, 237/255, 179/255)
    love.graphics.draw(t2, W - w2 - 40, 40)
    love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
    love.graphics.draw(t3, (W - w3) / 2, H * 0.775)
  end

  s.destroy = function ()
  end

  return s
end
