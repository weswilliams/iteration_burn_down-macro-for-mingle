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
      average_velocity = average_velocity iterations.first(3)

      <<-HTML
    h2. Metrics for #{release}

    Current Iteration: #{iteration} <br>
    Average Velocity: #{average_velocity} (last 3 iterations) <br>
    Completed Iterations: #{iterations.length}

    Iterations: #{iterations}
      HTML
    rescue Exception => e
      <<-ERROR
    h2. Release Metrics:

    "An Error occurred: #{e}"

      ERROR
    end
  end

  def average_velocity(iterations)
    total_velocity = iterations.inject(0) { |total, hash| hash['velocity'] ? total + hash['velocity'].to_i : total }
    total_velocity / iterations.length
  end

  def last_3_iterations
    iterations.first(3)
  end

  def completed_iterations
    begin
      data_rows = @project.execute_mql(
          "SELECT number, name, 'end date', velocity WHERE Type = iteration AND 'End Date' < today AND release = '#{release_name}' ORDER BY 'end date' desc")
      raise "##{release} is not a valid release" if data_rows.empty?
      data_rows
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

  def today
    @parameters[:today] || Date.today
  end

  def can_be_cached?
    false # if appropriate, switch to true once you move your macro to production
  end

end

