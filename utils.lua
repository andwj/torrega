--
--  Utility functions
--


geom = {}


function geom.ang_to_vec(angle, len)
  len = len or 1

  local dx =  math.cos(angle * math.pi / 180.0)
  local dy = -math.sin(angle * math.pi / 180.0)

  return dx * len , dy * len
end


function geom.vec_len(x, y)
  return math.sqrt(x * x + y * y)
end


function geom.dist(x1, y1, x2, y2)
  x1 = x1 - x2
  y1 = y1 - y2
  return math.sqrt(x1 * x1 + y1 * y1)
end


function geom.normalize(x, y)
  local len = geom.vec_len(x, y)

  if len < 0.001 then
    return 0 , 0
  end

  return x / len , y / len
end


function geom.angle_add(A, B)
  -- keeps result in range [0..360]
  A = A + B

  while A >= 360 do A = A - 360 end
  while A <    0 do A = A + 360 end

  return A
end


function geom.angle_diff(A, B)
  -- A + result = B
  -- result ranges from -180 to +180

  local D = (B - A)

  while D >  180 do D = D - 360 end
  while D < -180 do D = D + 360 end

  return D
end


function geom.calc_angle(dx, dy)
  if math.abs(dx) < 0.001 and math.abs(dy) < 0.001 then
    return nil
  end

  local angle = math.atan2(-dy, dx) * 180 / math.pi

  if angle < 0 then angle = angle + 360 end

  return angle
end

