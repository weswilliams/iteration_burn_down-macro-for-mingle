require "rspec"
require "date"
require "../../lib/iteration_burn_down_macro"


describe "burn down query" do
  before do
    @date_range = ((Date.parse('2011-06-01'))..(Date.parse('2011-06-07')))
    @parameters = {}
    @burn_down_macro = IterationBurnDownMacro.new(@parameters, nil, nil)
  end

  subject { @burn_down_macro.generate_burndown_line_data 8, @stories, @date_range }

  context "all finished before weekend" do
    before do
      @stories = [
          {'story_points' => '3', 'date_accepted' => Date.parse('2011-06-02')},
          {'story_points' => '5', 'date_accepted' => Date.parse('2011-06-03')}
      ]
    end
    it { should == '8,5,0,0,0' }
  end

  context "all finished on work days" do
    before do
      @stories = [
          {'story_points' => '3', 'date_accepted' => Date.parse('2011-06-02')},
          {'story_points' => '5', 'date_accepted' => Date.parse('2011-06-07')}
      ]
    end
    it { should == '8,5,5,5,0' }
  end

  context "one story finished on weekend" do
    before do
      @stories = [
          {'story_points' => '3', 'date_accepted' => Date.parse('2011-06-02')},
          {'story_points' => '5', 'date_accepted' => Date.parse('2011-06-05')}
      ]
    end
    it { should == '8,5,5,0,0' }
  end

  context "stories finished in future not displayed" do
    before do
      @parameters[:today] = Date.parse('2011-06-03')
      @stories = [
          {'story_points' => '3', 'date_accepted' => Date.parse('2011-06-02')},
          {'story_points' => '5', 'date_accepted' => Date.parse('2011-06-06')}
      ]
    end
    it { should == '8,5,5' }
  end

end