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

