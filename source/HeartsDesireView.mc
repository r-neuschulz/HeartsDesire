using Toybox.Graphics as Gfx;
using Toybox.Lang as Lang;
using Toybox.System as Sys;
using Toybox.UserProfile as User;
import Toybox.WatchUi;

class HeartsDesireView extends WatchUi.WatchFace {

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc) as Void {
        // Get and show the current time
        var clockTime = Sys.getClockTime();
        var timeStringHH = Lang.format("$1$", [clockTime.hour, clockTime.min.format("%02d")]);
        var timeStringMM = Lang.format("$2$", [clockTime.hour, clockTime.min.format("%02d")]);

        var viewHH = View.findDrawableById("TimeLabelHH") as Text;
        var viewMM = View.findDrawableById("TimeLabelMM") as Text;

        viewHH.setText(timeStringHH);
        viewMM.setText(timeStringMM);

        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }

}
