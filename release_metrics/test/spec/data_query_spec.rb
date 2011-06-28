require "rspec"
require "date"
require "../../lib/release_metrics"

describe "#last_3_iterations" do
  before do
    @parameters = {}
    @iterations = [
        {'number' => '5', 'name' => 'Iteration 5', 'end_date' => '2011-07-05'},
        {'number' => '4', 'name' => 'Iteration 4', 'end_date' => '2011-06-28'},
        {'number' => '3', 'name' => 'Iteration 3', 'end_date' => '2011-06-21'},
        {'number' => '2', 'name' => 'Iteration 2', 'end_date' => '2011-06-14'},
    ]
    @project = double('project',
                      :value_of_project_variable => '#1 Release 1',
                      :execute_mql => @iterations)
    @macro = ReleaseMetrics.new(@parameters, @project, nil)
  end

  context "query with default parameters" do
    before do
      @project.should_receive(:execute_mql).with(
          "SELECT number, name, 'end date' " +
              "WHERE Type = iteration AND 'End Date' < today AND release = 'Release 1' " +
              "ORDER BY 'end date' desc")
    end

    context do
      subject { @macro.last_3_iterations.length }
      it { should == 3 }
    end

    context do
      subject { @macro.last_3_iterations[0] }
      it { should have_value 'Iteration 5' }
    end

    context do
      subject { @macro.last_3_iterations[2] }
      it { should have_value 'Iteration 3' }
    end
  end
end

