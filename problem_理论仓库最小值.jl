using XLSX
using OffsetArrays
using CSV
using Plots

P = begin 
    col, label = XLSX.readtable("need.xlsx", "Sheet1")
    hcat(col...)
end
P = reshape(P, :)
theoretical_min = zeros(size(P))
max = 13
for i = 1: length(P)
    theoretical_min = max
end
