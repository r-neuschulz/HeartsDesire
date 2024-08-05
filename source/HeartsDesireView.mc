import Toybox.Graphics;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.UserProfile;

//! Display graph of heart rate history
class HeartRateHistoryView extends WatchUi.View {

    //! Constructor
    public function initialize() {
        View.initialize();
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
        //Get the hear Rate Zones (todo: only determine once)
        var heartRateZones = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var sensorIter = getHeartRateIterator();
        if (sensorIter != null) {
            var sample = sensorIter.next();
            var x = 0;
            var graphBottom = dc.getHeight();
            var graphHeight = graphBottom * 0.45;

            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_GREEN);

            while (sample != null) {
                var heartRate = sample.data;
                if (heartRate != null) {
                    var y = graphBottom - (heartRate / 200.0) * graphHeight;
                    // Color it, depending on the HR Zones, currently 
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
                x++;
                sample = sensorIter.next();
            }
        }

        // Get and show the current time
        var clockTime = System.getClockTime();
        var timeStringHH = Lang.format("$1$", [clockTime.hour.format("%02d")]);
        var timeStringMM = Lang.format("$1$", [clockTime.min.format("%02d")]);

        // Draw HH part
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLACK);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() * 0.25, Graphics.FONT_SYSTEM_NUMBER_THAI_HOT, timeStringHH, (Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER));

        // Draw MM part
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() * 0.55, Graphics.FONT_SYSTEM_NUMBER_THAI_HOT, timeStringMM, (Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER));
    }
}
