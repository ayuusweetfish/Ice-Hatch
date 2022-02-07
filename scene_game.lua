local boardPhys = require 'board_phys'
local sin, cos = math.sin, math.cos

return function ()
  local s = {}
  local W, H = W, H
  local T = 0

  local boardW = W * 0.8
  local boardH = H * 0.8

  local ADULT_R = 30
  local CHILD_R = 20
  local BREAK_DUR = 480
  local HATCH_DUR = 480
  local GROW_DUR = 480
  local EGG_SPAWN_DUR_MIN = 720
  local EGG_SPAWN_DUR_VAR = 240
  local EGG_R = 10
  local EGG_HOLE_AVOID = 20

  local phys = boardPhys(boardW, boardH)

  -- Randomly generate 3 obstacles and 3 actors
  local objPos = {}
  for i = 1, 6 do
    objPos[#objPos + 1] = {
      x = -boardW / 2 + math.random() * boardW,
      y = -boardH / 2 + math.random() * boardH
    }
  end
  for its = 1, 100 do
    local xRange = boardW / 2 - 100
    local yRange = boardH / 2 - 100
    for i = 1, #objPos do
      local xi, yi = objPos[i].x, objPos[i].y
      for j = 1, #objPos do if i ~= j then
        local xj, yj = objPos[j].x, objPos[j].y
        local dsq = (xi - xj)^2 + (yi - yj)^2
        xi = xi + (xi - xj) / (dsq + i + 10)
        yi = yi + (yi - yj) / (dsq + i + 10)
      end end
      if xi < -xRange then xi = xi - (xi + xRange) / 10 end
      if xi >  xRange then xi = xi - (xi - xRange) / 10 end
      if yi < -yRange then yi = yi - (yi + yRange) / 10 end
      if yi >  yRange then yi = yi - (yi - yRange) / 10 end
      objPos[i].x, objPos[i].y = xi, yi
    end
  end
  for i = 1, 3 do
    phys.addSolid(objPos[i].x - 80/2, objPos[i].y - 80/2, 80, 80)
  end
  for i = 4, 6 do
    local v = math.random() * 200 + 50
    local w = math.random() * math.pi * 2
    phys.addActor(ADULT_R, objPos[i].x, objPos[i].y,
      v * cos(w), v * sin(w), w, math.random() * 0.1)
  end

  local holes = {}
  local eggs = {}

  local nextEgg = EGG_SPAWN_DUR_MIN / 2

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
      -- Spawn an egg?
      if T == nextEgg then
        nextEgg = nextEgg + EGG_SPAWN_DUR_MIN + math.random(EGG_SPAWN_DUR_VAR)
        -- Pick a position for the egg
        local x, y
        local attempts = 0
        repeat
          x = -boardW / 2 + ADULT_R + math.random() * (boardW - ADULT_R * 2)
          y = -boardH / 2 + ADULT_R + math.random() * (boardH - ADULT_R * 2)
          local valid = not phys.queryPoint(x, y)
          -- Is in hole?
          if valid then
            for i = 1, #holes do
              local h = holes[i]
              if (x - h.x)^2 + (y - h.y)^2 < (h.r + EGG_R + EGG_HOLE_AVOID)^2 then
                valid = false
                break
              end
            end
          end
        until valid or attempts > 100
        if attempts <= 100 then
          eggs[#eggs + 1] = {x = x, y = y}
        end
      end
      phys.step()
      phys.eachActor(function (o, r, x, y, w, vx, vy)
        -- Self is stopped?
        if vx^2 + vy^2 < 20^2 then
          if o.stopTimer == nil then o.stopTimer = 1
          else
            o.stopTimer = o.stopTimer + 1
            if o.stopTimer >= BREAK_DUR then
              -- Hole!
              holes[#holes + 1] = {
                x = x, y = y, r = r,
                created = T,
                count = 1,
              }
              return true
            end
          end
        else
          o.stopTimer = nil
        end
        -- Falling into holes?
        for i = 1, #holes do
          local h = holes[i]
          if (x - h.x)^2 + (y - h.y)^2 < h.r^2 then
            -- Fallen!
            h.count = h.count + 1
            return true
          end
        end
        -- Growing?
        if o.growth ~= nil then
          o.growth = o.growth + 1
          if o.growth >= GROW_DUR then
            o.growth = nil
            phys.setRadius(o, ADULT_R)
          end
        end
        -- Incubating eggs?
        if o.holdEgg ~= nil then
          o.holdEgg = o.holdEgg + 1
          if o.holdEgg >= HATCH_DUR then
            -- Spawn a baby penguin
            local vsq = vx^2 + vy^2
            local vxUnit, vyUnit
            if vsq >= 1e-5 then
              local v = vsq^0.5
              vxUnit = vx / v
              vyUnit = vy / v
            else
              local psq = x^2 + y^2
              if psq >= 1e-5 then
                local p = psq^0.5
                vxUnit = x / p
                vyUnit = y / p
              else
                vxUnit, vyUnit = 1, 0
              end
            end
            local oNew = phys.addActor(
              CHILD_R,
              x - vxUnit * (ADULT_R + CHILD_R + 1e-4),
              y - vyUnit * (ADULT_R + CHILD_R + 1e-4),
              -vx * 0.6, -vy * 0.6,
              math.atan2(-vy, -vx), 0
            )
            oNew.growth = 0
            o.holdEgg = nil
          end
        end
        -- Collecting eggs?
        if o.growth == nil and o.holdEgg == nil then
          for i = 1, #eggs do
            local e = eggs[i]
            if (x - e.x)^2 + (y - e.y)^2 < (r + EGG_R)^2 then
              -- Remove egg
              eggs[i] = eggs[#eggs]
              eggs[#eggs] = nil
              -- Mark current penguin as holding an egg
              o.holdEgg = 0
              break
            end
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
      love.graphics.print(
        tostring(h.count) .. ', ' .. tostring(T - h.created),
        board_ox + h.x, board_oy + h.y)
    end
    for i = 1, #eggs do
      local e = eggs[i]
      love.graphics.setColor(0.9, 0.8, 0.7)
      love.graphics.circle('fill', board_ox + e.x, board_oy + e.y, EGG_R)
    end
    love.graphics.setColor(0, 0, 0)
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
      local s = ''
      for k, v in pairs(o) do
        if k == 'stopTimer' or k == 'holdEgg' or k == 'growth' then
          s = s .. k .. ' = ' .. tostring(v) .. '\n'
        end
      end
      love.graphics.print(s, board_ox + x, board_oy + y)
    end)
    phys.eachSolid(function (o, x, y, w, h)
      love.graphics.rectangle('fill', board_ox + x, board_oy + y, w, h)
    end)
  end

  s.destroy = function ()
    world:destroy()
  end

  return s
end
