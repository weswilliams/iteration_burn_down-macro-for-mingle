module CustomMacro

  class WhatIfScenario
    include CustomMacro

    def initialize(is_enabled, remaining_story_points, last_iter_end_date, days_in_iter)
      @is_enabled = is_enabled
      @remaining_story_points = remaining_story_points
      @last_iter_end_date = last_iter_end_date
      @days_in_iter = days_in_iter
    end

    def javascript
      return '' if !@is_enabled
      <<-JAVASCRIPT
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

      var lastIterEndDate = new Date('#{@last_iter_end_date.to_s}'),
          daysInIter = #{@days_in_iter},
          remainingStoryPoints = #{@remaining_story_points};

      var remainingIterations = function(velocity, remaining_story_points) {
        return Math.ceil(remaining_story_points / velocity);
      };

      var expectedCompletionDateFor = function(lastIterEndDate, daysInIter, remainingIterations) {
        return new Date(lastIterEndDate.getTime() + (1000 * 60 * 60 * 24 * (daysInIter * remainingIterations)));
      };

      var dateCalcText = jQuery("#what-if-date"),
          velocityText = jQuery("#what-if-velocity"),
          iterationsSpan = jQuery("#what-if-iterations"),
          debugInfo   = jQuery("#debug-info");

      velocityText.blur(function() {
        var velocity = parseInt(velocityText.val());
        var iterations = remainingIterations(velocity, remainingStoryPoints);
        var expectedDate = expectedCompletionDateFor(lastIterEndDate, daysInIter, iterations);
        var dateString = expectedDate.getFullYear() + '-' + (expectedDate.getMonth()+1) + '-' + expectedDate.getDate();
        iterationsSpan.html(iterations);
        dateCalcText.val(dateString);
      });

      dateCalcText.blur(function() {
        var desiredEndDate = new Date(dateCalcText.val());
        var dayDiff = dateDiffInDays(lastIterEndDate, desiredEndDate);
        var iterations = Math.ceil(dayDiff / daysInIter);
        var requiredVelocity = remainingStoryPoints / iterations;
        iterationsSpan.html(iterations);
        velocityText.val(requiredVelocity);
      });

    } catch(err) {
      debug-info.html(err);
    }
  });
</script>

      JAVASCRIPT
    end

    def velocity_field(disabled_value = $empty_column)
      @is_enabled ? "What if velocity: <input type='text' id='what-if-velocity'></input>" : disabled_value
    end

    def iterations_field(disabled_value = $empty_column)
      @is_enabled ? "<span id='what-if-iterations'></span>" : disabled_value
    end

    def date_field(disabled_value = $empty_column)
      @is_enabled ? "What if date: <input type='text' id='what-if-date'></input>" : disabled_value
    end

  end

end