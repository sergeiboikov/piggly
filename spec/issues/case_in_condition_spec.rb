require "spec_helper"

module Piggly
  describe "SQL CASE in PL/pgSQL conditions" do
    include GrammarHelper

    it "can parse IF with CASE in a function argument" do
      body = <<-SQL
      BEGIN
        IF 0 = public.f_test(
              p_doc_type_mnemo => line_rec.doc_type_mnemo,
              p_person_id => CASE
                               WHEN l_f_sub_acc = 1 THEN p_client_id
                               WHEN l_f_sub_acc = 0 THEN l_person_id
                             END,
              p_repres_id => NULL
            ) THEN
          NULL;
        END IF;
      END;
      SQL

      node = parse(:start, body.strip.downcase)
      node.count { |e| e.if? }.should == 1
    end

    it "can parse ELSIF with CASE in a function argument" do
      body = <<-SQL
      BEGIN
        IF false THEN
          NULL;
        ELSIF 0 = public.f_test(
                p_person_id => CASE WHEN l_flag = 1 THEN p_a ELSE p_b END
              ) THEN
          NULL;
        END IF;
      END;
      SQL

      node = parse(:start, body.strip.downcase)
      node.count { |e| e.if? }.should == 2
    end

    it "does not break simple IF conditions" do
      node = parse(:statement, "IF cond THEN a := 10; END IF;")
      node.should be_statement
      node.count { |e| e.if? }.should == 1
    end
  end
end
