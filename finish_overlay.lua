return function (score, best)
  local s = {}
  local W, H = W, H
  local font = _G['font_VarelaR']
  local T = -480
  --T, score, best = 0, 36, 24

  local text = function (size, str, w, h, tint, time)
    local t = love.graphics.newText(font[size], str)
    return {
      text = t,
      x = W * w - t:getWidth() / 2,
      y = H * h - t:getHeight() / 2,
      tint = tint,
      time = time,
    }
  end

  local texts = {
    text(40, 'Final Score', 0.5, 0.31, {1, 1, 1}, 0),
    text(28, 'Best', 0.45, 0.555, {0.8, 0.8, 0.8}, 360),
    text(28, tostring(best), 0.55, 0.555, {0.8, 0.8, 0.8}, 360),
    text(28, 'Press anywhere to restart', 0.5, 0.67, {0.6, 0.6, 0.6},
      score > best and 840 or 600),
  }

  local unpack = unpack or table.unpack

  local pressed = false
  s.press = function ()
    if T > 300 + texts[4].time then
      pressed = true
      return true
    else
      return false
    end
  end
  s.release = function ()
    return pressed
  end

  local scoreProgress = 0
  local bestProgress = best

  s.update = function ()
    T = T + 1

    if T >= 360 and T <= 540 then
      local t = (T - 360) / 180
      local p = math.floor((1 - (1 - t) * math.exp(-3 * t)) * score)
      if p ~= scoreProgress then
        scoreProgress = p
        texts[5] = nil
      end
    end

    if score > best and T >= 780 and T <= 960 then
      local t = (T - 780) / 180
      local p = best + math.floor((1 - (1 - t) * math.exp(-3 * t)) * (score - best))
      if p ~= bestProgress then
        bestProgress = p
        texts[3] = nil
      end
    end
  end

  s.draw = function ()
    if T < 0 then return end
    local w, bgAlpha = 1, 1
    if T < 240 then
      local t = T / 240
      w = 1 - (1 - t) * math.exp(-4 * t)
      alpha = 1 - (1 - t) * (1 - t)
    end
    love.graphics.setColor(0.21, 0.23, 0.24, bgAlpha * 0.9)
    love.graphics.rectangle('fill', 0, 0, w * W, H)

    -- Update text
    if texts[5] == nil then
      texts[5] = text(60, tostring(scoreProgress), 0.5 + 2 / W, 0.44 + 2 / H, {0.4, 0.4, 0.4}, 60)
      texts[6] = text(60, tostring(scoreProgress), 0.5, 0.44, {0.9, 0.98, 1}, 60)
    end
    if texts[3] == nil then
      texts[3] = text(28, tostring(bestProgress), 0.55, 0.555, {1, 0.8, 0.5}, 360)
    end

    for i = 1, #texts do
      local time = texts[i].time
      local textAlpha = 1
      if T < 300 + time then
        textAlpha = 0
      elseif T < 300 + time + 180 then
        local t = (T - 300 - time) / 180
        textAlpha = 1 - (1 - t) * (1 - t)
      end
      local r, g, b = unpack(texts[i].tint)
      love.graphics.setColor(r, g, b, textAlpha)
      love.graphics.draw(texts[i].text, texts[i].x, texts[i].y)
    end
  end

  return s
end
