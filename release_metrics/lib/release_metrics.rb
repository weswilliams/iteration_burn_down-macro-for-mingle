require "date"

class ReleaseMetrics
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
    begin
      iterations = completed_iterations
      average_velocity = average_velocity last_3_iterations(iterations)
      remaining_stories = incomplete_stories iterations
      remaining_story_points = story_points_for remaining_stories

      <<-HTML
    h2. Metrics for #{release}

    Current Iteration: #{iteration} <br>
    Average Velocity: #{"%.2f" % average_velocity} (last 3 iterations) <br>
    Completed Iterations: #{iterations.length} <br>
    Remaining Story Points: #{remaining_story_points} (includes all stories not in a past iteration)<br>

    h3. Projected Iterations to Complete

    Based on average of last 3 iterations: #{(remaining_story_points/average_velocity).ceil}

      HTML
    rescue Exception => e
      <<-ERROR
    h2. Release Metrics:

    "An Error occurred: #{e}"

      ERROR
    end
  end

  def story_points_for(stories)
    stories.inject(0) {|total, story| story['story_points'] ? total + story['story_points'].to_i : total }
  end

  def incomplete_stories(iterations)
    iter_names = iteration_names iterations
    begin
      @project.execute_mql(
          "SELECT 'story points' WHERE Type = story AND release = '#{release_name}' AND NOT iteration in (#{iter_names})")
    rescue Exception => e
      raise "[error retrieving stories for release '#{release}': #{e}]"
    end
  end

  def iteration_names(iterations)
    iterations.collect {|iter| "'#{iter['name']}'" }.join ","
  end

  def last_3_iterations(iterations)
    iterations.first(3)
  end

  def average_velocity(iterations)
    total_velocity = iterations.inject(0) { |total, hash| hash['velocity'] ? total + hash['velocity'].to_i : total }
    total_velocity / (iterations.length * 1.0)
  end

  def completed_iterations
    begin
      data_rows = @project.execute_mql(
          "SELECT number, name, 'end date', velocity WHERE Type = iteration AND 'End Date' < today AND release = '#{release_name}' ORDER BY 'end date' desc")
      raise "##{release} is not a valid release" if data_rows.empty?
      data_rows
    rescue Exception => e
      raise "[error retrieving completed iterations for #{release}: #{e}]"
    end
  end

  def release
    @parameters['release'] || @project.value_of_project_variable('Current Release')
  end

  def release_name
    match_data = /#\d+ (.*)/.match(release)
    if  match_data
      match_data[1]
    else
      'Unknown'
    end
  end

  def release_number
    match_data = /#(\d+).*/.match(release)
    if  match_data
      match_data[1].to_i
    else
      'Unknown'
    end
  end

  def iteration
    @parameters['iteration'] || @project.value_of_project_variable('Current Iteration')
  end

  def parameter_to_field(field)
    field.gsub('_', ' ').scan(/\w+/).collect { |word| word.capitalize }.join(' ')
  end

  def today
    @parameters[:today] || Date.today
  end

  def can_be_cached?
    false # if appropriate, switch to true once you move your macro to production
  end

end

