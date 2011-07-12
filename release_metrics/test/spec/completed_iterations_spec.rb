require "rspec"
require "date"
require "./lib/release_metrics"
require "./lib/iterations"

describe "completed iterations" do
  before do
    @parameters = {}
    @iterations = [
        {'start_date' => '2011-06-29', 'end_date' => '2011-07-05', 'velocity' => '12'},
        {'start_date' => '2011-06-22', 'end_date' => '2011-06-28', 'velocity' => '8'},
        {'start_date' => '2011-06-15', 'end_date' => '2011-06-21', 'velocity' => '10'},
        {'start_date' => '2011-06-08', 'end_date' => '2011-06-14', 'velocity' => '5'},
        {'start_date' => '2011-06-01', 'end_date' => '2011-06-07', 'velocity' => '0'},
    ]
    @r_iterations = CustomMacro::Iterations.new @iterations
    @project = double('project',
                      :value_of_project_variable => '#1 Release 1',
                      :execute_mql => @iterations)
    @macro = CustomMacro::ReleaseMetrics.new(@parameters, @project, nil)
  end

  context do
    before do
      @project.should_receive(:execute_mql).with(
          "SELECT name, 'Start Date', 'End Date', Velocity " +
              "WHERE Type = iteration AND 'End Date' < today AND release = 'Release 1' " +
              "ORDER BY 'End Date' desc")
    end

    context "number of iterations" do
      subject { @macro.completed_iterations.length }
      it { should == 5 }
    end

    context "most recent iteration" do
      subject { @macro.completed_iterations[0] }
      it { should have_value '2011-06-29' }
    end

    context "last iteration used in last 3 velocity" do
      subject { @macro.completed_iterations[2] }
      it { should have_value '2011-06-15' }
    end

    context "average velocity" do
      subject { @r_iterations.average_velocity_for @macro.completed_iterations.first(3) }
      it { should == 10 }
    end
  end

  context "no completed iterations" do

    context "should retrieve all stories in the release" do
      before do
        @stories = [{}]
        @project.stub(:execute_mql) { @stories }
        @project.should_receive(:execute_mql).with(
            "SELECT 'Story Points' WHERE Type = story AND release = 'Release 1'")
      end

      subject { @macro.stories CustomMacro::Iterations.new([]) }
      it { should == @stories }
    end
    
    context "average velocity with no iterations" do
      subject { @r_iterations.average_velocity_for [] }
      it { should == 0 }
    end

  end

  context "best velocity" do
    subject { @r_iterations.best_velocity }
    it { should == 12 }
  end

  context "worst velocity" do
    subject { @r_iterations.worst_velocity }
    it { should == 5 }
  end

  context "iteration length in days" do
    subject { @r_iterations.days_in_iteration }
    it { should == 7 }
  end

  context "expected completion date for end data and velocity" do
    subject { @macro.expected_completion_date_for Date.parse('2011-07-05'), 7, 5 }
    it { should == Date.parse('2011-08-09') }
  end

  context "expected completion date for end data and velocity" do
    subject { @macro.expected_completion_date_for Date.parse('2011-07-04'), 7, 13 }
    it { should == Date.parse('2011-10-03') }
  end

end



