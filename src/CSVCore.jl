# CSVCore: the trait module. The column types a reader can produce are a trait:
#   - `CSVColumn{T} <: Column`: a column the reader parses cells into, cell by cell; what it
#     produces is a column of a TraitTables table as it is. `Vector{Int}`, `Vector{Float64}`, the
#     two with missing cells (an empty cell) and `Vector{String}` conform here; another cell type conforms by a conformance in its own
#     package or in an extension (InlineStrings' `String15`: ext/TraitCSVInlineStringsExt.jl).
#     A conformance is a method of the conformance registry, so adding one invalidates no
#     compiled code of the reader: this is what CSV.jl's package extensions become.
#   - The reader tries the candidate column types in order, per column; each attempt runs a
#     worker compiled per column type, the key, and kept in the image of the package that
#     declared the conformance.
@trait_module module CSVCore
using TraitWorld
using TraitTables: TraitTables, Column, Table
export CSVColumn, parsecell!, emptylike, defaulttypes, addtype!, readtable

"A column the reader parses cells into: `parsecell!` appends the cell `s[a:b]` or returns `false` (the column type does not fit)."
@trait CSVColumn{T} <: Column begin
    T = eltype(Self)
    parsecell!(c::CSVColumn, s::String, a::Int, b::Int)::Bool
    emptylike(c::CSVColumn)::Self
end
@implement CSVColumn Vector{Int} begin
    parsecell!(c, s, a, b) = (x = tryparse(Int, SubString(s, a, b)); x === nothing ? false : (push!(c, x); true))
    emptylike(c) = Int[]
end
@implement CSVColumn Vector{Float64} begin
    parsecell!(c, s, a, b) = (x = tryparse(Float64, SubString(s, a, b)); x === nothing ? false : (push!(c, x); true))
    emptylike(c) = Float64[]
end
# columns with missing cells: an empty cell is `missing` (tried after the columns without)
@implement CSVColumn Vector{Union{Missing,Int}} begin
    parsecell!(c, s, a, b) = b < a ? (push!(c, missing); true) :
        (x = tryparse(Int, SubString(s, a, b)); x === nothing ? false : (push!(c, x); true))
    emptylike(c) = Union{Missing,Int}[]
end
@implement CSVColumn Vector{Union{Missing,Float64}} begin
    parsecell!(c, s, a, b) = b < a ? (push!(c, missing); true) :
        (x = tryparse(Float64, SubString(s, a, b)); x === nothing ? false : (push!(c, x); true))
    emptylike(c) = Union{Missing,Float64}[]
end
@implement CSVColumn Vector{String} begin
    parsecell!(c, s, a, b) = (push!(c, String(SubString(s, a, b))); true)
    emptylike(c) = String[]
end

"The column types tried by default, in order: `Int`, `Float64`, the two with missing cells, `String`."
defaulttypes() = CSVColumn[Dynamic{CSVColumn}(Int[]), Dynamic{CSVColumn}(Float64[]), Dynamic{CSVColumn}(Union{Missing,Int}[]),
                           Dynamic{CSVColumn}(Union{Missing,Float64}[]), Dynamic{CSVColumn}(String[])]
"Append a candidate column type (an empty column of it) to `types`."
addtype!(types::Vector{CSVColumn}, c::CSVColumn) = (push!(types, c); types)

# --- scanning: the cells' spans, per column (plain code over bytes) --------------------------------

"Header names and, per column, the byte ranges of its cells (quotes stripped). Blank lines are skipped."
function scan(s::String, delim::UInt8)
    b = codeunits(s)
    n = length(b)
    names = String[]
    spans = Vector{UnitRange{Int}}[]
    row = UnitRange{Int}[]
    i = 1
    header = true
    while i <= n
        # one row
        empty!(row)
        while true
            if i <= n && b[i] == UInt8('"')
                a = i + 1
                i = a
                while i <= n && !(b[i] == UInt8('"') && (i == n || b[i+1] != UInt8('"')))
                    i += b[i] == UInt8('"') ? 2 : 1
                end
                push!(row, a:i-1)
                i += 1
            else
                a = i
                while i <= n && b[i] != delim && b[i] != UInt8('\n') && b[i] != UInt8('\r')
                    i += 1
                end
                push!(row, a:i-1)
            end
            if i <= n && b[i] == delim
                i += 1
                continue
            end
            break
        end
        while i <= n && (b[i] == UInt8('\r') || b[i] == UInt8('\n'))
            i += 1
        end
        length(row) == 1 && isempty(row[1]) && continue          # a blank line
        if header
            append!(names, [String(SubString(s, first(r), last(r))) for r in row])
            append!(spans, [UnitRange{Int}[] for _ in row])
            header = false
        else
            length(row) == length(names) ||
                throw(ArgumentError("a row has $(length(row)) cells, the header $(length(names)): $(repr(SubString(s, first(row[1]), max(last(row[end]), first(row[1])))))"))
            for k in eachindex(row)
                push!(spans[k], row[k])
            end
        end
    end
    return names, spans
end

# --- reading: a worker per candidate column type ------------------------------------------------

"Parse every cell into `c`; the filled column, or `nothing` at the first cell that does not fit."
function fillcolumn(c::CSVColumn, s::String, spans::Vector{UnitRange{Int}})::Union{Nothing,Dynamic{Column}}
    for r in spans
        parsecell!(c, s, first(r), last(r)) || return nothing
    end
    return Dynamic{Column}(c)
end

"Read CSV text into a table; each column gets the first of `types` whose cells all parse."
function readtable(s::String, delim::UInt8, types::Vector{CSVColumn})::Table
    names, spans = scan(s, delim)
    t = TraitTables.TableCore.emptytable()
    for k in eachindex(names)
        col = nothing
        for c in types
            col = fillcolumn(emptylike(c), s, spans[k])::Union{Nothing,Dynamic{Column}}
            col === nothing || break
        end
        col === nothing && throw(ArgumentError("column \"$(names[k])\": no column type fits its cells"))
        push!(t.names, names[k])
        push!(t.cols, col)
    end
    return t
end

end
