--
-- Sound generation
--


function gen_firing_sound()
  local length = 11000
  local rate   = 22050

  local data = love.sound.newSoundData(length, rate, 16, 1)

  for i = 0, length - 1 do
    local along = i / length

    local m = (i * (2 - along))
    local m = m % 50

    if m > 24 then m = 50 - m end

    m = (m - 12.5) / 12.5

    data:setSample(i, m)
  end

  return data
end



function gen_missile_hit_wall()
  local length = 11000
  local rate   = 22050

  local data = love.sound.newSoundData(length, rate, 16, 1)

  for i = 0, length - 1 do
    local along = i / length

    m = math.random()

    m = m * (1 - along ^ 0.5)

    data:setSample(i, m)
  end

  return data
end



function gen_explosion_sound()
  local length = 30000
  local rate   = 22050

  local data = love.sound.newSoundData(length, rate, 16, 1)

  local last = { 0,0,0,0,0,0,0,0 }

  for i = 0, length - 1 do
    m = math.random()

    table.remove(last, 1)
    table.insert(last, m)

    m = (last[4] + last[1] + last[2] + last[3]
       + last[5] + last[6] + last[7] + last[8]) / 4

    local along = i / length
    local factor = ((math.cos(along * math.pi) + 1) / 2) ^ 2

    m = m * factor

    if m < -1 then m = m + 2 end
    if m >  1 then m = m - 2 end

    data:setSample(i, m)
  end

  return data
end



function gen_wah_wah_sound()
  local length = 20000
  local rate   = 22050

  local data = love.sound.newSoundData(length, rate, 16, 1)

  for i = 0, length - 1 do
    local along = i / length

    local k = i * 2

    local A = 100 + along * 10
    local B = 500 - along * 40
    local C = 650 - along * 15
    local D = 800 + along * 20

    local m1 = math.sin(k * math.pi * 2 / A) * 0.8
    local m2 = math.sin(k * math.pi * 2 / B) * 1.0
    local m3 = math.sin(k * math.pi * 2 / C) * 0.8
    local m4 = math.sin(k * math.pi * 2 / D) * 0.6

    local m = (m1 + m2 + m3 + m4) / 3

    if m >  1 then m =  1 end
    if m < -1 then m = -1 end

    data:setSample(i, m)
  end

  return data
end
