

local function mandel(width)
  local height, wscale = width, 2/width
  local m, limit2 = 50, 4
  local sum = 0
  local y = 0
  while y < height do
    local Ci = 2*y / height - 1
    local xb = 0
    while (xb < width) do
      local bits = 0
      local xbb = xb+7
      local xblimit
      if xbb < width then
        xblimit = xbb
      else
        xblimit = width-1
      end
      local x = xb
      while x <= xblimit do
        bits = bits + bits
        local Zr, Zi, Zrq, Ziq = 0, 0, 0, 0
        local Cr = x * wscale - 2/3
        local i = 1
        while i <= m do
          local Zri = Zr*Zi
          Zr = Zrq - Ziq + Cr
          Zi = Zri + Zri + Ci
          Zrq = Zr*Zr
          Ziq = Zi*Zi
          if Zrq + Ziq > limit2 then
            bits = bits + 1
            break
          end
          i = i + 1
        end
        x = x + 1
      end
      if xbb >= width then
        local x = width
        while x <= xbb do
          bits = bits + bits + 1
          x = x + 1
        end
      end
      sum = sum + bits
      xb = xb + 8
    end
    y = y + 1
  end
  return sum
end

local res = mandel(1024)
print(res)
