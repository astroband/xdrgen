require "fileutils"

module Xdrgen
  class Output
    attr_reader :source_paths
    attr_reader :output_dir

    def initialize(source_paths, output_dir)
      @source_paths = source_paths
      @output_dir = output_dir
      @files = {}
    end

    def open_file(child_path)
      if @files.has_key?(child_path)
        raise Xdrgen::DuplicateFileError, "Cannot open #{child_path} twice"
      end

      path = File.join @output_dir, child_path
      result = @files[child_path] = OutputFile.new(path)

      yield result if block_given?

      result
    end

    def write(child_path, content)
      open_file(child_path) { |c| c.puts content }
    end

    def close
      @files.values.each(&:close)
    end
  end
end
