
--
--  Torrega Race
--
--  by Andrew Apted
--


player =
{
  health = 100,

  x = 50,
  y = 500,

  r = 15,

  angle = 0,

  vel_x = 0,
  vel_y = 0
}

TURN_SPEED = 240

THRUST_VELOCITY = 200


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

  -- bounce of edges
  if p.x < 0 then
    p.x = 0
    p.vel_x = - p.vel_x
  
  elseif p.x > 800 then
    p.x = 800
    p.vel_x = - p.vel_x
  end

  if p.y < 0 then
    p.y = 0
    p.vel_y = - p.vel_y
  
  elseif p.y > 600 then
    p.y = 600
    p.vel_y = - p.vel_y
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
  love.window.setTitle("Torrega")
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



function love.draw()
  player_draw(player)

  love.graphics.setColor(255,255,0)
  love.graphics.print(math.floor(game_time), 700, 10)
end

