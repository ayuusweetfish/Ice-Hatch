local boardPhys = require 'board_phys'
local sin, cos = math.sin, math.cos

return function ()
  local s = {}
  local W, H = W, H
  local T = 0

  local boardW = W * 0.8
  local boardH = H * 0.8

  local phys = boardPhys(boardW, boardH)
  phys.addActor(50, 0, 0, 100, 50, 0, -3)
  phys.addActor(60, 0, -150, -50, 500, 1, 3)
  phys.addActor(50, 0, 200, -300, -50, 0, 3)
  phys.addSolid(-120, -20, 50, 80)

  local holes = {}

  local board_ox = W / 2
  local board_oy = H / 2

  local selObj = nil
  local selX, selY
  local dragX, dragY

  s.press = function (x, y)
    selObj = nil
    local best = 1e8
    local mx, my = x - board_ox, y - board_oy
    phys.eachActor(function (o, r, x, y, w, vx, vy)
      local dsq = (x - mx)^2 + (y - my)^2
      if dsq < (r + 50)^2 and dsq < best then
        selObj = o
        best = dsq
      end
    end)
    if selObj ~= nil then
      selX, selY = x, y
      dragX, dragY = 0, 0
    end
  end

  s.move = function (x, y)
    if selObj ~= nil then
      dragX = x - selX
      dragY = y - selY
    end
  end

  s.release = function (x, y)
    if selObj ~= nil then
      local scale = -3
      phys.imp(selObj, (x - selX) * scale, (y - selY) * scale)
      selObj = nil
    end
  end

  s.update = function ()
    if selObj == nil then
      T = T + 1
      phys.step()
      phys.eachActor(function (o, r, x, y, w, vx, vy)
        -- Self is stopped?
        if vx^2 + vy^2 < 20^2 then
          if o.timer == nil then o.timer = 1
          else
            o.timer = o.timer + 1
            if o.timer >= 480 then
              -- Hole!
              holes[#holes + 1] = {
                x = x, y = y, r = r + 10,
                created = T,
              }
              return true
            end
          end
        else
          o.timer = nil
        end
        -- Falling into holes?
        for i = 1, #holes do
          local h = holes[i]
          if h.r >= r and (x - h.x)^2 + (y - h.y)^2 < h.r^2 then
            -- Fallen!
            return true
          end
        end
      end)
    end
  end

  s.draw = function ()
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle('line',
      board_ox - boardW / 2,
      board_oy - boardH / 2,
      boardW, boardH)
    for i = 1, #holes do
      local h = holes[i]
      love.graphics.setColor(0.9, 0.9, 0.9)
      love.graphics.circle('fill', board_ox + h.x, board_oy + h.y, h.r)
      love.graphics.setColor(0, 0, 0)
      love.graphics.print(tostring(T - h.created), board_ox + h.x, board_oy + h.y)
    end
    phys.eachActor(function (o, r, x, y, w, vx, vy)
      if o == selObj then
        love.graphics.line(
          board_ox + x, board_oy + y,
          board_ox + x - dragX * 1,
          board_oy + y - dragY * 1)
      end
      love.graphics.circle('line', board_ox + x, board_oy + y, r)
      love.graphics.line(
        board_ox + x, board_oy + y,
        board_ox + x + r * cos(w),
        board_oy + y + r * sin(w))
      love.graphics.print(tostring(o.timer), board_ox + x, board_oy + y)
    end)
    phys.eachSolid(function (o, x, y, w, h)
      love.graphics.rectangle('fill', board_ox + x, board_oy + y, w, h)
    end)
  end

  s.destroy = function ()
  end

  return s
end
