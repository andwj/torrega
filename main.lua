
--
--  Torrega Race
--
--  by Andrew Apted
--
--  under the GNU GPLv3 (or later) license
--


require "utils"


SCREEN_W = 800
SCREEN_H = 600

BORDER = 8

INNER_W  = 300
INNER_H  = 200

-- set during startup
OUTER_X1 = 0
OUTER_Y1 = 0
OUTER_X2 = 0
OUTER_Y2 = 0

INNER_X1 = 0
INNER_Y1 = 0
INNER_X2 = 0
INNER_Y2 = 0


game_time  = 0
delta_time = 0

game_started = false


fonts =
{
  -- title
  -- credit
  -- normal
  -- score
}


-- indexed by DIR (2, 4, 6 or 8)
edges_hit  = {}
inners_hit = {}


--
-- player object(s)
--
-- Fields:
--    health
--    x, y, vel_x, vel_y
--    angle (in degrees)
--    r (radius, for physics)
--    info
--
player = {}


PLAYER_INFO =
{
  player1 =
  {
    -- props --

    spawn_x = 100,
    spawn_y = 100,

    turn_speed = 240,

    thrust_velocity = 500,
    bounce_friction = 0.88,

    missile_speed = 500,
    missile_len = 20,

    -- shape --

    r = 15,

    color = { 255,255,255 },

    lines =
    {
      { -140, 1.00 },
      {    0, 1.00 },
      {  140, 1.00 }
    }
  },


  player2 =
  {
    -- props --

    spawn_x = 80,
    spawn_y = 140,

    turn_speed = 240,

    thrust_velocity = 500,
    bounce_friction = 0.88,

    missile_speed = 500,
    missile_len = 20,

    -- shape --

    r = 15,

    color = { 85,255,255 },

    lines =
    {
      { -140, 1.00 },
      {    0, 1.00 },
      {  140, 1.00 }
    }
  },
}


--
-- enemy objects
--
-- Fields:
--    x, y, angle, r, info
--

all_enemies = {}


ENEMY_INFO =
{
  drone =
  {
    -- props --

    hits = 1,

    speed = 30,
    turn_speed = 120,

    -- shape --

    r = 15,

    color = { 64,192,128 },

    lines =
    {
      { -180, 0.00 },
      { -140, 1.00 },
      {  -70, 1.00 },
      {  -20, 1.00 },
      {   20, 1.00 },
      {   70, 1.00 },
      {  140, 1.00 },
      {  180, 0.00 }
    }
  },
}


--
-- missile objects
--
-- Fields:
--    x, y, angle
--    vel_x, vel_y
--    length, color
--    owner : player or enemy
--

all_missiles = {}



------ RENDERING ---------------------


function draw_shape(sh, base_x, base_y, base_angle)
  love.graphics.setColor(sh.color[1], sh.color[2], sh.color[3])

  local last_x
  local last_y

  for i = 1, #sh.lines do
    local point = sh.lines[i]

    local ang = base_angle + point[1]
    local r   = sh.r       * point[2]

    local dx, dy = geom.ang_to_vec(ang, r)

    local x = base_x + dx
    local y = base_y + dy

    if last_x then
      love.graphics.line(last_x, last_y, x, y)
    end

    last_x = x
    last_y = y
  end
end



function player_draw(p)
  draw_shape(p.info, p.x, p.y, p.angle)
end



function enemy_draw(e)
  draw_shape(e.info, e.x, e.y, e.angle)
end



function missile_draw(m)
  love.graphics.setColor(m.color[1], m.color[2], m.color[3])

  local dx, dy = geom.normalize(m.vel_x, m.vel_y)

  local end_x = m.x - dx * m.length
  local end_y = m.y - dy * m.length

  love.graphics.line(end_x, end_y, m.x, m.y)
end



function draw_all_entities()
  if not game_started then
    -- FIXME
    return
  end

  for i = 1, #all_missiles do
    missile_draw(all_missiles[i])
  end

  for i = 1, #all_enemies do
    enemy_draw(all_enemies[i])
  end

  player_draw(player)
end



function draw_outer_edge(dir, x1, y1, x2, y2)
  local TIME = 0.5

  local qty = edges_hit[dir] + TIME - game_time

  if qty <= 0 then return end

  qty = (qty / TIME) ^ 0.9

  love.graphics.setColor(255*qty, 255*qty, 0)
  love.graphics.line(x1, y1, x2, y2)
end


function draw_inner_edge(dir, x1, y1, x2, y2)
  local qty

  if game_started then
    qty = inners_hit[dir] + 1.0 - game_time
  else
    qty = 0
  end

  if qty <= 0 then qty = 0 end

  qty = qty ^ 0.5

  love.graphics.setColor(255*qty, 255*qty, 255*(1-qty))
  love.graphics.line(x1, y1, x2, y2)
