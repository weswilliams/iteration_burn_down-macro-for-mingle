require "rspec"
require "../../lib/release_metrics"

describe "remaining stories" do
  before do
    @iterations = [
        {'number' => '5', 'name' => 'Iteration 5', 'end_date' => '2011-07-05', 'velocity' => '12'},
        {'number' => '4', 'name' => 'Iteration 4', 'end_date' => '2011-06-28', 'velocity' => '8'},
        {'number' => '3', 'name' => 'Iteration 3', 'end_date' => '2011-06-21', 'velocity' => '10'},
        {'number' => '2', 'name' => 'Iteration 2', 'end_date' => '2011-06-14', 'velocity' => '5'},
    ]

    @parameters = {}
    @stories = [
        {'story_points' => '5'},
        {'story_points' => '3'},
        {'story_points' => '8'},
        {'story_points' => '1'},
    ]
    @project = double('project',
                      :value_of_project_variable => '#1 Release 1',
                      :execute_mql => @stories)
    @macro = ReleaseMetrics.new(@parameters, @project, nil)

  end

  context "iteration names" do
    subject { @macro.iteration_names @iterations }
    it { should == "'Iteration 5','Iteration 4','Iteration 3','Iteration 2'" }
  end

    context do
      before do
        @project.should_receive(:execute_mql).with(
            "SELECT 'story points' " +
            "WHERE Type = story AND release = 'Release 1' AND NOT iteration in ('Iteration 5','Iteration 4','Iteration 3','Iteration 2')")
      end

      subject { @macro.incomplete_stories @iterations }
      it { should == @stories }
    end

end
