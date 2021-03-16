# Function map
Simon Frost (@sdwfrost), 2020-04-27

## Introduction

The function map approach taken here is:

- Deterministic
- Discrete in time
- Continuous in state

## Libraries

```julia
using DifferentialEquations
using SimpleDiffEq
using DataFrames
using StatsPlots
using BenchmarkTools
```




## Utility functions

To assist in comparison with the continuous time models, we define a function that takes a constant rate, `r`, over a timespan, `t`, and converts it to a proportion.

```julia
@inline function rate_to_proportion(r::Float64,t::Float64)
    1-exp(-r*t)
end;
```




## Transitions

We define a function that takes the 'old' state variables, `u`, and writes the 'new' state variables into `du.` Note that the timestep, `δt`, is passed as an explicit parameter.

```julia
function sir_map!(du,u,p,t)
    (S,I,R) = u
    (β,c,γ,δt) = p
    N = S+I+R
    infection = rate_to_proportion(β*c*I/N,δt)*S
    recovery = rate_to_proportion(γ,δt)*I
    @inbounds begin
        du[1] = S-infection
        du[2] = I+infection-recovery
        du[3] = R+recovery
    end
    nothing
end;
```




## Time domain

Note that even though I'm using fixed time steps, `DifferentialEquations.jl` complains if I pass integer timespans, so I set the timespan to be `Float64`.

```julia
δt = 0.1
nsteps = 400
tmax = nsteps*δt
tspan = (0.0,nsteps)
t = 0.0:δt:tmax;
```




## Initial conditions

Note that we define the state variables as floating point.

```julia
u0 = [990.0,10.0,0.0];
```




## Parameter values

```julia
p = [0.05,10.0,0.25,δt]; # β,c,γ,δt
```




## Running the model

```julia
prob_map = DiscreteProblem(sir_map!,u0,tspan,p);
```


```julia
sol_map = solve(prob_map,solver=FunctionMap);
```




## Post-processing

We can convert the output to a dataframe for convenience.

```julia
df_map = DataFrame(sol_map')
df_map[!,:t] = t;
```




## Plotting

We can now plot the results.

```julia
@df df_map plot(:t,
    [:x1 :x2 :x3],
    label=["S" "I" "R"],
    xlabel="Time",
    ylabel="Number")
```

![](figures/function_map_10_1.png)



## Benchmarking

```julia
@benchmark solve(prob_map,solver=FunctionMap)
```

```
BenchmarkTools.Trial: 
  memory estimate:  57.52 KiB
  allocs estimate:  446
  --------------
  minimum time:     48.987 μs (0.00% GC)
  median time:      53.770 μs (0.00% GC)
  mean time:        62.717 μs (6.67% GC)
  maximum time:     7.752 ms (91.60% GC)
  --------------
  samples:          10000
  evals/sample:     1
```


