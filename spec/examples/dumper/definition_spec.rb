require "spec_helper"

module Piggly
  module Dumper

    describe SkeletonProcedure, "definition" do
      def qname(schema, name)
        QualifiedName.new(schema, name)
      end

      def qtype(*args)
        QualifiedType.parse(*args)
      end

      it "quotes user-defined types but not built-in types" do
        expect(qtype("character varying").quote).to eq("varchar")
        expect(qtype("pg_catalog", "varchar").quote).to eq("varchar")
        expect(qtype("bigint").quote).to eq("bigint")
        expect(qtype("private", "mytype").quote).to eq('"private"."mytype"')
      end

      it "generates valid SQL for functions with table return columns" do
        procedure = ReifiedProcedure.new(
          "begin end;",
          1,
          qname("public", "f_test_function"),
          false,
          false,
          true,
          qtype("pg_catalog", "varchar"),
          "volatile",
          %w[in in in t],
          %w[p_payment_session_id p_payment_type_start p_payment_type_end type_mnemo].map { |n| qname(nil, n) },
          ["bigint", "character varying", "character varying", "character varying"].map { |t| qtype(t) },
          [nil, nil, nil, nil]
        )

        sql = procedure.definition("begin end;")

        expect(sql).to include('in "p_payment_session_id" bigint')
        expect(sql).to include('in "p_payment_type_start" varchar')
        expect(sql).to include('returns table ("type_mnemo" varchar)')
        expect(sql).not_to include('t "type_mnemo"')
        expect(sql).not_to include('"varchar"')
      end
    end

  end
end
