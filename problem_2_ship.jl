using XLSX
using OffsetArrays

P = begin
    data = XLSX.readxlsx("need.xlsx")["Sheet1"]["A"][2:end]
    P = OffsetArray([0; data; 0], -1)
end # 1到8周需求量
X = OffsetArray(zeros( 9), -1) # 各周买入量,
N_st = OffsetArray(zeros(9), -1) # 各周能工作总数量
N_sf = OffsetArray(zeros(9), -1)# 各周保养量

X[0] = 13
τ = 0.2# 损耗率

for i = 1:8
    N_st[i] = N_st[i-1] - ceil(τ * P[i-1]) + X[i-1]
    X[i] = begin
        tmp_Xi = P[i+1] + ceil(P[i] * τ)  - N_st[i]
        tmp_Xi > 0 ? tmp_Xi : 0
    end
    N_sf[i] = N_st[i] - P[i]
end

Cost_ship = 200 * sum(X[1:8]) + 10 * sum(N_sf[1:8])
