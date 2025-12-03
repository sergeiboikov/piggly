#!/usr/bin/env ruby
# encoding: utf-8

# Script to reproduce the encoding bug with Cyrillic comments in SQL

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'piggly'

# Read the SQL file with Cyrillic comments
sql_file = File.join(__dir__, 'sql', 'update_quality.sql')
sql_content = File.read(sql_file, encoding: 'UTF-8')

puts "=" * 80
puts "Testing Piggly parser with Cyrillic comments"
puts "=" * 80
puts
puts "SQL File: #{sql_file}"
puts "SQL Content encoding: #{sql_content.encoding}"
puts "SQL Content length: #{sql_content.length} chars"
puts

# Extract just the function body for parsing
# Piggly parser expects only the function body, not CREATE FUNCTION wrapper
body_match = sql_content.match(/AS \$function\$(.*)\$function\$/m)

if body_match
  function_body = body_match[1].strip
  
  puts "Function body encoding: #{function_body.encoding}"
  puts "Function body preview (first 200 chars):"
  puts function_body[0..200]
  puts
  puts "-" * 80
  puts "Attempting to parse..."
  puts "-" * 80
  puts
  
  begin
    # This should trigger the encoding error
    tree = Piggly::Parser.parse(function_body)
    tree.force!  # Force evaluation of the thunk
    
    puts "SUCCESS: Parsing completed without errors!"
    puts "Tree: #{tree.inspect[0..200]}"
  rescue => e
    puts "ERROR REPRODUCED!"
    puts
    puts "Exception class: #{e.class}"
    puts "Exception message: #{e.message}"
    puts
    puts "Backtrace (first 10 lines):"
    puts e.backtrace[0..9].join("\n")
  end
else
  puts "ERROR: Could not extract function body from SQL file"
  puts "Make sure the file contains: AS $function$....$function$"
end

puts
puts "=" * 80

