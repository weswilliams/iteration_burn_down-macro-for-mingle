require 'test/unit'
require File.join(File.dirname(__FILE__), '..', '..', 'init.rb')
require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'iteration_burn_down_macro')
require File.join(File.dirname(__FILE__), 'fixture_loader')

class Test::Unit::TestCase
  
  def project(name)
    @projects ||= {}
    @projects[name] ||= FixtureLoaders::ProjectLoader.new(name).project
  end

end  
