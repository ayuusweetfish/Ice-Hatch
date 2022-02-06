local boardPhys = require 'board_phys'
local sin, cos = math.sin, math.cos

return function ()
  local s = {}
  local W, H = W, H

  local phys = boardPhys(W * 0.8, H * 0.8)
  phys.addActor(50, 0, 0, 100, 50, 0, -3)
  phys.addActor(60, 0, -150, -50, 500, 1, 3)
  phys.addSolid(-120, -20, 50, 80)

  local board_ox = W / 2
  local board_oy = H / 2

  s.press = function (x, y)
  end

  s.move = function (x, y)
  end

  s.release = function (x, y)
  end

  s.update = function ()
    phys.step()
  end

  s.draw = function ()
    love.graphics.setColor(0, 0, 0)
    phys.eachActor(function (o, r, x, y, w, vx, vy)
      love.graphics.circle('line', board_ox + x, board_oy + y, r)
      love.graphics.line(
        board_ox + x, board_oy + y,
        board_ox + x + r * cos(w),
        board_oy + y + r * sin(w))
    end)
    phys.eachSolid(function (o, x, y, w, h)
      love.graphics.rectangle('fill', board_ox + x, board_oy + y, w, h)
    end)
  end

  s.destroy = function ()
  end

  return s
end
