using Test, TraitCSV, TraitTables, TraitWorld
using InlineStrings: String15

@testset "TraitCSV" begin
    t = TraitCSV.parse("a,b,c,d\n1,2.5,x,7\n2,3.5,\"y, z\",8.5\n\n3,4,w,9\n")
    @test colnames(t) == ["a", "b", "c", "d"]
    @test t.cols isa Vector{Dynamic{Column}}
    d = describe(t)
    @test [s.eltype for s in d] == ["Int64", "Float64", "String", "Float64"]
    @test d[1].sum == 6.0 && d[2].mean == 10 / 3
    @test cell(t["c"], 2) == "y, z"
    # the user's choice of column types; String15 from the extension
    t2 = TraitCSV.parse("s,n\nab,1\nthis is longer than fifteen,2\n"; types = [Int[], String15[], String[]])
    @test describe(t2)[1].eltype == "String" && describe(t2)[2].eltype == "Int64"
    t3 = TraitCSV.parse("s\nab\ncd\n"; types = [Int[], String15[], String[]])
    @test describe(t3)[1].eltype == "String15"
    # a conformance by a package that owns neither the trait nor the type is refused (rule 3)
    @test_throws Exception @eval @implement CSVColumn Vector{Bool} begin
        parsecell!(c, s, a, b) = false
        emptylike(c) = Bool[]
    end
    @test_throws ArgumentError TraitCSV.parse("a,b\n1\n")
    path = tempname() * ".csv"
    write(path, "x;y\n1;2\n")
    @test size(TraitCSV.read(path; delim = ';')) == (1, 2)
end
