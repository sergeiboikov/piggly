#!/usr/bin/env ruby
# encoding: utf-8

# Script to reproduce the "cannot change routine kind" bug in Piggly
# PostgreSQL 11+ distinguishes between FUNCTIONS and PROCEDURES
# - Functions: have return types, called with SELECT
# - Procedures: no return type, called with CALL statement
# 
# Bug: Piggly's SkeletonProcedure.definition() always generates
# "CREATE OR REPLACE FUNCTION" even for procedures, causing PostgreSQL
# to reject it with "ERROR: cannot change routine kind"

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'piggly'

puts "=" * 80
puts "Testing Piggly SkeletonProcedure.definition() with PROCEDURE"
puts "=" * 80
puts

# Simulate the data that would come from PostgreSQL for a PROCEDURE
# Note: In PostgreSQL 11+, procedures are in pg_proc with prokind='p'
# They have prorettype = 2278 (void) but are NOT functions

puts "Creating mock PROCEDURE object (update_quality_outer)..."
puts "-" * 80

# Create QualifiedName and QualifiedType objects
schema_name = "public"
proc_name = "update_quality_outer"
qualified_name = Piggly::Dumper::QualifiedName.new(schema_name, proc_name)

# Procedures in PostgreSQL have void return type
void_type = Piggly::Dumper::QualifiedType.new("pg_catalog", "void", "")

# Procedure arguments (in p_param_id bigint)
arg_modes = ["in"]
arg_names = [Piggly::Dumper::QualifiedName.new(nil, "p_param_id")]
arg_types = [Piggly::Dumper::QualifiedType.parse("bigint")]
arg_defaults = [nil]

# Procedure body - contains CALL statement
procedure_source = <<~PLPGSQL.strip
begin
	call public.update_quality_procedure(p_caller_id => p_param_id);
end;
PLPGSQL

puts "Procedure details:"
puts "  Name: #{qualified_name.quote}"
puts "  Return type: #{void_type.quote}"
puts "  Arguments: #{arg_modes.zip(arg_names, arg_types).map{|m,n,t| "#{m} #{n.quote} #{t.quote}"}.join(", ")}"
puts "  Source body:"
procedure_source.lines.each { |line| puts "    #{line}" }
puts "-" * 80
puts

# Create a SkeletonProcedure object (this is what Piggly creates internally)
skeleton_procedure = Piggly::Dumper::SkeletonProcedure.new(
  12345,              # oid (fake)
  qualified_name,     # name
  false,              # strict
  true,               # secdef (security definer)
  false,              # setof
  void_type,          # type
  "volatile",         # volatility
  arg_modes,          # arg_modes
  arg_names,          # arg_names
  arg_types,          # arg_types
  arg_defaults,       # arg_defaults
  'p'                 # prokind ('p' = procedure, 'f' = function)
)

puts "=" * 80
puts "Generating SQL with SkeletonProcedure.definition()..."
puts "=" * 80
puts

generated_sql = skeleton_procedure.definition(procedure_source)

puts "Generated SQL:"
puts "-" * 80
puts generated_sql
puts "-" * 80
puts

puts "=" * 80
puts "VERIFICATION"
puts "=" * 80
puts

expected_sql = <<~SQL.strip
create or replace procedure "public"."update_quality_outer" (in "p_param_id" "int8")
 language plpgsql security definer as $__PIGGLY__$
begin
	call public.update_quality_procedure(p_caller_id => p_param_id);
end;
$__PIGGLY__$
SQL

if generated_sql.gsub(/\s+/, ' ').strip == expected_sql.gsub(/\s+/, ' ').strip
  puts "✓ SUCCESS! The generated SQL is correct."
  puts "  - Uses 'CREATE OR REPLACE PROCEDURE' (not FUNCTION)"
  puts "  - No RETURNS clause (procedures don't return values)"
  puts "  - Correct syntax for PostgreSQL 11+"
else
  puts "✗ PROBLEM DETECTED!"
  puts
  puts "The generated SQL uses 'CREATE OR REPLACE FUNCTION' but PostgreSQL"
  puts "requires 'CREATE OR REPLACE PROCEDURE' for procedures."
  puts
  puts "Expected SQL should be:"
  puts "-" * 80
  puts expected_sql
  puts "-" * 80
end
