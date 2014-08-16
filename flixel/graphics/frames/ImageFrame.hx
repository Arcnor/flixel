package flixel.graphics.frames;

import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.system.layer.TileSheetExt;
import flixel.util.FlxDestroyUtil;
import flixel.math.FlxPoint;
import flixel.graphics.FlxGraphic;

/**
 * Single-frame collection.
 * Could be useful for non-animated sprites.
 */
class ImageFrame extends FlxFramesCollection
{
	public static var POINT:Point = new Point();
	public static var RECT:FlxRect = new FlxRect();
	
	/**
	 * Single frame of this frame collection.
	 * Added this var for faster access, so you don't need to type something like: imageFrame.frames[0]
	 */
	public var frame:FlxFrame;
	
	private function new(parent:FlxGraphic) 
	{
		super(parent, FrameCollectionType.IMAGE);
	}
	
	/**
	 * Generates ImageFrame object for specified FlxFrame.
	 * 
	 * @param	source	FlxFrame to generate ImageFrame from.
	 * @return	Created ImageFrame object.
	 */
	public static function fromFrame(source:FlxFrame):ImageFrame
	{
		var graphic:FlxGraphic = source.parent;
		var rect:FlxRect = source.frame;
		
		var imageFrame:ImageFrame = ImageFrame.findFrame(graphic, rect);
		if (imageFrame != null)
		{
			return imageFrame;
		}
		
		imageFrame = new ImageFrame(graphic);
		imageFrame.frame = imageFrame.addSpriteSheetFrame(rect.copyTo(new FlxRect()));
		return imageFrame;
	}
	
	/**
	 * Creates ImageFrame object for the whole image.
	 * 
	 * @param	source	image graphic for ImageFrame. It could be String, BitmapData or FlxGraphic.
	 * @return	Newly created ImageFrame object for specified graphic.
	 */
	public static function fromImage(source:FlxGraphicAsset):ImageFrame
	{
		return fromRectangle(source, null);
	}
	
	/**
	 * Creates ImageFrame for specified region of FlxGraphic.
	 * 
	 * @param	graphic	graphic for ImageFrame.
	 * @param	region	region of image to create ImageFrame for.
	 * @return	Newly created ImageFrame object for specified region of FlxGraphic object.
	 */
	public static function fromGraphic(graphic:FlxGraphic, region:FlxRect = null):ImageFrame
	{
		if (graphic == null)	return null;
		
		// find ImageFrame, if there is one already
		var checkRegion:FlxRect = region;
		
		if (checkRegion == null)
		{
			checkRegion = RECT;
			checkRegion.x = checkRegion.y = 0;
			checkRegion.width = graphic.width;
			checkRegion.height = graphic.height;
		}
		
		var imageFrame:ImageFrame = ImageFrame.findFrame(graphic, checkRegion);
		if (imageFrame != null)
		{
			return imageFrame;
		}
		
		// or create it, if there is no such object
		imageFrame = new ImageFrame(graphic);
		
		if (region == null)
		{
			region = new FlxRect(0, 0, graphic.width, graphic.height);
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
		
		imageFrame.frame = imageFrame.addSpriteSheetFrame(region);
		return imageFrame;
	}
	
	/**
	 * Creates ImageFrame object for specified region of image.
	 * 
	 * @param	source	image graphic for ImageFrame. It could be String, BitmapData or FlxGraphic.
	 * @param	region	region of image to create ImageFrame for.
	 * @return	Newly created ImageFrame object for specified region of image.
	 */
	public static function fromRectangle(source:FlxGraphicAsset, region:FlxRect = null):ImageFrame
	{
		var graphic:FlxGraphic = FlxG.bitmap.add(source, false);
		return fromGraphic(graphic, region);
	}
	
	/**
	 * Searches ImageFrame object for specified FlxGraphic object which have the same frame rectangle.
	 * 
	 * @param	graphic		FlxGraphic object to search ImageFrame for.
	 * @param	frameRect	ImageFrame object should have frame with the same position and dimensions as specified with this argument.
	 * @return	ImageFrame object which corresponds to specified rectangle. Could be null if there is no such ImageFrame.
	 */
	public static function findFrame(graphic:FlxGraphic, frameRect:FlxRect):ImageFrame
	{
		var imageFrames:Array<ImageFrame> = cast graphic.getFramesCollections(FrameCollectionType.IMAGE);
		var imageFrame:ImageFrame;
		for (imageFrame in imageFrames)
		{
			if (imageFrame.equals(frameRect))
			{
				return imageFrame;
			}
		}
		
		return null;
	}
	
	/**
	 * ImageFrame comparison method. For internal use.
	 */
	public inline function equals(rect:FlxRect = null):Bool
	{
		return rect.equals(frame.frame);
	}
	
	override public function destroy():Void 
	{
		super.destroy();
		frame = FlxDestroyUtil.destroy(frame);
	}
}