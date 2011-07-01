require "rspec"
require "date"
require "../../lib/release_metrics"

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
    @project = double('project',
                      :value_of_project_variable => '#1 Release 1',
                      :execute_mql => @iterations)
    @macro = ReleaseMetrics.new(@parameters, @project, nil)
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
      subject { @macro.average_velocity @macro.completed_iterations.first(3) }
      it { should == 10 }
    end

    context "iteration length in days" do
      subject { @macro.iteration_length_in_days @macro.completed_iterations[0] }
      it { should == 7 }
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

  context "expected completion date for end data and velocity" do
    subject { @macro.expected_completion_date_for Date.parse('2011-07-05'), 7, 5 }
    it { should == Date.parse('2011-08-08') }
  end

  context "average velocity with no iterations" do
    subject { @macro.average_velocity [] }
    it { should == 0 }
  end

end



