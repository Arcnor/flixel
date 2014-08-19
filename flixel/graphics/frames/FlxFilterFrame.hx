package flixel.graphics.frames;

import flash.display.BitmapData;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.FlxG;
import flixel.math.FlxAngle;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.graphics.FlxGraphic;

/**
 * Base class for all frame types
 */
class FlxFilterFrame extends FlxFrame
{	
	/**
	 * Original frame
	 */
	public var sourceFrame(default, null):FlxFrame;
	
	/**
	 * Frames collection which this frame belongs to.
	 */
	public var filterFrames(default, null):FilterFrames;
	
	public function new(parent:FlxGraphic, sourceFrame:FlxFrame, filterFrames:FilterFrames)
	{
		super(parent);
		
		type = FrameType.FILTER;
		this.sourceFrame = sourceFrame;
		this.filterFrames = filterFrames;
	}
	
	override public function paintOnBitmap(bmd:BitmapData = null):BitmapData
	{
		var result:BitmapData = null;
		
		if (bmd != null && (bmd.width == sourceSize.x && bmd.height == sourceSize.y))
		{
			result = bmd;
			
			var w:Int = bmd.width;
			var h:Int = bmd.height;
			
			if (w > frame.width || h > frame.height)
			{
				var rect:Rectangle = FlxRect.RECT;
				rect.setTo(0, 0, w, h);
				bmd.fillRect(rect, FlxColor.RED);
			}
		}
		else if (bmd != null)
		{
			bmd.dispose();
		}
		
		if (result == null)
		{
			result = new BitmapData(Std.int(sourceSize.x), Std.int(sourceSize.y), true, FlxColor.TRANSPARENT);
		}
		
		var point:Point = FlxPoint.POINT;
		point.setTo(0.5 * filterFrames.widthInc, 0.5 * filterFrames.heightInc);
		
		var rect:Rectangle = FlxRect.RECT;
		rect.setTo(0, 0, sourceFrame.sourceSize.x, sourceFrame.sourceSize.y);
		
		result.copyPixels(sourceFrame.getBitmap(), rect, point);
		
		// apply filters
		point.setTo(0, 0);
		rect.setTo(0, 0, sourceSize.x, sourceSize.y);
		
		for (filter in filterFrames.filters)
		{
			result.applyFilter(result, rect, point, filter);
		}
		
		return result;
	}
	
	override public function destroy():Void
	{
		sourceFrame = null;
		filterFrames = null;
		super.destroy();
	}
}