using XLSX
using OffsetArrays
using CSV

P = begin
    col, label = XLSX.readtable("need.xlsx", "Sheet1")
    hcat(col...)
end
P = reshape(P, :)
P = [0; 0; P; 0; 0]
remain = zeros(size(P))
remain[1:3] = [13, 13, 13]
X = zeros(size(P))
#师生比
c = 1 / 20
τ = 0.1

function back_buy(i, diff_old)
    # 今天不买的情况下
    # 明天能用 = 今天能用 - 今天用  + 昨天用 - 昨天坏 
    remain_p1 = remain[i] - P[i] + P[i-1] - ceil(τ * P[i-1])
    # 不买明天也够
    if remain_p1 >= P[i+1]
        #今天不买
        X[i] = 0
        remain[i+1] = remain_p1
    else
        # 不买明天不够,今天得买刚好够明天的量diff
        diff = P[i+1] - remain_p1
        # 1. 老手够用->培训量(今天能用-今天用)/师生比  足够培训今天想买的新手
        if floor((remain[i] - P[i]) / c) >= diff
            #直接买
            X[i] = diff
            #明天刚好够用
            remain[i+1] = P[i+1]
        else
            # 2. 老手不够用,回头找机会买老手,回头一天？两天？三天？。。。
            # 当前数据记下来，进行回头安排买计划
            # 差的老手的量 = 没有老师的新生/师生比 |> 向上取整
            diff_old = (diff_new - floor((remain[i] - P[i]) / c)) * c |> ceil
            back_buy(i-1, diff_old)
            # 修改了前面的购买情况，使得老手凑齐或明天够用, 重新这轮计划
            @goto start_make_buying_plan
        end
    end
end



for i = 3:length(P)-2
@label start_make_buying_plan
    # 今天不买的情况下
    # 明天能用 = 今天能用 - 今天用  + 昨天用 - 昨天坏 
    remain_p1 = remain[i] - P[i] + P[i-1] - ceil(τ * P[i-1])
    # 不买明天也够
    if remain_p1 >= P[i+1]
        #今天不买
        X[i] = 0
        remain[i+1] = remain_p1
    else
        # 不买明天不够,今天得买刚好够明天的量diff
        diff = P[i+1] - remain_p1
        # 1. 老手够用->培训量(今天能用-今天用)/师生比  足够培训今天想买的新手
        if floor((remain[i] - P[i]) / c) >= diff
            #直接买
            X[i] = diff
            #明天刚好够用
            remain[i+1] = P[i+1]
        else
            # 2. 老手不够用,回头找机会买老手,回头一天？两天？三天？。。。
            # 当前数据记下来，进行回头安排买计划
            # 差的老手的量 = 没有老师的新生/师生比 |> 向上取整
            diff_old = (diff_new - floor((remain[i] - P[i]) / c)) * c |> ceil
            back_buy(i-1, diff_old)
            # 修改了前面的购买情况，使得老手凑齐或明天够用, 重新这轮计划
            @goto start_make_buying_plan
        end
    end
end