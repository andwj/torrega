
--
--  Torrega Race
--
--  by Andrew Apted
--


player =
{
  x = 50,
  y = 500,

  r = 15,

  angle = 0,

  vel_dx = 0,
  vel_dy = 0
}



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



function run_physics(dt)

  player.angle = player.angle - dt * 120
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

