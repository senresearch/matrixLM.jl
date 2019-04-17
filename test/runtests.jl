using Test
using matrixLM

using DataFrames
using Random
using LinearAlgebra
using GLM

@testset "GLM compatible" begin 

    # Tolerance for tests
    tol = 10.0^(-7)
    
    # Dimensions of matrices 
    n = 100
    m = 200
    p = 10
    q = 20
    
    # Generate some matrices.
    Random.seed!(4)
    X = rand(n,p)
    Z = rand(m,q)
    B = rand(1:20,p,q)
    E = randn(n,m)
    Y = X*B*transpose(Z)+E
    
    # Data frame to be passed into lm
    GLMData = DataFrame(hcat(vec(Y), kron(Z,X)))
    
    # Put together the formula for lm (no intercept)
    vlist = vcat(names(GLMData)[2:end], "-1")
    rhs = join(vlist," + ")
    fm = Formula(:x1, Meta.parse(rhs))
    
    # lm estimate
    GLMEst = lm(fm, GLMData)
    
    # Put together RawData object for MLM
    MLMData = RawData(Response(Y), Predictors(X, Z))
    
    # mlm estimate
    MLMEst = mlm(MLMData, isXIntercept = false, isZIntercept = false)
    
    @test isapprox(GLM.coef(GLMEst), vec(matrixLM.coef(MLMEst)), atol=tol)
    @test isapprox(GLM.predict(GLMEst), vec(matrixLM.predict(MLMEst).Y), atol=tol)
    @test LinearAlgebra.issymmetric(round.(MLMEst.sigma, digits=10)) # and also positive semi-definite?

end


# Tests for variance shrinkage, WLS
# Contrasts
# Permutations