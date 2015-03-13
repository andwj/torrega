
--
--  Torrega Race
--
--  by Andrew Apted
--
--  under the GNU GPLv3 (or later) license
--


require "utils"
require "sound_gen"


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


fonts =
{
  -- title
  -- credit
  -- normal
  -- score
}


--
-- the game state
--
game =
{
  -- can be : "none", "active", "wait", "over"
  state = "none",

  time  = 0,
  delta = 0,

  -- indexed by DIR (2, 4, 6 or 8)
  hit_outers = {},
  hit_inners = {},

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

    speed = 80,
    turn_speed = 360,

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
-- player object(s)
--
-- Fields:
--    health
--    x, y, vel_x, vel_y
--    angle (in degrees)
--    r (radius, for physics)
--    info
--
all_players = {}


PLAYER_INFO =
{
  player1 =
  {
    -- props --

    spawn_x = 400,
    spawn_y = 104,

    turn_speed = 270,

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

    spawn_x = 400,
    spawn_y = 140,

    turn_speed = 270,

    thrust_velocity = 500,
    bounce_friction = 0.88,

    missile_speed = 500,
    missile_len = 20,

    -- shape --

    r = 15,

    color = { 128,255,255 },

    lines =
    {
      { -140, 1.00 },
      {    0, 1.00 },
      {  140, 1.00 }
    }
  },

  player3 =
  {
    -- props --

    spawn_x = 400,
    spawn_y =  68,

    turn_speed = 270,

    thrust_velocity = 500,
    bounce_friction = 0.88,

    missile_speed = 500,
    missile_len = 20,

    -- shape --

    r = 15,

    color = { 255,160,160 },

    lines =
    {
      { -140, 1.00 },
      {    0, 1.00 },
      {  140, 1.00 }
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


function actor_draw(a, info)
  love.graphics.setColor(info.color[1], info.color[2], info.color[3])

  local last_x
  local last_y

  for i = 1, #info.lines do
    local point = info.lines[i]

    local ang = a.angle + point[1]
    local r   = info.r  * point[2]

    local dx, dy = geom.ang_to_vec(ang, r)

    local x = a.x + dx
    local y = a.y + dy

    if last_x then
      love.graphics.line(last_x, last_y, x, y)
    end

    last_x = x
    last_y = y
  end
end



function player_draw(p)
  actor_draw(p, p.info)
end



function enemy_draw(e)
  actor_draw(e, e.info)
end



function missile_draw(m)
  love.graphics.setColor(m.color[1], m.color[2], m.color[3])

  local dx, dy = geom.normalize(m.vel_x, m.vel_y)

  local end_x = m.x - dx * m.length
  local end_y = m.y - dy * m.length

  love.graphics.line(end_x, end_y, m.x, m.y)
end



function draw_all_entities()
  if game.state == "none" then
    return
  end

  for i = 1, #all_missiles do
    missile_draw(all_missiles[i])
  end

  for i = 1, #all_enemies do
    enemy_draw(all_enemies[i])
  end

  for i = 1, #all_players do
    player_draw(all_players[i])
  end
end



function draw_outer_edge(dir, x1, y1, x2, y2)
  local TIME = 0.5

  local qty = game.hit_outers[dir] + TIME - game.time

  if qty <= 0 then return end

  qty = (qty / TIME) ^ 0.9

  love.graphics.setColor(255*qty, 255*qty, 0)
  love.graphics.line(x1, y1, x2, y2)
end


function draw_inner_edge(dir, x1, y1, x2, y2)
  local qty = 0

  if game.state ~= "none" then
    qty = game.hit_inners[dir] + 1.0 - game.time

    if qty <= 0 then qty = 0 end
  end

  qty = qty ^ 0.5

  love.graphics.setColor(255*qty, 255*qty, 255*(1-qty))
  love.graphics.line(x1, y1, x2, y2)
end


function draw_map_edges()
  -- draw outer edges (only when hit)

  if game.state ~= "none" then
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


function actor_hit_line_raw(a, tx1,ty1, tx2,ty2)
  local last_x
  local last_y

  for i = 1, #info.lines do
    local point = info.lines[i]

    local ang = a.angle + point[1]
    local r   = info.r  * point[2]

    local dx, dy = geom.ang_to_vec(ang, r)

    local x = a.x + dx
    local y = a.y + dy

    if last_x then
      if geom.lines_intersect(tx1,ty1,tx2,ty2, last_x,last_y, x,y) then
        return true
      end
    end

    last_x = x
    last_y = y
  end

  return false
end



function actor_hit_actor_raw(a1, a2)
  local last_x
  local last_y

  for i = 1, #info.lines do
    local point = info.lines[i]

    local ang = a1.angle + point[1]
    local r   = info.r   * point[2]

    local dx, dy = geom.ang_to_vec(ang, r)

    local x = a1.x + dx
    local y = a1.y + dy

    if last_x then
      if actor_hit_line_raw(a2, last_x,last_y, x,y) then
        return true
      end
    end

    last_x = x
    last_y = y
  end

  return false
end



function player_spawn(info)
  local p = {}

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

  table.insert(all_players, p)

  return p
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
  }
end



function enemy_setup()
  all_enemies  = {}

  for ey = 1, 5 do
    for ex = 1, 6 do
      local x = INNER_X1 + ex * 50

      local path = enemy_create_drone_path(ey)
      local y = path[1].y

      local e = enemy_spawn(x, y, 0, 12, ENEMY_INFO.drone)

      e.speed = e.info.speed * (1.0 + (ex - 1) / 6)

      e.path = path
    end
  end
end



function game_setup()
  game.state = "active"

  game.time  = 0
  game.delta = 0

  for dir = 2,8,2 do
    game.hit_outers[dir] = -2
    game.hit_inners[dir] = -2
  end

  all_missiles = {}

  player_spawn(PLAYER_INFO.player1)
--  player_spawn(PLAYER_INFO.player2)
--  player_spawn(PLAYER_INFO.player3)

  enemy_setup()
end



function missile_check_hit_wall(x, y, old_x, old_y)
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

  local what, dir = missile_check_hit_wall(x, y, p.x, p.y)

  if what then
    if what == "outer" then game.hit_outers[dir] = game.time end
    if what == "inner" then game.hit_inners[dir] = game.time end

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
  -- still alive?
  if p.dead or p.dying then
    return
  end

  player_input(p, dt)

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
    game.hit_outers[4] = game.time
    return

  elseif p.x > OUTER_X2 - p.r then
    p.x = OUTER_X2 - p.r - epsilon
    p.vel_x = - p.vel_x * bounce_friction
    game.hit_outers[6] = game.time
    return
  end

  if p.y < OUTER_Y1 + p.r then
    p.y = OUTER_Y1 + p.r + epsilon
    p.vel_y = - p.vel_y * bounce_friction
    game.hit_outers[8] = game.time
    return

  elseif p.y > OUTER_Y2 - p.r then
    p.y = OUTER_Y2 - p.r - epsilon
    p.vel_y = - p.vel_y * bounce_friction
    game.hit_outers[2] = game.time
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
        game.hit_inners[6] = game.time
      else
        p.x = INNER_X1 - p.r - epsilon
        p.vel_x = - p.vel_x * bounce_friction
        p.vel_x = math.min(0.1, p.vel_x)
        game.hit_inners[4] = game.time
      end

    else -- way == "y"

      if p.y > SCREEN_H/2 then
        p.y = INNER_Y2 + p.r + epsilon
        p.vel_y = - p.vel_y * bounce_friction
        p.vel_y = math.max(-0.1, p.vel_y)
        game.hit_inners[2] = game.time
      else
        p.y = INNER_Y1 - p.r + epsilon
        p.vel_y = - p.vel_y * bounce_friction
        p.vel_y = math.min(0.1, p.vel_y)
        game.hit_inners[8] = game.time
      end

    end

    return
  end


  -- FIXME : hitting an enemy ship


  -- players bouncing off each other

  for i = 1, #all_players do
    local p2 = all_players[i]
    if p2 ~= p then
      local dx = p2.x - p.x
      local dy = p2.y - p.y

      local dist = p.r * 3 - geom.vec_len(dx, dy)

      if dist > 0 then
        -- circles intersect : apply a repulsive force
        local repulse = dist * 1000 * dt

        local nx, ny = geom.normalize(dx, dy)

        p.vel_x = p.vel_x - nx * repulse
        p.vel_y = p.vel_y - ny * repulse
      end
    end
  end
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

    return
  end


  -- follow a path?
  if e.path then
    local move_dist = e.speed * dt

    local dx = e.path[1].x - e.x
    local dy = e.path[1].y - e.y

    local dist = geom.vec_len(dx, dy)

    -- reached target?
    if dist <= move_dist then

      e.x = e.path[1].x
      e.y = e.path[1].y

      local PREV = table.remove(e.path, 1)

      -- move to end of list, to cycle indefinitely
      table.insert(e.path, PREV)

      if e.path[1] == nil then
        -- reached end of path
        e.path = nil
        return
      end

      -- begin turning to face next point
      e.target_angle = geom.calc_angle(e.path[1].x - e.x, e.path[1].y - e.y)
      return
    end

    local nx, ny = geom.normalize(dx, dy)

    e.x = e.x + nx * move_dist
    e.y = e.y + ny * move_dist

    return
  end


  -- TODO : other kinds of movement

  e.angle = geom.angle_add(e.angle, 360 * dt)
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

  local what, dir = missile_check_hit_wall(new_x, new_y, old_x, old_y)

  if what then
    -- FIXME : move missile onto wall

    if what == "outer" then game.hit_outers[dir] = game.time end
    if what == "inner" then game.hit_inners[dir] = game.time end

    m.dying = true
    return
  end


  m.x = new_x
  m.y = new_y


  -- check for hitting a player or enemy ship

  -- TODO

end



function run_physics(dt)

  for i = 1, #all_players do
    player_move(all_players[i], dt)
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


function draw_title_screen()
  love.graphics.setColor(104, 160, 255)
  love.graphics.setFont(fonts.title)
  love.graphics.printf("Torrega Race", 250, 250, 300, "center")

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



function draw_ui()
  if game.state == "none" then
    draw_title_screen()
    return
  end


  local sx = SCREEN_W / 2
  local sy = 230

  if all_players[3] then sy = sy - 15 end

  love.graphics.setColor(52, 80, 255)
  love.graphics.setFont(fonts.title)
  love.graphics.printf("Round 1", sx - 150, sy, 300, "center")

  sy = 310

  if all_players[3] then
    sy = sy - 35
  elseif all_players[2] then
    sy = sy - 20
  end

  love.graphics.setFont(fonts.normal)
  love.graphics.setColor(0, 0, 255)
  love.graphics.printf("Score:", sx - 110, sy, 100, "right")

  love.graphics.setColor(176, 176, 176)
  love.graphics.printf("000000", sx, sy, 100, "left")

  if all_players[2] then
    love.graphics.setColor(96, 192, 192)
    love.graphics.printf("000000", sx, sy + 30, 100, "left")

    sy = sy + 30
  end

  if all_players[3] then
    love.graphics.setColor(192, 128, 128)
    love.graphics.printf("000000", sx, sy + 30, 100, "left")

    sy = sy + 30
  end

  sy = sy + 30

  if not all_players[2] then sy = sy + 15 end

  love.graphics.setColor(0, 0, 255)
  love.graphics.printf("Lives:", sx - 110, sy, 100, "right")

  love.graphics.setColor(176, 176, 176)
  love.graphics.printf(">  >  >", sx, sy, 200, "left")
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
  if game.state == "none" then
    if love.keyboard.isDown(" ") then
      game_setup()
    end
  else
    game.time = game.time + dt

    game.delta = game.delta + dt

    while game.delta >= FRAME_TIME do
      run_physics(FRAME_TIME)

      game.delta = game.delta - FRAME_TIME
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

