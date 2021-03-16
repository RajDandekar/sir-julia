# Ordinary differential equation model
Simon Frost (@sdwfrost), 2020-04-27

## Introduction

The classical ODE version of the SIR model is:

- Deterministic
- Continuous in time
- Continuous in state

## Libraries

```julia
using DifferentialEquations
using SimpleDiffEq
using DataFrames
using StatsPlots
using BenchmarkTools
```




## Transitions

The following function provides the derivatives of the model, which it changes in-place. State variables and parameters are unpacked from `u` and `p`; this incurs a slight performance hit, but makes the equations much easier to read.

```julia
function sir_ode!(du,u,p,t)
    (S,I,R) = u
    (β,c,γ) = p
    N = S+I+R
    @inbounds begin
        du[1] = -β*c*I/N*S
        du[2] = β*c*I/N*S - γ*I
        du[3] = γ*I
    end
    nothing
end;
```




## Time domain

We set the timespan for simulations, `tspan`, initial conditions, `u0`, and parameter values, `p` (which are unpacked above as `[β,γ]`).

```julia
δt = 0.1
tmax = 40.0
tspan = (0.0,tmax)
t = 0.0:δt:tmax;
```




## Initial conditions

```julia
u0 = [990.0,10.0,0.0]; # S,I.R
```




## Parameter values

```julia
p = [0.05,10.0,0.25]; # β,c,γ
```




## Running the model

```julia
prob_ode = ODEProblem(sir_ode!,u0,tspan,p);
```


```julia
sol_ode = solve(prob_ode);
```




## Post-processing

We can convert the output to a dataframe for convenience.

```julia
df_ode = DataFrame(sol_ode(t)')
df_ode[!,:t] = t;
```




## Plotting

We can now plot the results.

```julia
@df df_ode plot(:t,
    [:x1 :x2 :x3],
    label=["S" "I" "R"],
    xlabel="Time",
    ylabel="Number")
```

![](figures/ode_9_1.png)



## Benchmarking

```julia
@benchmark solve(prob_ode)
```

```
BenchmarkTools.Trial: 
  memory estimate:  30.94 KiB
  allocs estimate:  303
  --------------
  minimum time:     23.174 μs (0.00% GC)
  median time:      26.267 μs (0.00% GC)
  mean time:        31.533 μs (7.52% GC)
  maximum time:     8.013 ms (98.62% GC)
  --------------
  samples:          10000
  evals/sample:     1
```


