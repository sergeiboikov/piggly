require 'spec_helper'

module Piggly

  describe Parser, "statements" do
    include GrammarHelper

    describe "single variable declarations" do
      it "parse successfully" do
        node = parse(:stmtDeclare, "declare t text;")
        node.count{|e| e.identifier? }.should == 1
        node.count{|e| e.datatype? }.should == 1
      end

      it "allows an initial assignment" do
        node = parse(:stmtDeclare, "declare a text := 10;")
      end

      it "parses parameterized cursor declarations" do
        parse(:stmtDeclare, <<~SQL)
          declare
            c_lic_acc_value cursor(c_lic_acc_id bigint, c_date_old timestamp) for
              select date_v, beg_val from public.t_table_value where link_lic_acc = c_lic_acc_id;
        SQL
      end

      it "parses cursor declarations without space before parameter list" do
        parse(:stmtDeclare, "declare c cursor(x int) for select 1;")
      end
    end

  end
end
