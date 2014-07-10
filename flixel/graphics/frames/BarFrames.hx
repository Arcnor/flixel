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
		
		// TODO: Continue from here...
		
		return null;
		
		/*
		var startX:Int = Std.int(region.x);
		var startY:Int = Std.int(region.y);
		
		var frameWidth:Float = 0;
		var frameHeight:Float = 0;
		
		var frameX:Float = 0;
		var frameY:Float = 0;
		
		var frameRect:Rectangle;
		var sourceSize:FlxPoint;
		var offset:FlxPoint;
		
		var ratio:Float = 0;
		
		for (i in 0...(numFrames))
		{
			ratio = i / numFrames;
			frameWidth = width;
			frameHeight = height;
			frameX = 0;
			frameY = 0;
			
			switch (barType)
			{
				case FlxBarFillDirection.LEFT_TO_RIGHT:
					frameWidth = width * ratio;
					
				case FlxBarFillDirection.TOP_TO_BOTTOM:
					frameHeight = height * ratio;
					
				case FlxBarFillDirection.BOTTOM_TO_TOP:
					frameHeight = height * ratio;
					frameY = height - frameHeight;
					
				case FlxBarFillDirection.RIGHT_TO_LEFT:
					frameWidth = width * ratio;
					frameX = width - frameWidth;
					
				case FlxBarFillDirection.HORIZONTAL_INSIDE_OUT:
					frameWidth = width * ratio;
					frameX = 0.5 * (width - frameWidth);
					
				case FlxBarFillDirection.HORIZONTAL_OUTSIDE_IN:
					frameWidth = width * (1 - ratio);
					frameX = 0.5 * (width - frameWidth);
					
				case FlxBarFillDirection.VERTICAL_INSIDE_OUT:
					frameHeight = height * ratio;
					frameY = 0.5 * (height - frameHeight);
					
				case FlxBarFillDirection.VERTICAL_OUTSIDE_IN:
					frameHeight = height * (1 - ratio);
					frameY = 0.5 * (height - frameHeight);
			}
			
			frameRect = new Rectangle(startX + frameX, startY + frameY, frameWidth, frameHeight);
			sourceSize = FlxPoint.get(width, height);
			offset = FlxPoint.get(frameX, frameY);
			
			barFrames.addAtlasFrame(frameRect, sourceSize, offset);
		}
		
		return barFrames;
		*/
		
		/*
		var xSpacing:Int = Std.int(frameSpacing.x);
		var ySpacing:Int = Std.int(frameSpacing.y);
		
		var frameWidth:Int = Std.int(frameSize.x);
		var frameHeight:Int = Std.int(frameSize.y);
		
		var spacedWidth:Int = frameWidth + xSpacing;
		var spacedHeight:Int = frameHeight + ySpacing;
		
		var clippedRect:Rectangle = new Rectangle(frame.offset.x, frame.offset.y, frame.frame.width, frame.frame.height);
		
		var helperRect:Rectangle = new Rectangle(0, 0, frameWidth, frameHeight);
		var frameRect:Rectangle;
		var frameOffset:FlxPoint;
		
		var rotated:Bool = (frame.type == FrameType.ROTATED);
		var angle:Float = 0;
		
		var numRows:Int = (frameHeight == 0) ? 1 : Std.int((bitmapHeight + ySpacing) / spacedHeight);
		var numCols:Int = (frameWidth == 0) ? 1 : Std.int((bitmapWidth + xSpacing) / spacedWidth);
		
		var startX:Int = 0;
		var startY:Int = 0;
		var dX:Int = spacedWidth;
		var dY:Int = spacedHeight;
		
		if (rotated)
		{
			var rotatedFrame:FlxRotatedFrame = cast frame;
			angle = rotatedFrame.angle;
			
			if (angle == -90)
			{
				startX = bitmapHeight - spacedHeight;
				startY = 0;
				dX = -spacedHeight;
				dY = spacedWidth;
				
				clippedRect.x = frame.sourceSize.y - frame.offset.y - frame.frame.width;
				clippedRect.y = frame.offset.x;
			}
			else if (angle == 90)
			{
				startX = 0;
				startY = bitmapWidth - spacedWidth;
				dX = spacedHeight;
				dY = -spacedWidth;
				clippedRect.x = frame.offset.y;
				clippedRect.y = frame.sourceSize.x - frame.offset.x - frame.frame.height;
			}
			
			helperRect.width = frameHeight;
			helperRect.height = frameWidth;
		}
		
		for (j in 0...(numRows))
		{
			for (i in 0...(numCols))	
			{
				helperRect.x = startX + dX * ((angle == 0) ? i : j);
				helperRect.y = startY + dY * ((angle == 0) ? j : i);
				frameRect = clippedRect.intersection(helperRect);
				
				if (frameRect.width == 0 || frameRect.height == 0)
				{
					frameRect.x = frameRect.y = 0;
					frameRect.width = frameWidth;
					frameRect.height = frameHeight;
					TileFrames.addEmptyFrame(frameRect);
				}
				else
				{
					if (angle == 0)
					{
						frameOffset = FlxPoint.get(frameRect.x - helperRect.x, frameRect.y - helperRect.y);
					}
					else if (angle == -90)
					{
						frameOffset = FlxPoint.get(frameRect.y - helperRect.y, frameRect.x - helperRect.x);
					}
					else
					{
						frameOffset = FlxPoint.get(helperRect.bottom - frameRect.bottom, frameRect.x - helperRect.x);
					}
					frameRect.x += frame.frame.x - clippedRect.x;
					frameRect.y += frame.frame.y - clippedRect.y;
					TileFrames.addAtlasFrame(frameRect, FlxPoint.get(frameWidth, frameHeight), frameOffset, null, angle);
				}
			}
		}
		
		return TileFrames;
		*/
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
		
		var frameWidth:Float = 0;
		var frameHeight:Float = 0;
		
		var frameX:Float = 0;
		var frameY:Float = 0;
		
		var frameRect:Rectangle;
		var sourceSize:FlxPoint;
		var offset:FlxPoint;
		
		var ratio:Float = 0;
		
		for (i in 0...(numFrames))
		{
			ratio = i / numFrames;
			frameWidth = width;
			frameHeight = height;
			frameX = 0;
			frameY = 0;
			
			switch (barType)
			{
				case FlxBarFillDirection.LEFT_TO_RIGHT:
					frameWidth = width * ratio;
					
				case FlxBarFillDirection.TOP_TO_BOTTOM:
					frameHeight = height * ratio;
					
				case FlxBarFillDirection.BOTTOM_TO_TOP:
					frameHeight = height * ratio;
					frameY = height - frameHeight;
					
				case FlxBarFillDirection.RIGHT_TO_LEFT:
					frameWidth = width * ratio;
					frameX = width - frameWidth;
					
				case FlxBarFillDirection.HORIZONTAL_INSIDE_OUT:
					frameWidth = width * ratio;
					frameX = 0.5 * (width - frameWidth);
					
				case FlxBarFillDirection.HORIZONTAL_OUTSIDE_IN:
					frameWidth = width * (1 - ratio);
					frameX = 0.5 * (width - frameWidth);
					
				case FlxBarFillDirection.VERTICAL_INSIDE_OUT:
					frameHeight = height * ratio;
					frameY = 0.5 * (height - frameHeight);
					
				case FlxBarFillDirection.VERTICAL_OUTSIDE_IN:
					frameHeight = height * (1 - ratio);
					frameY = 0.5 * (height - frameHeight);
			}
			
			frameRect = new Rectangle(startX + frameX, startY + frameY, frameWidth, frameHeight);
			sourceSize = FlxPoint.get(width, height);
			offset = FlxPoint.get(frameX, frameY);
			
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