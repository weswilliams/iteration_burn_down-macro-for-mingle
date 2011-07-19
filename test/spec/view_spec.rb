require "rspec"
require "date"
require "./lib/iteration_burn_down_macro"


describe "burn down query" do
  before do
    @date_range = ((Date.parse('2011-06-01'))..(Date.parse('2011-06-07')))
    @parameters = {}
    @project = double('project',
                      :value_of_project_variable => '#1 Release 1',
                      :execute_mql => [{'start_date' => '2011-06-01', 'end_date' => '2011-06-07'}])
    @burn_down_macro = CustomMacro::IterationBurnDownMacro.new(@parameters, @project, nil)
  end

  subject { @burn_down_macro.execute }
  it { should include "<img src='https://chart.googleapis.com/chart?" }
end
