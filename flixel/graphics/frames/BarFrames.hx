package flixel.graphics.frames;

import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FrameCollectionType;
import flixel.system.layer.TileSheetExt;
import flixel.math.FlxPoint;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxBitmapDataUtil;
import flixel.ui.FlxBar.FlxBarFillDirection;

/**
 * Bar frames collection. It is used by FlxBar class only. 
 */
class BarFrames extends FlxFramesCollection
{
	public static var POINT1:Point = new Point();
	public static var POINT2:Point = new Point();
	
	public static var RECT:Rectangle = new Rectangle();
	
	/**
	 * Atlas frame from which this frame collection had been generated.
	 * Could be null if this collection generated from rectangle.
	 */
	private var atlasFrame:FlxFrame;
	/**
	 * image region of image from which this frame collection had been generated.
	 */
	private var region:Rectangle;
	
	private var barType:FlxBarFillDirection;
	
	private function new(parent:FlxGraphic, barType:FlxBarFillDirection)
	{
		super(parent, FrameCollectionType.BAR(barType));
		this.barType = barType;
	}
	
	/**
	 * Generates BarFrames collection from provided frame. Can be usefull for images packed into atlases.
	 * It can generate BarFrames from rotated and cropped frames also, which is important for devices with small amount of memory.
	 * 
	 * @param	frame			frame, containg FlxBar image.
	 * @param	barType			fill direction of frames in FlxBar.
	 * @param	numFrames		number of frames (values) of FlxBar to create.
	 * @return	Newly created BarFrames collection.
	 */
	public static function fromFrame(frame:FlxFrame, barType:FlxBarFillDirection, numFrames:Int = 100):BarFrames
	{
		var graphic:FlxGraphic = frame.parent;
		// find BarFrames object, if there is one already
		var barFrames:BarFrames = BarFrames.findFrame(graphic, barType, numFrames, null, frame);
		if (barFrames != null)
		{
			return barFrames;
		}
		
		// or create it, if there is no such object
		barFrames = new BarFrames(graphic, barType);
		barFrames.atlasFrame = frame;
		barFrames.region = frame.frame;
		
		var width:Int = Std.int(frame.sourceSize.x);
		var height:Int = Std.int(frame.sourceSize.y);
		
		var clippedRect:Rectangle = new Rectangle(frame.offset.x, frame.offset.y, frame.frame.width, frame.frame.height);
		var helperRect:Rectangle = new Rectangle(0, 0, width, height);
		var frameRect:Rectangle;
		var frameOffset:FlxPoint;
		var sourceSize:FlxPoint;
		
		var x:Float, y:Float, w:Float, h:Float;
		var ratio:Float = 0;
		
		var rotated:Bool = (frame.type == FrameType.ROTATED);
		var angle:Float = 0;
		
		if (rotated)
		{
			var rotatedFrame:FlxRotatedFrame = cast frame;
			angle = rotatedFrame.angle;
			
			clippedRect.width = frame.frame.height;
			clippedRect.height = frame.frame.width;
		}
		
		for (i in 0...(numFrames + 1))
		{
			ratio = i / numFrames;
			helperRect.setTo(0, 0, width, height);
			
			switch (barType)
			{
				case FlxBarFillDirection.LEFT_TO_RIGHT:
					helperRect.width = width * ratio;
					
				case FlxBarFillDirection.TOP_TO_BOTTOM:
					helperRect.height = height * ratio;
					
				case FlxBarFillDirection.BOTTOM_TO_TOP:
					helperRect.height = height * ratio;
					helperRect.y = height - helperRect.height;
					
				case FlxBarFillDirection.RIGHT_TO_LEFT:
					helperRect.width = width * ratio;
					helperRect.x = width - helperRect.width;
					
				case FlxBarFillDirection.HORIZONTAL_INSIDE_OUT:
					helperRect.width = width * ratio;
					helperRect.x = 0.5 * (width - helperRect.width);
					
				case FlxBarFillDirection.HORIZONTAL_OUTSIDE_IN:
					helperRect.width = width * (1 - ratio);
					helperRect.x = 0.5 * (width - helperRect.width);
					
				case FlxBarFillDirection.VERTICAL_INSIDE_OUT:
					helperRect.height = height * ratio;
					helperRect.y = 0.5 * (height - helperRect.height);
					
				case FlxBarFillDirection.VERTICAL_OUTSIDE_IN:
					helperRect.height = height * (1 - ratio);
					helperRect.y = 0.5 * (height - helperRect.height);
			}
			
			frameRect = clippedRect.intersection(helperRect);
			
			if (frameRect.width == 0 || frameRect.height == 0)
			{
				frameRect.setTo(0, 0, width, height);
				barFrames.addEmptyFrame(frameRect);
			}
			else
			{
				frameOffset = FlxPoint.get(frameRect.x, frameRect.y);
				sourceSize = FlxPoint.get(width, height);
				
				x = frameRect.x;
				y = frameRect.y;
				w = frameRect.width;
				h = frameRect.height;
				
				if (angle == 0)
				{
					frameRect.x -= clippedRect.x;
					frameRect.y -= clippedRect.y;
				}
				if (angle == -90)
				{
					frameRect.x = clippedRect.bottom - y - h;
					frameRect.y = x - clippedRect.x;
					frameRect.width = h;
					frameRect.height = w;
				}
				else if (angle == 90)
				{
					frameRect.x = y - clippedRect.y;
					frameRect.y = clippedRect.right - x - w;
					frameRect.width = h;
					frameRect.height = w;
				}
				
				frameRect.x += frame.frame.x;
				frameRect.y += frame.frame.y;
				barFrames.addAtlasFrame(frameRect, sourceSize, frameOffset, null, angle);
			}
		}
		
		return barFrames;
	}
	
