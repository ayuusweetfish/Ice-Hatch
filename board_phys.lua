return function (W, H)
  local b = {}
  local actors = {}
  local solids = {}

  love.physics.setMeter(100)
  local world = love.physics.newWorld()

  local bodyBound = love.physics.newBody(world, 0, 0, 'static')
  local pts = {{-W/2, -H/2}, {-W/2, H/2}, {W/2, H/2}, {W/2, -H/2}, {-W/2, -H/2}}
  for i = 1, 4 do
    local shape = love.physics.newEdgeShape(
      pts[i][1], pts[i][2],
      pts[i + 1][1], pts[i + 1][2]
    )
    local fixt = love.physics.newFixture(bodyBound, shape)
    fixt:setRestitution(0.9)
  end

  b.addActor = function (r, x, y, vx, vy, w, vw)
    local body = love.physics.newBody(world, x, y, 'dynamic')
    local shape = love.physics.newCircleShape(r)
    local fixt = love.physics.newFixture(body, shape)
    body:setLinearVelocity(vx, vy)
    body:setAngle(w)
    body:setAngularVelocity(vw)

    body:setLinearDamping(100 / 100)
    body:setAngularDamping(1.0)
    fixt:setRestitution(0.9)

    local o = {
      r = r,
      body = body,
      shape = shape,
      fixt = fixt,
    }
    actors[#actors + 1] = o
    return o
  end

  b.addSolid = function (x, y, w, h)
    local body = love.physics.newBody(world, x, y, 'static')
    local shape = love.physics.newRectangleShape(w/2, h/2, w, h)
    local fixt = love.physics.newFixture(body, shape)
    fixt:setRestitution(0.9)

    local o = {
      w = w, h = h,
      body = body,
      shape = shape,
      fixt = fixt,
    }
    solids[#solids + 1] = o
    return o
  end

  b.imp = function (o, vx, vy)
    o.body:setLinearVelocity(vx, vy)
    o.body:setAngle(math.atan2(vy, vx))
    o.body:setAngularVelocity(0)
  end

  b.setRadius = function (o, r)
    o.r = r
    o.shape:setRadius(r)
    o.fixt:destroy()
    o.fixt = love.physics.newFixture(o.body, o.shape)
    o.fixt:setRestitution(0.9)
  end

  b.step = function ()
    world:update(1/240)
  end

  b.eachActor = function (fn)
    local remove = nil
    for i = 1, #actors do
      local o = actors[i]
      local x, y = o.body:getPosition()
      local w = o.body:getAngle()
      local vx, vy = o.body:getLinearVelocity()
      if fn(o, o.r, x, y, w, vx, vy) then
        if remove == nil then remove = {} end
        remove[#remove + 1] = i
      end
    end
    if remove ~= nil then
      for i = #remove, 1, -1 do
        actors[remove[i]].body:destroy()
        actors[remove[i]] = actors[#actors]
        actors[#actors] = nil
      end
    end
  end

  b.eachSolid = function (fn)
    for i = 1, #solids do
      local o = solids[i]
      local x, y = o.body:getPosition()
      fn(o, x, y, o.w, o.h)
    end
  end

  b.queryPoint = function (x, y)
    local found = false
    world:queryBoundingBox(x, y, x, y, function (fixt)
      if fixt:testPoint(x, y) then
        found = true
        return false
      end
    end)
    return found
  end

  return b
end
