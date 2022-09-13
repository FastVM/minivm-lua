local function Main(N)
    local function BottomUpTree(item, depth)
        if depth > 0 then
            local i = item + item
            depth = depth - 1
            local left = BottomUpTree(i-1, depth)
            local right = BottomUpTree(i, depth)
            return { item, left, right }
        else
            return { item }
        end
    end
    
    local function ItemCheck(tree)
        if #tree == 3 then
            return tree[1] + ItemCheck(tree[2]) - ItemCheck(tree[3])
        else
            return tree[1]
        end
    end
    
    local mindepth = 4
    local maxdepth = mindepth + 2
    if maxdepth < N then maxdepth = N end

    do
        local stretchdepth = maxdepth + 1
        local stretchtree = BottomUpTree(0, stretchdepth)
        print(ItemCheck(stretchtree))
    end

    local longlivedtree = BottomUpTree(0, maxdepth)

    for depth=mindepth,maxdepth,2 do
        local iterations = 2 ^ ((maxdepth - depth) + mindepth)
        local check = 0
        for i=1,iterations do
            local add = ItemCheck(BottomUpTree(1, depth)) + ItemCheck(BottomUpTree(-1, depth))
            check = check + add
        end
        print(check)
    end

    print(ItemCheck(longlivedtree))
end

Main(16)