require 'test/unit'
require File.join(File.dirname(__FILE__), '..', '..', 'init.rb')
require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'release_metrics')
require File.join(File.dirname(__FILE__), 'fixture_loader')

class Test::Unit::TestCase
  
  def project(name)
    @projects ||= {}
    @projects[name] ||= FixtureLoaders::ProjectLoader.new(name).project
  end

end  
