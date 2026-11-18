# TraitCSV

A CSV reader written with traits, producing TraitTables tables. The column types it can produce are a trait, `CSVColumn`. A cell type of another package joins by a membership, in its own package or in an extension; a membership invalidates no compiled code of the reader. This is what CSV.jl's package extensions become.

## The package

- **`TraitCSV`** (`src/TraitCSV.jl`): the ordinary layer. `TraitCSV.read(path; delim = ',', types = nothing)` and `TraitCSV.parse(text; …)` return a `TraitTables.Table`.
- **`CSVCore`** (`src/CSVCore.jl`): the trait module (`@trait_module`).
  - `@trait CSVColumn{T} <: Column{T}`: a column the reader parses cells into, with the operations `parsecell!(c, s, a, b)::Bool` and `emptylike(c)::Self`, and `T = eltype(Self)`.
  - Members: `Vector{Int}`, `Vector{Float64}`, `Vector{Union{Missing,Int}}`, `Vector{Union{Missing,Float64}}`, `Vector{String}`.
  - `defaulttypes()`, `addtype!(types, c)`: the candidate column types, as empty columns in a `Vector{CSVColumn}`; `readtable(s, delim, types)`.
- **The extension** `TraitCSVInlineStringsExt` (`ext/`): `Vector{String15}` joins `CSVColumn` when InlineStrings is loaded.

**Reading.** A byte scan finds each column's cells. Per column, the candidate column types are tried in order (by default `Int`, `Float64`, the two with missing cells, `String`); the first whose cells all parse is taken. Quoted cells may hold the delimiter. An empty cell is `missing` in a numeric column and an empty string in a column of strings.

## How it uses the design

- `CSVColumn` erases nothing by default (no `@default_dynamic`). The candidate columns are plain members in a container typed by the trait. The reader passes each candidate's empty column as it is to `fillcolumn`, and Julia compiles the call for the column's type (`src/CSVCore.jl`). No box or wrapper is made.
- The tests read into a column type of their own (`Flags`) and check that the reader's code was compiled for it (`test/runtests.jl`).

## Running

From the workspace root:

```sh
source env.sh
julia-next/julia --project=TraitCSV -e 'using Pkg; Pkg.test()'
```

The tests read files with and without the extension, refuse a membership declared by a package that owns neither the trait nor the type, and read missing cells.

## Results

The current numbers, each against plain Julia or Python, are in the design repository's `writeup/design/evidence.md`. The suites' last results are in its `writeup/state.md` §3.

- Tests: 14 pass on `julia-unified` (2026-11-08, `unified` f90d152208; `experiments/implementation/stack/logs/w104-slice1-TraitCSV.log`).
- Tests on `julia-next`: 16 pass in 2 testsets (2026-11-18, `next` 02139b2168, TraitWorld 3e64ede; `experiments/implementation/w156/logs/after-csv.log`).

## The design

- The design: the design repository's `writeup/reference/` (traits, facts, compiler, lowering).
- The lessons of the ports: `writeup/intro/porting.md`.
- TraitReport (`../TraitReport/`) reads with this package in its form with traits.
