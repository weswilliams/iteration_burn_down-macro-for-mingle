require "rspec"
require "date"
require "../../lib/release_metrics"

describe "completed iterations" do
  before do
    @parameters = {}
    @iterations = [
        {'number' => '5', 'name' => 'Iteration 5', 'end_date' => '2011-07-05', 'velocity' => '12'},
        {'number' => '4', 'name' => 'Iteration 4', 'end_date' => '2011-06-28', 'velocity' => '8'},
        {'number' => '3', 'name' => 'Iteration 3', 'end_date' => '2011-06-21', 'velocity' => '10'},
        {'number' => '2', 'name' => 'Iteration 2', 'end_date' => '2011-06-14', 'velocity' => '5'},
        {'number' => '1', 'name' => 'Iteration 1', 'end_date' => '2011-06-14', 'velocity' => '0'},
    ]
    @project = double('project',
                      :value_of_project_variable => '#1 Release 1',
                      :execute_mql => @iterations)
    @macro = ReleaseMetrics.new(@parameters, @project, nil)
  end

  context do
    before do
      @project.should_receive(:execute_mql).with(
          "SELECT number, name, 'end date', velocity " +
              "WHERE Type = iteration AND 'End Date' < today AND release = 'Release 1' " +
              "ORDER BY 'end date' desc")
    end

    context "number of iterations" do
      subject { @macro.completed_iterations.length }
      it { should == 5 }
    end

    context "most recent iteration" do
      subject { @macro.completed_iterations[0] }
      it { should have_value 'Iteration 5' }
    end

    context "last iteration used in last 3 velocity" do
      subject { @macro.completed_iterations[2] }
      it { should have_value 'Iteration 3' }
    end

    context "average velocity" do
      subject { @macro.average_velocity @macro.completed_iterations.first(3) }
      it { should == 10 }
    end
  end

  context "best velocity" do
    subject { @macro.best_velocity_for @iterations }
    it { should == 12 }
  end

  context "worst velocity" do
    subject { @macro.worst_velocity_for @iterations }
    it { should == 5 }
  end
end

