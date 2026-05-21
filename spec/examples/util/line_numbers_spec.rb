require 'spec_helper'

module Piggly::Util

  describe LineNumbers do
    describe ".count" do
      it "returns 0 for empty source" do
        expect(LineNumbers.count("")).to eq(0)
        expect(LineNumbers.count(nil)).to eq(0)
      end

      it "counts lines without a trailing newline" do
        expect(LineNumbers.count("a\nb\nc")).to eq(3)
      end

      it "does not over-count when source ends with a newline" do
        expect(LineNumbers.count("a\nb\nc\n")).to eq(3)
      end

      it "counts CRLF sources consistently" do
        expect(LineNumbers.count("a\r\nb\r\nc\r\n")).to eq(3)
      end

      it "matches String#lines for a large trailing-newline body" do
        source = (1..366).map { |i| "line#{i}" }.join("\n") + "\n"
        expect(LineNumbers.count(source)).to eq(366)
        expect(LineNumbers.count(source)).to eq(source.lines.count)
      end
    end

    describe ".at_offset" do
      let(:source) { "a\nb\nc\n" }

      it "returns 1 for empty source" do
        expect(LineNumbers.at_offset("", 0)).to eq(1)
      end

      it "maps byte offsets to 1-based line numbers" do
        expect(LineNumbers.at_offset(source, 0)).to eq(1)
        expect(LineNumbers.at_offset(source, 2)).to eq(2)
        expect(LineNumbers.at_offset(source, 4)).to eq(3)
      end

      it "clamps offsets past EOF to the last line" do
        expect(LineNumbers.at_offset(source, source.length)).to eq(3)
        expect(LineNumbers.at_offset(source, source.length + 10)).to eq(3)
      end

      it "does not report a line beyond count when offset is on trailing newline" do
        source = (1..366).map { |i| "line#{i}" }.join("\n") + "\n"
        max_line = LineNumbers.count(source)

        expect(LineNumbers.at_offset(source, source.length - 1)).to eq(max_line)
        expect(LineNumbers.at_offset(source, source.length)).to eq(max_line)
      end
    end
  end

end
