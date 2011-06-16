require File.join(File.dirname(__FILE__), 'unit_test_helper')

class Wes::WesTestTest < Test::Unit::TestCase
  
  FIXTURE = 'sample'
  
  def test_macro_contents
    wes_test = Wes::WesTest.new(nil, project(FIXTURE), nil)
    result = wes_test.execute
    assert result
  end
  
  def test_macro_contents_with_a_project_group
    wes_test = Wes::WesTest.new(nil, [project(FIXTURE), project(FIXTURE)], nil)
    result = wes_test.execute
    assert result
  end

end