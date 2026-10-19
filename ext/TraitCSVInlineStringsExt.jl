# InlineStrings' String15 as a column type of the reader: an implementation, declared in an
# extension of TraitCSV (which counts as TraitCSV, the trait's owner). Loading InlineStrings adds
# one implementation method; no compiled code of the reader is invalidated, unlike CSV.jl's
# CSVInlineStringsExt, which adds methods to CSV's internal functions.
module TraitCSVInlineStringsExt
using TraitWorld
using TraitCSV: CSVColumn, parsecell!, emptylike
using InlineStrings: String15

@implement CSVColumn Vector{String15} begin
    parsecell!(c, s, a, b) = b - a + 1 <= 15 ? (push!(c, String15(SubString(s, a, b))); true) : false
    emptylike(c) = String15[]
end

TraitWorld.@workload begin
    TraitCSV_ = Base.loaded_modules[Base.PkgId(Base.UUID("e712023c-2e26-4d3a-87f2-b4bc91f10df5"), "TraitCSV")]
    TraitCSV_.parse("s,n\nab,1\ncd,2\n"; types = [Int[], Float64[], String15[], String[]])
end

end
