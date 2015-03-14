
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

INNER_COLOR = { 0, 0, 255 }

FLASH_TIME = 0.5


-- physics are run at 100 fps
FRAME_TIME = (1 / 100)

-- accumulator for very small dt values
TIME_ACCUM = 0


fonts =
{
  -- title
  -- credit
  -- normal
  -- score
}


--
--  sound info
--
--  Fields: sources, use_sources
--
sounds =
{
  -- firing1
  -- firing2
  -- firing3

  -- explosion
}


--
-- the game state
--
game =
{
  -- can be : "title", "active", "wait", "over"
  state = "title",

  time = 0,

  -- indexed by DIR (2, 4, 6 or 8)
  hit_outers = {},
  hit_inners = {},

  lives = 0,
  lives_str = "",
  lives_max = 5,

  round = 0,
  round_str = "",
}


--
-- enemy objects
--
-- Fields:
--    kind ("enemy"), info
--    x, y, angle, r
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

    die_sound = "drone_die",

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
--    kind ("player"), info
--    x, y, vel_x, vel_y
--    angle (in degrees)
--    r (radius, for physics)
--    enter_score
--
all_players = {}


PLAYER_INFO =
{
  -- stuff shared by all players
  common =
  {
    -- draw radius
    r = 15,

    turn_speed = 270,

    thrust_velocity = 500,
    bounce_friction = 0.88,

    missile_speed = 500,
    missile_len = 20,

    lines =
    {
      { -140, 1.00 },
      {  -70, 0.84 },
      {    0, 1.00 },
      {   70, 0.84 },
      {  140, 1.00 },
    },
  },

  player1 =
  {
    spawn_x = 400,
    spawn_y = 104,

    color = { 255,255,255 },

    firing_sound = "firing1",
  },

  player2 =
  {
    spawn_x = 400,
    spawn_y = 140,

    color = { 128,255,255 },

    firing_sound = "firing2",
  },

  player3 =
  {
    spawn_x = 400,
    spawn_y =  68,

    color = { 255,160,160 },

    firing_sound = "firing3",
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



---=== RENDERING ======-------------------------------


function actor_draw(a, info)
  local explode_along = a.explode_along

  love.graphics.setColor(info.color[1], info.color[2], info.color[3])

  if explode_along then
    local f = (1.0 - explode_along) ^ 0.7
    love.graphics.setColor(info.color[1] * f, info.color[2] * f, info.color[3] * f)
  end

if a.colliding then
love.graphics.setColor(255, 0, 0)
end

  local last_x
  local last_y

  local lines = info.lines

  if explode_along then
    lines = info.explode_lines or lines
  end

  for i = 1, #lines do
    local point = lines[i]

    local ang = a.angle + point[1]
    local r   = info.r  * point[2]

    local dx, dy = geom.ang_to_vec(ang, r)

    local x = a.x + dx
    local y = a.y + dy

    if last_x then
      -- the explosion effect
      if explode_along then
        local mx = (last_x + x) / 2
        local my = (last_y + y) / 2

        local nx, ny = geom.normalize(mx - a.x, my - a.y)

        local dist = 300 * explode_along

        local x1 = last_x + nx * dist
        local y1 = last_y + ny * dist

        local x2 = x + nx * dist
        local y2 = y + ny * dist

        love.graphics.line(x1, y1, x2, y2)
      else
        love.graphics.line(last_x, last_y, x, y)
      end
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
  if game.state == "title" then
    return
  end

  if game.state == "over" and game.time > game.end_time + 5 then
    return
  end

  love.graphics.push()

  if game.state == "over" and game.time > game.end_time + 1 then
    local along = game.time - (game.end_time + 1)
    local scale = 1 + along ^ 2 / 3

    local dx = SCREEN_W * (scale - 1) / 2 
    local dy = SCREEN_H * (scale - 1) / 2

    love.graphics.translate(-dx, -dy)
    love.graphics.scale(scale)
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

  love.graphics.pop()
end



function draw_outer_edge(dir, x1, y1, x2, y2)
  if game.state == "title" then return end

  local H = game.hit_outers[dir]

  local along = (game.time - H.time) / FLASH_TIME
  local color = H.color

  assert(along >= 0)

  if along >= 1 then return end

  local qty = (1.0 - along) ^ 0.8

  -- normal color of outer borders is black [ implicit here ]

  love.graphics.setColor(color[1] * qty, color[2] * qty, color[3] * qty)
  love.graphics.line(x1, y1, x2, y2)
end


function draw_inner_edge(dir, x1, y1, x2, y2)
  local qty   = 0
  local color = INNER_COLOR

  if game.state ~= "title" then
    local H = game.hit_inners[dir]

    local along = (game.time - H.time) / FLASH_TIME
    assert(along >= 0)

    if along < 1 then
      qty   = (1.0 - along) ^ 0.5
      color = H.color
    end
  end

  local r = INNER_COLOR[1] * (1 - qty) + color[1] * qty
  local g = INNER_COLOR[2] * (1 - qty) + color[2] * qty
  local b = INNER_COLOR[3] * (1 - qty) + color[3] * qty

  love.graphics.setColor(r, g, b)
  love.graphics.line(x1, y1, x2, y2)
end


function draw_map_edges()
  -- draw outer edges (only when hit)

  draw_outer_edge(2, OUTER_X1, OUTER_Y2, OUTER_X2, OUTER_Y2)
  draw_outer_edge(8, OUTER_X1, OUTER_Y1, OUTER_X2, OUTER_Y1)
  draw_outer_edge(4, OUTER_X1, OUTER_Y1, OUTER_X1, OUTER_Y2)
  draw_outer_edge(6, OUTER_X2, OUTER_Y1, OUTER_X2, OUTER_Y2)

  -- draw the inner box

  draw_inner_edge(2, INNER_X1, INNER_Y2, INNER_X2, INNER_Y2)
  draw_inner_edge(8, INNER_X1, INNER_Y1, INNER_X2, INNER_Y1)
  draw_inner_edge(4, INNER_X1, INNER_Y1, INNER_X1, INNER_Y2)
  draw_inner_edge(6, INNER_X2, INNER_Y1, INNER_X2, INNER_Y2)
end



---=== PHYSICS ======-----------------------------------


function actor_hit_line_raw(a, tx1,ty1, tx2,ty2)
  local last_x
  local last_y

  for k = 1, #a.info.lines do
    local point = a.info.lines[k]

    local ang = a.angle  + point[1]
    local r   = a.info.r * point[2]

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

  for i = 1, #a1.info.lines do
    local point = a1.info.lines[i]

    local ang = a1.angle  + point[1]
    local r   = a1.info.r * point[2]

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



function missile_hit_actor(m, x1,y1, x2,y2, a)
  -- actor already dead?
  if a.dead then return end

  -- player missiles cannot hurt players, enemy missiles cannot hurt enemies
  if m.owner.kind == a.kind then return false end

  -- do a fast bbox test to eliminate actors far away from the missile

  if a.x + a.info.r + 2 < math.min(x1, x2) then return false end
  if a.x - a.info.r - 2 > math.max(x1, x2) then return false end

  if a.y + a.info.r + 2 < math.min(y1, y2) then return false end
  if a.y - a.info.r - 2 > math.max(y1, y2) then return false end

  -- ok, now do much slower line intersection test

  return actor_hit_line_raw(a, x1,y1, x2,y2)
end



function actor_hit_actor(a1, a2)
  assert(a1 ~= a2)

  -- currently assumes 'a1' is a player, 'a2' is an enemy

  -- actor already dead?
  if a2.dead then return end

  -- do a fast bbox test first

  if a1.x + a1.info.r + 2 < a2.x - a2.info.r then return false end
  if a1.x - a1.info.r - 2 > a2.x + a2.info.r then return false end

  if a1.y + a1.info.r + 2 < a2.y - a2.info.r then return false end
  if a1.y - a1.info.r - 2 > a2.y + a2.info.r then return false end

  -- now do the much much slower line-v-line intersection tests

  return actor_hit_actor_raw(a1, a2)
end



function prune_dead_stuff(list)
  -- prune completely dead objects from the list
  -- can be used for enemies or missiles (but NOT players)

  -- must step backwards through the list
  for i = #list, 1, -1 do
    local a = list[i]

    if a.dead == "remove" then
      table.remove(list, i)
    end
  end
end



function player_set_score(p, score)
  p.score = score

  p.score_str = string.format("%06d", score)
end



function player_create(id)
  local info = PLAYER_INFO["player" .. id]
  assert(info)

  local p = {}

  p.id   = id
  p.kind = "player"
  p.info = info

  p.r = 10  -- used for physics

  p.score = 0

  table.insert(all_players, p)

  return p
end



function player_create_all()
  all_players = {}

  player_create(1)
--player_create(2)
--player_create(3)
end



function player_spawn(p)
  -- places the player into the level

  p.dead = nil
  p.explode_along = nil

  p.x = p.info.spawn_x
  p.y = p.info.spawn_y

  p.angle = p.info.spawn_angle or 0

  p.vel_x = 0
  p.vel_y = 0

  -- prevent firing immediately on level start (bit of a hack)
  p.is_firing = true

  player_set_score(p, p.enter_score)
end



function player_spawn_all()
  for i = 1, #all_players do
    local p = all_players[i]

    player_spawn(p)
  end
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



function enemy_make_drone_path(ey)
  -- makes a set of target points which drones follow

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



function enemy_spawn_all()
  for ey = 1, 5 do
    for ex = 1, 6 do
      local x = INNER_X1 + ex * 50

      local path = enemy_make_drone_path(ey)
      local y = path[1].y

      local e = enemy_spawn(x, y, 0, 12, ENEMY_INFO.drone)

      e.speed = e.info.speed * (1.0 + (ex - 1) / 6)

      e.path = path
    end
  end
end



function game_set_lives(num)
  game.lives = num

  if num == 0 then game.lives_str = "" end
  if num == 1 then game.lives_str = ">" end
  if num == 2 then game.lives_str = "> >" end
  if num == 3 then game.lives_str = "> > >" end
  if num == 4 then game.lives_str = "> > > >" end
  if num >= 5 then game.lives_str = "> > > > >" end
end



function game_set_round(round)
  game.round = round

  game.round_str = "Round " .. round
end



function level_init()
  game.state = "active"
  game.time  = 0

  for dir = 2,8,2 do
    game.hit_outers[dir] = { time=-2 }
    game.hit_inners[dir] = { time=-2 }
  end

  all_missiles = {}
  all_enemies  = {}

  player_spawn_all()

  enemy_spawn_all()
end



function new_level()
  -- remember scores of players
  for i = 1, #all_players do
    local p = all_players[i]
    p.enter_score = p.score
  end

  level_init()
end



function new_game()
  game_set_round(1)
  game_set_lives(0)

  player_create_all()

  new_level()
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
    player_hit_wall(p, what, dir, "hit_wall")
    return
  end

  local m = missile_spawn(p, x, y, p.angle, p.info.missile_speed, p.info.color, p.info.missile_len)
end



function begin_sound(name)
  local info = sounds[name]
  if not info then return end

  local sfx = info.sources[info.cur_idx]
  assert(sfx)

  -- bump index to use the next source
  info.cur_idx = info.cur_idx + 1

  if info.cur_idx > info.max_idx then
    info.cur_idx = 1
  end

  -- if source is already playing, rewind it
  if sfx:isPlaying() then
    sfx:rewind()
  else
    sfx:play()
  end
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

      begin_sound(p.info.firing_sound)
    end
  end
end



function player_hit_wall(p, what, dir, sound_name)
  -- flash the wall hit
  -- Note : used for missiles too!

  local H

  if what == "inner" then
    H = game.hit_inners[dir]
  else
    H = game.hit_outers[dir]
  end

  H.time  = game.time
  H.color = p.info.color

  if sound_name then
    begin_sound(sound_name)
  end
end



function player_think(p, dt)
  if p.dead then
    if p.dead == "animate" then
      dt = game.time - p.death_time

      if dt >= 4 then
        p.dead = "dead"
        return
      end

      p.explode_along = dt / 4
    end

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
    player_hit_wall(p, "outer", 4, "hit_wall")
    return

  elseif p.x > OUTER_X2 - p.r then
    p.x = OUTER_X2 - p.r - epsilon
    p.vel_x = - p.vel_x * bounce_friction
    player_hit_wall(p, "outer", 6, "hit_wall")
    return
  end

  if p.y < OUTER_Y1 + p.r then
    p.y = OUTER_Y1 + p.r + epsilon
    p.vel_y = - p.vel_y * bounce_friction
    player_hit_wall(p, "outer", 8, "hit_wall")
    return

  elseif p.y > OUTER_Y2 - p.r then
    p.y = OUTER_Y2 - p.r - epsilon
    p.vel_y = - p.vel_y * bounce_friction
    player_hit_wall(p, "outer", 2, "hit_wall")
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
        player_hit_wall(p, "inner", 6, "hit_wall")
      else
        p.x = INNER_X1 - p.r - epsilon
        p.vel_x = - p.vel_x * bounce_friction
        p.vel_x = math.min(0.1, p.vel_x)
        player_hit_wall(p, "inner", 4, "hit_wall")
      end

    else -- way == "y"

      if p.y > SCREEN_H/2 then
        p.y = INNER_Y2 + p.r + epsilon
        p.vel_y = - p.vel_y * bounce_friction
        p.vel_y = math.max(-0.1, p.vel_y)
        player_hit_wall(p, "inner", 2, "hit_wall")
      else
        p.y = INNER_Y1 - p.r + epsilon
        p.vel_y = - p.vel_y * bounce_friction
        p.vel_y = math.min(0.1, p.vel_y)
        player_hit_wall(p, "inner", 8, "hit_wall")
      end

    end

    return
  end


  -- players bouncing off each other

  for i = 1, #all_players do
    local p2 = all_players[i]
    if p2 ~= p and not p2.dead then
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



function player_die(p)
  p.dead = "animate"
  p.death_time = game.time

  begin_sound("explosion")
end



function player_check_hit_enemy(p)
  if p.dead then return end

  for i = 1,#all_enemies do
    local e = all_enemies[i]

    if actor_hit_actor(p, e) then
      player_die(p)
      return
    end
  end
end



function enemy_die(e, p)
  if p then
    player_set_score(p, p.score + 10)
  end

  e.dead = "animate"
  e.death_time = game.time

  begin_sound(e.info.die_sound)
end



function enemy_shot_by_player(e, p)
  -- FIXME: implement 'hits' field, flash of red perhaps

  enemy_die(e, p)
end



function enemy_think(e, dt)
  if e.dead then
    if e.dead == "animate" then
      dt = game.time - e.death_time

      if dt >= 4 then
        e.dead = "remove"
        return
      end

      e.explode_along = dt / 4
    end

    return
  end


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



function missile_think(m, dt)
  if m.dead then
    -- shrink length while dying
    if m.dead == "animate" then
      m.length = m.length - m.speed * dt

      if m.length <= 0 then
        m.length = 0
        m.dead = "remove"
      end
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

    if m.owner.kind == "player" then
      player_hit_wall(m.owner, what, dir, "hit_wall")
    end

    m.dead = "animate"
    return
  end


  m.x = new_x
  m.y = new_y


  local dx, dy = geom.normalize(m.vel_x, m.vel_y)

  local end_x = m.x - dx * m.length
  local end_y = m.y - dy * m.length


  -- check for hitting a player or enemy ship

  if m.owner.kind == "player" then
    for i = 1, #all_enemies do
      local e = all_enemies[i]

      if missile_hit_actor(m, end_x,end_y, m.x,m.y, e) then
        enemy_shot_by_player(e, m.owner)
        m.dead = "animate"
        return
      end
    end
  end


  if m.owner.kind == "enemy" then
    for i = 1, #all_players do
      local p = all_players[i]

      if missile_hit_actor(m, end_x,end_y, m.x,m.y, p) then
        player_die(p)
        m.dead = "animate"
        return
      end
    end
  end
end



function level_think(dt)
  for i = 1, #all_enemies do
    enemy_think(all_enemies[i], dt)
  end

  for i = 1, #all_players do
    player_think(all_players[i], dt)
    player_check_hit_enemy(all_players[i])
  end

  -- missiles will hit stuff now

  for i = 1, #all_missiles do
    missile_think(all_missiles[i], dt)
  end

  -- remove completely dead missiles and enemies
  prune_dead_stuff(all_enemies)
  prune_dead_stuff(all_missiles)
end



function no_players_alive()
  for i = 1, #all_players do
    if all_players[i].dead ~= "dead" then
      return false
    end
  end

  return true
end


function game_think(dt)
  game.time = game.time + dt

  if game.state == "title" then
    if love.keyboard.isDown(" ") then
      new_game()
    end
  end

  if game.state ~= "active" then
    return
  end

  -- active game --

  level_think(dt)

  if no_players_alive() then
    if game.lives < 1 then
      game.state = "over"
      game.end_time = game.time
    else
      game_set_lives(game.lives - 1)

      level_init()
    end

    return
  end

  if #all_enemies == 0 then

  end
end



function love.update(dt)
  TIME_ACCUM = TIME_ACCUM + dt

  while TIME_ACCUM >= FRAME_TIME do
    game_think(FRAME_TIME)

    TIME_ACCUM = TIME_ACCUM - FRAME_TIME
  end

  -- this can be used anywhere [ currently... ]
  if love.keyboard.isDown("escape") then
    love.event.push("quit")
  end
end



---=== UI STUFF ======--------------------------------------


function draw_help1()
  love.graphics.setFont(fonts.normal)
  love.graphics.setColor(216, 216, 216)
  love.graphics.printf("press SPACE to start", 300, 450, 300, "left")

  love.graphics.setColor(176, 176, 176)
  love.graphics.printf("press ESC to quit",    300, 490, 300, "left")
  love.graphics.printf("press O for options",  300, 530, 300, "left")
end



function draw_title_screen()
  love.graphics.setColor(104, 160, 255)
  love.graphics.setFont(fonts.title)
  love.graphics.printf("Torrega Race", 250, 250, 300, "center")

  love.graphics.setColor(0, 0, 255)
  love.graphics.setFont(fonts.credit)
  love.graphics.printf("by Andrew Apted", 250, 310, 300, "center")

  draw_help1()
end



function draw_ui()
  if game.state == "title" then
    draw_title_screen()
    return
  end


  local sx = SCREEN_W / 2
  local sy = 230

  if all_players[3] then sy = sy - 15 end

  love.graphics.setFont(fonts.title)

  if game.state == "over" then
    love.graphics.setColor(40, 200, 130)
    love.graphics.printf("Game Over", sx - 150, sy, 300, "center")
  else
    love.graphics.setColor(52, 80, 255)
    love.graphics.printf(game.round_str, sx - 150, sy, 300, "center")
  end

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
  love.graphics.printf(all_players[1].score_str, sx, sy, 100, "left")

  if all_players[2] then
    love.graphics.setColor(96, 192, 192)
    love.graphics.printf(all_players[2].score_str, sx, sy + 30, 100, "left")

    sy = sy + 30
  end

  if all_players[3] then
    love.graphics.setColor(192, 128, 128)
    love.graphics.printf(all_players[3].score_str, sx, sy + 30, 100, "left")

    sy = sy + 30
  end

  sy = sy + 30

  if not all_players[2] then sy = sy + 15 end

  if game.state ~= "over" then
    love.graphics.setColor(0, 0, 255)
    love.graphics.printf("Lives:", sx - 110, sy, 100, "right")

    love.graphics.setColor(176, 176, 176)
    love.graphics.printf(game.lives_str, sx, sy, 200, "left")
  end
end



function love.draw()
  draw_map_edges()
  draw_all_entities()
  draw_ui()
end



---=== RESOURCE LOADING ======------------------------------


function init_screen()
  INNER_X1 = (SCREEN_W - INNER_W) / 2
  INNER_Y1 = (SCREEN_H - INNER_H) / 2
  INNER_X2 = INNER_X1 + INNER_W
  INNER_Y2 = INNER_Y1 + INNER_H

  OUTER_X1 = BORDER
  OUTER_Y1 = BORDER
  OUTER_X2 = SCREEN_W - BORDER
  OUTER_Y2 = SCREEN_H - BORDER
end



function flesh_out_players()
  for name,info in pairs(PLAYER_INFO) do
    if name ~= "common" then
      for k,v in pairs(PLAYER_INFO.common) do
        if info[k] == nil then
           info[k] = v
        end
      end
    end
  end
end



function load_all_fonts()
  fonts.title  = love.graphics.setNewFont(36)
  fonts.credit = love.graphics.setNewFont(24)
  fonts.score  = love.graphics.setNewFont(30)
  fonts.normal = love.graphics.setNewFont(20)
end



function load_all_sounds()

  local function make_sound(name, data, num_sources, volume, pitch)
    sounds[name] =
    {
      cur_idx = 1,
      max_idx = num_sources,

      sources = {},
    }

    for i = 1, num_sources do
      local sfx = love.audio.newSource(data)

      if volume then sfx:setVolume(volume) end
      if pitch  then sfx:setPitch (pitch)  end

      sounds[name].sources[i] = sfx
    end
  end

  --- load_all_sounds ---

  local firing1_data = gen_firing_sound()
  local firing2_data = gen_firing_sound()
  local firing3_data = gen_firing_sound()

  local hit_wall_data = gen_missile_hit_wall()

  make_sound("firing1", firing1_data, 4, 0.5, 1.41)
  make_sound("firing2", firing2_data, 4, 0.5, 1.00)
  make_sound("firing3", firing3_data, 4, 0.5, 1.85)

  make_sound("hit_wall", hit_wall_data, 5, 0.5, 0.75)

  local explosion_data = gen_explosion_sound()

  make_sound("explosion", explosion_data, 2, 1.0, 0.50)
end



function love.load()
  love.graphics.setColor(255,255,255)
  love.graphics.setBackgroundColor(0,0,0)

  load_all_fonts()

  love.window.setMode(800, 600, {fullscreen=true})
  love.window.setTitle("Torrega Race")

  love.audio.setVolume(0.5)

  load_all_sounds()

  init_screen()
  flesh_out_players()
end


