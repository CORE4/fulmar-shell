require 'fulmar-shell/version'
require 'open3'

module Fulmar

  class Shell

    attr_accessor :debug, :last_output, :last_error, :quiet

    def initialize(path, host = 'localhost')
      @path = path
      @host = host
      @last_output = []
      @last_error = []
      @debug = false
      @quiet = false
    end

    def run(command)

      if command.class == String
        command = [command]
      end

      command.unshift "cd #{@path}"

      if local?
        execute('sh -c \'' + escape_for_sh(command.join(' && ')) + '\'')
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
      @last_error = stderr.readlines
      @last_output = stdout.readlines
      stdin.close
      stdout.close
      stderr.close

      # Remove annoying newlines at the end
      @last_output = @last_output.collect{|line| line.chomp}
      @last_error = @last_error.collect{|line| line.chomp}

      unless @quiet
        @last_error.each do |line|
          puts line
        end
      end

      wait_thr.value == 0
    end

    def escape_for_sh(text)
      text.gsub('\\', '\\\\').gsub("'", "'\\\\''")
    end

  end

end
