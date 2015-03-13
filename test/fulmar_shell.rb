#!/usr/bin/env ruby
# coding: utf-8

require 'minitest/autorun'
require 'fulmar/shell'

# Tests the fulmar shell with some simple commands
class FulmarShellTest < MiniTest::Unit::TestCase
  def setup
    @local_shell = Fulmar::Shell.new('/tmp')
    @local_shell.quiet = true
  end

  def test_shell_runs_commands
    assert @local_shell.run('/bin/echo')
  end

  def test_shell_can_handle_tests
    assert @local_shell.run('[ "Wheee" == "Wheee" ]')
  end

  def test_shell_returns_failed_commands
    assert !@local_shell.run('[ "Wheee" == "Whooo" ]')
  end

  def test_shell_returns_output
    @local_shell.run('/bin/echo "Wheee"')
    assert_equal 'Wheee', @local_shell.last_output.first.chomp
  end

  def test_shell_returns_escapes_single_quotes
    @local_shell.run('/bin/echo \'Wheee\'')
    assert_equal 'Wheee', @local_shell.last_output.first.chomp
  end

  def test_shell_return_errors
    @local_shell.run('/bin/echo "Wheee" 1>&2')
    assert_equal 'Wheee', @local_shell.last_error.first.chomp
  end
end
