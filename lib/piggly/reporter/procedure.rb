module Piggly
  module Reporter

    class Procedure < Base

      def initialize(config, profile)
        @config, @profile = config, profile
        @line_coverage = Compiler::LineCoverage.new(config)
      end

      def report(procedure)
        io = File.open(report_path(procedure.source_path(@config), ".html"), "w")

        begin
          compiler = Compiler::CoverageReport.new(@config)
          data     = compiler.compile(procedure, @profile)

          # Calculate line coverage for this procedure
          line_summary = nil
          begin
            coverage = @line_coverage.calculate(procedure, @profile)
            line_summary = @line_coverage.summary(coverage)
          rescue => e
            # Skip if can't calculate
          end

          html(io) do
            tag :html, :xmlns => "http://www.w3.org/1999/xhtml" do
              tag :head do
                tag :title, "Code Coverage: #{procedure.name}"
                tag :meta, :charset => "utf-8"
                tag :link, :rel => "stylesheet", :type => "text/css", :href => "piggly.css"
                tag :script, "<!-- -->", :type => "text/javascript", :src => "highlight.js"
              end

              tag :body do
                tag :div, :class => "header" do
                  aggregate(procedure.name, @profile.summary(procedure), line_summary)
                end

                tag :div, :class => "container" do
                  tag :div, :class => "listing" do
                    tag :table do
                      tag :tr do
                        tag :td, "&nbsp;", :class => "signature"
                        tag :td, signature(procedure), :class => "signature"
                      end

                      tag :tr do
                        tag :td, data[:lines].to_a.map{|n| %[<a href="#L#{n}" id="L#{n}">#{n}</a>] }.join("\n"), :class => "lines"
                        tag :td, data[:html], :class => "code"
                      end
                    end
                  end

                  toc(@profile[procedure])
                end

                tag :a, "Return to index", :href => "index.html", :class => "return"

                timestamp

              end
            end
          end
        ensure
          io.close
        end
      end

    private

      def signature(procedure)
        keyword = procedure.prokind == "p" ? "procedure" : "function"
        string = "<span class='tK'>create function</span> <b><span class='tI'>#{procedure.name}</span></b>"

        if procedure.arg_names.size <= 1
          string   << " ( "
          separator = ", "
          spacer    = " "
        else
          string   << "\n\t( "
          separator = ",\n\t  "
          spacer    = "\t"
        end

        arguments = procedure.arg_types.zip(procedure.arg_modes, procedure.arg_names).map do |atype, amode, aname|
          amode &&= "<span class='tK'>#{amode.downcase}</span>#{spacer}"
          aname &&= "<span class='tI'>#{aname}</span>#{spacer}"
          "#{amode}#{aname}<span class='tD'>#{atype}</span>"
        end.join(separator)

        string << arguments << " )"

        if procedure.prokind != "p"
          string << "\n<span class='tK'>returns#{procedure.setof ? ' setof' : ''}</span>"

          if procedure.type.table?
            fields = procedure.type.types.zip(procedure.type.names).map do |rtype, rname|
              rname = "<span class='tI'>#{rname}</span>\t"
              rtype = "<span class='tD'>#{rtype}</span>"
              "#{rname}#{rtype}"
            end.join(",\n\t")

            string << " <span class='tK'>table</span> (\n\t" << fields << " )"
          else
            string << " <span class='tD'>#{procedure.type.shorten}</span>"
          end
        end

        string << "\n  <span class='tK'>language #{procedure.language}</span>"
        string << "\n  <span class='tK'>security definer</span>" if procedure.secdef
        string << "\n  <span class='tK'>strict</span>" if procedure.strict
        string << "\n  <span class='tK'>#{procedure.volatility.downcase}</span>" if procedure.prokind != "p"

        string
      end

      def toc(tags)
        todo = tags.reject{|t| t.complete? }

        tag :div, :class => 'toc' do
          tag :strong, 'Notes'

          tag :ol do
            todo.each do |t|
              tag(:li, :class => t.type) do
                tag :a, t.description, :href => "#T#{t.id}",
                  :onMouseOver => "highlight('T#{t.id}')"
              end
            end
          end unless todo.empty?
        end
      end

    end

  end
end
