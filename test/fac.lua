local function fac(n)
    if n == 0 then
        return 1
    else
        return fac(n-1) * n
    end
end

local t = 0

for i=1, 1000 * 1000 do
    t = fac(16)
end

print(t)