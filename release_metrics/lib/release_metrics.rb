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
      <<-HTML
    h2. Metrics for #{release}

    Current Iteration: #{iteration}

    Last 3 Iterations: #{last_3_iterations}
      HTML
    rescue Exception => e
      <<-ERROR
    h2. Release Metrics:

    "An Error occurred: #{e}"

      ERROR
    end
  end

  def calculate_total_story_points(stories)
    stories.inject(0) { |total, hash| hash[estimate_property] ? total + hash[estimate_property].to_i : total }
  end

  def last_3_iterations
    begin
      data_rows = @project.execute_mql(
          "SELECT number, name, 'end date' WHERE Type = iteration AND 'End Date' < today AND release = '#{release_name}' ORDER BY 'end date' desc")
      raise "##{release} is not a valid release" if data_rows.empty?
      data_rows.first(3)
    rescue Exception => e
      raise "[error retrieving story info for iteration '#{iteration}': #{e}]"
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

  def iteration
    @parameters['iteration'] || @project.value_of_project_variable('Current Iteration')
  end

  def iteration_name
    match_data = /#\d+ (.*)/.match(iteration)
    if  match_data
      match_data[1]
    else
      'Unknown'
    end
  end

  def iteration_number
    match_data = /#(\d+).*/.match(iteration)
    if  match_data
      match_data[1].to_i
    else
      'Unknown'
    end
  end

  def parameter_to_field(field)
    field.gsub('_', ' ').scan(/\w+/).collect { |word| word.capitalize }.join(' ')
  end

  def date_accepted_property
    @parameters['date_accepted'] || 'date_accepted'
  end

  def estimate_property
    @parameters['story_points'] || 'story_points'
  end

  def today
    @parameters[:today] || Date.today
  end

  def can_be_cached?
    false # if appropriate, switch to true once you move your macro to production
  end

end

