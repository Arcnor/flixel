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

// TODO: use FlxPoint and FlxRect as method arguments
// in this and other frames related classes.

/**
 * Spritesheet frame collection. It is used for tilemaps and animated sprites. 
 */
class SpritesheetFrames extends FlxFramesCollection
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
	/**
	 * The size of frame in this spritesheet.
	 */
	private var frameSize:Point;
	/**
	 * offsets between frames in this spritesheet.
	 */
	private var frameSpacing:Point;
	
	private function new(parent:FlxGraphic) 
	{
		super(parent, FrameCollectionType.SPRITESHEET);
	}
	
	/**
	 * Gets source bitmapdata, generates new bitmapdata with spaces between frames (if there is no such bitmapdata in the cache already) 
	 * and creates SpritesheetFrames collection.
	 * 
	 * @param	source			the source of graphic for frame collection (can be String, BitmapData or FlxGraphic).
	 * @param	frameSize		the size of tiles in spritesheet
	 * @param	frameSpacing	desired offsets between frames in spritesheet
	 * 							(this method takes spritesheet bitmap without offsets between frames and adds them).
	 * @param	region			Region of image to generate spritesheet from. Default value is null, which means that
	 * 							whole image will be used for spritesheet generation
	 * @return	Newly created spritesheet
	 */
	// TODO: make it accept only FlxGraphic, String, or BitmapData
	public static function fromBitmapWithSpacings(source:Dynamic, frameSize:Point, frameSpacing:Point, region:Rectangle = null):SpritesheetFrames
	{
		var graphic:FlxGraphic = FlxG.bitmap.add(source, false);
		if (graphic == null) return null;
		
		var key:String = FlxG.bitmap.getKeyWithSpacings(graphic.key, frameSize, frameSpacing, region);
		var result:FlxGraphic = FlxG.bitmap.get(key);
		if (result == null)
		{
			var bitmap:BitmapData = FlxBitmapDataUtil.addSpacing(graphic.bitmap, frameSize, frameSpacing, region);
			result = FlxG.bitmap.add(bitmap, false, key);
		}
		
		return SpritesheetFrames.fromRectangle(result, frameSize, null, frameSpacing);
	}
	
	/**
	 * Generates spritesheet frame collection from provided frame. Can be usefull for spritesheets packed into atlases.
	 * It can generate spritesheets from rotated and cropped frames also, which is important for devices with small amount of memory.
	 * 
	 * @param	frame			frame, containg spritesheet image
	 * @param	frameSize		the size of tiles in spritesheet
	 * @param	frameSpacing	offsets between frames in spritesheet. Default value is null, which means no offsets between tiles
	 * @return	Newly created spritesheet frame collection.
	 */
	public static function fromFrame(frame:FlxFrame, frameSize:Point, frameSpacing:Point = null):SpritesheetFrames
	{
		var graphic:FlxGraphic = frame.parent;
		// find SpritesheetFrames object, if there is one already
		var spritesheetFrames:SpritesheetFrames = SpritesheetFrames.findFrame(graphic, frameSize, null, frame, frameSpacing);
		if (spritesheetFrames != null)
		{
			return spritesheetFrames;
		}
		
		// or create it, if there is no such object
		frameSpacing = (frameSpacing != null) ? frameSpacing : new Point();
		
		spritesheetFrames = new SpritesheetFrames(graphic);
		spritesheetFrames.atlasFrame = frame;
		spritesheetFrames.region = frame.frame;
		spritesheetFrames.frameSize = frameSize;
		spritesheetFrames.frameSpacing = frameSpacing;
		
		var bitmapWidth:Int = Std.int(frame.sourceSize.x);
		var bitmapHeight:Int = Std.int(frame.sourceSize.y);
		
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
		
		var frameX:Int = 0;
		var frameY:Int = 0;
		
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
		
		var startOffsetX:Float = clippedRect.x;
		var startOffsetY:Float = clippedRect.y;	
		
		for (j in 0...(numRows))
		{
			for (i in 0...(numCols))	
			{
				helperRect.x = frameX = startX + dX * ((angle == 0) ? i : j);
				helperRect.y = frameY = startY + dY * ((angle == 0) ? j : i);
				frameRect = clippedRect.intersection(helperRect);
				
				if (frameRect.width == 0 || frameRect.height == 0)
				{
					frameRect.x = frameRect.y = 0;
					frameRect.width = frameWidth;
					frameRect.height = frameHeight;
					spritesheetFrames.addEmptyFrame(frameRect);
				}
				else
				{
					if (angle == 0)
					{
						frameOffset = FlxPoint.get(frameRect.x - frameX, frameRect.y - frameY);
					}
					else if (angle == -90)
					{
						frameOffset = FlxPoint.get(frameRect.y - frameY, frameRect.x - frameX);
					}
					else
					{
						frameOffset = FlxPoint.get(helperRect.bottom - frameRect.bottom, frameRect.x - helperRect.x);
					}
					frameRect.x += frame.frame.x - startOffsetX;
					frameRect.y += frame.frame.y - startOffsetY;
					spritesheetFrames.addAtlasFrame(frameRect, FlxPoint.get(frameWidth, frameHeight), frameOffset, null, angle);
				}
			}
		}
		
		return spritesheetFrames;
	}
	
	/**
	 * Generates spritesheet frame collection from provided region of image.
	 * 
	 * @param	graphic			source graphic for spritesheet.
	 * @param	frameSize		the size of tiles in spritesheet.
	 * @param	region			region of image to use for spritesheet generation. Default value is null,
	 * 							which means that the whole image will be used for it.
	 * @param	frameSpacing	offsets between frames in spritesheet. Default value is null, which means no offsets between tiles
	 * @return	Newly created spritesheet frame collection.
	 */
	public static function fromGraphic(graphic:FlxGraphic, frameSize:Point, region:Rectangle = null, frameSpacing:Point = null):SpritesheetFrames
	{
		// find SpritesheetFrames object, if there is one already
		var spritesheetFrames:SpritesheetFrames = SpritesheetFrames.findFrame(graphic, frameSize, region, null, frameSpacing);
		if (spritesheetFrames != null)
		{
			return spritesheetFrames;
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
		
		frameSpacing = (frameSpacing != null) ? frameSpacing : new Point();
		
		spritesheetFrames = new SpritesheetFrames(graphic);
		spritesheetFrames.region = region;
		spritesheetFrames.atlasFrame = null;
		spritesheetFrames.frameSize = frameSize;
		spritesheetFrames.frameSpacing = frameSpacing;
		
		var bitmapWidth:Int = Std.int(region.width);
		var bitmapHeight:Int = Std.int(region.height);
		
		var startX:Int = Std.int(region.x);
		var startY:Int = Std.int(region.y);
		
		var xSpacing:Int = Std.int(frameSpacing.x);
		var ySpacing:Int = Std.int(frameSpacing.y);
		
		var width:Int = Std.int(frameSize.x);
		var height:Int = Std.int(frameSize.y);
		
		var spacedWidth:Int = width + xSpacing;
		var spacedHeight:Int = height + ySpacing;
		
		var numRows:Int = (height == 0) ? 1 : Std.int((bitmapHeight + ySpacing) / spacedHeight);
		var numCols:Int = (width == 0) ? 1 : Std.int((bitmapWidth + xSpacing) / spacedWidth);
		
		var tempRect:Rectangle;
		
		for (j in 0...(numRows))
		{
			for (i in 0...(numCols))
			{
				tempRect = new Rectangle(startX + i * spacedWidth, startY + j * spacedHeight, width, height);
				spritesheetFrames.addSpriteSheetFrame(tempRect);
			}
		}
		
		return spritesheetFrames;
	}
	
	/**
	 * Generates spritesheet frame collection from provided region of image.
	 * 
	 * @param	source			source graphic for spritesheet.
	 * 							It can be BitmapData, String or FlxGraphic.
	 * @param	frameSize		the size of tiles in spritesheet.
	 * @param	region			region of image to use for spritesheet generation. Default value is null,
	 * 							which means that whole image will be used for it.
	 * @param	frameSpacing	offsets between frames in spritesheet. Default value is null, which means no offsets between tiles
	 * @return	Newly created spritesheet frame collection
	 */
	// TODO: make it accept only FlxGraphic, String, or BitmapData
	public static function fromRectangle(source:Dynamic, frameSize:Point, region:Rectangle = null, frameSpacing:Point = null):SpritesheetFrames
	{
		var graphic:FlxGraphic = FlxG.bitmap.add(source, false);
		if (graphic == null)	return null;
		return fromGraphic(graphic, frameSize, region, frameSpacing);
	}
	
	/**
	 * Searches SpritesheetFrames object for specified FlxGraphic object which have the same parameters (frame size, frame spacings, region of image, etc.).
	 * 
	 * @param	graphic			FlxGraphic object to search SpritesheetFrames for.
	 * @param	frameSize		The size of tiles in SpritesheetFrames.
	 * @param	region			The region of source image used for spritesheet generation.
	 * @param	atlasFrame		Optional FlxFrame object used for spritesheet generation.
	 * @param	frameSpacing	Spaces between tiles in spritesheet.
	 * @return	ImageFrame object which corresponds to specified arguments. Could be null if there is no such SpritesheetFrames.
	 */
	public static function findFrame(graphic:FlxGraphic, frameSize:Point, region:Rectangle = null, atlasFrame:FlxFrame = null, frameSpacing:Point = null):SpritesheetFrames
	{
		var spritesheetFrames:Array<SpritesheetFrames> = cast graphic.getFramesCollections(FrameCollectionType.SPRITESHEET);
		var sheet:SpritesheetFrames;
		
		for (sheet in spritesheetFrames)
		{
			if (sheet.equals(frameSize, region, null, frameSpacing))
			{
				return sheet;
			}
		}
		
		return null;
	}
	
	/**
	 * SpritesheetFrames comparison method. For internal use.
	 */
	public function equals(frameSize:Point, region:Rectangle = null, atlasFrame:FlxFrame = null, frameSpacing:Point = null):Bool
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
		
		if (frameSpacing == null)
		{
			frameSpacing = POINT1;
			POINT1.x = POINT1.y = 0;
		}
		
		return (this.atlasFrame == atlasFrame && this.region.equals(region) && this.frameSize.equals(frameSize) && this.frameSpacing.equals(frameSpacing));
	}
	
	override public function destroy():Void 
	{
		super.destroy();
		atlasFrame = null;
		region = null;
		frameSize = null;
		frameSpacing = null;
	}
}