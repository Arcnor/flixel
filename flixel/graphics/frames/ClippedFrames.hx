package flixel.graphics.frames;

import flash.geom.Rectangle;
import flixel.graphics.FlxGraphic;

// TODO: document it...
/**
 * ...
 * @author Zaphod
 */
class ClippedFrames extends FlxFramesCollection
{
	// TODO: document it...
	/**
	 * 
	 */
	private var clipRect:Rectangle;
	// TODO: document it...
	/**
	 * 
	 */
	private var original:FlxFramesCollection;
	
	public function new(original:FlxFramesCollection, clipRect:Rectangle)
	{
		super(original.parent, FrameCollectionType.CLIPPED);
		
		this.original = original;
		this.clipRect = clipRect;
		createFrames();
	}
	
	// TODO: implement it...
	private function createFrames():Void 
	{
		
	}
	
	/**
	 * Searches ClippedFrames object for specified frames collection.
	 * 
	 * @param	frames			FlxFramesCollection object to search clipped frames for.
	 * @param	clipRect		Clipping rectangle.
	 * @return	ClippedFrames object which corresponds to specified arguments. Could be null if there is no such ClippedFrames object.
	 */
	public static function findFrame(frames:FlxFramesCollection, clipRect:Rectangle):ClippedFrames
	{
		var clippedFramesArr:Array<ClippedFrames> = cast graphic.getFramesCollections(FrameCollectionType.CLIPPED);
		var clippedFrames:ClippedFrames;
		
		for (clippedFrames in clippedFramesArr)
		{
			if (clippedFrames.equals(frames, clipRect))
			{
				return clippedFrames;
			}
		}
		
		return null;
	}
	
	/**
	 * ClippedFrames comparison method. For internal use.
	 */
	public function equals(original:FlxFramesCollection, clipRect:Rectangle):Bool
	{
		return (this.original == original && this.clipRect.equals(clipRect));
	}
	
	override public function destroy():Void 
	{
		super.destroy();
		clipRect = null;
		original = null;
	}
	
}