require "rspec"
require "date"
require "./lib/iteration_burn_down_macro"

describe "iteration date range query" do
  before do
    @iteration_date_range = [{'start_date' => '2011-06-01', 'end_date' => '2011-06-07'}]
    @parameters = {}
    @project = double('project',
                      :value_of_project_variable => '#3 Iteration 1',
                      :execute_mql => @iteration_date_range)
    @burn_down_macro = CustomMacro::IterationBurnDownMacro.new(@parameters, @project, nil)
  end

  subject { @burn_down_macro.iteration_date_range }
  context "query with default parameters" do
    before do
      @project.should_receive(:execute_mql).with(
          "SELECT 'Start Date', 'End Date' WHERE Number = 3")
    end
    it { should == ((Date.parse('2011-06-01'))..(Date.parse('2011-06-07'))) }
  end

  context "query with iteration parameter" do
    before do
      @parameters['iteration'] = '#34 Iteration 54'
      @project.should_receive(:execute_mql).with(
          "SELECT 'Start Date', 'End Date' WHERE Number = 34")
    end
    it { should == ((Date.parse('2011-06-01'))..(Date.parse('2011-06-07'))) }
  end

  context "query with iteration parameter of THIS CARD" do
    before do
      @parameters['iteration'] = 'THIS CARD'
      @project.should_receive(:execute_mql).with(
          "SELECT 'Start Date', 'End Date' WHERE Number = THIS CARD.'Number'")
    end
    it { should == ((Date.parse('2011-06-01'))..(Date.parse('2011-06-07'))) }
  end

end

describe "burn down query" do
  before do
    @story_info = [
        {'story_points' => '3', 'date_accepted' => '2011-06-23'}
    ]
    @parameters = {}
    @project = double('project',
                      :value_of_project_variable => '#3 Iteration 1',
                      :execute_mql => @story_info)
    @burn_down_macro = CustomMacro::IterationBurnDownMacro.new(@parameters, @project, nil)
  end

  subject { @burn_down_macro.story_info }
  context "query with default parameters" do
    before do
      @project.should_receive(:execute_mql).with(
          "SELECT 'Story Points', 'Date Accepted' WHERE type is Story AND Iteration = 'Iteration 1'")
    end
    it { should == @story_info }
  end

  context "query with iteration parameter" do
    before do
      @parameters['iteration'] = '#23 Iteration 45'
      @project.should_receive(:execute_mql).with(
          "SELECT 'Story Points', 'Date Accepted' WHERE type is Story AND Iteration = 'Iteration 45'")
    end
    it { should == @story_info }
  end

  subject { @burn_down_macro.story_info }
  context "query with iteration parameter 'THIS CARD'" do
    before do
      @parameters['iteration'] = 'THIS CARD'
      @project.should_receive(:execute_mql).with(
          "SELECT 'Story Points', 'Date Accepted' WHERE type is Story AND Iteration = THIS CARD")
    end
    it { should == @story_info }
  end
end