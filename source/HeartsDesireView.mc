import Toybox.Graphics;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.UserProfile;
import Toybox.Time;

//! Display graph of heart rate history
class HeartRateHistoryView extends WatchUi.View {

    //! Instance variable to store heart rate zones and font
    private var _heartRateZones as Lang.Array or Null;
    private var _bigNumProtomolecule as Toybox.WatchUi.FontResource or Null;
    private var _width, _height as Lang.Number or Null;

    //! Constructor
    public function initialize() {
        View.initialize();

        System.println("[" + Time.now().value() + "] initialize() - Initializing HeartRateHistoryView");

        // Determine and store HRZones once
        _heartRateZones = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC);
        System.println("[" + Time.now().value() + "] initialize() - Heart rate zones: " + _heartRateZones.toString());

        // Init the correct font        
        _bigNumProtomolecule = WatchUi.loadResource(Rez.Fonts.protomoleculefont);
        System.println("[" + Time.now().value() + "] initialize() - Font loaded: " + _bigNumProtomolecule);

        // Dummy Values, will be overwritten on onLayout
        _width = 50;
        _height = 50;

        System.println("[" + Time.now().value() + "] initialize() - Dummy width and height loaded: w = " + _width + ", h = " + _height);  
        System.println("[" + Time.now().value() + "] initialize() - Constructor finished");
    }

    // Get the heart rate iterator
    // @return The heart rate iterator
    private function getSensorRateIterator() {
        System.println("[" + Time.now().value() + "] getSensorRateIterator() - Getting heart rate iterator");

        // Check device for SensorHistory compatibility
        if ((Toybox has :SensorHistory) && (Toybox.SensorHistory has :getHeartRateHistory)) {
            var sixHours = new Time.Duration(21600);  // Six hours in seconds
            System.println("[" + Time.now().value() + "] getSensorRateIterator() - Invoking getHeartRateHistory method");

            return Toybox.SensorHistory.getHeartRateHistory({:period => sixHours, :order => SensorHistory.ORDER_OLDEST_FIRST});
        }

        return null;
    }

    public function onShow(){
        System.println("[" + Time.now().value() + "] onShow() - HeartRateHistoryView shown");
    }

    public function onLayout(dc) {
        System.println("[" + Time.now().value() + "] onLayout() - onLayout started");

        _width = dc.getWidth();
        _height = dc.getHeight();

        System.println("[" + Time.now().value() + "] onLayout() - Screen dimensions: width=" + _width + ", height=" + _height);
    }

    //! Update the view
    //! @param dc Device context
    public function onUpdate(dc) {
        System.println("[" + Time.now().value() + "] onUpdate() - Updating view");

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

        var sensorIter = getSensorRateIterator();

        // Nullcheck the sensorIterator
        if (sensorIter == null) {
            System.println("[" + Time.now().value() + "] onUpdate() - No heart rate data available");
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
            System.println("[" + Time.now().value() + "] onUpdate() - Time moments are null");
            return;
        }

        var oldestTime = oldestTimeMoment.value() as Lang.Number or Null;
        var newestTime = newestTimeMoment.value() as Lang.Number or Null;

        if (oldestTime == null || newestTime == null) {
            System.println("[" + Time.now().value() + "] onUpdate() - Oldest or newest time is null");
            return;
        }

        System.println("[" + Time.now().value() + "] onUpdate() - Oldest time: " + oldestTime);
        System.println("[" + Time.now().value() + "] onUpdate() - Newest time: " + newestTime);

        var totalDuration = newestTime - oldestTime;
        System.println("[" + Time.now().value() + "] onUpdate() - Total duration: " + totalDuration);

        // Getting the next sample
        var sample = sensorIter.next();
        // Nullchecking the next sample
        if (sample == null) {
            System.println("[" + Time.now().value() + "] onUpdate() - No samples found");
            return;
        }
        
        var nextSample = sample;
        var nextSampleTime = sample.when.value() as Lang.Number or Null;

        System.println("[" + Time.now().value() + "] onUpdate() - Starting graph drawing loop");
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
                    System.println("[" + Time.now().value() + "] onUpdate() - Drawing heart rate at x=" + x + ", y=" + y);
                }

                dc.drawLine(x, graphBottom, x, y);
            }
        }
    }
}