	/**
	 * Generates BarFrames collection from provided region of image.
	 * 
	 * @param	graphic			source graphic for BarFrames.
	 * @param	barType			the fill direction of BarFrames.
	 * @param	numFrames		number of frames (values) of FlxBar to create.
	 * @param	region			region of image to use for BarFrames generation. Default value is null,
	 * 							which means that the whole image will be used for it.
	 * @return	Newly created BarFrames collection.
	 */
	public static function fromGraphic(graphic:FlxGraphic, barType:FlxBarFillDirection, numFrames:Int = 100, region:Rectangle = null):BarFrames
	{
		// find BarFrames object, if there is one already
		var barFrames:BarFrames = BarFrames.findFrame(graphic, barType, numFrames, region, null);
		if (barFrames != null)
		{
			return barFrames;
		}
		
		// or create it, if there is no such object
		if (region == null)
		{
			region = graphic.bitmap.rect;
		}
		else
		{
			if (region.width == 0)
			{
				region.width = graphic.width - region.x;
			}
			
			if (region.height == 0)
			{
				region.height = graphic.height - region.y;
			}
		}
		
		barFrames = new BarFrames(graphic, barType);
		barFrames.region = region;
		barFrames.atlasFrame = null;
		
		var width:Int = Std.int(region.width);
		var height:Int = Std.int(region.height);
		
		var startX:Int = Std.int(region.x);
		var startY:Int = Std.int(region.y);
		
		var frameRect:Rectangle;
		var sourceSize:FlxPoint;
		var offset:FlxPoint;
		
		var ratio:Float = 0;
		
		for (i in 1...(numFrames + 1))
		{
			ratio = i / numFrames;
			frameRect = new Rectangle(0, 0, width, height);
			
			switch (barType)
			{
				case FlxBarFillDirection.LEFT_TO_RIGHT:
					frameRect.width = width * ratio;
					
				case FlxBarFillDirection.TOP_TO_BOTTOM:
					frameRect.height = height * ratio;
					
				case FlxBarFillDirection.BOTTOM_TO_TOP:
					frameRect.height = height * ratio;
					frameRect.y = height - frameRect.height;
					
				case FlxBarFillDirection.RIGHT_TO_LEFT:
					frameRect.width = width * ratio;
					frameRect.x = width - frameRect.width;
					
				case FlxBarFillDirection.HORIZONTAL_INSIDE_OUT:
					frameRect.width = width * ratio;
					frameRect.x = 0.5 * (width - frameRect.width);
					
				case FlxBarFillDirection.HORIZONTAL_OUTSIDE_IN:
					frameRect.width = width * (1 - ratio);
					frameRect.x = 0.5 * (width - frameRect.width);
					
				case FlxBarFillDirection.VERTICAL_INSIDE_OUT:
					frameRect.height = height * ratio;
					frameRect.y = 0.5 * (height - frameRect.height);
					
				case FlxBarFillDirection.VERTICAL_OUTSIDE_IN:
					frameRect.height = height * (1 - ratio);
					frameRect.y = 0.5 * (height - frameRect.height);
			}
			
			sourceSize = FlxPoint.get(width, height);
			offset = FlxPoint.get(frameRect.x, frameRect.y);
			
			frameRect.x += startX;
			frameRect.y += startY;
			
			barFrames.addAtlasFrame(frameRect, sourceSize, offset);
		}
		
		return barFrames;
	}
	
