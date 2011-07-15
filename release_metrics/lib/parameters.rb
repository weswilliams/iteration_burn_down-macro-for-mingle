module CustomMacro

  module Parameters

    @parameter_defaults = Hash.new { |h, k| h[k]=k }
    @parameter_defaults['iteration'] = lambda { @project.value_of_project_variable('Current Iteration') }
    @parameter_defaults['release'] = lambda { @project.value_of_project_variable('Current Release') }
    @parameter_defaults['time_box'] = 'iteration'
    @parameter_defaults['show_what_if'] = false
    @parameter_defaults['mini'] = false
    @parameter_defaults['debug'] = false



  end

end