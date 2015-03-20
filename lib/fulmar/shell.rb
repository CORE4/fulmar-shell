require 'open3'

# This shell is part of the fulmar deployment tools
# it can be used stand-alone, though
module Fulmar
  # Implements simple access to shell commands
  class Shell
    VERSION = '1.1.2'

    attr_accessor :debug, :last_output, :last_error, :quiet

    def initialize(path, host = 'localhost')
      @path = (path.nil? || path.empty?) ? '.' : path
      @host = host
      @last_output = []
      @last_error = []
      @debug = false
      @quiet = false
    end

    def run(command)
      command = [command] if command.class == String

      command.unshift "cd #{@path}"

      if local?
        execute("sh -c '#{escape_for_sh(command.join(' && '))}'")
      else
        remote_command = escape_for_sh('/bin/sh -c \'' + escape_for_sh(command.join(' && ')) + '\'')
        execute("ssh #{@host} '#{remote_command}'")
      end
    end

    def local?
      @host == 'localhost'
    end

    protected

    # Run the command and capture the output
    def execute(command)
      # DEBUG, baby!
      puts command if @debug

      stdin, stdout, stderr, wait_thr = Open3.popen3(command)

      # Remove annoying newlines at the end
      @last_output = stdout.readlines.collect(&:chomp)
      @last_error = stderr.readlines.collect(&:chomp)

      stdin.close
      stdout.close
      stderr.close

      @last_error.each { |line| puts line } unless @quiet

      wait_thr.value == 0
    end

    def escape_for_sh(text)
      text.gsub('\\', '\\\\').gsub("'", "'\\\\''")
    end
  end
end
