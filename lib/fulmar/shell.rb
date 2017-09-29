require 'open3'
require 'pathname'
require 'fulmar/ringbuffer'

# This shell is part of the fulmar deployment tools
# it can be used stand-alone, though
module Fulmar
  # Implements simple access to shell commands
  class Shell
    VERSION = '1.8.0'

    attr_accessor :debug, :last_output, :last_error, :quiet, :strict, :interactive
    attr_reader :path

    DEFAULT_BUFFER_SIZE = 1000

    DEFAULT_OPTIONS = {
      login: false,
      escape_bundler: false
    }

    def initialize(path = '.', host = 'localhost')
      @host = host.nil? ? 'no_hostname_set' : host
      @path = (path.nil? || path.empty?) ? '.' : path
      @path = File.expand_path(@path) if local?
      reset_output
      @debug = false
      @quiet = true
      @strict = false
      @interactive = false
      @clean_environment = [] # list of things to clean from environment variables
    end

    def interactive=(interactive)
      @interactive = interactive
      @quiet = false if interactive
    end

    def run(command, options = DEFAULT_OPTIONS)
      reset_output(@last_output.max_size)
      command = [command] if command.class == String

      # is a custom path given?
      if options[:in]
        # is it absolute?
        (Pathname.new options[:in]).absolute? ? options[:in] : "#{@path}/#{options[:in]}"
      else
        path = @path
      end

      options[:error_message] ||= 'Last shell command returned an error.'

      command.unshift "cd \"#{path}\""

      # invoke a login shell?
      shell_command = shell_command(options[:login])

      @clean_environment << 'bundler' if options[:escape_bundler]

      if local?
        execute("#{shell_command} '#{escape_for_sh(command.join(' && '))}'", options[:error_message])
      else
        remote_command = escape_for_sh("#{shell_command} '#{escape_for_sh(command.join(' && '))}'")
        execute("ssh #{@host} '#{remote_command}'", options[:error_message])
      end
    end

    def local?
      @host == 'localhost'
    end

    def path=(path)
      @path = local? ? File.expand_path(path) : path
    end

    def buffer_size(size)
      reset_output(size)
    end

    protected

    def reset_output(size = DEFAULT_BUFFER_SIZE)
      @last_output = Fulmar::RingBuffer.new(size)
      @last_error = Fulmar::RingBuffer.new(size)
    end

    def shell_command(login)
      login ? "env -i HOME=\"#{ENV['HOME']}\" LANG=\"#{ENV['LANG']}\" bash -lc" : 'bash -c'
    end

    def environment
      env = ENV.clone
      if @clean_environment.include? 'bundler'
        bundler_variable_parts = %w(ruby gem_ bundle)
        # Remove any variables which contain the words above
        env.delete_if { |key| bundler_variable_parts.select { |part| key.downcase.include?(part) }.any? }
        env['PATH'] = path_without_bundler
      end
      puts "Environment: #{env.inspect}" if @debug
      env
    end

    def path_without_bundler
      ENV['PATH'].split(':').reject { |path| path.include?('ruby') || path.include?('gems') }.join(':')
    end

    def execute(command, error_message)
      if @interactive
        execute_interactive(command, error_message)
      else
        execute_quiet(command, error_message)
      end
    end

    def execute_interactive(command, error_message)
      unless system(command)
        puts "\n\n#{error_message}"
      end
    end

    # Run the command and capture the output
    def execute_quiet(command, error_message)
      # Ladies and gentleman: More debug, please!
      puts command if @debug
      return_value = -1

      Open3.popen3(environment, command) do |_stdin, stdout, stderr, wait_thread|
        Thread.new do
          stdout.each do |line|
            @last_output << line.strip
            puts line unless @quiet
          end
        end

        Thread.new do
          stderr.each do |line|
            @last_error << line
            puts line unless @quiet
          end
        end

        _stdin.close

        return_value = wait_thread.value

        if @strict and return_value.exitstatus != 0
          dump_error_message(command)
          fail error_message
        end
      end

      puts "Program exited with status #{return_value.exitstatus}." if @debug

      return_value.exitstatus == 0
    end

    def escape_for_sh(text)
      text.gsub('\\', '\\\\').gsub("'", "'\\\\''")
    end

    def dump_error_message(command)
      STDERR.puts command unless @debug
      STDERR.puts 'Command output (stdout):'
      @last_output.each { |line| STDERR.puts line }
      STDERR.puts ''
      STDERR.puts 'Command error message (stderr):'
      @last_error.each { |line| STDERR.puts line }
    end
  end
end
