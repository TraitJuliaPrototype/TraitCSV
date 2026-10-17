"""
    TraitCSV

A CSV reader written in the trait world (`CSVCore`), producing TraitTables tables. The column
types it can produce are a trait, `CSVColumn`; a cell type of another package joins by a
conformance (InlineStrings' `String15`, in an extension), which invalidates no compiled code of
the reader. This module is the ordinary layer: `TraitCSV.read(path)`.
"""
module TraitCSV
using TraitWorld
using TraitTables: TraitTables, Table

include("CSVCore.jl")
using .CSVCore
export CSVColumn

"""
    TraitCSV.read(path; delim = ',', types = nothing) -> TraitTables.Table

Read a CSV file. Each column gets the first column type in `types` whose cells all parse: by
default `Int`, `Float64`, `String`. `types` lists empty columns of the candidate types, in order,
for instance `[Int[], Float64[], String15[], String[]]`.
"""
function read(path::AbstractString; delim::Union{Char,UInt8} = ',', types = nothing)
    return parse(Base.read(path, String); delim, types)
end
"Read CSV text (see `TraitCSV.read`)."
function parse(text::AbstractString; delim::Union{Char,UInt8} = ',', types = nothing)
    ts = CSVCore.defaulttypes()
    if types !== nothing
        empty!(ts)
        for c in types
            CSVCore.addtype!(ts, c)
        end
    end
    return CSVCore.readtable(String(text), UInt8(delim), ts)
end

# a precompile workload: every default column type, quoted cells, and a file
TraitWorld.@workload begin
    t = parse("a,b,c\n1,2.5,x\n2,3.5,\"y, z\"\n")
    TraitTables.summary_text(t)
    path = tempname() * ".csv"
    Base.write(path, "x,y\n0.1,1\n0.2,2\n")
    TraitTables.summary_text(read(path))
    rm(path; force = true)
end

end
