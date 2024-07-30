
using JuMP
using HiGHS

mutable struct CoberturaData
    n::Int #numero de vertices
    ng::Array{Array{Int}} #vizinhancas
end

function readData(file)
	n = 0
	ng = [[]]
	for l in eachline(file)
		q = split(l, " ")

		if q[1] == "n"
			n = parse(Int64, q[2])
			ng = [[] for i=1:n]
		elseif q[1] == "e"
			v = parse(Int64, q[2])
			u = parse(Int64, q[3])
			push!(ng[v], u)
			push!(ng[u], v)
		end
	end
	return CoberturaData(n,ng)
end

function printSolution(data, x)
	println("Uma Cobertura Mínima:")
	for i = 1: data.n
		if value(x[i]) > 0.5
			println("$i")
		end
	end
	println()
end

model = Model(HiGHS.Optimizer)

file = open(ARGS[1], "r")

data = readData(file)

@variable(model, x[i=1:data.n], Bin)

for i=1:data.n
	@constraint(model, sum(x[j] for j in data.ng[i]) >= 1)	
end

@objective(model, Min, sum(x[i] for i=1:data.n))

print(model)

optimize!(model)

sol = objective_value(model)
println("Valor otimo= ", sol)

printSolution(data, x)

