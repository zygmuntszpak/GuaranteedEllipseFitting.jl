function (::DirectEllipseFit)(observations::AbstractObservations)
    @unpack data = observations
    # # Convert the N x 2 matrix to a one-dimensional array of 2D points. 
    # ā³ = svectors(transpose(data[1]), Val{2}())
    ā³ = data[1]
    N = length(ā³)
    šā = zeros(N, 3)
    šā = zeros(N, 3)
    for n = 1:N
        š¦ = ā³[n]
        # Quadratic part of the design matrix.
        šā[n, 1] = š¦[1]^2
        šā[n, 2] = š¦[1]*š¦[2]
        šā[n, 3] = š¦[2]^2
        # Linear part of the design matrix.
        šā[n, 1] = š¦[1]
        šā[n, 2] = š¦[2]
        šā[n, 3] = 1.0
    end
    # Quadratic part of the scatter matrix.
    šā = šā' * šā 
    # Combined part of the scatter matrix.
    šā = šā' * šā 
    # Linear part of the scatter matrix.
    šā = šā' * šā 
    # For getting aā from aā.
    š = -inv(šā) * šā' 
    # Reduce scatter matrix.
    š = šā + šā * š
    # Premultiply by inv(Cā).
    šā = vcat(š[3,:]' / 2, -š[2,:]', š[1,:]' / 2) 
    # Solve eigensystem.
    F = eigen(šā) 
    evec = F.vectors
    evalue = F.values
    # Evaluate a'Ca.
    cond = 4 * evec[1,:] .* evec[3,:] - evec[2,:].^2
    index = findfirst(cond .> 0)
    # Ellipse coefficients.
    šā = SVector(evec[:, index]...)
    š = vcat(šā, š * šā)
    return š / norm(š)
end