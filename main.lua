
--
--  Torrega Race
--
--  by Andrew Apted
--


player =
{
  -- Fields:
  --    health
  --    x, y, vel_x, vel_y
  --    angle (in degrees)
  --    r (radius)
}

TURN_SPEED = 240

THRUST_VELOCITY = 300

BOUNCE_FRICTION = 0.95


SCREEN_W = 800
SCREEN_H = 600

INNER_W  = 300
INNER_H  = 200

-- indexed by DIR (2, 4, 6 or 8)
edges_hit  = { }
inners_hit = { }



------ RENDERING ---------------------


function player_draw(p)
  local dx1 =  math.cos((p.angle + 140) * math.pi / 180.0)
  local dy1 = -math.sin((p.angle + 140) * math.pi / 180.0)

  local dx2 =  math.cos(p.angle * math.pi / 180.0)
  local dy2 = -math.sin(p.angle * math.pi / 180.0)

  local dx3 =  math.cos((p.angle - 140) * math.pi / 180.0)
  local dy3 = -math.sin((p.angle - 140) * math.pi / 180.0)

  love.graphics.setColor(255,255,255)

  love.graphics.line(
    p.x + p.r * dx1, p.y + p.r * dy1,
    p.x + p.r * dx2, p.y + p.r * dy2,
    p.x + p.r * dx3, p.y + p.r * dy3)
end



------ PHYSICS ---------------------


function player_reset(p)
  p.health = 100

  p.x = 50
  p.y = 100

  p.vel_x = 0
  p.vel_y = 0

  p.angle = 0

  p.r = 15
end



function game_reset()
  game_time  = 0
  delta_time = 0

  player_reset(player)

  for dir = 2,8,2 do
    edges_hit[dir]  = -2
    inners_hit[dir] = -2
  end
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
    local dx =  math.cos(p.angle * math.pi / 180.0)
    local dy = -math.sin(p.angle * math.pi / 180.0)
    
    p.vel_x = p.vel_x + THRUST_VELOCITY * dx * dt
    p.vel_y = p.vel_y + THRUST_VELOCITY * dy * dt
  end


  local fire = love.keyboard.isDown(" ") or love.keyboard.isDown("lctrl") or
               love.keyboard.isDown("rctrl")

  -- TODO : firing
end



function move_ship(p, dt)
  -- p can be a player or enemy ship

  p.x = p.x + p.vel_x * dt
  p.y = p.y + p.vel_y * dt

  -- safety buffer
  local epsilon = 0.001

  -- bounce of edges
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
    edges_hit[2] = game_time
  
  elseif p.y > SCREEN_H - p.r then
    p.y = SCREEN_H - p.r - epsilon
    p.vel_y = - p.vel_y * BOUNCE_FRICTION
    edges_hit[8] = game_time
  end
end



function run_physics(dt)

  if player.health > 0 then
    player_input(player, dt)
    move_ship(player, dt)
  end

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

  INNER_X = (SCREEN_W - INNER_W) / 2
  INNER_Y = (SCREEN_H - INNER_H) / 2

  INNER_X2 = INNER_X + INNER_W
  INNER_Y2 = INNER_Y + INNER_H

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



local function draw_edge(dir, x1, y1, x2, y2)
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

  love.graphics.setColor(255*qty, 255, 0)
  love.graphics.line(x1, y1, x2, y2)
end



function love.draw()
  player_draw(player)

  -- draw outer edges (when hit)

  draw_edge(2, 1, 1, SCREEN_W-1, 1)
  draw_edge(8, 1, SCREEN_H-1, SCREEN_W-1, SCREEN_H-1)
  draw_edge(4, 1, 1, 1, SCREEN_H-1)
  draw_edge(6, SCREEN_W-1, 1, SCREEN_W-1, SCREEN_H-1)

  -- draw the inner box

  draw_inner_edge(2, INNER_X,  INNER_Y,  INNER_X2, INNER_Y)
  draw_inner_edge(8, INNER_X,  INNER_Y2, INNER_X2, INNER_Y2)
  draw_inner_edge(4, INNER_X,  INNER_Y,  INNER_X,  INNER_Y2)
  draw_inner_edge(6, INNER_X2, INNER_Y,  INNER_X2, INNER_Y2)

  -- score etc  (FIXME)

  love.graphics.setColor(255,255,0)
  love.graphics.print(math.floor(game_time), 700, 10)
end

