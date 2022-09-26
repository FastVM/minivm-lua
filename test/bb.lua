
local n = 10000

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
                                                                                                                            end
                                                                                                                            v30 = not v30
                                                                                                                        end
                                                                                                                        v29 = not v29
                                                                                                                    end
                                                                                                                    v28 = not v28
                                                                                                                end
                                                                                                                v27 = not v27
                                                                                                            end
                                                                                                            v26 = not v26
                                                                                                        end
                                                                                                        v25 = not v25
                                                                                                    end
                                                                                                    v24 = not v24
                                                                                                end
                                                                                                v23 = not v23
                                                                                            end
                                                                                            v22 = not v22
                                                                                        end
                                                                                        v21 = not v21
                                                                                    end
                                                                                    v20 = not v20
                                                                                end
                                                                                v19 = not v19
                                                                            end
                                                                            v18 = not v18
                                                                        end
                                                                        v17 = not v17
                                                                    end
                                                                    v16 = not v16
                                                                end
                                                                v15 = not v15
                                                            end
                                                            v14 = not v14
                                                        end
                                                        v13 = not v13
                                                    end
                                                    v12 = not v12
                                                end
                                                v11 = not v11
                                            end
                                            v10 = not v10
                                        end
                                        v9 = not v9
                                    end
                                    v8 = not v8
                                end
                                v7 = not v7
                            end
                            v6 = not v6
                        end
                        v5 = not v5
                    end
                    v4 = not v4
                end
                v3 = not v3
            end
            v2 = not v2
        end
        v1 = not v1
    end
    v0 = not v0
    y = y + 1
end

print(y)

