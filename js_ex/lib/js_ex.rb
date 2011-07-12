require "date"

module CustomMacro

  class JsEx

    def initialize(parameters, project, current_user)
      @parameters = parameters
      @project = project
      @current_user = current_user
      @parameter_defaults = {}

   end

    def execute
      begin
        remaining_story_points = 50
        last_iter_end_date = Date.parse('2011-07-04')
        days_in_iter = 7

        <<-HTML
    h2. JavaScript Example

    <div class="wiki" id="js-output">Enter a velocity to see expected end date.</div>
    <span>What if velocity: </span> <input type='text' id='what-if-velocity'></input>
    <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.6.1/jquery.min.js"></script>
    <script type="text/javascript">
      jQuery.noConflict();
      // register the initialize function for executing after page loaded.
      MingleJavascript.register(function initialize() {
        try {

          var lastIterEndDate = new Date('#{last_iter_end_date.to_s}'),
              daysInIter = #{days_in_iter},
              remainingStoryPoints = #{remaining_story_points};

          var remainingIterations = function(velocity, remaining_story_points) {
            return remaining_story_points / velocity;
          };

          var expectedCompletionDateFor = function(lastIterEndDate, daysInIter, remainingIterations) {
            return new Date(lastIterEndDate.getTime() + 1000 * 60 * 60 * 24 * (daysInIter * remainingIterations));
          };

          var out = jQuery("#js-output");

          jQuery("#what-if-velocity").blur(function() {
            var velocity = parseInt(jQuery("#what-if-velocity").val());
            var iterations = remainingIterations(velocity, remainingStoryPoints);
            var expectedDate = expectedCompletionDateFor(lastIterEndDate, daysInIter, iterations);
            var dateString = expectedDate.getFullYear() + '-' + expectedDate.getMonth() + '-' + expectedDate.getDate();
            out.html("<span>Expected end date for a velocity of " + velocity + " is " + dateString + "</span>");
          });
        } catch(err) {
          out.html("<span>Error: " + err + "</span>");
        }
      });
    </script>

        HTML
      rescue Exception => e
        <<-ERROR
    h2. JavaScript Example

    "An Error occurred: #{e}"
        ERROR
      end
    end

    def parameter_to_field(field)
      field.gsub('_', ' ').scan(/\w+/).collect { |word| word.capitalize }.join(' ')
    end

    def can_be_cached?
      false # if appropriate, switch to true once you move your macro to production
    end

    #noinspection RubyUnusedLocalVariable
    def method_missing(method_sym, *arguments, &block)
      if method_sym.to_s =~ /^(.*)_field$/
        parameter_to_field(send "#{$1}_parameter".to_s)
      elsif  method_sym.to_s =~ /^(.*)_(parameter|type)$/
        param = @parameters[$1] || @parameter_defaults[$1]
        if param.respond_to? :call
          param.call
        else
          param
        end
      else
        super
      end
    end

    def respond_to?(method_sym, include_private = false)
      puts 'in respond to'
      if method_sym.to_s =~ /^(.*)_[field|parameter|type]$/
        true
      else
        super
      end
    end

  end

end
