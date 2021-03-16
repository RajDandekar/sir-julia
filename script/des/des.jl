
using ResumableFunctions
using SimJulia
using Distributions
using DataFrames
using Random
using StatsPlots
using BenchmarkTools


function increment!(a::Array{Int64})
    push!(a,a[length(a)]+1)
end

function decrement!(a::Array{Int64})
    push!(a,a[length(a)]-1)
end

function carryover!(a::Array{Int64})
    push!(a,a[length(a)])
end;


mutable struct SIRPerson
    id::Int64 # numeric ID
    status::Symbol # :S,I,R
end;


mutable struct SIRModel
    sim::Simulation
    β::Float64
    c::Float64
    γ::Float64
    ta::Array{Float64}
    Sa::Array{Int64}
    Ia::Array{Int64}
    Ra::Array{Int64}
    allIndividuals::Array{SIRPerson}
end;


function infection_update!(sim::Simulation,m::SIRModel)
    push!(m.ta,now(sim))
    decrement!(m.Sa)
    increment!(m.Ia)
    carryover!(m.Ra)
end;


function recovery_update!(sim::Simulation,m::SIRModel)
    push!(m.ta,now(sim))
    carryover!(m.Sa)
    decrement!(m.Ia)
    increment!(m.Ra)
end;


@resumable function live(sim::Simulation, individual::SIRPerson, m::SIRModel)
  while individual.status==:S
      # Wait until next contact
      @yield timeout(sim,rand(Distributions.Exponential(1/m.c)))
      # Choose random alter
      alter=individual
      while alter==individual
          N=length(m.allIndividuals)
          index=rand(Distributions.DiscreteUniform(1,N))
          alter=m.allIndividuals[index]
      end
      # If alter is infected
      if alter.status==:I
          infect = rand(Distributions.Uniform(0,1))
          if infect < m.β
              individual.status=:I
              infection_update!(sim,m)
          end
      end
  end
  if individual.status==:I
      # Wait until recovery
      @yield timeout(sim,rand(Distributions.Exponential(1/m.γ)))
      individual.status=:R
      recovery_update!(sim,m)
  end
end;


function MakeSIRModel(u0,p)
    (S,I,R) = u0
    N = S+I+R
    (β,c,γ) = p
    sim = Simulation()
    allIndividuals=Array{SIRPerson,1}(undef,N)
    for i in 1:S
        p=SIRPerson(i,:S)
        allIndividuals[i]=p
    end
    for i in (S+1):(S+I)
        p=SIRPerson(i,:I)
        allIndividuals[i]=p
    end
    for i  in (S+I+1):N
        p=SIRPerson(i,:R)
        allIndividuals[i]=p
    end
    ta=Array{Float64,1}(undef,0)
    push!(ta,0.0)
    Sa=Array{Int64,1}(undef,0)
    push!(Sa,S)
    Ia=Array{Int64,1}(undef,0)
    push!(Ia,I)
    Ra=Array{Int64,1}(undef,0)
    push!(Ra,R)
    SIRModel(sim,β,c,γ,ta,Sa,Ia,Ra,allIndividuals)
end;


function activate(m::SIRModel)
     [@process live(m.sim,individual,m) for individual in m.allIndividuals]
end;


function sir_run(m::SIRModel,tf::Float64)
    SimJulia.run(m.sim,tf)
end;


function out(m::SIRModel)
    result = DataFrame()
    result[!,:t] = m.ta
    result[!,:S] = m.Sa
    result[!,:I] = m.Ia
    result[!,:R] = m.Ra
    result
end;


tmax = 40.0;


u0 = [990,10,0];


p = [0.05,10.0,0.25];


Random.seed!(1234);


des_model = MakeSIRModel(u0,p)
activate(des_model)
sir_run(des_model,tmax)


data_des=out(des_model);


@df data_des plot(:t,
    [:S :I :R],
    labels = ["S" "I" "R"],
    xlab="Time",
    ylab="Number")


@benchmark begin
    des_model = MakeSIRModel(u0,p)
    activate(des_model)
    sir_run(des_model,tmax)
end

