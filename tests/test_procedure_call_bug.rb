#!/usr/bin/env ruby
# encoding: utf-8

# Script to reproduce the CALL statement parsing bug in Piggly
# PostgreSQL 11+ allows procedures to call other procedures using CALL statement
# Piggly's parser doesn't recognize this syntax

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'piggly'

puts "=" * 80
puts "Testing Piggly parser with CALL statement (PostgreSQL procedures)"
puts "=" * 80
puts

# Procedure body with CALL statement (from update_quality_outer)
procedure_body = <<~PLPGSQL
  begin
  	call public.update_quality_procedure(p_caller_id => p_param_id);
  end;
PLPGSQL

puts "Procedure body:"
puts "-" * 80
puts procedure_body
puts "-" * 80
puts
puts "Body encoding: #{procedure_body.encoding}"
puts "Body length: #{procedure_body.length} chars"
puts

puts "=" * 80
puts "Attempting to parse with Piggly::Parser..."
puts "=" * 80
puts

begin
  # This should trigger the parser error
  tree = Piggly::Parser.parse(procedure_body)
  tree.force!  # Force evaluation of the thunk
  
  puts "SUCCESS: Parsing completed without errors!"
  puts "Tree: #{tree.inspect[0..200]}"
rescue => e
  puts "ERROR REPRODUCED!"
  puts
  puts "Exception class: #{e.class}"
  puts "Exception message: #{e.message}"
  puts
  if e.respond_to?(:line) && e.respond_to?(:column)
    puts "Error location: line #{e.line}, column #{e.column}"
  end
  puts
  puts "Backtrace (first 10 lines):"
  puts e.backtrace[0..9].join("\n")
  puts
  puts "=" * 80
  puts "DIAGNOSIS:"
  puts "=" * 80
  puts "Piggly's parser doesn't recognize the CALL statement syntax."
  puts "CALL is used in PostgreSQL 11+ to invoke procedures from within procedures."
  puts "The parser expects: /*, --, :=, or = after 'begin'"
  puts "But encounters: 'call' which is not in its grammar."
end

puts
puts "=" * 80

