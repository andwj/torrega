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


function geom.normalize(x, y)
  local len = geom.vec_len(x, y)

  if len < 0.001 then
    return 0 , 0
  end

  return x / len , y / len
end

