using XLSX
using OffsetArrays
using CSV
using Plots
plotlyjs()

#状态变量 P remain X
P = begin
    col, label = XLSX.readtable("need.xlsx", "Sheet1")
    data = reshape(hcat(col...), :)
    data = [0; 0; data; 0; 0]
end
#
remain = begin
    tmp = [50; 50; 50; zeros(length(P) - 3)]
end
X = zeros(size(P))

#参数
##师生比
c = 1 / 10
##损耗率
τ = 0.1

# 中间变量
## 当天在保养的
in_rest = zeros(size(P))

function back_buy(i, diff_old)
    # 今天得多买diff_old个充当后面的老手
    # 1. 当前老手足够多买diff_old个
    # 今天能用-今天用-今天计划老手{ceil((原本买 + 再多买)*师生比)}
    if remain[i] - 4 * P[i] - ceil((X[i] + diff_old) * c) >= 0
        X[i] += diff_old
        remain[i+1] += diff_old
        return
    else
        # 2. 当前老手不够多买diff_old个
        #原则：能买几个算几个,剩下的再往前面买
        if diff_old != 1
            # 假如按原本计划下，剩下0.15个能用作老手,则还可以再买floor(0.15/c)
            okbuy = floor((remain[i] - 4 * P[i] - X[i] * c) / c)
            X[i] += okbuy
            remain[i+1] += diff_old
            back_buy(i - 1, diff_old - okbuy)
        else
            remain[i+1] += diff_old
            back_buy(i - 1, diff_old)
        end
    end
end



for i = 3:length(P)-2
    @label start_make_buying_plan
    # 今天不买的情况下
    # 明天能用 = 今天能用 - 今天用  + 昨天用 - 昨天坏 
    remain_p1 = remain[i] - 4 * P[i] + 4 * P[i-1] - ceil(τ * 4 * P[i-1])
    # 今天保养(后面要买的话再减) = 今天能用 - 今天用 + 昨天用 - 昨天坏
    in_rest[i] = remain[i] - P[i] + P[i-1] - ceil(τ*P[i-1])

    # 不买明天也够
    if remain_p1 >= 4 * P[i+1]
        #今天不买
        X[i] = 0
        remain[i+1] = remain_p1
    else
        # 不买明天不够,今天得买刚好够明天的量diff
        diff = 4 * P[i+1] - remain_p1
        # 1. 老手够用->培训量(今天能用-今天用)/师生比  足够培训今天想买的新手
        if floor((remain[i] - 4 * P[i]) / c) >= diff
            #直接买
            X[i] = diff
            #明天刚好够用
            remain[i+1] = 4 * P[i+1]
        else
        # 2. 老手不够用,回头找机会买老手
            # 差的老手的量 = 没有老师的新生/师生比 |> 向上取整
            diff_old = (diff - floor((remain[i] - 4 * P[i]) / c)) * c |> ceil
            back_buy(i - 1, diff_old)
            # 修改了前面的购买情况，使得老手凑齐或明天够用, 重新这轮计划
            @goto start_make_buying_plan
        end

        # 减去用来培训的
        in_rest[i] -= ceil(X[i]*τ)
    end
end

cost = 200*sum(X[2:end-2]) + 10*sum(in_rest[2:end-2])

# 验证
using MATLAB
yao = MATLAB.read_matfile("ans0.mat")["ans0"] |> jarray

yaoX = yao[4, 3:end-1]
yaoRemain = yao[3, 3:end-1]
yaoRest = yao

all(yaoX .== X[3:end-2])
all(yaoRemain .== (remain[3:end-2] - 4 * P[3:end-2]))

