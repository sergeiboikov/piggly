module Piggly
  module Reporter

    class Index < Base

      def initialize(config, profile)
        @config, @profile = config, profile
        @line_coverage = Compiler::LineCoverage.new(config)
      end

      def report(procedures, index)
        io = File.open("#{report_path}/index.html", "w")

        # Calculate line coverage for all procedures
        all_line_coverage = calculate_all_line_coverage(procedures)
        overall_line_summary = @line_coverage.summary(all_line_coverage)

        html(io) do
          tag :html do
            tag :head do
              tag :title, "Piggly PL/pgSQL Code Coverage"
              tag :meta, :charset => "utf-8"
              tag :link, :rel => "stylesheet", :type => "text/css", :href => "piggly.css"
              tag :script, "<!-- -->", :type => "text/javascript", :src => "sortable.js"
            end

            tag :body do
              aggregate("PL/pgSQL Coverage Summary", @profile.summary, overall_line_summary)
              table(procedures.sort_by{|p| index.label(p) }, index)
              timestamp
            end
          end
        end
      ensure
        io.close
      end

    private

      # Calculate combined line coverage summary for all procedures
      # Returns aggregated coverage data that can be passed to @line_coverage.summary()
      def calculate_all_line_coverage(procedures)
        all_coverage = {}
        next_key = 1  # Use sequential keys to avoid collisions
        
        procedures.each do |procedure|
          begin
            coverage = @line_coverage.calculate(procedure, @profile)
            # Add each line's coverage data with a unique key
            # Keys don't need to represent actual line numbers for summary calculation
            coverage.each do |_line, data|
              all_coverage[next_key] = data
              next_key += 1
            end
          rescue => e
            $stderr.puts "Index: ERROR calculating coverage for #{procedure.name}: #{e.class}: #{e.message}"
          end
        end
        all_coverage
      end

      def table(procedures, index)
        tag :div, :class => "table-wrapper" do
          tag :table, :class => "summary sortable" do
            tag :tr do
              tag :th, "Procedure"
              tag :th, "Lines"
              tag :th, "Blocks"
              tag :th, "Loops"
              tag :th, "Branches"
              tag :th, "Line Coverage"
              tag :th, "Block Coverage"
              tag :th, "Loop Coverage"
              tag :th, "Branch Coverage"
            end

            procedures.each_with_index do |procedure, k|
              summary = @profile.summary(procedure)
              row     = k.modulo(2) == 0 ? "even" : "odd"
              label   = index.label(procedure)

              # Calculate line coverage for this procedure
              line_summary = nil
              begin
                coverage = @line_coverage.calculate(procedure, @profile)
                line_summary = @line_coverage.summary(coverage)
              rescue => e
                # Skip if can't calculate
              end

              tag :tr, :class => row do
                unless summary.include?(:block) or summary.include?(:loop) or summary.include?(:branch)
                  # Parser couldn't parse this file
                  tag :td, label, :class => "file fail"
                  tag(:td, :class => "count") { tag :span, -1 }
                  tag(:td, :class => "count") { tag :span, -1 }
                  tag(:td, :class => "count") { tag :span, -1 }
                  tag(:td, :class => "count") { tag :span, -1 }
                  tag(:td, :class => "pct") { tag :span, -1 }
                  tag(:td, :class => "pct") { tag :span, -1 }
                  tag(:td, :class => "pct") { tag :span, -1 }
                  tag(:td, :class => "pct") { tag :span, -1 }
                else
                  tag(:td, :class => "file") { tag :a, label, :href => procedure.identifier + ".html" }
                  tag :td, (line_summary ? line_summary[:count] : 0), :class => "count"
                  tag :td, (summary[:block][:count]  || 0), :class => "count"
                  tag :td, (summary[:loop][:count]   || 0), :class => "count"
                  tag :td, (summary[:branch][:count] || 0), :class => "count"
                  tag(:td, :class => "pct") { percent(line_summary ? line_summary[:percent] : nil) }
                  tag(:td, :class => "pct") { percent(summary[:block][:percent])  }
                  tag(:td, :class => "pct") { percent(summary[:loop][:percent])   }
                  tag(:td, :class => "pct") { percent(summary[:branch][:percent]) }
                end
              end

            end
          end
        end
      end

      def percent(pct)
        if pct
          tag :table, :align => "center" do
            tag :tr do
              tag :td, "%0.2f%%&nbsp;" % pct, :class => "num"

              style =
                case pct.to_f
                when 0;      "zero"
                when 0...30; "low"
                when 0...60; "mid"
                when 0...99; "high"
                else         "full"
                end

              tag :td, :class => "graph" do
                if pct
                  tag :table, :align => "right", :class => "graph #{style}" do
                    tag :tr do
                      covered_width = (pct/2.0).round
                      tag :td, :class => "covered", :width => covered_width
                      tag :td, :class => "uncovered", :width => (50 - covered_width)
                    end
                  end
                end
              end
            end
          end
        else
          tag :span, -1, :style => "display:none"
        end
      end
    end

  end
end
