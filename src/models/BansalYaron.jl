##############################################################################
##
## Type
##
##############################################################################

type BansalYaronModel  <: EconPDEModel
    # consumption process parameters
    μbar::Float64 
    νD::Float64
    κμ::Float64 
    κσ::Float64 
    νμ::Float64 
    νσ::Float64 

    # utility parameters
    ρ::Float64  
    γ::Float64 
    ψ::Float64
end

function BansalYaronModel(;μbar = 0.018, νD = 0.027, κμ = 0.252, κσ = 0.156, νμ = 0.0143, νσ = 0.131, ρ = 0.024, γ = 7.5, ψ = 1.5)
    BansalYaronModel(μbar, νD, κμ, κσ, νμ, νσ, ρ, γ, ψ)
end

function StateGrid(m::BansalYaronModel; μn = 30, σn = 30)
    μbar = m.μbar ; νD = m.νD ; κμ = m.κμ ; κσ = m.κσ ; νμ = m.νμ ; νσ = m.νσ ; ρ = m.ρ ; γ = m.γ ; ψ = m.ψ

    σ = sqrt(νσ^2 / (2 * κσ))
    σmin = max(0.01, quantile(Normal(1.0, σ), 0.001))
    σmax = quantile(Normal(1.0, σ), 0.999)
    σs = collect(linspace(σmin, σmax, σn))

    σ = sqrt(νμ^2 / (2 * κμ))
    μmin = quantile(Normal(μbar, σ), 0.001)
    μmax = quantile(Normal(μbar, σ), 0.999)
    μs = collect(linspace(μmin, μmax, μn))

    StateGrid(μ = μs, σ = σs)
end

function initialize(m::BansalYaronModel, grid::StateGrid)
    fill(1.0, size(grid)...)
end

function pde(m::BansalYaronModel, grid, y, ituple, idrift = (0.0, 0.0))
    μbar = m.μbar ; νD = m.νD ; κμ = m.κμ ; κσ = m.κσ ; νμ = m.νμ ; νσ = m.νσ ; ρ = m.ρ ; γ = m.γ ; ψ = m.ψ
    μ, σ = grid[ituple]
    p, pμ, pσ, pμμ, pμσ, pσσ = derive(grid, y[1], ituple, idrift)
    μC = μ
    σC = νD * sqrt(σ)
    μμ = κμ * (μbar - μ)
    σZ1μ = νμ * sqrt(σ)
    μσ = κσ * (1 - σ)
    σZ2σ = νσ 
    σZ1pμ = pμ / p * σZ1μ
    σZ2pσ = pσ / p * σZ2σ
    σ2p = σZ1pμ^2 + σZ2pσ^2
    μp = pμ / p * μμ + pσ / p * μσ + 0.5 * pμμ / p * σZ1μ^2 + 0.5 * pσσ / p * σZ2σ^2
    out = p * (1 / p - ρ + (1 - 1 / ψ) * (μC - 0.5 * γ * σC^2) + μp + 0.5 * (1 / ψ - γ) / (1 - 1 / ψ) * σ2p)
    return out, (μμ, μσ), (:p => p, :μμ => μμ, :σZ1μ => σZ1μ, :σZ2μ => 0.0, :μσ => μσ, :σZ1σ => 0.0, :σZ2σ => σZ2σ, :μ => μ, :σ => σ, :σ2μ => σZ1μ^2, :σ2σ => σZ2σ^2, :σμσ => 0.0)
end