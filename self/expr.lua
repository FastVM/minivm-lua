#lang lua

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

    local branch = nil

    local compile = nil

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
        elseif ast.type == 'block' then
            for i=1, #ast do
                compile(ast[i])
            end
        elseif ast.type == 'assign' then
            local from = compile(ast[2])
            local varname = ast[1][1]
            if type(varname) ~= 'string' then
                varname = varname[1]
            end
            add('r' .. name(varname), '<-', 'reg', 'r' .. from)
        elseif ast.type == 'local' then
            local ret = reg()
            cself = ast[1][1]
            if type(cself) ~= 'string' then
                cself = cself[1]
            end
            stack[#stack].locals[cself] = ret
            local from = compile(ast[2])
            cself = nil
            add('r' .. ret, '<-', 'reg', 'r' .. from)
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
        elseif ast.type == '+' then
            local out = reg()
            local lhs = compile(ast[1])
            local rhs = compile(ast[2])
            add('r' .. out, '<-', 'add', 'r' .. lhs, 'r' .. rhs)
            return out
        elseif ast.type == '-' then
            local out = reg()
            local lhs = compile(ast[1])
            local rhs = compile(ast[2])
            add('r' .. out, '<-', 'sub', 'r' .. lhs, 'r' .. rhs)
            return out
        elseif ast.type == '*' then
            local out = reg()
            local lhs = compile(ast[1])
            local rhs = compile(ast[2])
            add('r' .. out, '<-', 'mul', 'r' .. lhs, 'r' .. rhs)
            return out
        elseif ast.type == '/' then
            local out = reg()
            local lhs = compile(ast[1])
            local rhs = compile(ast[2])
            add('r' .. out, '<-', 'div', 'r' .. lhs, 'r' .. rhs)
            return out
        elseif ast.type == '%' then
            local out = reg()
            local lhs = compile(ast[1])
            local rhs = compile(ast[2])
            add('r' .. out, '<-', 'mod', 'r' .. lhs, 'r' .. rhs)
            return out
        elseif ast.type == '<' or ast.type == '>' or ast.type == '<=' or ast.type == '>=' or ast.type == '==' or ast.type == '~=' then
            local out = reg()
            local iff = gensym()
            local ift = gensym()
            local done = gensym()
            branch(ast[1], iff, ift)
            add('@' .. iff)
            add('r' .. out, '<-', 'int', '0')
            add('jump', done)
            add('@' .. ift)
            add('r' .. out, '<-', 'int', '1')
            add('@' .. done)
            return out
        elseif ast.type == 'call' then
            local out = reg()
            local regs = {}
            local func = compile(ast[1])
            for i=2, #ast do
                regs[#regs + 1] = 'r' .. compile(ast[i])
            end
            -- add('r0', '<-', 'int', '0')
            -- add('r0', '<-', 'get', 'r' .. func, 'r0')
            add('r' .. out, '<-', 'ccall', 'r' .. func, table.concat(regs, ' '))
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
        elseif ast.type == 'index' then
            local obj = compile(ast[1])
            local ind = compile(ast[2])
            local out = reg()
            add('r' .. out, '<-', 'get', 'r' .. obj, 'r' .. ind)
            return out
        elseif ast.type == 'table' then
            local out = reg()
            add('r0', '<-', 'int', #ast + 1)
            add('r' .. out, '<-', 'arr', 'r0')
            for i=1, #ast do
                add('r0', '<-', 'int', i)
                local tmp = compile(ast[i][1])
                add('set', 'r' .. out, 'r' .. tmp, 'r0')
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
                    if captures[i].name == ast[1] then
                        local out = reg()
                        add('r0', '<-', 'int', i)
                        add('r' .. out, '<-', 'get', 'r1', 'r0')
                        stack[#stack].locals[ast[1]] = out
                        return out
                    end
                end
                if ast[1] == 'print' then
                    local block1 = push()
                    local digit = gensym()
                    local ret = gensym()
                    add('bb r2', ret, digit)
                    add('@' .. digit)
                    add('r0', '<-', 'int', '10')
                    add('r0', '<-', 'div', 'r2', 'r0')
                    add('r0', '<-', 'call', block1.name, 'r1', 'r0')
                    add('r0', '<-', 'int', '10')
                    add('r2', '<-', 'mod', 'r2', 'r0')
                    add('r0', '<-', 'int', '48')
                    add('r2', '<-', 'add', 'r2', 'r0')
                    add('putchar', 'r2')
                    add('@' .. ret)
                    add('r0', '<-', 'int', '0')
                    add('ret', 'r0')
                    pop()
                    local block2 = push()
                    local zero = gensym()
                    local more = gensym()
                    add('bb r2', zero, more)
                    add('@' .. zero)
                    add('r0 <- int 48')
                    add('putchar r0')
                    add('r0 <- int 10')
                    add('putchar r0')
                    add('r0 <- int 0')
                    add('ret r0')
                    add('@' .. more)
                    add('r0', '<-', 'call', block1.name, 'r1', 'r2')
                    add('r0 <- int 10')
                    add('putchar r0')
                    add('r0 <- int 0')
                    add('ret r0')
                    pop()
                    local ret = reg()
                    local value = reg()
                    add('r0', '<-', 'int', 1)
                    add('r' .. ret, '<-', 'arr', 'r0')
                    add('r' .. value, '<-', 'addr', block2.name)
                    add('r0', '<-', 'int', '0')
                    add('set', 'r' .. ret, 'r0', 'r' .. value)
                    return ret
                end
                for k,v in pairs(stack[#stack].locals) do
                    print(ast[1], k)
                end
            end
        else
            print(ast)
        end
    end

    compile(ast)

    return table.concat(done, '\n\n')
end

return expr
