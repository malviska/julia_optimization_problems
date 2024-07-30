
using JuMP
using HiGHS

mutable struct MochilaData
    n::Int #numero de objetos
    w::Array{Int} #pesos
    p::Array{Int} #lucros
    B::Int #tamanho da mochila
end

function readData(file)
	n = 0
	w = []
	p = []
	B = 0
	for l in eachline(file)
		q = split(l, " ")
		num = parse(Int64, q[2])
		if q[1] == "n"
			n = num
			w = [0 for i=1:n]
			p = [0 for i=1:n]
		elseif q[1] == "w"
			w[num] = parse(Float64, q[3])
		elseif q[1] == "p"
			p[num] = parse(Float64, q[3])									
		elseif q[1] == "B"
			B = num
		end
	end
	return MochilaData(n,w,p,B)
end

function printSolution(data, x)
	println("Objetos na Solução:")
	for i = 1: data.n
		if(value(x[i]) >= 0.5)
			print(i)
			print(";")
		end
	end
	println()
end

model = Model(HiGHS.Optimizer)

file = open(ARGS[1], "r")

data = readData(file)

@variable(model, x[i=1:data.n] , Bin)

@constraint(model, sum(data.w[i]*x[i] for i=1:data.n) <= data.B)

@objective(model, Max, sum(data.p[i]*x[i] for i=1:data.n))

print(model)

optimize!(model)

sol = objective_value(model)
println("Valor otimo= ", sol)

printSolution(data, x)

