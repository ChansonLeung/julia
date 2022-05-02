using XLSX
using DataFrames
using OffsetArrays

# 1到8周需求量
P = XLSX.readxlsx("need.xlsx")["Sheet1"]["A"][2:end]
P = [P; 0]
# 各周买入量, 各周能工作总数量, 各周保养量
X, Xm, Xb = OffsetArray(zeros(9), -1), OffsetArray(zeros(9), -1), OffsetArray(zeros(9), -1)
X[0] = 13

for i = 1:8
    X[i] = begin
        tmp_Xi = P[i+1] - sum(X[0:i-1])
        tmp_Xi > 0 ? tmp_Xi : 0.0
    end
    Xm[i] = sum(X[0:i-1])
    Xb[i] = Xm[i] - P[i]
end

Cost_ship = 200 * sum(X[1:8]) + 10 * sum(Xb[1:8])