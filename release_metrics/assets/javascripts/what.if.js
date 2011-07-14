var whatIf = {};

whatIf.init = function(daysInIter, remainingStoryPoints, lastIterEndDate) {
    try {
        var dateCalcText = jQuery("#what-if-date"),
            velocityText = jQuery("#what-if-velocity"),
            iterationsSpan = jQuery("#what-if-iterations"),
            debugInfo = jQuery("#debug-info");

        var dateDiffInDays = function(d1, d2) {
            var t2 = d2.getTime();
            var t1 = d1.getTime();
            return parseInt((t2 - t1) / (24 * 3600 * 1000));
        };

        var remainingIterations = function(velocity, remaining_story_points) {
            return Math.ceil(remaining_story_points / velocity);
        };

        var expectedCompletionDateFor = function(lastIterEndDate, daysInIter, remainingIterations) {
            return new Date(lastIterEndDate.getTime() + (1000 * 60 * 60 * 24 * (daysInIter * remainingIterations)));
        };

        velocityText.blur(function() {
            var velocity = parseInt(velocityText.val());
            var iterations = remainingIterations(velocity, remainingStoryPoints);
            var expectedDate = expectedCompletionDateFor(lastIterEndDate, daysInIter, iterations);
            var dateString = expectedDate.getFullYear() + '-' + (expectedDate.getMonth() + 1) + '-' + expectedDate.getDate();
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
        debugInfo.html(err);
    }
};