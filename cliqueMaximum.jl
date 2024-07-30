
using JuMP
using HiGHS

mutable struct GraphData
    n::Int #number of vertices
    g::Array{Int, 2}
end


function readData(file)
	n = 0
	firstLine = readline(file)
	q = split(firstLine, r"\s+")
	graph = Array{Int,2}
	if q[1] == "n"
		size = parse(Int64, q[2])
		n = size
		graph = [0 for i in 1:size, j in 1:size]
	else
		return
	end
	for l in eachline(file)
		q = split(l, r"\s+")
		if q[1] == "e"
			v1 = parse(Int64, q[2])
			v2 = parse(Int64, q[3])
			graph[v1,v2] = 1
			graph[v2,v1] = 1
		end
	end
	return GraphData(n,graph)
end

function printSolution(data, v, sol)
	println("$(sol) VERTICES")
	for i in 1:length(v)
		if round(v[i]) == 1
			print("$(i) ")
		end
	end
	println()
end
	



model = Model(HiGHS.Optimizer)
set_silent(model)
 
file = open(ARGS[1], "r")
 
data = readData(file)

@variable(model, v[i=1:data.n], Bin)


for i in 1:data.n
	for j in i+1:data.n 
		if data.g[i,j] == 0
			@constraint(model, v[i] + v[j] <= 1)
		end
	end
end


@objective(model, Max, sum(v[i] for i in 1:data.n))

optimize!(model)
sol = objective_value(model)
val = value.(v)
printSolution(data,val,sol)

