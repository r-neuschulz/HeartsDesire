import Toybox.Graphics;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.UserProfile;

//! Display graph of heart rate history
//! Display graph of heart rate history
class HeartRateHistoryView extends WatchUi.View {

    //! Instance variable to store heart rate zones
    private var heartRateZones as Lang.Array;
    private var bigNumProtomolecule;

    //! Constructor
    public function initialize() {
        View.initialize();

        // Determine and store HRZones once
        heartRateZones = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC);

        // Init the correct font        
        bigNumProtomolecule = WatchUi.loadResource(Rez.Fonts.protomoleculefont); 
    }

    //! Get the heart rate iterator
    //! @return The heart rate iterator
    private function getHeartRateIterator() as SensorHistoryIterator? {
        if (Toybox has :SensorHistory && SensorHistory has :getHeartRateHistory) {
            var getMethod = new Lang.Method(SensorHistory, :getHeartRateHistory);
            var sixHours = new Time.Duration(21600);  // Six hours in seconds
            return getMethod.invoke({:period => sixHours, :order => SensorHistory.ORDER_OLDEST_FIRST}) as SensorHistoryIterator;
        }
        return null;
    }

    //! Update the view
    //! @param dc Device context
    public function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Get and show the current time
        var clockTime = System.getClockTime();
        var timeStringHH = Lang.format("$1$", [clockTime.hour.format("%02d")]);
        var timeStringMM = Lang.format("$1$", [clockTime.min.format("%02d")]);

        // Draw HH part
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() * 0.28, bigNumProtomolecule, timeStringHH, (Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER));

        // Draw MM part
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() * 0.60, bigNumProtomolecule, timeStringMM, (Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER));

        var sensorIter = getHeartRateIterator();
        if (sensorIter != null) {
            var graphBottom = dc.getHeight();
            var graphHeight = dc.getHeight() * 0.40;
            var graphWidth = dc.getWidth();

            // Determine the total time span in the data
            var oldestTime = sensorIter.getOldestSampleTime().value();
            var newestTime = sensorIter.getNewestSampleTime().value();
            var totalDuration = newestTime - oldestTime;

            var sample = sensorIter.next();
            var nextSample = sample;
            var nextSampleTime = (sample != null) ? sample.when.value() : null;

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
                                      
                    var y = graphBottom*1.0 - (heartRate*1.0 / heartRateZones[5]*1.0) * graphHeight;

                    // Color it, depending on the HR Zones, currently set for Running
                    if (heartRate < heartRateZones[0]) {
                        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
                    } else if (heartRate <= heartRateZones[1]) {
                        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_LT_GRAY);
                    } else if (heartRate <= heartRateZones[2]) {
                        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
                    } else if (heartRate <= heartRateZones[3]) {
                        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_GREEN);
                    } else if (heartRate <= heartRateZones[4]) {
                        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_ORANGE);
                    } else {
                        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
                    }

                    dc.drawLine(x, graphBottom, x, y);
                }
            }
        }
    }
}
