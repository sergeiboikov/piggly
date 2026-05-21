require "spec_helper"

module Piggly
  describe "standalone transaction statements" do
    include GrammarHelper

    it "can parse commit without trailing expression" do
      node = parse(:statement, "commit;")
      node.should be_statement
      node.count { |e| e.sql? }.should == 1
      node.find { |e| e.sql? }.source_text.should == "commit;"
    end

    it "can parse rollback without trailing expression" do
      node = parse(:statement, "rollback;")
      node.should be_statement
      node.count { |e| e.sql? }.should == 1
    end

    it "can parse a procedure with multiple commit statements" do
      body = <<-SQL
      BEGIN
        call i_schema.create_choice1(p_session_id => l_session_id);
        commit;
        call i_schema.create_choice2(l_session_id);
        commit;
      END;
      SQL

      node = parse(:start, body.strip.downcase)
      node.count { |e| e.sql? }.should == 4
    end
  end
end
