--
-- Sound generation
--


function gen_firing_sound()
  local length = 11000
  local rate   = 22050

  local data = love.sound.newSoundData(length, rate, 16, 1)

local last = { 0,0,0,0,0,0,0,0 }

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



function gen_explosion_sound()
  local length = 20000
  local rate   = 22050

  local data = love.sound.newSoundData(length, rate, 16, 1)

  local last = { 0,0,0,0,0,0,0,0 }

  for i = 0, length - 1 do

    m = math.random()

    table.remove(last, 1)
    table.insert(last, m)

    m = (last[4] + last[1] + last[2] + last[3]
       + last[5] + last[6] + last[7] + last[8]) / 4

    m = m * ((length - i) / length)

    data:setSample(i, m)
  end

  return data
end

