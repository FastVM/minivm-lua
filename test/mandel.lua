

local function mandel(width)
  local height, wscale = width, 2/width
  local m, limit2 = 50, 4
  local sum = 0
  for y=0,height-1 do
    local Ci = 2*y / height - 1
    for xb=0,width-1,8 do
      local bits = 0
      local xbb = xb+7
      local xblimit
      if xbb < width then
        xblimit = xbb
      else
        xblimit = width-1
      end
      for x=xb,xblimit do
        bits = bits + bits
        local Zr, Zi, Zrq, Ziq = 0, 0, 0, 0
        local Cr = x * wscale - 2/3
        for i=1,m do
          local Zri = Zr*Zi
          Zr = Zrq - Ziq + Cr
          Zi = Zri + Zri + Ci
          Zrq = Zr*Zr
          Ziq = Zi*Zi
          if Zrq + Ziq > limit2 then
            bits = bits + 1
            break
          end
        end
      end
      if xbb >= width then
        for x=width,xbb do bits = bits + bits + 1 end
      end
      sum = sum + bits
    end
  end
  return sum
end

local res = mandel(1024)
print(res)
