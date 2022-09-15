#lang lua

local runtime = [[

func vm.pow
    r0 <- int 0
    beq r2 r0 vm.pow.rec vm.pow.zero
@vm.pow.zero
    r0 <- int 1
    ret r0
@vm.pow.rec
    r0 <- int 1
    r0 <- sub r2 r0
    r0 <- call vm.pow r1 r0
    r1 <- mul r1 r0
    ret r1
end

func vm.print.u
    r0 <- int 10
    blt r2 r0 vm.print.u.digit vm.print.u.ret 
@vm.print.u.digit
    r0 <- int 10
    r0 <- div r2 r0
    r0 <- call vm.print.u r1 r0
@vm.print.u.ret
    r0 <- int 10
    r2 <- mod r2 r0
    r0 <- int 48
    r0 <- add r2 r0
    putchar r0
    r0 <- int 0
    ret r0
end

func vm.println.i
    r0 <- int 0
    blt r2 r0 vm.println.i.pos vm.println.i.neg
@vm.println.i.neg
    r0 <- int 45
    putchar r0
    r0 <- int 0
    r2 <- sub r0 r2
@vm.println.i.pos
    r0 <- call vm.print.u r1 r2
    r0 <- int 10
    putchar r0
    r0 <- int 0
    ret r0
end

]]

local expr = {}

