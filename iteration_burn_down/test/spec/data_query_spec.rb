require "rspec"
require "../../lib/iteration_burn_down_macro"

describe "burn down query" do
  before do
    @story_info = [
        {'story_points' => '3', 'date_accepted' => '2011-06-23'}
    ]
    @parameters = {}
    @project = double('project',
      :value_of_project_variable => '#3 Iteration 1',
      :execute_mql => @story_info)
    @burn_down_macro = IterationBurnDownMacro.new(@parameters, @project, nil)
  end

  subject { @burn_down_macro }

  describe "story estimate and accepted on query" do
    subject { @burn_down_macro.story_info }
    context "query with default parameters" do
      before do
        @project.should_receive(:execute_mql).with(
          "SELECT 'Story Points', 'Date Accepted' WHERE type is Story AND Iteration = 'Iteration 1'")
      end
      it { should == @story_info }
    end
  end
end