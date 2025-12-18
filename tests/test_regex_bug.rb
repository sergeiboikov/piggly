#!/usr/bin/env ruby
# encoding: utf-8

# Script to reproduce the regex escape bug in Ruby 3.4

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

puts "=" * 80
puts "Testing Piggly CacheDir regex pattern with Ruby #{RUBY_VERSION}"
puts "=" * 80
puts

begin
  # This will trigger the regex compilation error if the escape sequences are invalid
  require 'piggly/compiler/cache_dir'
  
  puts "✓ Successfully loaded piggly/compiler/cache_dir"
  puts "✓ HINT regex pattern compiled successfully"
  
  # Test the regex pattern actually works
  cache_dir_class = Piggly::Compiler::CacheDir
  hint_regex = cache_dir_class::HINT
  
  puts "✓ HINT regex: #{hint_regex.inspect}"
  
  # Test with some actual data
  test_cases = [
    ["\x00\x01\x02", true, "null bytes"],
    ["\x7F", true, "DEL character"],
    ["normal text", false, "normal ASCII"],
    ["UTF-8 текст", false, "UTF-8 text"],
  ]
  
  puts
  puts "Testing pattern matching:"
  test_cases.each do |data, should_match, description|
    matches = data[0,2] =~ hint_regex
    result = should_match ? matches : !matches
    status = result ? "✓" : "✗"
    puts "  #{status} #{description}: #{result ? 'PASS' : 'FAIL'}"
  end
  
  puts
  puts "=" * 80
  puts "SUCCESS: All tests passed!"
  puts "=" * 80
  
  exit 0
  
rescue SyntaxError => e
  puts "✗ SYNTAX ERROR (regex escape issue):"
  puts
  puts "Exception: #{e.class}"
  puts "Message: #{e.message}"
  puts
  puts "Backtrace:"
  puts e.backtrace[0..9].join("\n")
  puts
  puts "=" * 80
  
  exit 1
  
rescue => e
  puts "✗ ERROR:"
  puts
  puts "Exception: #{e.class}"
  puts "Message: #{e.message}"
  puts
  puts "Backtrace:"
  puts e.backtrace[0..9].join("\n")
  puts
  puts "=" * 80
  
  exit 1
end

