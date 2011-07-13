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
       * last end date: #{last_iter_end_date}
    |_. Remaining story point |_. Days/Iteration |_. Velocity |_. Calculated End Date |
    | #{remaining_story_points} | #{days_in_iter} | <input type='text' id='what-if-velocity'></input> | <input type='text' id="what-if-date" value='Enter a velocity to see expected end date.'></input> |

    <span id='debug-info'></span>

    <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.6.1/jquery.min.js"></script>
    <script type="text/javascript">
      jQuery.noConflict();
      // register the initialize function for executing after page loaded.
      MingleJavascript.register(function initialize() {
        try {

          var dateDiffInDays = function(d1, d2) {
            var t2 = d2.getTime();
            var t1 = d1.getTime();
            return parseInt((t2-t1)/(24*3600*1000));
          };

          var lastIterEndDate = new Date('#{last_iter_end_date.to_s}'),
              daysInIter = #{days_in_iter},
              remainingStoryPoints = #{remaining_story_points};

          var remainingIterations = function(velocity, remaining_story_points) {
            return Math.ceil(remaining_story_points / velocity);
          };

          var expectedCompletionDateFor = function(lastIterEndDate, daysInIter, remainingIterations) {
            return new Date(lastIterEndDate.getTime() + (1000 * 60 * 60 * 24 * (daysInIter * remainingIterations)));
          };

          var dateCalcText = jQuery("#what-if-date"),
              velocityText = jQuery("#what-if-velocity"),
              debugInfo   = jQuery("#debug-info");

          velocityText.blur(function() {
            var velocity = parseInt(velocityText.val());
            var iterations = remainingIterations(velocity, remainingStoryPoints);
            var expectedDate = expectedCompletionDateFor(lastIterEndDate, daysInIter, iterations);
            var dateString = expectedDate.getFullYear() + '-' + (expectedDate.getMonth()+1) + '-' + expectedDate.getDate();
            dateCalcText.val(dateString);
          });

          dateCalcText.blur(function() {
            var desiredEndDate = new Date(dateCalcText.val());
            var dayDiff = dateDiffInDays(lastIterEndDate, desiredEndDate);
            var numberOfIterations = Math.ceil(dayDiff / daysInIter);
            var requiredVelocity = remainingStoryPoints / numberOfIterations;
            velocityText.val(requiredVelocity);
          });

        } catch(err) {
          debug-info.html(err);
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
      if method_sym.to_s =~ /^(.*)_[field|parameter|type]$/
        true
      else
        super
      end
    end

  end

end
