module Piggly
  module Reporter

    #
    # Generates SonarQube generic test coverage XML format.
    #
    # Format specification:
    # https://docs.sonarsource.com/sonarqube-server/latest/analyzing-source-code/test-coverage/generic-test-data/
    #
    class Sonar < Base

      def initialize(config, profile, output_path = nil)
        @config = config
        @profile = profile
        @output_path = output_path || File.join(@config.report_root, "sonar-coverage.xml")
        @line_coverage = Compiler::LineCoverage.new(config)
      end

      # Generate Sonar coverage report for all procedures
      # @param procedures [Array<Dumper::ReifiedProcedure>] list of procedures
      def report(procedures)
        FileUtils.makedirs(File.dirname(@output_path))
        
        File.open(@output_path, "w:UTF-8") do |io|
          io.puts '<?xml version="1.0" encoding="UTF-8"?>'
          io.puts '<coverage version="1">'
          
          procedures.each do |procedure|
            begin
              write_procedure_coverage(io, procedure)
            rescue => e
              # Skip procedures that can't be processed
              $stderr.puts "Warning: Could not generate Sonar coverage for #{procedure.name}: #{e.message}"
            end
          end
          
          io.puts '</coverage>'
        end
        
        @output_path
      end

    private

      # Write coverage data for a single procedure
      def write_procedure_coverage(io, procedure)
        coverage = @line_coverage.calculate(procedure, @profile)
        return if coverage.empty?
        
        # Get the source file path and convert to relative path
        absolute_path = procedure.source_path(@config)
        source_path = make_relative_path(absolute_path)
        
        io.puts "  <file path=\"#{escape_xml(source_path)}\">"
        
        # Sort lines and output coverage data
        coverage.keys.sort.each do |line|
          line_data = coverage[line]
          write_line_coverage(io, line, line_data)
        end
        
        io.puts "  </file>"
      end

      # Write coverage data for a single line
      def write_line_coverage(io, line_number, line_data)
        attrs = []
        attrs << "lineNumber=\"#{line_number}\""
        attrs << "covered=\"#{line_data[:covered]}\""
        
        io.puts "    <lineToCover #{attrs.join(' ')}/>"
      end

      # Escape special XML characters
      def escape_xml(text)
        text.to_s
          .gsub("&", "&amp;")
          .gsub("<", "&lt;")
          .gsub(">", "&gt;")
          .gsub("\"", "&quot;")
          .gsub("'", "&apos;")
      end

      # Convert absolute path to relative path from project root for cross-platform compatibility
      def make_relative_path(absolute_path)
        project_root = File.dirname(File.dirname(@config.cache_root))
        
        relative = absolute_path.sub(/^#{Regexp.escape(project_root)}[\/\\]?/, '')
        relative.gsub('\\', '/')
      end
    end

  end
end
