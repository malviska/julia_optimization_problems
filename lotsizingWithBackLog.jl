
using JuMP
using HiGHS

mutable struct lotSizingData
    n::Int #number of periods
		c::Array{Float64} #Production cost
		d::Array{Float64} #Demand for the product
		s::Array{Float64} #Storage cost
		p::Array{Float64} #Penalty
end


function readData(file)
	n = 0
	c = []
	d = []
	s = []
	p = []
	for l in eachline(file)
		q = split(l, r"\s+")
		val = parse(Int64, q[2])
		if q[1] == "n"
			n = val
			c = [0 for i in 1:n]
			d = [0 for i in 1:n]
			s = [0 for i in 1:n]
			p = [0 for i in 1:n]
		elseif q[1] == "c"
			c[val] = parse(Float64, q[3])
		elseif q[1] == "d"
			d[val] = parse(Float64, q[3])
		elseif q[1] == "s"
			s[val] = parse(Float64, q[3])
		elseif q[1] == "p"
			p[val] = parse(Float64, q[3])
		end
	end
	return lotSizingData(n,c,d,s,p)
end

function printSolution(data, prod, sol)
	println("SOLUÇÃO: $(sol)")
	for i in 1:data.n
		println("PRODUÇÃO PERIODO $(i) : $(prod[i])")
	end
end

model = Model(HiGHS.Optimizer)
set_silent(model)
 
file = open(ARGS[1], "r")
 
data = readData(file)


@variable(model, d[i=1:data.n] >= 0)
@variable(model, s[i=1:data.n] >= 0)
@variable(model, x[i=1:data.n] >= 0)
@variable(model, y[i=1:data.n] >= 0)
@variable(model, u[i=1:data.n] >= 0)
@variable(model, c[i=1:data.n] >= 0)
@variable(model, e[i=1:data.n] >= 0)
@variable(model, p[i=1:data.n] >= 0)
@variable(model, h[i=1:data.n] >= 0)


@constraint(model, d[1] == data.d[1])
@constraint(model, s[1] == 0)
@constraint(model, c[1] == data.c[1]*x[1])
@constraint(model, h[1] == data.s[1]*y[1])
@constraint(model, y[1] <= x[1] + s[1])
@constraint(model, u[1] == d[1] - e[1])
@constraint(model, e[1] <= x[1] - y[1] + s[1])
@constraint(model, p[1] == data.p[1]*u[1])
@constraint(model, u[data.n] == 0)

for i in 2:data.n
	@constraint(model, d[i] == data.d[i] + u[i-1])
	@constraint(model, s[i] == y[i-1])
	@constraint(model, c[i] == data.c[i]*x[i])
	@constraint(model, h[i] == data.s[i]*y[i])
	@constraint(model, y[i] <= x[i] + s[i])
	@constraint(model, u[i] == d[i] - e[i])
	@constraint(model, e[i] <= x[i] - y[i] + s[i])
	@constraint(model, p[i] == data.p[i]*u[i])
end


@objective(model, Min, sum(c[i] + h[i] + p[i] for i in 1:data.n))

optimize!(model)
sol = objective_value(model)
val = value.(x)

printSolution(data, val, sol)

