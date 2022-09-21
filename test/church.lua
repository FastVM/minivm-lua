local church = {}

local function zero()
    return function(x) return x end
end

local function succ(c)
    return function(f)
        return function(x)
            return f(c(f)(x))
        end
    end
end

local function exp(c, e)
    return e(c)
end

local function tochurch(n)
    if n == 0 then
        return zero
    else
        return succ(tochurch(n-1))
    end
end

local function tolua(c)
    return c(function (x) return x + 1 end)(0)
end

print(tolua(exp(tochurch(2), tochurch(24))))
