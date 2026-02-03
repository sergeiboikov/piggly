module Piggly
  module Compiler

    #
    # Calculates line-level coverage from tagged parse tree nodes.
    #
    class LineCoverage
      def initialize(config)
        @config = config
      end

      # Calculate line coverage for a procedure
      # @param procedure [Dumper::ReifiedProcedure, Dumper::SkeletonProcedure]
      # @param profile [Profile]
      # @return [Hash] { line_number => { covered: bool } }
      def calculate(procedure, profile)
        Parser.parser
        
        compiler = TraceCompiler.new(@config)
        
        # Let compile() handle staleness - it will recompile if needed
        data = compiler.compile(procedure)
        
        # Return empty if compilation failed (tree is nil)
        tree = data[:tree]
        return {} if tree.nil?
        
        source = procedure.source(@config)
        
        coverage = {}
        traverse(tree, profile, source, coverage)
        coverage
      end

      # Calculate summary statistics from coverage data
      # @param coverage [Hash] line coverage data from calculate()
      # @return [Hash] { count: Integer, percent: Float }
      def summary(coverage)
        return { count: 0, percent: nil } if coverage.empty?
        
        total_lines = coverage.size
        covered_lines = coverage.count { |_, v| v[:covered] }
        
        {
          count: total_lines,
          percent: total_lines > 0 ? (covered_lines.to_f / total_lines * 100) : nil
        }
      end


    protected

      # Traverse the parse tree and collect coverage data for each line
      # @param node [NodeClass] parse tree node
      # @param profile [Profile] coverage profile with tags
      # @param source [String] source code text
      # @param coverage [Hash] accumulator for line coverage data
      def traverse(node, profile, source, coverage)
        if node.tagged?
          begin
            tag = profile[node.tag_id]
            
            # Get line numbers for this node
            start_line, end_line = node_line_range(node, source)
            
            # Record coverage for each line spanned by this node
            # Skip lines containing only structural keywords (begin, end, declare, etc.)
            if start_line && end_line && start_line > 0 && end_line >= start_line
              (start_line..end_line).each do |line|
                next if excluded_line?(source, line)
                record_line_coverage(coverage, line, tag)
              end
            end
          rescue RuntimeError => e
            # Skip nodes where tag lookup fails (expected for some nodes)
          rescue => e
            # Skip nodes with unexpected errors
          end
        end
        
        # Recurse into child nodes
        if node.respond_to?(:elements) && node.elements
          node.elements.each { |child| traverse(child, profile, source, coverage) }
        end
        
        coverage
      end

      # Check if a source line should be excluded from coverage
      # Lines containing only structural keywords or comments are not executable
      # @param source [String] full source code
      # @param line_number [Integer] 1-based line number
      # @return [Boolean] true if line should be excluded
      def excluded_line?(source, line_number)
        lines = source.split("\n")
        return true if line_number < 1 || line_number > lines.length
        
        line_content = lines[line_number - 1].strip.downcase
        
        # Exclude lines containing only structural keywords or comments
        excluded_patterns = [
          /\A\s*end\s*;\s*\z/i,           # end;
          /\A\s*begin\s*\z/i,             # begin
          /\A\s*declare\s*\z/i,           # declare
          /\A\s*\$\$\s*\z/,               # $$ (dollar quoting)
          /\A\s*\z/,                      # empty lines
          /\A\s*--/,                      # single-line comments (-- ...)
          /\A\s*\/\*.*\*\/\s*\z/          # single-line block comments (/* ... */)
        ]
        
        excluded_patterns.any? { |pattern| line_content =~ pattern }
      end

      # Calculate the line range for a node
      # @param node [NodeClass] parse tree node
      # @param source [String] source code text
      # @return [Array<Integer, Integer>] start_line and end_line, or [nil, nil] if unable to calculate
      def node_line_range(node, source)
        return [nil, nil] unless node.respond_to?(:interval)
        return [nil, nil] unless source.is_a?(String) && !source.empty?
        
        interval = node.interval
        return [nil, nil] unless interval.is_a?(Range)
        
        start_pos = interval.first.to_i
        return [nil, nil] if start_pos < 0
        
        # Handle exclusive ranges (most common in Treetop)
        if interval.exclude_end?
          end_pos = [interval.end.to_i - 1, start_pos].max
        else
          end_pos = interval.end.to_i
        end
        
        # Clamp to source bounds
        source_len = source.length
        start_pos = [start_pos, source_len - 1].min if source_len > 0
        end_pos = [end_pos, source_len - 1].min if source_len > 0
        
        # Calculate line numbers by counting newlines
        # Line numbers are 1-based
        start_line = source[0...start_pos].count("\n") + 1
        end_line = source[0..end_pos].count("\n") + 1
        
        [start_line, end_line]
      end

      # Record coverage data for a specific line
      # @param coverage [Hash] accumulator
      # @param line [Integer] line number
      # @param tag [Tags::AbstractTag] the tag for this node
      def record_line_coverage(coverage, line, tag)
        coverage[line] ||= {
          covered: nil,           # nil = no block/loop tags yet, will be determined by branches if any
          has_block_or_loop: false
        }
        
        case tag.type
        when :block
          # Block tags affect line coverage - line is covered if block was executed
          coverage[line][:has_block_or_loop] = true
          if coverage[line][:covered].nil?
            coverage[line][:covered] = tag.complete?
          else
            coverage[line][:covered] = coverage[line][:covered] && tag.complete?
          end
          
        when :loop
          # A loop is covered if it was executed at least once (any iteration pattern)
          coverage[line][:has_block_or_loop] = true
          loop_executed = loop_was_executed?(tag)
          if coverage[line][:covered].nil?
            coverage[line][:covered] = loop_executed
          else
            coverage[line][:covered] = coverage[line][:covered] && loop_executed
          end
          
        when :branch
          # For lines with only branches, mark as covered if at least one branch was taken
          unless coverage[line][:has_block_or_loop]
            if tag.is_a?(Tags::ConditionalBranchTag)
              branch_taken = tag.true || tag.false
              if coverage[line][:covered].nil?
                coverage[line][:covered] = branch_taken
              else
                coverage[line][:covered] = coverage[line][:covered] || branch_taken
              end
            else
              # Unconditional branches (return, exit, etc.)
              if coverage[line][:covered].nil?
                coverage[line][:covered] = tag.complete?
              else
                coverage[line][:covered] = coverage[line][:covered] || tag.complete?
              end
            end
          end
        end
        
        # Ensure covered has a boolean value (default to false if still nil)
        coverage[line][:covered] = false if coverage[line][:covered].nil?
      end

      # Check if a loop tag indicates the loop was executed at least once
      # For Sonar, partial loop coverage counts as covered
      # @param tag [Tags::AbstractLoopTag] the loop tag
      # @return [Boolean] true if loop was executed (any iteration pattern)
      def loop_was_executed?(tag)
        tag.pass || tag.once || tag.twice || tag.ends
      end
    end

  end
end
