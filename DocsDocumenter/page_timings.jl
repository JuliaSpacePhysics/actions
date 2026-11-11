# Preloaded (`julia -L`) before docs/make.jl: records per-page wall time of Documenter's
# ExpandTemplates stage, where @example/@repl/@setup blocks run, as `page<TAB>seconds`
# lines to $DOCS_PAGE_TIMINGS (stdout when unset).
#
# Hooks Documenter's selector pipelines: a never-matching expander placed first sees each
# page's first node, so a page's time runs until the next page starts; a builder step right
# after ExpandTemplates closes the last page and writes the file.
using Documenter: Documenter, Selectors

const PAGE_TIMES = Pair{String, Float64}[]
const PAGE_START = Ref{Union{Nothing, Tuple{String, Float64}}}(nothing)

function lap_page!(next)
    t = time()
    cur = PAGE_START[]
    isnothing(cur) || push!(PAGE_TIMES, cur[1] => t - cur[2])
    PAGE_START[] = isnothing(next) ? nothing : (next, t)
    return
end

abstract type PageTimer <: Documenter.Expanders.ExpanderPipeline end
Selectors.order(::Type{PageTimer}) = 0.0
function Selectors.matcher(::Type{PageTimer}, node, page, doc)
    src = relpath(page.source, doc.user.source)
    cur = PAGE_START[]
    (isnothing(cur) || cur[1] != src) && lap_page!(src)
    return false
end

abstract type PageTimingReport <: Documenter.Builder.DocumentPipeline end
Selectors.order(::Type{PageTimingReport}) = 2.5
function Selectors.runner(::Type{PageTimingReport}, doc)
    lap_page!(nothing)
    path = get(ENV, "DOCS_PAGE_TIMINGS", "")
    io = isempty(path) ? stdout : open(path, "w")
    try
        for (src, t) in PAGE_TIMES
            println(io, src, '\t', round(t; digits = 2))
        end
    finally
        io === stdout || close(io)
    end
    empty!(PAGE_TIMES)
    return
end
