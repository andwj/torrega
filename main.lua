
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


-- indexed by DIR (2, 4, 6 or 8)
edges_hit  = {}
inners_hit = {}


player =
{
  -- Fields:
  --    health
  --    x, y, vel_x, vel_y
  --    angle (in degrees)
  --    r (radius, for physics)
  --    shape
}

TURN_SPEED = 240

THRUST_VELOCITY = 500

BOUNCE_FRICTION = 0.87


SHAPES =
{
  player1 =
  {
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
    r = 15,

    color = { 85,255,255 },

    lines =
    {
      { -140, 1.00 },
      {    0, 1.00 },
      {  140, 1.00 }
    }
  },

  drone =
  {
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


-- enemy class
--
-- Fields:
--    x, y, angle, r, shape
--

all_enemies = {}


-- missile class
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
  draw_shape(p.shape, p.x, p.y, p.angle)
end



function enemy_draw(e)
  draw_shape(e.shape, e.x, e.y, e.angle)
end



function missile_draw(m)
  love.graphics.setColor(m.color[1], m.color[2], m.color[3])

  local dx, dy = geom.ang_to_vec(m.angle, m.length)

  local x2 = m.x + dx
  local y2 = m.y + dy

  love.graphics.line(x2, y2, m.x, m.y)
end



function draw_all_entities()
  for i = 1, #all_missiles do
    missile_draw(all_missiles[i])
  end

  for i = 1, #all_enemies do
    enemy_draw(all_enemies[i])
  end

  player_draw(player)
end



------ PHYSICS ---------------------


function player_reset(p)
  p.kind = "player"

  p.health = 100
  p.score  = 0

  p.x = 50
  p.y = 100

  p.vel_x = 0
  p.vel_y = 0

  p.angle = 0

  p.r = 10  -- used for physics

  p.shape = SHAPES.player2
end



function enemy_create(x, y, angle, r, shape)
  local e = {}

  e.kind = "enemy"

  e.x = x
  e.y = y
  e.angle = angle
  e.shape = shape
  e.r = r

  table.insert(all_enemies, e)

  return e
end


function missile_create(owner, x, y, angle, speed, color, target_length)
  local m = {}

  m.kind  = "missile"
  m.owner = owner

  m.x = x
  m.y = y

  m.color  = color
  m.length = 1
  m.target_length = target_length

  local dx, dy = geom.ang_to_vec(angle, speed)

  m.vel_x = dx
  m.vel_y = dy

  return m
end



function enemy_reset()
  all_enemies  = {}

  for ex = 1, 5 do
  for ey = 1, 4 do
    local e = enemy_create(INNER_X1 + ex * 50, INNER_Y2 + ey * 35, 0, 12, SHAPES.drone)

  end
  end
end



function game_reset()
  game_time  = 0
  delta_time = 0

  for dir = 2,8,2 do
    edges_hit[dir]  = -2
    inners_hit[dir] = -2
  end

  all_missiles = {}

  player_reset(player)

  enemy_reset()
end



function player_fire(p)
  local dx, dy = geom.ang_to_vec(p.angle)

  -- FIXME
end


function player_input(p, dt)

  local turn_left  = love.keyboard.isDown("left")  or love.keyboard.isDown("a")
  local turn_right = love.keyboard.isDown("right") or love.keyboard.isDown("d")

  if turn_left and turn_right then
    -- do nothing if both are pressed
  elseif turn_left then
    p.angle = p.angle + TURN_SPEED * dt
  elseif turn_right then
    p.angle = p.angle - TURN_SPEED * dt
  end


  local thrust = love.keyboard.isDown("up") or love.keyboard.isDown("w")

  if thrust then
    local dx, dy = geom.ang_to_vec(p.angle, THRUST_VELOCITY * dt)

    p.vel_x = p.vel_x + dx
    p.vel_y = p.vel_y + dy
  end


  local fire = love.keyboard.isDown(" ") or love.keyboard.isDown("lctrl") or
               love.keyboard.isDown("rctrl")

  if p.is_firing ~= fire then
    p.is_firing = fire

    if fire then
      player_fire(p)
    end
  end

  -- TODO : firing
end



function move_player(p, dt)
  -- p can be a player or enemy ship

  local old_inside_x = (INNER_X1 - p.r <= p.x) and (p.x <= INNER_X2 + p.r)
  local old_inside_y = (INNER_Y1 - p.r <= p.y) and (p.y <= INNER_Y2 + p.r)

  p.x = p.x + p.vel_x * dt
  p.y = p.y + p.vel_y * dt

  -- safety buffer
  local epsilon = 0.001

  -- bounce off edges

  -- FIXME : user OUTER_xxxx !!!

  if p.x < p.r then
    p.x = p.r + epsilon
    p.vel_x = - p.vel_x * BOUNCE_FRICTION
    edges_hit[4] = game_time

  elseif p.x > SCREEN_W - p.r then
    p.x = SCREEN_W - p.r - epsilon
    p.vel_x = - p.vel_x * BOUNCE_FRICTION
    edges_hit[6] = game_time
  end

  if p.y < p.r then
    p.y = p.r + epsilon
    p.vel_y = - p.vel_y * BOUNCE_FRICTION
    edges_hit[8] = game_time

  elseif p.y > SCREEN_H - p.r then
    p.y = SCREEN_H - p.r - epsilon
    p.vel_y = - p.vel_y * BOUNCE_FRICTION
    edges_hit[2] = game_time
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
        p.vel_x = - p.vel_x * BOUNCE_FRICTION
        p.vel_x = math.max(-0.1, p.vel_x)
        inners_hit[6] = game_time
      else
        p.x = INNER_X1 - p.r - epsilon
        p.vel_x = - p.vel_x * BOUNCE_FRICTION
        p.vel_x = math.min(0.1, p.vel_x)
        inners_hit[4] = game_time
      end

    else -- way == "y"

      if p.y > SCREEN_H/2 then
        p.y = INNER_Y2 + p.r + epsilon
        p.vel_y = - p.vel_y * BOUNCE_FRICTION
        p.vel_y = math.max(-0.1, p.vel_y)
        inners_hit[2] = game_time
      else
        p.y = INNER_Y1 - p.r + epsilon
        p.vel_y = - p.vel_y * BOUNCE_FRICTION
        p.vel_y = math.min(0.1, p.vel_y)
        inners_hit[8] = game_time
      end

    end

  end
end



function move_enemy(e, dt)
  -- TODO
end



function move_missile(m, dt)
  local old_x = m.x
  local old_y = m.y

  local new_x = m.x + m.vel_x * dt
  local new_y = m.y + m.vel_y * dt

  local old_inner_x = (INNER_X1 <= old_x and old_x <= INNER_X2)
  local old_inner_y = (INNER_Y1 <= old_y and old_y <= INNER_Y2)

  local inner_x = (INNER_X1 <= new_x and new_x <= INNER_X2)
  local inner_y = (INNER_Y1 <= new_y and new_y <= INNER_Y2)


  m.x = new_x
  m.y = new_y

  -- collide with edge of map

  -- FIXME


  -- grow length
  local vel_len = geom.vec_len(m.x - old_x, m.y - old_y)

  if m.length < m.total_length then
    m.length = math.min(m.length + vel_len, m.total_length)
  end
end



function run_physics(dt)

  if player.health > 0 then
    player_input(player, dt)
    move_player(player, dt)
  end

  for i = 1, #all_enemies do
    move_enemy(all_enemies[i], dt)
  end

  -- missiles will hit stuff now

  for i = 1, #all_missiles do
    move_missile(all_missiles[i], dt)
  end
end



------------------------------------------------------------------------
--  UI STUFF (Menu, Score, etc)
------------------------------------------------------------------------


function draw_ui()

  -- TEMP CRUD
  love.graphics.setColor(255,255,0)
  love.graphics.print(math.floor(game_time), 700, 10)
end



------------------------------------------------------------------------
--  CALLBACKS
------------------------------------------------------------------------


game_time  = 0
delta_time = 0

FRAME_TIME = (1 / 100)


function love.load()
  love.graphics.setColor(255,255,255)
  love.graphics.setBackgroundColor(0,0,0)
  love.graphics.setNewFont(20)

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

  game_reset()
end



function love.update(dt)
  game_time = game_time + dt

  delta_time = delta_time + dt

  while delta_time >= FRAME_TIME do
    run_physics(FRAME_TIME)

    delta_time = delta_time - FRAME_TIME
  end

  if love.keyboard.isDown("escape") then
    love.event.push("quit")
  end
end



local function draw_outer_edge(dir, x1, y1, x2, y2)
  local qty = edges_hit[dir] + 1.0 - game_time

  if qty <= 0 then return end

  qty = qty ^ 0.5

  love.graphics.setColor(255*qty, 255*qty, 0)
  love.graphics.line(x1, y1, x2, y2)
end


local function draw_inner_edge(dir, x1, y1, x2, y2)
  local qty = inners_hit[dir] + 1.0 - game_time

  if qty <= 0 then qty = 0 end

  qty = qty ^ 0.5

  love.graphics.setColor(255*qty, 255*qty, 255*(1-qty))
  love.graphics.line(x1, y1, x2, y2)
end



function love.draw()
  -- draw outer edges (when hit)

  draw_outer_edge(2, OUTER_X1, OUTER_Y2, OUTER_X2, OUTER_Y2)
  draw_outer_edge(8, OUTER_X1, OUTER_Y1, OUTER_X2, OUTER_Y1)
  draw_outer_edge(4, OUTER_X1, OUTER_Y1, OUTER_X1, OUTER_Y2)
  draw_outer_edge(6, OUTER_X2, OUTER_Y1, OUTER_X2, OUTER_Y2)

  -- draw the inner box

  draw_inner_edge(2, INNER_X1, INNER_Y2, INNER_X2, INNER_Y2)
  draw_inner_edge(8, INNER_X1, INNER_Y1, INNER_X2, INNER_Y1)
  draw_inner_edge(4, INNER_X1, INNER_Y1, INNER_X1, INNER_Y2)
  draw_inner_edge(6, INNER_X2, INNER_Y1, INNER_X2, INNER_Y2)

  -- entities (player, enemies, missiles, etc)

  draw_all_entities()

  -- user interface

  draw_ui()
end

