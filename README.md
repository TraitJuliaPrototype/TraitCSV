# TraitCSV

A CSV reader written in the trait world, producing TraitTables tables: the reader half of TraitReport's form (t) (`../TraitReport/README.md`). Decided in session 26 as the principled fix for CSV.jl's invalidations (`../writeup/decisions.md`); first version in session 27.

- **`CSVColumn{T} <: Column`** (`src/CSVCore.jl`): the columns the reader can parse into, `parsecell!(c, s, a, b)` and `emptylike(c)`. Implementations: `Vector{Int}`, `Vector{Float64}`, `Vector{Union{Missing, Int}}` and `Vector{Union{Missing, Float64}}` (an empty cell is missing; session 30), `Vector{String}`; InlineStrings' `String15` in the extension `ext/TraitCSVInlineStringsExt.jl`.
- **What package extensions become:** CSV.jl's `CSVInlineStringsExt` adds methods to CSV's internal functions and so discards CSV's compiled read path whenever InlineStrings loads, also for files without strings. Here the extension declares one implementation, a method of the `conformance` registry, which invalidates no compiled code of the reader (TraitReport row 11).
- **Reading:** a byte scan finds the cells' spans per column; per column, the candidate column types are tried in order (`types = [Int[], Float64[], String15[], String[]]`; by default `Int`, `Float64`, the two with missing cells, `String`), each attempt a worker compiled per column type. Quoted cells may hold the delimiter; an empty cell is missing in a numeric column, an empty string in a strings column.
- **Definition checking at work:** a `sizehint!` on a trait object in the first draft was refused when the package compiled, naming the line: `sizehint!` is not an operation of `CSVColumn`.

Tests: `julia --project=. -e 'using Pkg; Pkg.test()'` (13, with the extension, a refused implementation by a package that owns neither trait nor type, and missing cells).
