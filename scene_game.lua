local boardPhys = require 'board_phys'
local drawUtils = require 'draw_utils'
local sin, cos = math.sin, math.cos

return function ()
  local s = {}
  local W, H = W, H
  local T = 0

  local boardW = W * 0.8
  local boardH = H * 0.8

  local ADULT_R = 35
  local CHILD_R = 25
  local BREAK_DUR = 480
  local HATCH_DUR = 720
  local GROW_DUR = 960
  local EGG_SPAWN_DUR_MIN = 720
  local EGG_SPAWN_DUR_VAR = 240
  local EGG_R = 10
  local EGG_HOLE_AVOID = 20
  local IMP_MAX = 160
  local IMP_CD = 240

  local phys = boardPhys(boardW, boardH)

  love.math.setRandomSeed(101)

  -- Randomly generate 3 obstacles and 2 penguins
  local objPos = {}
  for i = 1, 5 do
    objPos[#objPos + 1] = {
      x = -boardW / 2 + love.math.random() * boardW,
      y = -boardH / 2 + love.math.random() * boardH
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
        if dsq <= 300^2 then
          local d = dsq^0.5
          xi = xi + (xi - xj) / d * (300 - d)
          yi = yi + (yi - yj) / d * (300 - d)
        end
      end end
      if xi < -xRange then xi = xi - (xi + xRange) / 2 end
      if xi >  xRange then xi = xi - (xi - xRange) / 2 end
      if yi < -yRange then yi = yi - (yi + yRange) / 2 end
      if yi >  yRange then yi = yi - (yi - yRange) / 2 end
      objPos[i].x, objPos[i].y = xi, yi
    end
  end
  for i = 1, 3 do
    phys.addSolid(objPos[i].x - 80/2, objPos[i].y - 80/2, 80, 80)
  end
  for i = 4, 5 do
    local v = love.math.random() * 200 + 50
    local w = love.math.random() * math.pi * 2
    phys.addActor(ADULT_R, objPos[i].x, objPos[i].y,
      v * cos(w), v * sin(w), w, love.math.random() * 0.1)
  end

  local holes = {}
  local eggs = {}

  local nextEgg = EGG_SPAWN_DUR_MIN / 2
  local impCooldown = 0

  -- {x, y, created}
  local puffAnims = {}

  local board_ox = W / 2
  local board_oy = H / 2

  local selObj = nil
  local selX, selY
  local dragX, dragY

  -- Scale ranges outside the board
  local boardPtScale = function (x, halfW)
    if x < -halfW then return x + (x + halfW) * 2 end
    if x >  halfW then return x + (x - halfW) * 2 end
    return x
  end

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
      selX = boardPtScale(x - board_ox, boardW / 2)
      selY = boardPtScale(y - board_oy, boardH / 2)
      dragX, dragY = 0, 0
    end
  end

  s.move = function (x, y)
    if selObj ~= nil then
      dragX = boardPtScale(x - board_ox, boardW / 2) - selX
      dragY = boardPtScale(y - board_oy, boardH / 2) - selY
      -- Limit amplitude
      local ampsq = dragX^2 + dragY^2
      if ampsq > IMP_MAX^2 then
        local scale = IMP_MAX / ampsq^0.5
        dragX = dragX * scale
        dragY = dragY * scale
      end
    end
  end

  s.release = function (x, y)
    if selObj ~= nil and impCooldown == 0 then
      local scale = -3
      phys.imp(selObj, dragX * scale, dragY * scale)
      impCooldown = IMP_CD
    end
    selObj = nil
  end

  s.update = function ()
    if selObj == nil or impCooldown > 0 then
      T = T + 1
      if impCooldown > 0 then impCooldown = impCooldown - 1 end
      -- Spawn an egg?
      if T == nextEgg then
        nextEgg = nextEgg + EGG_SPAWN_DUR_MIN + love.math.random(EGG_SPAWN_DUR_VAR)
        -- Pick a position for the egg
        local x, y
        local attempts = 0
        repeat
          x = -boardW / 2 + ADULT_R + love.math.random() * (boardW - ADULT_R * 2)
          y = -boardH / 2 + ADULT_R + love.math.random() * (boardH - ADULT_R * 2)
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
          eggs[#eggs + 1] = {x = x, y = y, created = T}
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
                falls = {},
              }
              -- Will fall into the hole in the following check
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
            h.falls[#h.falls + 1] = (r == CHILD_R and 0 or 1)
            if #h.falls > 5 then table.remove(h.falls, 1) end
            h.lastFall = T
            -- This may happen if the object is held before cooldown runs out
            if selObj == o then selObj = nil end
            return true
          end
        end
        -- Growing?
        if o.growth ~= nil then
          o.growth = o.growth + 1
          if o.growth >= GROW_DUR then
            o.growth = nil
            phys.setRadius(o, ADULT_R)
            -- Create a puff animation
            puffAnims[#puffAnims + 1] = {
              x = board_ox + x + cos(w) * 20,
              y = board_oy + y + sin(w) * 20,
              created = T,
            }
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
            local clamp = function (x, w)
              if x < -w / 2 + CHILD_R then return -w / 2 + CHILD_R end
              if x >  w / 2 - CHILD_R then return  w / 2 - CHILD_R end
              return x
            end
            local oNew = phys.addActor(
              CHILD_R,
              clamp(x - vxUnit * (ADULT_R + CHILD_R + 1e-4), boardW),
              clamp(y - vyUnit * (ADULT_R + CHILD_R + 1e-4), boardH),
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
    love.graphics.clear(0.95, 0.98, 1)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(tostring(impCooldown), 20, 20)
    love.graphics.rectangle('line',
      board_ox - boardW / 2,
      board_oy - boardH / 2,
      boardW, boardH)
    -- Holes
    for i = 1, #holes do
      local h = holes[i]
      love.graphics.setColor(1, 1, 1)
      drawUtils.img(
        h.r == CHILD_R and 'hole_small' or 'hole_large',
        board_ox + h.x, board_oy + h.y)
    end
    for i = 1, #holes do
      local h = holes[i]
      local t = T - h.lastFall
      -- Penguins inside
      local falls = h.falls
      local startAngle = love.math.noise(h.created / 240.05) + #falls
      local t0 = (T - h.created) / 240
      love.graphics.setColor(1, 1, 1)
      for j = 1, #falls do
        local angle = startAngle + j / #falls * math.pi * 2 + t0 * 0.3
        local dx = cos(angle) * h.r * (0.5 + #falls * 0.04)
        local dy = sin(angle) * h.r * (0.5 + #falls * 0.04)
        dy = dy + (1 + sin(t0 * 2 + j * 0.7)) * 3
        drawUtils.img(
          falls[j] == 0 and 'penguin_head_young' or 'penguin_head_adult',
          board_ox + h.x + dx,
          board_oy + h.y + dy,
          0.6, 0.6
        )
      end
    end
    for i = 1, #holes do
      local h = holes[i]
      local t = T - h.lastFall
      -- Splattering particles
      if t <= 180 then
        t = t / 180
        love.graphics.setColor(0.4, 0.6, 0.8)
        for j = 1, 5 do
          local vx = love.math.noise(h.x, h.y, h.lastFall / 240.05, j * 12.34)
          local ht = love.math.noise(h.x, h.y, j * 56.789, h.lastFall / 240.05)
          vx = vx * vx * 150
          ht = ht * 200 + 200
          if (j <= 3) == (h.x % 1 < 0.5) then vx = -vx end
          love.graphics.circle('fill',
            board_ox + h.x + vx * t,
            board_oy + h.y - ht * t * (1 - t),
            10 * (1 - t)
          )
        end
      end
    end
    -- Obstacles
    love.graphics.setColor(1, 1, 1)
    phys.eachSolid(function (o, x, y, w, h)
      drawUtils.img('obstacle',
        board_ox + x, board_oy + y,
        0, 0, 0, w / 80, h / 80)
    end)
    -- Eggs
    for i = 1, #eggs do
      local e = eggs[i]
      love.graphics.setColor(1, 1, 1)
      local rot = 0
      local t = T - e.created
      if t <= 360 then
        t = t / 360
        rot = math.sin(20 * t) * math.exp(-3 * t) * (1 - t) * 0.4
      end
      drawUtils.img('egg', board_ox + e.x, board_oy + e.y, 0.5, 0.7, rot, 1.2)
    end
    -- Penguins
    phys.eachActor(function (o, r, x, y, w, vx, vy)
      -- Egg
      if o.holdEgg ~= nil then
        love.graphics.setColor(1, 1, 1)
        drawUtils.img('egg',
          board_ox + x - cos(w) * 24,
          board_oy + y - sin(w) * 24,
          0.5, 0.5, w + math.pi / 2)
      end
      -- Penguin body
      local tint = 1
      if o.growth ~= nil then
        tint = 1 - o.growth / GROW_DUR * 0.3
      end
      love.graphics.setColor(tint, tint, tint)
      drawUtils.img(
        (o.growth ~= nil) and 'penguin_young' or 'penguin_adult',
        board_ox + x, board_oy + y,
        0.5, 0.6, w + math.pi / 2)
      if o == selObj and impCooldown == 0 then
        love.graphics.line(
          board_ox + x, board_oy + y,
          board_ox + x - dragX * 1,
          board_oy + y - dragY * 1)
      end
    --[[
      love.graphics.circle('line', board_ox + x, board_oy + y, r)
      love.graphics.line(
        board_ox + x, board_oy + y,
        board_ox + x + r * cos(w),
        board_oy + y + r * sin(w))
    --]]
      love.graphics.setColor(0, 0, 0)
      local s = ''
      for k, v in pairs(o) do
        if k == 'stopTimer' or k == 'holdEgg' or k == 'growth' then
          s = s .. k .. ' = ' .. tostring(v) .. '\n'
        end
      end
      love.graphics.print(s, board_ox + x, board_oy + y)
    end)
    -- Puff animations
    local i = 1
    while i <= #puffAnims do
      local a = puffAnims[i]
      local t = T - a.created
      if t >= 360 then
        puffAnims[i] = puffAnims[#puffAnims]
        puffAnims[#puffAnims] = nil
      else
        local alpha = 1 - t / 360
        local scale = 2.5 - math.exp(-t / 360 * 3)
        love.graphics.setColor(1, 1, 1, alpha)
        drawUtils.img('puff', a.x, a.y, 0.5, 0.5, 0, scale, scale)
        i = i + 1
      end
    end
  end

  s.destroy = function ()
    world:destroy()
  end

  return s
end
