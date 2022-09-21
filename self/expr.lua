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
        return {
            name = 'r' .. tostring(ret),
            mut = false
        }
    end

    local function locals(name)
        local place = reg()
        if stack[#stack].locals[name] == nil then
            stack[#stack].locals[name] = place
        end
        return stack[#stack].locals[name]
    end

    local ends = {}

    local captures = {}

    local cself = nil

    local selfs = {}

    local function pstr(str)
        local len = string.len(str)
        local out = reg()
        add('r0', '<-', 'int', len)
        add(out.name, '<-', 'arr', 'r0')
        local tmp = reg()
        for i=1, len do
            local val = string.byte(str, i)
            add(tmp.name, '<-', 'int', val)
            add('r0', '<-', 'int', i-1)
            add('set', out.name, 'r0', tmp.name)
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
            add('blt', lhs.name, rhs.name, iffalse, iftrue)
        elseif ast.type == '>' then
            local lhs = compile(ast[1])
            local rhs = compile(ast[2])
            add('blt', rhs.name, lhs.name, iffalse, iftrue)
        elseif ast.type == '<=' then
            local lhs = compile(ast[1])
            local rhs = compile(ast[2])
            add('blt', rhs.name, lhs.name, iftrue, iffalse)
        elseif ast.type == '>=' then
            local lhs = compile(ast[1])
            local rhs = compile(ast[2])
            add('blt', lhs.name, rhs.name, iftrue, iffalse)
        elseif ast.type == '~=' then
            local lhs = compile(ast[1])
            local rhs = compile(ast[2])
            add('beq', lhs.name, rhs.name, iftrue, iffalse)
        elseif ast.type == '==' then
            local lhs = compile(ast[1])
            local rhs = compile(ast[2])
            add('beq', lhs.name, rhs.name, iffalse, iftrue)
        else
            local case = compile(ast)
            add('bb', case.name, iffalse, iftrue)
        end
    end

    local function nonlocal(name, out) 
        out = out or reg()
        for i=1, #captures do
            local cur = captures[i]
            if cur.name == name then
                out = out or reg()
                add('r0', '<-', 'int', cur.index)
                add(out.name, '<-', 'get', 'r1', 'r0')
                stack[#stack].locals[name] = out
                return out
            end
        end
        if name == 'print' then
            local value = reg()
            add('r0', '<-', 'int', 1)
            add(out.name, '<-', 'arr', 'r0')
            add(value.name, '<-', 'addr', 'vm.println.i')
            add('r0', '<-', 'int', '0')
            add('set', out.name, 'r0', value.name)
            return out
        end
        local cur = {
            name = name,
            index = captures.max
        }
        captures.max = captures.max + 1
        captures[#captures+1] = cur
        add('r0', '<-', 'int', cur.index)
        add(out.name, '<-', 'get', 'r1', 'r0')
        stack[#stack].locals[name] = out
        return out
    end

    local function lookup(name, out)
        if stack[#stack].locals[name] ~= nil then
            local val = locals(name)
            if out then
                add(out.name, '<-', 'reg', val.name)
                return out
            else
                return val
            end
        else
            return nonlocal(name, out)
        end
    end

    compile = function(ast, out)
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
            local tos = ast[1]
            local froms = ast[2]
            if tos.type ~= 'to' then
                tos = {tos}
            end
            if froms.type ~= 'from' then
                froms = {froms}
            end
            for i=1, #tos do
                local varname = tos[i]
                if varname.type == 'ident' then
                    local reg = locals(varname[1])
                    local from = compile(froms[i], reg)
                    if from.name ~= reg.name then
                        add(reg.name, '<-', 'reg', from.name)
                    end
                elseif varname.type == 'dotindex' then
                    local from = compile(froms[i])
                    local obj = compile(varname[1])
                    local ind = pstr(varname[2][1])
                    add('set', obj.name, ind.name, from.name)
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
            stack[#stack].locals[name] = {
                name = iter.name,
                mut = false
            }
            add(iter.name, '<-', 'reg', start.name)
            add('blt', stop.name, iter.name, ift, iff)
            add('@' .. ift)
            local bv = breakv
            breakv = iff
            compile(ast[#ast])
            breakv = bv
            if #ast == 4 then
                add('r0', '<-', 'int', '1')
                add(iter.name, '<-', 'add', iter.name, 'r0')
            else
                local val = compile(ast[4])
                add(iter.name, '<-', 'add', iter.name, val.name)
            end
            add('blt', stop.name, iter.name, ift, iff)
            add('@' .. iff)
        elseif ast.type == 'local' then
            local tos = ast[1]
            local froms = ast[2]
            for i=1, #tos do
                local to = tos[i]
                if to.type == 'ident' then
                    if froms and froms[i] then
                        cself = to[1]
                        local from = compile(froms[i])
                        cself = nil
                        if from.mut then
                            stack[#stack].locals[to[1]] = {
                                name = from.name,
                                mut = false,
                            }
                        else
                            local ret = reg()
                            stack[#stack].locals[to[1]] = ret
                            add(ret.name, '<-', 'reg', from.name)
                        end
                    else
                        local ret = reg()
                        stack[#stack].locals[to[1]] = {
                            name = ret.name,
                            mut = false
                        }
                        add(ret.name, '<-', 'nil')
                    end
                else
                    print(to.type)
                end
            end
        elseif ast.type == 'lambda' then
            local block = push()
            if cself ~= nil then
                block.locals[cself] = {
                    name = 'r1',
                    mut = false
                }
            end
            for i=1, #ast[1] do
                block.locals[ast[1][i][1]] = {
                    name = 'r' .. tostring(i + 1),
                    mut = false
                }
            end
            if cself ~= nil then
                selfs[#selfs + 1] = {
                    name = cself,
                    block = block.name
                }
            else
                selfs[#selfs + 1] = {}
            end
            local last = captures
            captures = {max = 1}
            compile(ast[2])
            local res = captures
            captures = last
            selfs[#selfs] = nil
            add('r0', '<-', 'nil')
            add('ret', 'r0')
            pop()
            out = out or reg()
            add('r0', '<-', 'int', tostring(res.max + 5))
            add(out.name, '<-', 'arr', 'r0')
            local value = reg()
            add(value.name, '<-', 'addr', block.name)
            add('r0', '<-', 'int', '0')
            add('set', out.name, 'r0', value.name)
            for i=1, #res do
                local cur = res[i]
                if cur.name == cself then
                    add('r0', '<-', 'int', cur.index)
                    add('set', out.name, 'r0', out.name)
                else
                    local found = lookup(cur.name).name
                    add('r0', '<-', 'int', cur.index)
                    add('set', out.name, 'r0', found)
                end
            end
            return out
        elseif ast.type == 'else' then
            compile(ast[1])
            add('jump', ends[#ends])
        elseif ast.type == 'case' then
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
            out = out or reg()
            add(out.name, '<-', 'call vm.pow', lhs.name, rhs.name)
            return out
        elseif ast.type == 'neg' then
            out = out or reg()
            local rhs = compile(ast[1])
            add('r0', '<-', 'int', '0')
            add(out.name, '<-', 'sub', 'r0', rhs.name)
            return out
        elseif ast.type == '+' then
            local lhs = compile(ast[1])
            local rhs = compile(ast[2])
            out = out or reg()
            add(out.name, '<-', 'add', lhs.name, rhs.name)
            return out
        elseif ast.type == '-' then
            local lhs = compile(ast[1])
            local rhs = compile(ast[2])
            out = out or reg()
            add(out.name, '<-', 'sub', lhs.name, rhs.name)
            return out
        elseif ast.type == '*' then
            out = out or reg()
            local lhs = compile(ast[1])
            local rhs = compile(ast[2])
            out = out or reg()
            add(out.name, '<-', 'mul', lhs.name, rhs.name)
            return out
        elseif ast.type == '/' then
            local lhs = compile(ast[1])
            local rhs = compile(ast[2])
            out = out or reg()
            add(out.name, '<-', 'div', lhs.name, rhs.name)
            return out
        elseif ast.type == '%' then
            local lhs = compile(ast[1])
            local rhs = compile(ast[2])
            out = out or reg()
            add(out.name, '<-', 'mod', lhs.name, rhs.name)
            return out
        elseif ast.type == '<' or ast.type == '>' or ast.type == '<=' or ast.type == '>=' or ast.type == '==' or ast.type == '~=' then
            local iff = gensym()
            local ift = gensym()
            local done = gensym()
            branch(ast[1], iff, ift)
            out = out or reg()
            add('@' .. iff)
            add(out.name, '<-', 'int', 'false')
            add('jump', done)
            add('@' .. ift)
            add(out.name, '<-', 'int', 'true')
            add('@' .. done)
            return out
        elseif ast.type == 'call' then
            out = out or reg()
            local regs = {}
            for i=2, #ast do
                regs[#regs + 1] = compile(ast[i]).name
            end
            if #selfs ~= 0 and ast[1].type == 'ident' and selfs[#selfs].name == ast[1][1] then
                add(out.name, '<-', 'call', selfs[#selfs].block, 'r1', table.concat(regs, ' '))
            else
                local func = compile(ast[1])
                add(out.name, '<-', 'ccall', func.name, table.concat(regs, ' '))
            end
            return out
        elseif ast.type == 'number' then
            out = out or reg()
            add(out.name, '<-', 'int', ast[1])
            return out
        elseif ast.type == 'return' then
            if #ast == 0 then
                add('r0', '<-', 'int', '0')
                add('ret', 'r0')
            else
                local val = compile(ast[1])
                add('ret', val.name)
            end
        elseif ast.type == 'from' then
            return compile(ast[1])
        elseif ast.type == 'length' then
            local obj = compile(ast[1])
            out = out or reg()
            add(out.name, '<-', 'len', obj.name)
            add('r0', '<-', 'int', '1')
            add(out.name, '<-', 'sub', out.name, 'r0')
            return out
        elseif ast.type == 'dotindex' then
            local obj = compile(ast[1])
            local ind = pstr(ast[2][1])
            local ret = reg()
            add(ret.name, '<-', 'get', obj.name, ind.name)
            return ret
        elseif ast.type == 'index' then
            local obj = compile(ast[1])
            local ind = compile(ast[2])
            out = out or reg()
            add(out.name, '<-', 'get', obj.name, ind.name)
            return out
        elseif ast.type == 'table' then
            out = out or reg()
            add(out.name, '<-', 'tab')
            for i=1, #ast do
                if ast[i].type == 'fieldnth' then
                    local tmp = compile(ast[i][1])
                    add('r0', '<-', 'int', i)
                    add('set', out.name, 'r0', tmp.name)
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
            local bv = breakv
            breakv = done
            compile(ast[2])
            breakv = bv
            branch(ast[1], done, ift)
            add('@' .. done)
        elseif ast.type == 'ident' then
            return lookup(ast[1], out)
        else
            print(ast)
        end
    end

    compile(ast)

    return runtime .. table.concat(done, '\n\n')
end

return expr
