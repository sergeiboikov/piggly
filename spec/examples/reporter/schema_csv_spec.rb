require "spec_helper"
require "csv"
require "tmpdir"
require "fileutils"

module Piggly

  describe Reporter::SchemaCsv do
    let(:profile) { double(:profile) }
    let(:line_coverage) { double(:line_coverage) }
    let(:tmpdir) { Dir.mktmpdir("piggly-schema-csv") }
    let(:config) { double(:config, :report_root => tmpdir) }
    let(:output_path) { File.join(tmpdir, "schema-coverage.csv") }

    def procedure(schema, name)
      qualified_name = Dumper::QualifiedName.new(schema, name)
      double(:procedure, :name => qualified_name)
    end

    before do
      allow(Compiler::LineCoverage).to receive(:new).with(config).and_return(line_coverage)
    end

    after do
      FileUtils.remove_entry(tmpdir) if File.exist?(tmpdir)
    end

    it "writes schema coverage CSV with headers and aggregated rows" do
      first_public = procedure("public", "alpha")
      second_public = procedure("public", "beta")
      app_proc = procedure("app", "gamma")
      no_schema_proc = procedure(nil, "delta")

      allow(line_coverage).to receive(:calculate).with(first_public, profile).and_return(:cov_public_1)
      allow(line_coverage).to receive(:calculate).with(second_public, profile).and_return(:cov_public_2)
      allow(line_coverage).to receive(:calculate).with(app_proc, profile).and_return(:cov_app)
      allow(line_coverage).to receive(:calculate).with(no_schema_proc, profile).and_return(:cov_no_schema)

      allow(line_coverage).to receive(:summary).with(:cov_public_1).and_return(:percent => 100.0)
      allow(line_coverage).to receive(:summary).with(:cov_public_2).and_return(:percent => 0.0)
      allow(line_coverage).to receive(:summary).with(:cov_app).and_return(:percent => nil)
      allow(line_coverage).to receive(:summary).with(:cov_no_schema).and_return(:percent => 75.0)

      reporter = Reporter::SchemaCsv.new(config, profile, output_path)
      result_path = reporter.report([first_public, second_public, app_proc, no_schema_proc])

      expect(result_path).to eq(output_path)
      expect(File).to exist(output_path)

      rows = CSV.read(output_path, :headers => true)

      expect(rows.headers).to eq(["No", "Schema Name", "Objects Count", "Covered Objects", "Line Coverage Percent"])

      by_schema = rows.each_with_object({}) do |row, hash|
        hash[row["Schema Name"]] = row
      end

      expect(by_schema.fetch("public")["Objects Count"]).to eq("2")
      expect(by_schema.fetch("public")["Covered Objects"]).to eq("1")
      expect(by_schema.fetch("public")["Line Coverage Percent"]).to eq("50.00")

      expect(by_schema.fetch("app")["Objects Count"]).to eq("1")
      expect(by_schema.fetch("app")["Covered Objects"]).to eq("0")
      expect(by_schema.fetch("app")["Line Coverage Percent"]).to eq("0.00")

      expect(by_schema.fetch("<no schema>")["Objects Count"]).to eq("1")
      expect(by_schema.fetch("<no schema>")["Covered Objects"]).to eq("1")
      expect(by_schema.fetch("<no schema>")["Line Coverage Percent"]).to eq("75.00")
    end
  end

end