	/**
	 * Generates BarFrames collection from provided region of image.
	 * 
	 * @param	source			source graphic for spritesheet.
	 * 							It can be BitmapData, String or FlxGraphic.
	 * @param	barType			fill direction of bar frames.
	 * @param	numFrames		number of frames (values) of FlxBar to create.
	 * @param	region			region of image to use for BarFrames generation. Default value is null,
	 * 							which means that whole image will be used for it.
	 * @return	Newly created BarFrames collection
	 */
	// TODO: make it accept only FlxGraphic, String, or BitmapData
	public static function fromRectangle(source:Dynamic, barType:FlxBarFillDirection, numFrames:Int = 100, region:Rectangle = null):BarFrames
	{
		var graphic:FlxGraphic = FlxG.bitmap.add(source, false);
		if (graphic == null)	return null;
		return fromGraphic(graphic, barType, numFrames, region);
	}
	
	/**
	 * Searches BarFrames object for specified FlxGraphic object which have the same parameters (barType, region of image, etc.).
	 * 
	 * @param	graphic			FlxGraphic object to search BarFrames for.
	 * @param	barType			The type of FlxBar frames (or fill direction).
	 * @param	numFrames		number of frames (values) of FlxBar to create.
	 * @param	region			The region of source image used for BarFrames generation.
	 * @param	atlasFrame		Optional FlxFrame object used for BarFrames generation.
	 * @return	BarFrames object which corresponds to specified arguments. Could be null if there is no such BarFrames object.
	 */
	public static function findFrame(graphic:FlxGraphic, barType:FlxBarFillDirection, numFrames:Int = 100, region:Rectangle = null, atlasFrame:FlxFrame = null):BarFrames
	{
		var barFramesArr:Array<BarFrames> = cast graphic.getFramesCollections(FrameCollectionType.BAR(barType));
		var barFrames:BarFrames;
		
		for (barFrames in barFramesArr)
		{
			if (barFrames.equals(barType, numFrames, region, null))
			{
				return barFrames;
			}
		}
		
		return null;
	}
	
	/**
	 * BarFrames comparison method. For internal use.
	 */
	public function equals(barType:FlxBarFillDirection, numFrames:Int, region:Rectangle = null, atlasFrame:FlxFrame = null):Bool
	{
		if (atlasFrame != null)
		{
			region = atlasFrame.frame;
		}
		
		if (region == null)
		{
			region = RECT;
			RECT.x = RECT.y = 0;
			RECT.width = parent.width;
			RECT.height = parent.height;
		}
		
		return (this.atlasFrame == atlasFrame && this.region.equals(region) && this.barType == barType && this.numFrames == numFrames);
	}
	
	override public function destroy():Void 
	{
		super.destroy();
		atlasFrame = null;
		region = null;
		barType = null;
	}
}