expr.program = function(ast)
    local done = {}

    local stack = {}

    local sym = 0

    local function gensym()
        sym = sym + 1
        return '.' .. tostring(sym)
    end

    local function push(name)
        name = name or gensym()
        stack[#stack + 1] = {
            name = name,
            data = {},
            locals = {},
            regs = 9,
            cache = {}
        }
        return stack[#stack]
    end

    local function pop()
        local entry = stack[#stack]
        stack[#stack] = nil
        local tab = {}
        tab[#tab + 1] = 'func ' .. entry.name
        for i=1, #entry.data do
            if string.sub(entry.data[i], 1, 1) == '@' then
                tab[#tab + 1] = entry.data[i]
            else
                tab[#tab + 1] = '    ' .. entry.data[i]
            end
        end
        tab[#tab + 1] = 'end'
        done[#done + 1] = table.concat(tab, '\n')
    end

    local function add(...)
        local data = stack[#stack].data
        data[#data + 1] = table.concat({...}, ' ')
    end

    local function reg()
        local entry = stack[#stack]
        local ret = entry.regs
        entry.regs = entry.regs + 1
        return ret
    end

    local function name(name)
        local place = reg()
        if stack[#stack].locals[name] == nil then
            stack[#stack].locals[name] = place
        end
        return stack[#stack].locals[name]
    end

    local ends = {}

    local captures = {}

    local cself = nil

    local function pstr(str)
        local len = string.len(str)
        local out = reg()
        add('r0', '<-', 'int', len)
        add('r' .. out, '<-', 'arr', 'r0')
        local tmp = reg()
        for i=1, len do
            local val = string.byte(str, i)
            add('r' .. tmp, '<-', 'int', val)
            add('r0', '<-', 'int', i-1)
            add('set', 'r' .. out, 'r0', 'r' .. tmp)
        end
        return out
    end

    local branch = nil

    local compile = nil

    local breakv = nil

    branch = function(ast, iffalse, iftrue)
        if ast.type == '<' then
            local lhs = compile(ast[1])
            local rhs = compile(ast[2])
            add('blt', 'r' .. lhs, 'r' .. rhs, iffalse, iftrue)
        elseif ast.type == '>' then
            local lhs = compile(ast[1])
            local rhs = compile(ast[2])
            add('blt', 'r' .. rhs, 'r' .. lhs, iffalse, iftrue)
        elseif ast.type == '<=' then
            local lhs = compile(ast[1])
            local rhs = compile(ast[2])
            add('blt', 'r' .. rhs, 'r' .. lhs, iftrue, iffalse)
        elseif ast.type == '>=' then
            local lhs = compile(ast[1])
            local rhs = compile(ast[2])
            add('blt', 'r' .. lhs, 'r' .. rhs, iftrue, iffalse)
        elseif ast.type == '~=' then
            local lhs = compile(ast[1])
            local rhs = compile(ast[2])
            add('beq', 'r' .. lhs, 'r' .. rhs, iftrue, iffalse)
        elseif ast.type == '==' then
            local lhs = compile(ast[1])
            local rhs = compile(ast[2])
            add('beq', 'r' .. lhs, 'r' .. rhs, iffalse, iftrue)
        else
            local case = compile(ast)
            add('bb', 'r' .. case, iffalse, iftrue)
        end
    end

    compile = function(ast)
        -- print(ast.type, table.unpack(ast))
        if ast.type == 'program' then
            push('__entry')
            for i=1, #ast do
                compile(ast[i])
            end
            add('exit')
            pop()
        elseif ast.type == 'parens' then
            return compile(ast[1])
        elseif ast.type == 'block' then
            for i=1, #ast do
                compile(ast[i])
            end
        elseif ast.type == 'assign' then
            local tos = ast[1]
            local froms = ast[2]
            if tos.type ~= 'to' then
                tos = {tos}
            end
            if froms.type ~= 'from' then
                froms = {froms}
            end
            for i=1, #tos do
                local from = compile(froms[i])
                local varname = tos[i]
                if varname.type == 'ident' then
                    add('r' .. name(varname[1]), '<-', 'reg', 'r' .. from)
                elseif varname.type == 'dotindex' then
                    local obj = compile(varname[1])
                    local ind = pstr(varname[2][1])
                    add('set', 'r' .. obj, 'r' .. ind, 'r' .. from)
                else
                    print('bad set: ' .. varname.type)
                end
            end
        elseif ast.type == 'break' then
            add('jump', breakv)
        elseif ast.type == 'for' then
            local name = ast[1][1]
            local start = compile(ast[2])
            local stop = compile(ast[3])
            local iff = gensym()
            local ift = gensym()
            local iter = reg()
            stack[#stack].locals[name] = iter
            add('r' .. iter, '<-', 'reg', 'r' .. start)
            add('blt', 'r' .. stop, 'r' .. iter, ift, iff)
            add('@' .. ift)
            local bv = breakv
            breakv = iff
            compile(ast[#ast])
            breakv = bv
            if #ast == 4 then
                add('r0', '<-', 'int', '1')
                add('r' .. iter, '<-', 'add', 'r' .. iter, 'r0')
            else
                local val = compile(ast[4])
                add('r' .. iter, '<-', 'add', 'r' .. iter, 'r' .. val)
            end
            add('blt', 'r' .. stop, 'r' .. iter, ift, iff)
            add('@' .. iff)
        elseif ast.type == 'local' then
            local tos = ast[1]
            local froms = ast[2]
            for i=1, #tos do
                local ret = reg()
                local to = tos[i]
                if to.type == 'ident' then
                    if froms and froms[i] then
                        cself = to[1]
                        stack[#stack].locals[cself] = ret
                        local from = compile(froms[i])
                        cself = nil
                        add('r' .. ret, '<-', 'reg', 'r' .. from)
                    else
                        add('r' .. ret, '<-', 'nil')
                    end
                else
                    print(to.type)
                end
            end
        elseif ast.type == 'lambda' then
            local count = 1
            for name, reg in pairs(stack[#stack].locals) do
                captures[#captures+1] = {
                    name = name,
                    reg = reg,
                    index = count
                }
                count = count + 1
            end
            local block = push()
            if cself ~= nil then
                block.locals[cself] = 1
            end
            for i=1, #ast[1] do
                block.locals[ast[1][i][1]] = i + 1
            end
            compile(ast[2])
            add('r0', '<-', 'int', '0')
            add('ret', 'r0')
            pop()
            local ret = reg()
            local value = reg()
            add('r0', '<-', 'int', count)
            add('r' .. ret, '<-', 'arr', 'r0')
            add('r' .. value, '<-', 'addr', block.name)
            add('r0', '<-', 'int', '0')
            add('set', 'r' .. ret, 'r0', 'r' .. value)
            for i=1, #captures do
                local cur = captures[i]
                if cur.name == cself then
                    add('r0', '<-', 'int', cur.index)
                    add('set', 'r' .. ret, 'r0', 'r' .. ret)
                else
                    add('r0', '<-', 'int', cur.index)
                    add('set', 'r' .. ret, 'r0', 'r' .. cur.reg)
                end
            end
            for i=1, count do
                captures[#captures] = nil
            end
            return ret
        elseif ast.type == 'else' then
            compile(ast[1])
            add('jump', ends[#ends])
        elseif ast.type == 'case' then
            -- local cond = compile(ast[1])
            local select = gensym()
            local noselect = gensym()
            branch(ast[1], noselect, select)
            add('@' .. select)
            compile(ast[2])
            add('jump', ends[#ends])
            add('@' .. noselect)
        elseif ast.type == 'cond' then
            local out = gensym()
            ends[#ends + 1] = out
            for i=1, #ast do
                compile(ast[i])
            end
            ends[#ends] = nil
            add('@' .. out)
        elseif ast.type == '^' then
            local lhs = compile(ast[1])
            local rhs = compile(ast[2])
            local out = reg()
            add('r' .. out, '<-', 'call vm.pow', 'r' .. lhs, 'r' .. rhs)
            return out
        elseif ast.type == 'neg' then
            local out = reg()
            local rhs = compile(ast[1])
            add('r0', '<-', 'int', '0')
            add('r' .. out, '<-', 'sub', 'r0', 'r' .. rhs)
            return out
        elseif ast.type == '+' then
            local lhs = compile(ast[1])
            local rhs = compile(ast[2])
            local out = reg()
            add('r' .. out, '<-', 'add', 'r' .. lhs, 'r' .. rhs)
            return out
        elseif ast.type == '-' then
            local lhs = compile(ast[1])
            local rhs = compile(ast[2])
            local out = reg()
            add('r' .. out, '<-', 'sub', 'r' .. lhs, 'r' .. rhs)
            return out
        elseif ast.type == '*' then
            local out = reg()
            local lhs = compile(ast[1])
            local rhs = compile(ast[2])
            local out = reg()
            add('r' .. out, '<-', 'mul', 'r' .. lhs, 'r' .. rhs)
            return out
        elseif ast.type == '/' then
            local lhs = compile(ast[1])
            local rhs = compile(ast[2])
            local out = reg()
            add('r' .. out, '<-', 'div', 'r' .. lhs, 'r' .. rhs)
            return out
        elseif ast.type == '%' then
            local lhs = compile(ast[1])
            local rhs = compile(ast[2])
            local out = reg()
            add('r' .. out, '<-', 'mod', 'r' .. lhs, 'r' .. rhs)
            return out
        elseif ast.type == '<' or ast.type == '>' or ast.type == '<=' or ast.type == '>=' or ast.type == '==' or ast.type == '~=' then
            local iff = gensym()
            local ift = gensym()
            local done = gensym()
            branch(ast[1], iff, ift)
            local out = reg()
            add('@' .. iff)
            add('r' .. out, '<-', 'int', 'false')
            add('jump', done)
            add('@' .. ift)
            add('r' .. out, '<-', 'int', 'true')
            add('@' .. done)
            return out
        elseif ast.type == 'call' then
            local out = reg()
            local regs = {}
            local func = compile(ast[1])
            for i=2, #ast do
                regs[#regs + 1] = 'r' .. compile(ast[i])
            end
            add('r' .. out, '<-', 'dcall', 'r' .. func, table.concat(regs, ' '))
            return out
        elseif ast.type == 'number' then
            local out = reg()
            add('r' .. out, '<-', 'int', ast[1])
            return out
        elseif ast.type == 'return' then
            if #ast == 0 then
                add('r0', '<-', 'int', '0')
                add('ret', 'r0')
            else
                local val = compile(ast[1])
                add('ret', 'r' .. val)
            end
        elseif ast.type == 'from' then
            return compile(ast[1])
        elseif ast.type == 'length' then
            local obj = compile(ast[1])
            local out = reg()
            add('r' .. out, '<-', 'len', 'r' .. obj)
            add('r0', '<-', 'int', '1')
            add('r' .. out, '<-', 'sub', 'r' .. out, 'r0')
            return out
        elseif ast.type == 'dotindex' then
            local obj = compile(ast[1])
            local ind = pstr(ast[2][1])
            local ret = reg()
            add('r' .. ret, '<-', 'get', 'r' .. obj, 'r' .. ind)
            return ret
        elseif ast.type == 'index' then
            local obj = compile(ast[1])
            local ind = compile(ast[2])
            local out = reg()
            add('r' .. out, '<-', 'get', 'r' .. obj, 'r' .. ind)
            return out
        elseif ast.type == 'table' then
            local out = reg()
            -- add('r0', '<-', 'int', #ast + 1)
            add('r' .. out, '<-', 'tab')
            for i=1, #ast do
                if ast[i].type == 'fieldnth' then
                    local tmp = compile(ast[i][1])
                    add('r0', '<-', 'int', i)
                    add('set', 'r' .. out, 'r0', 'r' .. tmp)
                else
                    print(ast[i])
                end
            end
            return out
        elseif ast.type == 'while' then
            local ift = gensym()
            local done = gensym()
            branch(ast[1], done, ift)
            add('@' .. ift)
            compile(ast[2])
            branch(ast[1], done, ift)
            add('@' .. done)
        elseif ast.type == 'ident' then
            if stack[#stack].locals[ast[1]] ~= nil then
                return name(ast[1])
            else
                for i=1, #captures do
                    local cur = captures[i]
                    if cur.name == ast[1] then
                        local out = reg()
                        add('r0', '<-', 'int', cur.index)
                        add('r' .. out, '<-', 'get', 'r1', 'r0')
                        stack[#stack].locals[ast[1]] = out
                        return out
                    end
                end
                if ast[1] == 'print' then
                    local ret = reg()
                    local value = reg()
                    add('r0', '<-', 'int', 1)
                    add('r' .. ret, '<-', 'arr', 'r0')
                    add('r' .. value, '<-', 'addr', 'vm.println.i')
                    add('r0', '<-', 'int', '0')
                    add('set', 'r' .. ret, 'r0', 'r' .. value)
                    return ret
                end
                print('--- ERROR ---')
                for k,v in pairs(stack[#stack].locals) do
                    print(ast[1], k)
                end
                print()
            end
        else
            print(ast)
        end
    end

    compile(ast)

    return runtime .. table.concat(done, '\n\n')
end

return expr
