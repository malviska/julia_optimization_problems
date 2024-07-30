
using JuMP
using HiGHS

mutable struct PackagingData
    n::Int #numero de objetos
    w::Array{Float64} #pesos
		index::Array{Int64} #id dos produtos
end


function readData(file)
	n = 0
	w = Float64[] 
	index = Int64[]
	for l in eachline(file)
		q = split(l, r"\s+")
		num = parse(Int64, q[2])
		if q[1] == "n"
			n = num
		elseif q[1] == "o"
			val = parse(Int64, q[2])
			push!(w, parse(Float64, q[3]))
			push!(index, val)
		end
	end
	return PackagingData(n,w, index)
end

function printSolution(data, x, optimum)
	println("$(round(optimum)) Caixas")
	newCaixas = Vector{Vector{Float64}}()
	for i = 1: data.n
		if sum(round(x[i,j]) for j in 1:data.n) > 0
			push!(newCaixas, x[i,:])
		end
	end
	for k = 1: length(newCaixas)
		print("Caixa $(k): ")
		for l = 1: length(newCaixas[k])
			if(round(newCaixas[k][l]) == 1)
				print("$(data.index[l]) ")
			end
		end
		println()
	end
end
	


model = Model(HiGHS.Optimizer)
set_silent(model)

file = open(ARGS[1], "r")

data = readData(file)

@variable(model, x[i=1:data.n, j=1:data.n], Bin)
@variable(model, p[i=1:data.n] >=0)
@variable(model, a[i=1:data.n], Bin)


for k in 1:data.n
	@constraint(model, p[k] == sum(data.w[i]*x[k,i] for i in 1:data.n))
	@constraint(model, sum(x[i,k] for i in 1:data.n) == 1)
	@constraint(model, p[k] <= 20*a[k])

end


@objective(model, Min, sum(a[i] for i in 1:data.n))

optimize!(model)
sol = objective_value(model)
val = value.(x)
printSolution(data, val, sol)

