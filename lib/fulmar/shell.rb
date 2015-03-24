require 'open3'

# This shell is part of the fulmar deployment tools
# it can be used stand-alone, though
module Fulmar
  # Implements simple access to shell commands
  class Shell
    VERSION = '1.3.0'

    attr_accessor :debug, :last_output, :last_error, :quiet
    attr_reader :path

    def initialize(path = '.', host = 'localhost')
      @host = host
      @path = (path.nil? || path.empty?) ? '.' : path
      @path = File.expand_path(@path) if local?
      @last_output = []
      @last_error = []
      @debug = false
      @quiet = false
      @environment = {}
    end

    def run(command, options = {})
      command = [command] if command.class == String

      # is a custom path given?
      if options[:in]
        # is it absolute?
        path = options[:in][0, 1] == '/' ? options[:in] : "#{@path}/#{options[:in]}"
      else
        path = @path
      end

      command.unshift "cd #{path}"

      # invoke a login shell?
      shell_command = options[:login] ? 'env -i bash -lc' : 'bash -c'

      if local?
        execute("#{shell_command} '#{escape_for_sh(command.join(' && '))}'")
      else
        remote_command = escape_for_sh("#{shell_command} '#{escape_for_sh(command.join(' && '))}'")
        execute("ssh #{@host} '#{remote_command}'")
      end
    end

    def local?
      @host == 'localhost'
    end

    def path=(path)
      @path = local? ? File.expand_path(path) : path
    end

    protected

    # Run the command and capture the output
    def execute(command)
      # Ladies and gentleman: More debug, please!
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
