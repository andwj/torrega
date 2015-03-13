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


function geom.perp_dist(x, y, sx,sy, ex,ey)
  x = x - sx ; ex = ex - sx
  y = y - sy ; ey = ey - sy

  local len = math.sqrt(ex*ex + ey*ey)

  if len < 0.001 then
    error("perp_dist: zero-length line")
  end

  return (x * ey - y * ex) / len
end


function geom.along_dist(x, y, sx,sy, ex,ey)
  x = x - sx ; ex = ex - sx
  y = y - sy ; ey = ey - sy

  local len = math.sqrt(ex*ex + ey*ey)

  if len < 0.001 then
    error("perp_dist: zero-length line")
  end

  return (x * ex + y * ey) / len
end


function geom.lines_intersect(ax1,ay1,ax2,ay2, bx1,by1,bx2,by2)
  local a1 = geom.perp_dist(ax1, ay1, bx1,by1,bx2,by2)
  local a2 = geom.perp_dist(ax2, ay2, bx1,by1,bx2,by2)

  -- half-width of lines
  local hw = 0.5

  if a1 >  hw and a2 >  hw then return false end
  if a1 < -hw and a2 < -hw then return false end

  local b1 = geom.perp_dist(bx1, by1, ax1,ay1,ax2,ay2)
  local b2 = geom.perp_dist(bx2, by2, ax1,ay1,ax2,ay2)

  if b1 >  hw and b2 >  hw then return false end
  if b1 < -hw and b2 < -hw then return false end

  return true
end