end


function draw_map_edges()
  -- draw outer edges (only when hit)

  if game_started then
    draw_outer_edge(2, OUTER_X1, OUTER_Y2, OUTER_X2, OUTER_Y2)
    draw_outer_edge(8, OUTER_X1, OUTER_Y1, OUTER_X2, OUTER_Y1)
    draw_outer_edge(4, OUTER_X1, OUTER_Y1, OUTER_X1, OUTER_Y2)
    draw_outer_edge(6, OUTER_X2, OUTER_Y1, OUTER_X2, OUTER_Y2)
  end

  -- draw the inner box

  draw_inner_edge(2, INNER_X1, INNER_Y2, INNER_X2, INNER_Y2)
  draw_inner_edge(8, INNER_X1, INNER_Y1, INNER_X2, INNER_Y1)
  draw_inner_edge(4, INNER_X1, INNER_Y1, INNER_X1, INNER_Y2)
  draw_inner_edge(6, INNER_X2, INNER_Y1, INNER_X2, INNER_Y2)
end



------ PHYSICS ---------------------


function player_setup(p, info)
  p.kind = "player"
  p.info = info

  p.health = 100
  p.score  = 0

  p.x = info.spawn_x
  p.y = info.spawn_y

  p.vel_x = 0
  p.vel_y = 0

  p.angle = 0

  p.r = 10  -- used for physics

  -- prevent firing immediately on game start (bit of a hack)
  p.is_firing = true
end



function enemy_spawn(x, y, angle, r, info)
  local e = {}

  e.kind = "enemy"
  e.info = info

  e.x = x
  e.y = y
  e.angle = angle
  e.r = r

  table.insert(all_enemies, e)

-- TEST
e.target_angle = 170 + math.random() * 20

  return e
end


function missile_spawn(owner, x, y, angle, speed, color, target_length)
  local m = {}

  m.kind  = "missile"
  m.owner = owner

  m.x = x
  m.y = y

  m.color  = color
  m.speed  = speed

  m.length = 1
  m.target_length = target_length

  local dx, dy = geom.ang_to_vec(angle, speed)

  m.vel_x = dx
  m.vel_y = dy

  table.insert(all_missiles, m)

  return m
end



function enemy_create_drone_path(ey)
  -- creates a set of target points which drones follow

  local y1 = INNER_Y2 + ey * 35
  local y3 = INNER_Y1 - ey * 35

  local x2 = INNER_X2 + ey * 40
  local x4 = INNER_X1 - ey * 40

  local x5 = SCREEN_W / 2

  return
  {
    { x=x2, y=y1 },
    { x=x2, y=y3 },
    { x=x4, y=y3 },
    { x=x4, y=y1 },
    { x=x5, y=y1 }
  }
end



function enemy_setup()
  all_enemies  = {}

  for ey = 1, 4 do
    for ex = 1, 5 do
      local x = INNER_X1 + ex * 50

      local path = enemy_create_drone_path(ey)
      local y = path[1].y

      local e = enemy_spawn(x, y, 0, 12, ENEMY_INFO.drone)

      e.path = path
    end
  end
end



function game_setup()
  game_started = true

  game_time  = 0
  delta_time = 0

  for dir = 2,8,2 do
    edges_hit[dir]  = -2
    inners_hit[dir] = -2
  end

  all_missiles = {}

  player_setup(player, PLAYER_INFO.player1)

  enemy_setup()
end



function missile_check_hit(x, y, old_x, old_y)
  -- returns:
  --    nil, nil     : hits nothing
  --    "outer", dir : hits outer edge of map
  --    "inner,  dir : hits inner box

  if x < OUTER_X1 then return "outer", 4 end
  if x > OUTER_X2 then return "outer", 6 end

  if y < OUTER_Y1 then return "outer", 8 end
  if y > OUTER_Y2 then return "outer", 2 end

  if x < INNER_X1 then return nil end
  if x > INNER_X2 then return nil end

  if y < INNER_Y1 then return nil end
  if y > INNER_Y2 then return nil end

  -- hit inner box --

  if old_x < INNER_X1 then return "inner", 4 end
  if old_x > INNER_X2 then return "inner", 6 end

  if old_y < INNER_Y1 then return "inner", 8 end
  if old_y > INNER_Y2 then return "inner", 2 end

  -- fallback

  local d1 = math.abs(x - INNER_X1)
  local d2 = math.abs(x - INNER_X2)
  local d3 = math.abs(y - INNER_Y1)
  local d4 = math.abs(y - INNER_Y2)

  if d1 < math.min(d2, d3, d4) then return "inner", 4 end
  if d2 < math.min(d1, d3, d4) then return "inner", 6 end
  if d3 < math.min(d1, d2, d4) then return "inner", 8 end
  if d4 < math.min(d1, d2, d3) then return "inner", 2 end

  -- oops
  return "inner", 4
