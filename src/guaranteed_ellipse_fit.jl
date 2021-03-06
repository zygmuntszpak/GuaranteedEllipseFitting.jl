function (method::GuaranteedEllipseFit)(observations::AbstractObservations)
    @unpack parametrisation = method  
    @unpack optimisation_scheme = method
    @unpack seed = optimisation_scheme

    πβ = to_latent_parameters(parametrisation, seed.π)
    optimisation_scheme = @set optimisation_scheme.seed = ManualEstimation(πβ)
    N = length(observations.data[1])
    jacobian_matrix = JacobianMatrix(observations, zeros(N,5)) 

    optimisation_result = optimisation_scheme(observations, jacobian_matrix)   
    πβ = optimisation_result.minimiser

    if (method.verbose)
        cost = optimisation_result.minimum
        info_str = optimisation_result.info_str
        @info "AML Cost: $cost"
        @info info_str
    end

    # TODO Remove parametrisation option and just always use "SecondLatentEllipseParametrisation". 
    # The lm method below assumes "SecondLatentEllipseParametrisation".
    π = from_latent_parameters(parametrisation, πβ)   
    return π / norm(π)
end

function (lm::LevenbergMarquardt)(observations::AbstractObservations, jacobian_matrix::JacobianMatrix)
    @unpack data = observations
    @unpack Ξ³, Ξ³_inc, Ξ³_dec = lm
    @unpack Ξ», Ξ»_lower_bound = lm
    @unpack tol_π, tol_cost, tol_Ξ, tol_β = lm
    @unpack max_iter = lm
    @unpack seed = lm
    @unpack max_func_eval = lm

    # minimum allowable magnitude of conic determinant to prevent ellipse from
    # convering on a degenarate parabola (e.g. two parallel lines).
    tol_detD = 1e-5
    # barrier tolerance tp prevent ellipse from convering on parabola.
    tol_barrier = 15.5

    πβ = seed.π

    info_str = ""
    keep_going = true
    theta_updated = false
    func_eval = 0
    k = 1

    βπ« = jacobian_matrix
    πβ = from_latent_parameters(SecondLatentEllipseParametrisation(), πβ)
    Ξβ = ones(length(πβ))

    N = length(first(data))
    π« = vector_valued_objective(observations, πβ)
    # Sum of squared residuals: π«'*π«
    costβ = sum(abs2, π«)

    π = UniformScaling(1)
    πβ = SA_F64[0 0 2; 0 -1 0; 2 0 0]
    π = SA_F64[1 0; 0 0] β πβ

    was_updated = false
    while keep_going && k < max_iter

        πβ = from_latent_parameters(SecondLatentEllipseParametrisation(), πβ)
        π« = vector_valued_objective(observations, πβ)
        π = βπ«(πβ)
        π = π'*π       

        πβ = UniformScaling(1) - (πβ*πβ')/norm(πβ)^2
        βΟ = norm(πβ)^-1 * πβ *  βπ(πβ)
        π = (βΟ'*βΟ) 

        # Compute two potential updates based on different weightings of π.
        Ξ»β = max(Ξ»,  Ξ»_lower_bound)
        Ξβ = -(π + Ξ»β*π) \ (π'*π«)
        πβ = πβ + Ξβ        

        Ξ»β = max(Ξ» / Ξ³,  Ξ»_lower_bound)
        Ξβ = -(π + Ξ»β*π) \ (π'*π«)
        πβ = πβ + Ξβ

        πβ = from_latent_parameters(SecondLatentEllipseParametrisation(), πβ)
        πβ = from_latent_parameters(SecondLatentEllipseParametrisation(), πβ)
        

        # Compute new residuals and costs based on these updates.
        π«β = vector_valued_objective(observations, πβ)
        costβ = sum(abs2, π«β)
        π«β = vector_valued_objective(observations, πβ)
        costβ = sum(abs2, π«β)

        if costβ >= costβ && costβ >= costβ
            # Neither potential update reduced the cost.
            was_updated = false
            πβββ = πβ
            πβββ = πβ
            Ξβββ = Ξβ
            costβββ = costβ
            Ξ» = Ξ» * Ξ³ # In the next iteration add more of the identity matrix.
            func_eval = func_eval + 1
        elseif costβ < costβ
            # Update (2) reduced the cost function.
            was_updated = true
            πβββ = πβ
            πβββ = πβ
            Ξβββ = Ξβ
            costβββ = costβ
            Ξ» = Ξ» / Ξ³  # In the next iteration add less of the identity matrix.
        else
            # Update (1) reduced the cost function.
            was_updated = true
            πβββ = πβ
            πβββ = πβ
            Ξβββ = Ξβ
            costβββ = costβ
            Ξ» = Ξ»  # Keep the same damping for the next iteration.
        end

        barrier = (πβββ'*π*πβββ)/(πβββ'*π*πβββ)
        D = SA_F64[πβββ[1] πβββ[2]/2 πβββ[4]/2 ;
                   πβββ[2]/2 πβββ[3] πβββ[5]/2 ;
                   πβββ[4]/2 πβββ[5]/2 πβββ[6]]
    
        detD = det(D)

        # Since π is a projective entity this converge criterion will have
        # to change to take into account the scale/sign ambiguity.
        if min(norm(πβββ - πβ), norm(πβββ + πβ)) < tol_π && was_updated
            info_str = "Breaking because of tolerance."
            keep_going = false
        elseif abs(costβββ - costβ) < tol_cost && was_updated
            info_str = "Breaking because of cost."
            keep_going = false
        elseif norm(Ξβββ) < tol_Ξ
            info_str = "Breaking because of update norm."
            keep_going = false
        elseif  norm(π'*π«, Inf) < tol_β
            info_str = "Breaking because of gradient norm."
            keep_going = false
        elseif func_eval > max_func_eval
            info_str = "Breaking because maximum func evaluations reached."
            keep_going = false
        elseif log(barrier) > tol_barrier || abs(detD) < tol_detD
            info_str = "Breaking because approaching degenerate ellipse."
            keep_going = false
        end

        πβ = πβββ
        Ξβ = Ξβββ
        costβ = costβββ
        k = was_updated ? k + 1 : k
    end

    return OptimisationResult(πβ, costβ, info_str)
end


function vector_valued_objective(observations::AbstractObservations, π::AbstractVector)
    @unpack data = observations
    β³ = data[1]
    N = length(β³)
    π« = zeros(N)
    for n = 1:N
        π¦ = β³[n]
        π?β = SA_F64[π¦[1]^2, π¦[1]*π¦[2], π¦[2]^2, π¦[1], π¦[2], 1]
        βπ?β = SA_F64[2*π¦[1]  π¦[2]  0  1  0  0; 0 π¦[1] 2*π¦[2] 0 1 0]'
        πβ = π?β * π?β'
        π²β =  SA_F64[1 0 ; 0 1]
        πβ = βπ?β * π²β * βπ?β'
        π«[n] = sqrt(abs((π' * πβ * π)/(π' * πβ * π)))
    end
    return π«
end


function to_latent_parameters(::FirstLatentEllipseParametrisation, π::AbstractVector)
    p = π[2] / (2*π[1])
    q = ((π[3] / π[1]) - (π[2]/(2*π[1]))^2)^(-0.5)
    r = (π[4] / π[1])
    s = (π[5] / π[1])
    t = (π[6] / π[1])
    return SVector(p, q, r, s, t)
end

function from_latent_parameters(::FirstLatentEllipseParametrisation, π::AbstractVector)
    p, q, r, s, t = π
    a = 1
    b = 2*p
    c = p^2 + q^(-2)
    d = r
    e = s
    f = t
    π = SVector(a, b, c, d, e ,f)
    return π / norm(π)
end

function to_latent_parameters(::SecondLatentEllipseParametrisation, π::AbstractVector)
    p = π[2] / (2*π[1])
    q = ((π[3] / π[1]) - (π[2]/(2*π[1]))^2)^(0.5)
    r = (π[4] / π[1])
    s = (π[5] / π[1])
    t = (π[6] / π[1])
    return SVector(p, q, r, s, t)
end

function from_latent_parameters(::SecondLatentEllipseParametrisation, π::AbstractVector)
    p, q, r, s, t = π
    a = 1
    b = 2*p
    c = p^2 + q^(2)
    d = r
    e = s
    f = t
    π = SVector(a, b, c, d, e ,f)
    return π / norm(π)
end

function βπ(π)
    return SA_F64[0      0       0 0 0 ;
                  2      0       0 0 0 ;
                  2*π[1] 2*π[2]  0 0 0 ;
                  0      0       1 0 0 ;
                  0      0       0 1 0 ;
                  0      0       0 0 1]
end

function (jacobian_matrix::JacobianMatrix)(π::AbstractVector)
    @unpack observations = jacobian_matrix
    @unpack data = observations
    β³ = data[1]
    N = length(β³)
   
    π = from_latent_parameters(SecondLatentEllipseParametrisation(), π)
   
    πβ = UniformScaling(1) - (π*π')/norm(π)^2
    βΟ = norm(π)^-1 * πβ *  βπ(π)
    # TODO overwrite the pre-allocated array instead (for performance).
    βπ«β² = zeros(N, 5)
    for n = 1:N
        π¦ = β³[n]
        π?β = SA_F64[π¦[1]^2, π¦[1]*π¦[2], π¦[2]^2, π¦[1], π¦[2], 1]
        βπ?β = SA_F64[2*π¦[1]  π¦[2]  0  1  0  0; 0 π¦[1] 2*π¦[2] 0 1 0]'
        πβ = π?β * π?β'
        π²β =  SA_F64[1 0 ; 0 1]
        πβ = βπ?β * π²β * βπ?β'
        πβ = πβ / (π' * πβ * π)
        πβ =  πβ - πβ * ((π' * πβ * π)/ (π' * πβ * π)^2)
        βπ« = (πβ*π / sqrt(abs((π' * πβ * π) / (π' * πβ * π)) + eps()))'
        βπ«β²[n,:] = βπ« * βΟ 
     end
    return βπ«β²
end