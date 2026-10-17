# TraitCSV

A CSV reader written in the trait world, producing TraitTables tables: the reader half of TraitReport's form (t) (`../TraitReport/README.md`). Decided in session 26 as the principled fix for CSV.jl's invalidations (`../writeup/decisions.md`); first version in session 27.

- **`CSVColumn{T} <: Column`** (`src/CSVCore.jl`): the columns the reader can parse into, `parsecell!(c, s, a, b)` and `emptylike(c)`. Conformances: `Vector{Int}`, `Vector{Float64}`, `Vector{String}`; InlineStrings' `String15` in the extension `ext/TraitCSVInlineStringsExt.jl`.
- **What package extensions become:** CSV.jl's `CSVInlineStringsExt` adds methods to CSV's internal functions and so discards CSV's compiled read path whenever InlineStrings loads, also for files without strings. Here the extension declares one conformance, a method of the conformance registry, which invalidates no compiled code of the reader (TraitReport row 11).
- **Reading:** a byte scan finds the cells' spans per column; per column, the candidate column types are tried in order (`types = [Int[], Float64[], String15[], String[]]`, default `Int`, `Float64`, `String`), each attempt a worker compiled per column type. Quoted cells may hold the delimiter; missing values are not handled yet.
- **Definition checking at work:** a `sizehint!` on a trait object in the first draft was refused when the package compiled, naming the line: `sizehint!` is not an operation of `CSVColumn`.

Tests: `julia --project=. -e 'using Pkg; Pkg.test()'` (10, with the extension and a refused conformance by a package that owns neither trait nor type).