end



function fire_missile(p)
  local dx, dy = geom.ang_to_vec(p.angle)

  local x = p.x + p.info.r * dx
  local y = p.y + p.info.r * dy

  -- TODO : play a sound

  -- don't spawn a missile if it is already off the map

  local what, dir = missile_check_hit(x, y, p.x, p.y)

  if what then
    if what == "outer" then  edges_hit[dir] = game_time end
    if what == "inner" then inners_hit[dir] = game_time end

    return
  end

  local m = missile_spawn(p, x, y, p.angle, p.info.missile_speed, p.info.color, p.info.missile_len)
end


function player_input(p, dt)

  local turn_left  = love.keyboard.isDown("left")  or love.keyboard.isDown("a")
  local turn_right = love.keyboard.isDown("right") or love.keyboard.isDown("d")

  if turn_left and turn_right then
    -- do nothing if both are pressed
  elseif turn_left then
    p.angle = geom.angle_add(p.angle,   p.info.turn_speed * dt)
  elseif turn_right then
    p.angle = geom.angle_add(p.angle, - p.info.turn_speed * dt)
  end


  local thrust = love.keyboard.isDown("up") or love.keyboard.isDown("w")

  if thrust then
    local dx, dy = geom.ang_to_vec(p.angle, p.info.thrust_velocity * dt)

    p.vel_x = p.vel_x + dx
    p.vel_y = p.vel_y + dy
  end


  local fire = love.keyboard.isDown(" ") or love.keyboard.isDown("lctrl") or
               love.keyboard.isDown("rctrl")

  if p.is_firing ~= fire then
    p.is_firing = fire

    if fire then
      fire_missile(p)
    end
  end
end



function player_move(p, dt)
  -- p can be a player or enemy ship

  local old_inside_x = (INNER_X1 - p.r <= p.x) and (p.x <= INNER_X2 + p.r)
  local old_inside_y = (INNER_Y1 - p.r <= p.y) and (p.y <= INNER_Y2 + p.r)

  p.x = p.x + p.vel_x * dt
  p.y = p.y + p.vel_y * dt

  -- safety buffer
  local epsilon = 0.001

  -- bounce off edges

  local bounce_friction = p.info.bounce_friction

  if p.x < OUTER_X1 + p.r then
    p.x = OUTER_X1 + p.r + epsilon
    p.vel_x = - p.vel_x * bounce_friction
    edges_hit[4] = game_time
    return

  elseif p.x > OUTER_X2 - p.r then
    p.x = OUTER_X2 - p.r - epsilon
    p.vel_x = - p.vel_x * bounce_friction
    edges_hit[6] = game_time
    return
  end

  if p.y < OUTER_Y1 + p.r then
    p.y = OUTER_Y1 + p.r + epsilon
    p.vel_y = - p.vel_y * bounce_friction
    edges_hit[8] = game_time
    return

  elseif p.y > OUTER_Y2 - p.r then
    p.y = OUTER_Y2 - p.r - epsilon
    p.vel_y = - p.vel_y * bounce_friction
    edges_hit[2] = game_time
    return
  end

  -- bounce off inner box

  local inside_x = (INNER_X1 - p.r <= p.x) and (p.x <= INNER_X2 + p.r)
  local inside_y = (INNER_Y1 - p.r <= p.y) and (p.y <= INNER_Y2 + p.r)

  if inside_x and inside_y then
    -- figure out if we hit the top/bottom ("y") or the left/right sides ("x")
    local way

    if not old_inside_x and not old_inside_y then
      -- hit at a corner
      way = "x"  -- TODO : check velocity

    elseif old_inside_x then
      way = "y"

    else
      way = "x"
    end

    if way == "x" then
      if p.x > SCREEN_W/2 then
        p.x = INNER_X2 + p.r + epsilon
        p.vel_x = - p.vel_x * bounce_friction
        p.vel_x = math.max(-0.1, p.vel_x)
        inners_hit[6] = game_time
      else
        p.x = INNER_X1 - p.r - epsilon
        p.vel_x = - p.vel_x * bounce_friction
        p.vel_x = math.min(0.1, p.vel_x)
        inners_hit[4] = game_time
      end

    else -- way == "y"

      if p.y > SCREEN_H/2 then
        p.y = INNER_Y2 + p.r + epsilon
        p.vel_y = - p.vel_y * bounce_friction
        p.vel_y = math.max(-0.1, p.vel_y)
        inners_hit[2] = game_time
      else
        p.y = INNER_Y1 - p.r + epsilon
        p.vel_y = - p.vel_y * bounce_friction
        p.vel_y = math.min(0.1, p.vel_y)
        inners_hit[8] = game_time
      end

    end

    return
  end


  -- TODO : players bouncing off each other
