using Test

@testset "Manual case 1" begin
    @eval module Case1
        using HackRecursion: @reduce
        f(x, y, val::Val) = f(Base.tail(x), (y..., x[1]), val)
        f(x::Tuple{Any,Vararg}, y::NTuple{N,Any}, ::Val{N}) where {N} = x, y
        f(::Tuple{}, y, ::Val) = (), y
    end
    @test_throws ErrorException @inferred(Case1.f((1,2,3,4,5,6), (), Val(3))) == ((4,5,6), (1,2,3))
    @eval Case1 @reduce f([x], y, val::Val) = f(Base.tail(x), (y..., x[1]), val)
    @test @inferred(Case1.f((1,2,3,4,5,6), (), Val(3))) == ((4,5,6), (1,2,3))

    @eval Case1 @reduce f([x], y, [val::Val]) = f(Base.tail(x), (y..., x[1]), val)
    @test_throws ErrorException @inferred(Case1.f((1,2,3,4,5,6), (), Val(3))) == ((4,5,6), (1,2,3))

    @eval Case1 @reduce f(x, [y], [val::Val]) = f(Base.tail(x), (y..., x[1]), val)
    @test_throws ErrorException @inferred(Case1.f((1,2,3,4,5,6), (), Val(3))) == ((4,5,6), (1,2,3))

    @eval Case1 @reduce f(x, [y], val::Val) = f(Base.tail(x), (y..., x[1]), val)
    @test_throws ErrorException @inferred(Case1.f((1,2,3,4,5,6), (), Val(3))) == ((4,5,6), (1,2,3))

    @eval Case1 @reduce f([x], [y], val::Val) = f(Base.tail(x), (y..., x[1]), val)
    @test_throws ErrorException @inferred(Case1.f((1,2,3,4,5,6), (), Val(3))) == ((4,5,6), (1,2,3))

    @eval Case1 @reduce [f](x, [y], val::Val) = f(Base.tail(x), (y..., x[1]), val)
    @test_throws ErrorException @inferred(Case1.f((1,2,3,4,5,6), (), Val(3))) == ((4,5,6), (1,2,3))
end
