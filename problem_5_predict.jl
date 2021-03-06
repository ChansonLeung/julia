using Revise
using XLSX
using OffsetArrays
using CSV
using Plots
import Base
plotlyjs()

roundup(num) = round(num, RoundNearestTiesUp)

#状态变量 
##P 需求量 
P = begin
    col, label = XLSX.readtable("need.xlsx", "Sheet1")
    data = reshape(hcat(col...), :)
    data = [0; 0; data; 0; 0]
end
## 当天能用(不含当天要工作)
remain = begin
    tmp = [50; 50; 50; zeros(length(P) - 3)]
end
## 购买量
X = zeros(size(P))

#参数
##师生比
c = 1 / 10
##损耗率
τ = 0.2

# 中间变量
## 当天在保养的
in_rest = zeros(size(P))

function back_buy(i, diff_old)
    # 今天得多买diff_old个充当后面的老手
    # 1. 当前老手足够多买diff_old个
    # 全部参与培训，够用
    if floor((remain[i] - 4 * P[i])/c) >= X[i]+diff_old
    # if remain[i] - 4 * P[i] - ceil((X[i] + diff_old) * c) >= 0
        X[i] += diff_old
        remain[i+1] += diff_old
    else
        # 2. 当前老手不够多买diff_old个
        #原则：和主循环一样先能买多少买多少，剩下一九分
        markX = X[i]
        X[i] = floor((remain[i] - 4 * P[i] ) / c) 
        # 还差的less，分成两部分，一部分今天买X[i]，另一部分交给前面
        less = markX + diff_old - X[i]
        if less == 1
            back_buy(i - 1, 1)
        else 
            # 优先保证往前买的老手是整数
            o = ceil(less/(1+1/c)) 
            X[i] += less-o
            back_buy(i - 1, o)
        end
        remain[i+1] += diff_old
    end
    # 今天保养(后面要买的话再减) = 今天能用 - 今天用 + 昨天用 - 昨天坏
    in_rest[i] = remain[i] - P[i] + P[i-1] - roundup(τ*P[i-1]) - ceil(X[i]*c)
    print("hi")
end



for i = 3:length(P)-2
    @label start_make_buying_plan
    # 今天不买的情况下
    # 明天能用 = 今天能用 - 今天用  + 昨天用 - 昨天坏 
    remain_p1 = remain[i] - 4 * P[i] + 4 * P[i-1] - roundup(τ * 4 * P[i-1])
    # 今天保养(后面要买的话再减) = 明天能用的
    in_rest[i] = remain_p1 
    # 不买明天也够
    if remain_p1 >= 4 * P[i+1]
        #则不买
        X[i] = 0
        remain[i+1] = remain_p1
    else
        # 不够,今天得买刚好够明天的量diff
        diff = 4 * P[i+1] - remain_p1
        # 1. 老手够用->培训量:{剩余老手:{今天能用-今天用}/师生比}  足够培训今天想买的新手
        @show remain[i], 4*P[i]
        if floor((remain[i] - 4 * P[i]) / c) >= diff
            #直接买
            X[i] = diff
            #明天刚好够用
            remain[i+1] = 4 * P[i+1]
        else
        # 2. 老手不够用,回头找机会买老手
            # 差的老手的量O+买的量X = diff
            # 剩下老师傅都参与培训,能买X[i]
            X[i] = floor((remain[i] - 4 * P[i]) / c) 
            # 还差的less，分成两部分，一部分今天买X[i]，另一部分交给前面
            less =diff - X[i]
            if less == 1
                back_buy(i - 1, 1)
            else 
                # 优先保证往前买的老手是整数
                o = ceil(less/(1+1/c)) 
                X[i] += less-o
                back_buy(i - 1, o)
            end
            # 修改了前面的购买情况，使得老手凑齐或明天够用, 重新这轮计划
            @goto start_make_buying_plan
        end
    end
    # 减去用来培训的
    in_rest[i] -= ceil(X[i]*c)
end

cost = 100*sum(X[2:end-2]) + 5*sum(in_rest[2:end-2]) + 10*sum(X[2:end-2] + ceil.(c*X[2:end-2]) )


sum(X)
sum(in_rest)

plot(X)

sum(X)
sum(P*0.1*4)

# 验证
using MATLAB
yao = MATLAB.read_matfile("ans0.mat")["ans0"] |> jarray

yaoX = yao[4, 3:end-1]
yaoRemain = yao[3, 3:end-1]
yaoRest = yao

all(yaoX .== X[3:end-2])
all(yaoRemain .== (remain[3:end-2] - 4 * P[3:end-2]))

@show yaoX - X[3:end-2]

plot([yaoX,remain[3:end-2],X[3:end-2],yaoRemain+4*P[3:end-2], 4*P[3:end-2]] )

plot([remain[3:end-2],yaoRemain+4*P[3:end-2]] )