end



function enemy_move(e, dt)
  if e.dead then return end

  -- turning?
  if e.target_angle then
    local diff = geom.angle_diff(e.angle, e.target_angle)

    local turn = e.info.turn_speed * dt

    if math.abs(diff) <= math.abs(turn) then
      -- reached it
      e.angle = e.target_angle
      e.target_angle = nil
    else
      if diff < 0 then turn = -turn end

      e.angle = geom.angle_add(e.angle, turn)
    end
  end


  -- follow a path?
  if e.path then

    
    
  end

  -- TODO : other kinds of movement
end



function missile_move(m, dt)
  if m.dead then return end

  -- shrink length while dying
  if m.dying then
    m.length = m.length - m.speed * dt

    if m.length <= 0 then
      m.length = 0
      m.dead = 1
    end

    return
  end


  -- grow missile after spawn
  if m.length < m.target_length then
    m.length = math.min(m.length + m.speed * dt, m.target_length)
  end


  local old_x = m.x
  local old_y = m.y

  local new_x = m.x + m.vel_x * dt
  local new_y = m.y + m.vel_y * dt


  -- check for collision with edges of map

  local what, dir = missile_check_hit(new_x, new_y, old_x, old_y)

  if what then
    -- FIXME : move missile onto wall

    if what == "outer" then  edges_hit[dir] = game_time end
    if what == "inner" then inners_hit[dir] = game_time end

    m.dying = true
    return
  end


  m.x = new_x
  m.y = new_y


  -- check for hitting a player or enemy ship

  -- TODO

end



function run_physics(dt)

  if player.health > 0 then
    player_input(player, dt)
    player_move(player, dt)
  end

  for i = 1, #all_enemies do
    enemy_move(all_enemies[i], dt)
  end

  -- missiles will hit stuff now

  for i = 1, #all_missiles do
    missile_move(all_missiles[i], dt)
  end
end



------------------------------------------------------------------------
--  UI STUFF (Menu, Score, etc)
------------------------------------------------------------------------


function draw_ui()
  if game_started then
    love.graphics.setColor(0, 0, 255)
  else
    love.graphics.setColor(104, 160, 255)
  end

  love.graphics.setFont(fonts.title)
  love.graphics.printf("Torrega Race", 250, 250, 300, "center")

  if game_started then

  else
    love.graphics.setColor(0, 0, 255)
    love.graphics.setFont(fonts.credit)
    love.graphics.printf("by Andrew Apted", 250, 310, 300, "center")

    love.graphics.setFont(fonts.normal)
    love.graphics.setColor(216, 216, 216)
    love.graphics.printf("press SPACE to start", 300, 450, 300, "left")

    love.graphics.setColor(176, 176, 176)
    love.graphics.printf("press ESC to quit",    300, 490, 300, "left")
    love.graphics.printf("press O for options",  300, 530, 300, "left")
  end
end



------------------------------------------------------------------------
--  CALLBACKS
------------------------------------------------------------------------


FRAME_TIME = (1 / 100)


function love.load()
  love.graphics.setColor(255,255,255)
  love.graphics.setBackgroundColor(0,0,0)

  fonts.title  = love.graphics.setNewFont(36)
  fonts.credit = love.graphics.setNewFont(24)
  fonts.score  = love.graphics.setNewFont(30)
  fonts.normal = love.graphics.setNewFont(20)

  love.window.setMode(800, 600, {fullscreen=false})
  love.window.setTitle("Torrega Race")

  INNER_X1 = (SCREEN_W - INNER_W) / 2
  INNER_Y1 = (SCREEN_H - INNER_H) / 2
  INNER_X2 = INNER_X1 + INNER_W
  INNER_Y2 = INNER_Y1 + INNER_H

  OUTER_X1 = BORDER
  OUTER_Y1 = BORDER
  OUTER_X2 = SCREEN_W - BORDER
  OUTER_Y2 = SCREEN_H - BORDER
end



function love.update(dt)
  if game_started then
    game_time = game_time + dt

    delta_time = delta_time + dt

    while delta_time >= FRAME_TIME do
      run_physics(FRAME_TIME)

      delta_time = delta_time - FRAME_TIME
    end

  else
    if love.keyboard.isDown(" ") then
      game_setup()
    end
  end

  -- this can be used anywhere
  if love.keyboard.isDown("escape") then
    love.event.push("quit")
  end
end



function love.draw()
  draw_map_edges()
  draw_all_entities()
  draw_ui()
end

