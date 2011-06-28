require File.join(File.dirname(__FILE__), 'unit_test_helper')

class IterationBurnDownTest < Test::Unit::TestCase
  
  FIXTURE = 'sample'
  
  def test_macro_contents
    iteration_burn_down = ReleaseMetrics.new(nil, project(FIXTURE), nil)
    result = iteration_burn_down.execute
    assert result
  end
  
  def test_macro_contents_with_a_project_group
    iteration_burn_down = ReleaseMetrics.new(nil, [project(FIXTURE), project(FIXTURE)], nil)
    result = iteration_burn_down.execute
    assert result
  end

end