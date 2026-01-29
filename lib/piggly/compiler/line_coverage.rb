module Piggly
  module Compiler

    #
    # Calculates line-level coverage from tagged parse tree nodes.
    # Used by both HTML and Sonar reporters to ensure consistent metrics.
    #
    class LineCoverage
      def initialize(config)
        @config = config
      end

      # Calculate line coverage for a procedure
      # @param procedure [Dumper::ReifiedProcedure, Dumper::SkeletonProcedure]
      # @param profile [Profile]
      # @return [Hash] { line_number => { covered: bool, branches_to_cover: int, covered_branches: int } }
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

      # Calculate branch coverage summary from coverage data
      # @param coverage [Hash] line coverage data from calculate()
      # @return [Hash] { branches_to_cover: Integer, covered_branches: Integer, percent: Float }
      def branch_summary(coverage)
        total_branches = 0
        covered_branches = 0
        
        coverage.each do |_, line_data|
          total_branches += line_data[:branches_to_cover] || 0
          covered_branches += line_data[:covered_branches] || 0
        end
        
        {
          branches_to_cover: total_branches,
          covered_branches: covered_branches,
          percent: total_branches > 0 ? (covered_branches.to_f / total_branches * 100) : nil
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
            if start_line && end_line && start_line > 0 && end_line >= start_line
              (start_line..end_line).each do |line|
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
          has_block_or_loop: false,
          branches_to_cover: 0,
          covered_branches: 0
        }
        
        case tag.type
        when :block, :loop
          # Block and loop tags affect line coverage
          # Line is covered only if ALL block/loop tags are complete
          coverage[line][:has_block_or_loop] = true
          if coverage[line][:covered].nil?
            coverage[line][:covered] = tag.complete?
          else
            coverage[line][:covered] = coverage[line][:covered] && tag.complete?
          end
          
        when :branch
          # Branch tags contribute to branch coverage metrics
          if tag.is_a?(Tags::ConditionalBranchTag)
            # Conditional branches have true/false paths
            coverage[line][:branches_to_cover] += 2
            coverage[line][:covered_branches] += (tag.true ? 1 : 0) + (tag.false ? 1 : 0)
            
            # For lines with only branches, mark as covered if at least one branch was taken
            unless coverage[line][:has_block_or_loop]
              branch_taken = tag.true || tag.false
              if coverage[line][:covered].nil?
                coverage[line][:covered] = branch_taken
              else
                # Multiple branches: covered if ANY branch was taken (OR logic for branch-only lines)
                coverage[line][:covered] = coverage[line][:covered] || branch_taken
              end
            end
          else
            # Unconditional branches (return, exit, etc.)
            coverage[line][:branches_to_cover] += 1
            coverage[line][:covered_branches] += tag.complete? ? 1 : 0
            
            # For lines with only branches, mark as covered if this branch was executed
            unless coverage[line][:has_block_or_loop]
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
    end

  end
end
