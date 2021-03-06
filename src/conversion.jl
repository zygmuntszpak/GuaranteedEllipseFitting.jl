function (::GeometricToAlgebraic)(š::AbstractVector)
    A, B, H, K, Ļ = š    

    a = cos(Ļ)^2/A^2 + sin(Ļ)^2/B^2
    b = (1/A^2 - 1/B^2)*sin(2*Ļ)
    c = (cos(Ļ)^2/B^2) + sin(Ļ)^2/A^2;
    d = (2*sin(Ļ)*(K*cos(Ļ)-H*sin(Ļ))) / B^2 - (2*cos(Ļ)^2*(H+K*tan(Ļ))) / A^2
    e = (2*cos(Ļ)*(H*sin(Ļ) - K*cos(Ļ))) / B^2 - (2*sin(Ļ)*(H*cos(Ļ) + K*sin(Ļ))) / A^2
    f = (H*cos(Ļ) + K*sin(Ļ))^2 / A^2 + (K*cos(Ļ) - H*sin(Ļ))^2 / B^2 - 1

    š = SVector(a, b, c, d, e, f)
    return š
end

function (::AlgebraicToGeometric)(š::AbstractVector)
    a, b, c, d, e, f  = š   
    Ī = b^2 - 4*a*c
    Ī»ā = 0.5*(a + c - (b^2 + (a - c)^2)^0.5)
    Ī»ā = 0.5*(a + c + (b^2 + (a - c)^2)^0.5)

    Ļ = b*d*e - a*e^2 - b^2*f + c*(4*a*f - d^2)
    Vā = (Ļ/(Ī»ā*Ī))^0.5
    Vā = (Ļ/(Ī»ā*Ī))^0.5

    # major semi-axis
    A = max(Vā, Vā)
    # minor semi-axis
    B = min(Vā, Vā)

    # determine x-coordinate of ellipse centroid
    H = (2*c*d - b*e)/(Ī)
    # determine y-coordinate of ellipse centroid
    K = (2*a*e - b*d)/(Ī)

    # angle between x-axis and major axis 
    Ļ = 0
    # determine tilt of ellipse in radians
    if Vā >= Vā
        if (b == 0 && a < c)
            Ļ = 0
        elseif (b == 0 && a >= c)
            Ļ  = 0.5*Ļ
        elseif (b < 0 && a < c)
            Ļ  = 0.5*acot((a - c)/b)
        elseif (b < 0 && a == c) 
            Ļ = Ļ/4
        elseif (b < 0 && a > c)
            Ļ = 0.5*acot((a - c)/b) + Ļ/2
        elseif (b > 0 && a < c)
            Ļ = 0.5*acot((a - c)/b) + Ļ
        elseif (b > 0 && a == c)
            Ļ = Ļ*(3/4)
        elseif (b > 0 && a > c)
            Ļ = 0.5*acot((a - c)/b) + Ļ/2
        end
    elseif Vā < Vā
        if (b == 0 && a < c)
            Ļ = Ļ/2
        elseif (b == 0 && a >= c)
            Ļ = 0
        elseif (b < 0 && a < c)
            Ļ = 0.5*acot((a - c)/b) + Ļ/2
        elseif (b < 0 && a == c)
            Ļ = Ļ*(3/4)
        elseif (b < 0 && a > c)
            Ļ = 0.5*acot((a - c)/b) + Ļ
        elseif (b > 0 && a < c)
            Ļ = 0.5*acot((a - c)/b) + Ļ/2
        elseif (b > 0 && a == c)
            Ļ = Ļ/4
        elseif (b > 0 && a > c)
            Ļ = 0.5*acot((a - c)/b)
        end
    end
    š = SVector(A, B, H, K, Ļ)
    return š
end