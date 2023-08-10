require "test/unit"
require "open3"

class TestGettingStarted < Test::Unit::TestCase
  def setup
    puts "installing rails"
    assert(system("mkdir -p tmp"), "create tmp directory")

    puts "which: #{`which rails`}"
    puts "rails version: #{`rails --version`}"
  end

  def test_build_succeeds
    Dir.chdir("tmp") {
      assert(system("rm -rf ./testum"), "existing rails app is removed")

      cmd = <<~CMD
        rails new testum \
              --database=postgresql \
              --javascript=esbuild \
              --skip-test \
              --skip-action-cable \
              --skip-hotwire \
              --skip-action-mailbox \
              --skip-action-text \
              --skip-hotwire \
              --skip-jbuilder \
              --template='../template.rb'
      CMD

      puts "running:"
      puts "$ #{cmd} (#{`pwd`.strip})"

      result = system(cmd)

      assert(result, "command exits with zero exit status")
    }
  end

  def test_specs_pass
    Dir.chdir("tmp/testum") {
      assert(system("bundle exec rspec spec"), "tests pass")
    }
  end

  def test_rails_console
    Dir.chdir("tmp/testum") {
      assert(system("echo 'puts \"hello!\"' | bundle exec rails c"), "rails console works")
    }
  end
end
