require "test/unit"

class TestGettingStarted < Test::Unit::TestCase
  def setup
    puts "installing rails"
    a = `gem install rails --no-document`
    puts "which: #{`which rails`}"
    puts "rails version: #{`rails --version`}"
  end

  def test_build_succeeds
    assert(system("rm -rf tmp; mkdir -p tmp"), "tmp dir is replaced")

    Dir.chdir("tmp") {
      cmd = "yes | YES_ALL=1 rails new Foobar -T --skip-coffee --webpack --database=postgresql -m '../rails-kickoff-template.rb'"

      puts "running:"
      puts "$ #{cmd} (#{`pwd`.strip})"

      result = system(cmd)

      assert(result, "command exits with zero exit status")
    }
  end

  def test_specs_pass
    Dir.chdir("tmp/Foobar") {
      assert(system("bundle exec rspec spec"), "tests pass")
    }
  end

  def test_rails_console
    Dir.chdir("tmp/Foobar") {
      assert(system("echo 'puts \"hello!\"' | bundle exec rails c"), "rails console works")
    }
  end
end
