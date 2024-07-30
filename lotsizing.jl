
using JuMP
using HiGHS

mutable struct LotSizingData
    n::Int #numero de periodos
    c::Array{Int} #custo de produção
    h::Array{Int} #custo de estoque
    d::Array{Int} #demandas dos clientes
end

function readData(file)
	n = 0
	c = []
	h = []
	d = []
	for l in eachline(file)
		q = split(l, " ")
		num = parse(Int64, q[2])
		if q[1] == "n"
			n = num
			c = [0 for i=1:n]
			h = [0 for i=1:n]
			d = [0 for i=1:n]
		elseif q[1] == "c"
			num = parse(Int64, q[2])
			c[num] = parse(Float64, q[3])
		elseif q[1] == "h"
			num = parse(Int64, q[2])
			h[num] = parse(Float64, q[3])									
		elseif q[1] == "d"
			num = parse(Int64, q[2])
			d[num] = parse(Float64, q[3])
		end
	end
	return LotSizingData(n,c,h,d)
end

function printSolution(data, x)
	println("Esquema de produção:")
	for i = 1: data.n
		println("No periodo $i é produzido $(value(x[i]))")
	end
	println()
end

model = Model(HiGHS.Optimizer)

file = open(ARGS[1], "r")

data = readData(file)

@variable(model, x[i=1:data.n] >= 0)
@variable(model, s[i=1:data.n+1] >= 0)

for i=1:data.n
	@constraint(model, s[i+1] == s[i] + x[i] - data.d[i] )	
end

@constraint(model, s[1] == 0)


@objective(model, Min, sum(data.c[i]*x[i] + data.h[i]*s[i]  for i=1:data.n))

print(model)

optimize!(model)

sol = objective_value(model)
println("Valor otimo= ", sol)

printSolution(data, x)

