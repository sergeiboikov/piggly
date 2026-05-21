require "spec_helper"

module Piggly
  describe "GET CURRENT DIAGNOSTICS" do
    include GrammarHelper

    it "can parse a GET CURRENT DIAGNOSTICS statement" do
      body = "GET CURRENT DIAGNOSTICS l_wdc_inserted := ROW_COUNT;"

      node = parse(:statement, body)
      node.should be_statement
    end

    it "can parse a procedure with GET CURRENT DIAGNOSTICS" do
      body = <<-SQL
      DECLARE
        l_wdc_inserted bigint;
      BEGIN
        INSERT INTO foo DEFAULT VALUES;
        GET CURRENT DIAGNOSTICS l_wdc_inserted := ROW_COUNT;
        RETURN l_wdc_inserted;
      END;
      SQL

      node = parse(:start, body.strip.downcase)
      node.count { |e| e.assignment? }.should == 0
      node.count { |e| Parser::Nodes::Return === e }.should == 1
    end
  end
end
