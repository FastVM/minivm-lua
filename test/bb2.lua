local n = 1000000000

local v0 = n % 2 ^ 1 < 2 ^ 0
local v1 = n % 2 ^ 2 < 2 ^ 1
local v2 = n % 2 ^ 3 < 2 ^ 2
local v3 = n % 2 ^ 4 < 2 ^ 3
local v4 = n % 2 ^ 5 < 2 ^ 4
local v5 = n % 2 ^ 6 < 2 ^ 5
local v6 = n % 2 ^ 7 < 2 ^ 6
local v7 = n % 2 ^ 8 < 2 ^ 7
local v8 = n % 2 ^ 9 < 2 ^ 8
local v9 = n % 2 ^ 10 < 2 ^ 9
local v10 = n % 2 ^ 11 < 2 ^ 10
local v11 = n % 2 ^ 12 < 2 ^ 11
local v12 = n % 2 ^ 13 < 2 ^ 12
local v13 = n % 2 ^ 14 < 2 ^ 13
local v14 = n % 2 ^ 15 < 2 ^ 14
local v15 = n % 2 ^ 16 < 2 ^ 15
local v16 = n % 2 ^ 17 < 2 ^ 16
local v17 = n % 2 ^ 18 < 2 ^ 17
local v18 = n % 2 ^ 19 < 2 ^ 18
local v19 = n % 2 ^ 20 < 2 ^ 19
local v20 = n % 2 ^ 21 < 2 ^ 20
local v21 = n % 2 ^ 22 < 2 ^ 21
local v22 = n % 2 ^ 23 < 2 ^ 22
local v23 = n % 2 ^ 24 < 2 ^ 23
local v24 = n % 2 ^ 25 < 2 ^ 24
local v25 = n % 2 ^ 26 < 2 ^ 25
local v26 = n % 2 ^ 27 < 2 ^ 26
local v27 = n % 2 ^ 28 < 2 ^ 27
local v28 = n % 2 ^ 29 < 2 ^ 28
local v29 = n % 2 ^ 30 < 2 ^ 29
local v30 = n % 2 ^ 31 < 2 ^ 30

local y = 0

while true do
    if v0 then
        if v1 then
            if v2 then
                if v3 then
                    if v4 then
                        if v5 then
                            if v6 then
                                if v7 then
                                    if v8 then
                                        if v9 then
                                            if v10 then
                                                if v11 then
                                                    if v12 then
                                                        if v13 then
                                                            if v14 then
                                                                if v15 then
                                                                    if v16 then
                                                                        if v17 then
                                                                            if v18 then
                                                                                if v19 then
                                                                                    if v20 then
                                                                                        if v21 then
                                                                                            if v22 then
                                                                                                if v23 then
                                                                                                    if v24 then
                                                                                                        if v25 then
                                                                                                            if v26 then
                                                                                                                if v27 then
                                                                                                                    if v28 then
                                                                                                                        if v29 then
                                                                                                                            if v30 then
                                                                                                                                break
                                                                                                                            else
                                                                                                                                v30 = true
                                                                                                                            end
                                                                                                                            v29 = false
                                                                                                                        else
                                                                                                                            v29 = true
                                                                                                                        end
                                                                                                                        v28 = false
                                                                                                                    else
                                                                                                                        v28 = true
                                                                                                                    end
                                                                                                                    v27 = false
                                                                                                                else
                                                                                                                    v27 = true
                                                                                                                end
                                                                                                                v26 = false
                                                                                                            else
                                                                                                                v26 = true
                                                                                                            end
                                                                                                            v25 = false
                                                                                                        else
                                                                                                            v25 = true
                                                                                                        end
                                                                                                        v24 = false
                                                                                                    else
                                                                                                        v24 = true
                                                                                                    end
                                                                                                    v23 = false
                                                                                                else
                                                                                                    v23 = true
                                                                                                end
                                                                                                v22 = false
                                                                                            else
                                                                                                v22 = true
                                                                                            end
                                                                                            v21 = false
                                                                                        else
                                                                                            v21 = true
                                                                                        end
                                                                                        v20 = false
                                                                                    else
                                                                                        v20 = true
                                                                                    end
                                                                                    v19 = false
                                                                                else
                                                                                    v19 = true
                                                                                end
                                                                                v18 = false
                                                                            else
                                                                                v18 = true
                                                                            end
                                                                            v17 = false
                                                                        else
                                                                            v17 = true
                                                                        end
                                                                        v16 = false
                                                                    else
                                                                        v16 = true
                                                                    end
                                                                    v15 = false
                                                                else
                                                                    v15 = true
                                                                end
                                                                v14 = false
                                                            else
                                                                v14 = true
                                                            end
                                                            v13 = false
                                                        else
                                                            v13 = true
                                                        end
                                                        v12 = false
                                                    else
                                                        v12 = true
                                                    end
                                                    v11 = false
                                                else
                                                    v11 = true
                                                end
                                                v10 = false
                                            else
                                                v10 = true
                                            end
                                            v9 = false
                                        else
                                            v9 = true
                                        end
                                        v8 = false
                                    else
                                        v8 = true
                                    end
                                    v7 = false
                                else
                                    v7 = true
                                end
                                v6 = false
                            else
                                v6 = true
                            end
                            v5 = false
                        else
                            v5 = true
                        end
                        v4 = false
                    else
                        v4 = true
                    end
                    v3 = false
                else
                    v3 = true
                end
                v2 = false
            else
                v2 = true
            end
            v1 = false
        else
            v1 = true
        end
        v0 = false
    else
        v0 = true
    end
    y = y + 1
end

print(y)
