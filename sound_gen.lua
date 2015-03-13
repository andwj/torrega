--
-- Sound generation
--


function gen_firing_sound()
  local length = 40000
  local rate   = 22050

  local data = love.sound.newSoundData(length, rate, 16, 1)

  for i = 0, length - 1 do
    local along = i / length

    local m = (i * (1 + along))
    local m = m % 50

    if m > 24 then m = 50 - m end

    m = (m - 12.5) / 12.5

    m = m * ((length - i) / length)

    data:setSample(i, m)
  end

  return data
end

