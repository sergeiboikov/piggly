module Piggly
  module Compiler
    autoload :CacheDir,       "piggly/compiler/cache_dir"
    autoload :TraceCompiler,  "piggly/compiler/trace_compiler"
    autoload :CoverageReport, "piggly/compiler/coverage_report"
    autoload :LineCoverage,   "piggly/compiler/line_coverage"
  end
end
