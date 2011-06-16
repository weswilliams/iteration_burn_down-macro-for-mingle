require 'delegate'
require 'test/unit'
require File.join(File.dirname(__FILE__), '..', '..', 'init.rb')
require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'wes_test')
require File.join(File.dirname(__FILE__), 'rest_loader')

class Test::Unit::TestCase
  
  def project(resource)
    @projects ||= {}
    @projects[resource] ||= load_project_resource(resource)
  end
  
  def projects(*resources)
    resources.collect {|resource| project(resource)}
  end
  
  def errors
    @errors ||= []
  end
  
  def alert(message)
    errors << message
  end
  
  private
  
  def load_project_resource(resource)
    RESTfulLoaders::ProjectLoader.new(resource, self).project
  end
end
