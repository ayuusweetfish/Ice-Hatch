local imgs = {}

local files = love.filesystem.getDirectoryItems('res')
for i = 1, #files do
  local file = files[i]
  if file:sub(-4) == '.png' then
    local name = file:sub(1, #file - 4)
    local img = love.graphics.newImage('res/' .. file)
    imgs[name] = {
      img = img,
      w = img:getWidth(),
      h = img:getHeight(),
    }
  end
end

local img = function (name, x, y, ax, ay, r, sx, sy)
  ax = ax or 0.5
  ay = ay or 0.5
  r = r or 0
  sx = sx or 1
  sy = sy or sx
  local i = imgs[name]
  local w, h = i.w, i.h
  love.graphics.draw(i.img,
    x, y, r,
    sx, sy,
    ax * w, ay * h)
end

return {
  img = img,
}
