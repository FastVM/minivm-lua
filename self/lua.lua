#lang lua

local files = require('self.files')
local parse = require('self.parser')
local expr = require('self.expr')

local src = files.slurp(arg[1])
local res = parse(src)
if res.ok == true then
    local res = expr.program(res.ast)
    files.dump(arg[2], tostring(res))
else
    print(res.msg)
end
