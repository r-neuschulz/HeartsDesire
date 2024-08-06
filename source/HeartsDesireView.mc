import Toybox.Graphics;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.UserProfile;

//! Display graph of heart rate history
class HeartRateHistoryView extends WatchUi.View {

    //! Instance variable to store heart rate zones and font
    private var _heartRateZones as Lang.Array or Null;
    private var _bigNumProtomolecule as Toybox.WatchUi.FontResource or Null;
    private var _width, _height as Lang.Number or Null;

    //! Constructor
    public function initialize() {
        View.initialize();

        System.println("Initializing HeartRateHistoryView");

        // Determine and store HRZones once
        _heartRateZones = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC);
        System.println("Heart rate zones: " + _heartRateZones.toString());

        // Init the correct font        
        _bigNumProtomolecule = WatchUi.loadResource(Rez.Fonts.protomoleculefont);
        System.println("Font loaded: " + _bigNumProtomolecule); // I get until here, according to log.

        // Dummy Values, will be overwritten on onLayout
        _width = 50;
        _height = 50;

        System.println("Dummy width and height loaded: w = " + _width + ", h = " + _height);  
        System.println("Constructor finished");
    }

    //! Get the heart rate iterator
    //! @return The heart rate iterator
    private function getHeartRateIterator() as SensorHistoryIterator? {
        System.println("Getting heart rate iterator");
        if (Toybox has :SensorHistory && SensorHistory has :getHeartRateHistory) {
            var getMethod = new Lang.Method(SensorHistory, :getHeartRateHistory);
            var sixHours = new Time.Duration(21600);  // Six hours in seconds
            System.println("Invoking getHeartRateHistory method");
            return getMethod.invoke({:period => sixHours, :order => SensorHistory.ORDER_OLDEST_FIRST}) as SensorHistoryIterator;
        }
        return null;
    }

    public function onShow() as Void {
        System.println("HeartRateHistoryView shown");
    }

    public function onLayout(dc) {
        System.println("onLayout started");

        _width = dc.getWidth();
        _height = dc.getHeight();

        System.println("Screen dimensions: width=" + _width + ", height=" + _height);
    }

    //! Update the view
    //! @param dc Device context
    public function onUpdate(dc as Dc) as Void {
        System.println("Updating view");

        // Draw Background and clear device context
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Get and show the current time
        var clockTime = System.getClockTime();
        var timeStringHH = Lang.format("$1$", [clockTime.hour.format("%02d")]);
        var timeStringMM = Lang.format("$1$", [clockTime.min.format("%02d")]);

        // Draw HH part
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(_width / 2, _height * 0.28, _bigNumProtomolecule, timeStringHH, (Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER));

        // Draw MM part
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        dc.drawText(_width / 2, _height * 0.60, _bigNumProtomolecule, timeStringMM, (Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER));

        var sensorIter = getHeartRateIterator();

        // Nullcheck the sensorIterator
        if (sensorIter == null) {
            System.println("No heart rate data available");
            return;
        }

        var graphBottom = _height;
        var graphHeight = _height * 0.40;
        var graphWidth = _width;

        // Determine the total time span in the data
        var oldestTimeMoment = sensorIter.getOldestSampleTime() as Toybox.Time.Moment or Null;
        var newestTimeMoment = sensorIter.getNewestSampleTime() as Toybox.Time.Moment or Null;

        // Nullcheck the TimeMoments
        if (oldestTimeMoment == null || newestTimeMoment == null) {
            System.println("Time moments are null");
            return;
        }

        var oldestTime = oldestTimeMoment.value() as Lang.Number or Null;
        var newestTime = newestTimeMoment.value() as Lang.Number or Null;

        if (oldestTime == null || newestTime == null) {
            System.println("Oldest or newest time is null");
            return;
        }

        System.println("Oldest time: " + oldestTime);
        System.println("Newest time: " + newestTime);

        var totalDuration = newestTime - oldestTime;
        System.println("Total duration: " + totalDuration);

        // Getting the next sample
        var sample = sensorIter.next();
        // Nullchecking the next sample
        if (sample == null) {
            System.println("No samples found");
            return;
        }
        
        var nextSample = sample;
        var nextSampleTime = sample.when.value() as Lang.Number or Null;

        System.println("Starting graph drawing loop");
        for (var x = 0; x < graphWidth; x++) {
            // Calculate the target time for this x position
            var targetTime = oldestTime + (totalDuration * x / graphWidth);

            // Find the nearest sample to the target time
            while (nextSampleTime != null && nextSampleTime < targetTime) {
                sample = nextSample;
                nextSample = sensorIter.next();
                nextSampleTime = (nextSample != null) ? nextSample.when.value() : null;
            }

            if (sample != null && sample.data != null) {
                var heartRate = sample.data;
                var y = graphBottom*1.0 - (heartRate*1.0 / _heartRateZones[5]*1.0) * graphHeight;

                // Color it, depending on the HR Zones, currently set for Running
                if (heartRate < _heartRateZones[0]) {
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
                } else if (heartRate <= _heartRateZones[1]) {
                    dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_LT_GRAY);
                } else if (heartRate <= _heartRateZones[2]) {
                    dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
                } else if (heartRate <= _heartRateZones[3]) {
                    dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_GREEN);
                } else if (heartRate <= _heartRateZones[4]) {
                    dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_ORANGE);
                } else {
                    dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
                }

                //Printing one element of the loop here
                if (x == 0){
                    System.println("Drawing heart rate at x=" + x + ", y=" + y);
                }

                dc.drawLine(x, graphBottom, x, y);
            }
        }
    }
}
