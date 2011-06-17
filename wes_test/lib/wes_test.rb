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
    begin
      chart_url = 'https://chart.googleapis.com/chart?'
      chart_title = 'chtt=Iteration%20Burndown'
      date_range = iteration_date_range
      weekdays_x_axis = weekdays_for(date_range).collect { |day| "#{day.month}-#{day.day}" }.join('|')
      stories = story_info
      total_story_points = calculate_total_story_points stories
      points_y_axis = generate_y_axis(total_story_points)
      chart_range = "chxr=1,0,#{total_story_points},1"
      ideal_line_data = generate_idea_line_data(total_story_points, date_range)
      x_data = generate_x_data(date_range)
      burn_down_line = generate_cumulative_accepted_points_by_weekday(total_story_points, story_info, date_range)

      <<-HTML
    h2. Iteration ##{@parameters['current_iteration']} Burndown:

    points by past days = #{generate_cumulative_accepted_points_by_weekday(total_story_points, story_info, date_range)} <br>
    x axis weekdays = #{weekdays_x_axis} <br>
    y axis points = #{points_y_axis} <br>
    total story points #{total_story_points} <br>
    date range #{date_range} <br>
    idea line data = #{ideal_line_data} <br>
    x data = #{x_data} <br>
    story info #{story_info.to_s}

    <img src='#{chart_url}cht=lxy&chs=600x400&chds=a&#{chart_title}&chls=1,6,6&chxt=x,y&#{chart_range}&chma=50,0,0,50&chdl=Ideal%20Line|Burndown&chco=00FF00,FF0000&chd=t:#{x_data}|#{ideal_line_data}|#{x_data}|#{burn_down_line}&chxl=0:|#{weekdays_x_axis}|1:|#{points_y_axis}|'></img>
      HTML
    rescue Exception
      "Something went way wrong: #{$!}"
    end
  end

  def generate_cumulative_accepted_points_by_weekday(total_story_points, story_info, date_range)
    weekdays = weekdays_for(date_range)
    points_by_past_weekdays = {}
    weekdays.each { |day| points_by_past_weekdays[day] = total_story_points if day < Date.today }
    story_info.select { |story_hash| story_hash['accepted_on'] }.each do |story_hash|
      accepted_on = story_hash['accepted_on']
      points = story_hash['planning_estimate'] || 0
      points_by_past_weekdays.keys.select { |date| date >= accepted_on }.each { |date| points_by_past_weekdays[date] -= points.to_i }
    end
    points_by_past_weekdays.values.join(',')
  end

  def generate_x_data(date_range)
    (0...(weekdays_for(date_range).count)).to_a.join(',')
  end

  def generate_y_axis(total_story_points)
    '|' + ((1..total_story_points).to_a.join('|'))
  end

  def generate_idea_line_data(total_story_points, date_range)
    number_of_weekdays = weekdays_for(date_range).count
    step = (total_story_points*1.0) / (number_of_weekdays-1)
    idea_data = []
    (0.0..total_story_points).step(step) { |value| idea_data << value }
    idea_data.reverse.join(',')
  end

  def calculate_total_story_points(stories)
    stories.inject(0) { |total, hash| hash['planning_estimate'] ? total + hash['planning_estimate'].to_i : total }
  end

  def story_info
    begin
      iteration = /#\d+ (.*)/.match(current_iteration)[1]
      data_rows = @project.execute_mql(
          "SELECT 'Planning Estimate', 'Accepted On' WHERE type is Story AND Iteration = '#{iteration}'")
      data_rows.each { |hash| hash.update(hash) { |key, value| (key == 'accepted_on' && value) ? Date.parse(value) : value } }
    rescue Exception
      "[error retrieving story info for iteration '#{iteration}': #{$!}]"
    end
  end

  def iteration_date_range
    begin
      data_rows = @project.execute_mql("SELECT 'Start Date', 'End Date' WHERE Number = #{iteration}")
      throw "##{iteration} is not a valid iteration" if data_rows.empty?
      Date.parse(data_rows[0]['start_date'])..Date.parse(data_rows[0]['end_date'])
    rescue Exception
      throw "error getting data for iteration #{iteration}: #{$!}"
    end
  end

  def weekdays_for(date_range)
    ((date_range.begin)..(date_range.end)).select { |day| WEEKDAYS.include? day.wday }
  end

  def current_iteration
    @project.value_of_project_variable('Current Iteration')
  end

  def iteration
    /#(\d+).*/.match(current_iteration)[1].to_i
  end

  def can_be_cached?
    false # if appropriate, switch to true once you move your macro to production
  end

end

