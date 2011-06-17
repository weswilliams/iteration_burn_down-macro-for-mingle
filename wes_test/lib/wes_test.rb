require "date"

class WesTest
  MON = 1
  TUE = 2
  WED = 3
  THU = 4
  FRI = 5

  WEEKDAYS = [MON, TUE, WED, THU, FRI]

  def initialize(parameters, project, current_user)
    @parameters = parameters
    @project = project
    @current_user = current_user
  end
    
  def execute
#    @parameters.each {|key, value| html << "param: '#{key} = #{value}'<br>"}
    
    weekdays = query_data

    <<-HTML
    h2. Iteration ##{@parameters['current_iteration']} Burndown:

    weekdays = #{weekdays}

    <img src='https://chart.googleapis.com/chart?cht=lxy&chs=600x400&chds=a&chtt=Iteration%20Burndown&chls=1,6,6&chxt=x,y&chxr=1,0,11,1&chma=50,0,0,50&chdl=Ideal%20Line|Burndown&chco=00FF00,FF0000&chd=t:0,1,2,3,4|11,8.25,5.5,2.75,0|0,1,2,3,4|11,11,6,3,0&chxl=0:|6-9|6-10|6-13|6-14|6-15|1:||1|2|3|4|'></img>
    HTML
  end

  def get_weekdays(start_date, end_date)
    weekdays = (Date.parse(start_date)..Date.parse(end_date)).select {|day| WEEKDAYS.include? day.wday }
    weekdays.collect {|day| "#{day.month}-#{day.day}"}.join(',')
  end

  def iteration
    iteration = @parameters['current_iteration']
    iteration ||= /#(\d+).*/.match(@project.value_of_project_variable('Current Iteration'))[1].to_i
  end

  def query_data
    begin
      data_rows = @project.execute_mql("SELECT 'Start Date', 'End Date' WHERE Number = #{iteration}")
      throw "##{iteration} is not a valid iteration" if data_rows.empty?
      get_weekdays(data_rows[0]['start_date'], data_rows[0]['end_date'])
    rescue Exception
      throw "error getting data for iteration #{iteration}: #{$!}"
    end
  end

#  <div id="burndown_chart" style="width: 600px; height: 400px"></div>
#  <script type="text/javascript" src="https://www.google.com/jsapi"></script>

#  <script type="text/javascript">
#    MingleJavascript.register(function initialize() {
#     alert('Test macro javascript');
#    });
#  </script>

#  $('burndown_chart').innerHTML = 'burn down div';
#  var drawChart = function() {
#    $('burndown_chart').innerHTML = 'burn down div';
#    //var data = new google.visualization.DataTable();
#    //data.addColumn('string', 'Day');
#    //data.addColumn('number', 'Ideal');
#    //data.addRow(["6/1/11", 6]);
#    //data.addRow(["6/2/11", 5]);
#    //data.addRow(["6/3/11", 4]);
#    //data.addRow(["6/4/11", 3]);
#    //data.addRow(["6/5/11", 2]);
#    //data.addRow(["6/6/11", 1]);
#    //data.addRow(["6/7/11", 0]);
#    // Create and draw the visualization.
#    //new google.visualization.LineChart(document.getElementById('burndown_chart')).
#    //  draw(data, {curveType: "function",
#    //          width: 600, height: 400,
#    //          vAxis: {maxValue: 8}});
#  };
#  google.load('visualization', '1', {'packages':['corechart']}
#  google.setOnLoadCallback(drawChart);
#  drawChart();


  def can_be_cached?
    false  # if appropriate, switch to true once you move your macro to production
  end

end

