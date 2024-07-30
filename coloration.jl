
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
	println("$(sol) CORES")
	colorMap = Vector{Vector{Float64}}()
	for i in 1:data.n
		for j in 1:data.n
			if round(v[i,j]) == 1
				push!(colorMap, v[i,:])
				break
			end
		end
	end
	for k in 1:length(colorMap)
		print("COR $k : ")
		for p in 1: length(colorMap[k])
			if round(colorMap[k][p]) == 1
				print("$p ")
			end
		end
		println()
	end
	println()
end
	



model = Model(HiGHS.Optimizer)
set_silent(model)
 
file = open(ARGS[1], "r")
 
data = readData(file)

@variable(model, cg[i=1:data.n,j=1:data.n], Bin)
@variable(model, c[i=1:data.n], Bin)

for i in 1:data.n
	@constraint(model, sum(cg[x, i] for x in 1:data.n) == 1)
	@constraint(model, sum(cg[i, x] for x in 1:data.n) <= data.n*c[i])
	for j in i+1:data.n 
		if data.g[i,j] == 1
			for x in 1:data.n
				@constraint(model, cg[x,i] + cg[x,j] <= 1)
			end
		end
	end
end


@objective(model, Min, sum(c[i] for i in 1:data.n))

optimize!(model)
sol = objective_value(model)
val = value.(cg)
printSolution(data,val,sol)

