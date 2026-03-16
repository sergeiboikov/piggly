require "csv"
require "fileutils"

module Piggly
  module Reporter

    #
    # Generates schema-level coverage summary in CSV format.
    #
    class SchemaCsv < Base
      HEADERS = ["No", "Schema Name", "Objects Count", "Covered Objects", "Line Coverage Percent"].freeze
      NO_SCHEMA = "<no schema>".freeze

      def initialize(config, profile, output_path = nil)
        @config = config
        @profile = profile
        @output_path = output_path || File.join(@config.report_root, "coverage_by_schema.csv")
        @line_coverage = Compiler::LineCoverage.new(config)
      end

      # Generate CSV schema coverage report for all procedures
      # @param procedures [Array<Dumper::ReifiedProcedure>] list of procedures
      def report(procedures)
        FileUtils.makedirs(File.dirname(@output_path))
        aggregates = aggregate_by_schema(procedures)

        CSV.open(@output_path, "wb:UTF-8") do |csv|
          csv << HEADERS

          aggregates.each_with_index do |row, index|
            csv << [
              index + 1,
              row[:schema_name],
              row[:objects_count],
              row[:covered_objects],
              format("%0.2f", row[:coverage_percent])
            ]
          end
        end

        @output_path
      end

    private

      def aggregate_by_schema(procedures)
        grouped = Hash.new do |hash, key|
          hash[key] = {
            schema_name: key,
            objects_count: 0,
            covered_objects: 0,
            coverage_values: []
          }
        end

        procedures.each do |procedure|
          schema_name = schema_label(procedure)
          row = grouped[schema_name]
          row[:objects_count] += 1

          begin
            percent = line_coverage_percent(procedure)
            next if percent.nil?

            row[:covered_objects] += 1 if percent > 0.0
            row[:coverage_values] << percent
          rescue => e
            $stderr.puts "Warning: Could not calculate schema CSV coverage for #{procedure.name}: #{e.message}"
          end
        end

        grouped.keys.sort.map do |schema_name|
          row = grouped[schema_name]
          values = row[:coverage_values]
          average = values.empty? ? 0.0 : values.inject(0.0, :+) / values.size

          {
            schema_name: row[:schema_name],
            objects_count: row[:objects_count],
            covered_objects: row[:covered_objects],
            coverage_percent: average
          }
        end
      end

      def schema_label(procedure)
        schema = procedure.name.schema.to_s.strip
        schema.empty? ? NO_SCHEMA : schema
      end

      def line_coverage_percent(procedure)
        coverage = @line_coverage.calculate(procedure, @profile)
        @line_coverage.summary(coverage)[:percent]
      end
    end

  end
end
