package flixel.graphics.frames;

import flash.display.BitmapData;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.FlxG;
import flixel.math.FlxAngle;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.graphics.FlxGraphic;

/**
 * Base class for all frame types
 */
class FlxFrame implements IFlxDestroyable
{
	public static var POINT:Point = new Point();
	public static var MATRIX:Matrix = new Matrix();
	public static var RECT:Rectangle = new Rectangle();
	
	public var name:String;
	/**
	 * Region of image to render
	 */
	public var frame:Rectangle;
	
	public var parent:FlxGraphic;
	public var tileID:Int = -1;
	/**
	 * Rotation angle of this frame. 
	 * Required for packed atlas images.
	 */
	public var angle:Float = 0;  // TODO: remove casting from frame collections generation methods which detects if the frame is rotated or not 
	
	/**
	 * Original (uncropped) image size.
	 */
	public var sourceSize(default, null):FlxPoint;
	/**
	 * Frame offset from top left corner of original image.
	 */
	public var offset(default, null):FlxPoint;
	/**
	 * Helper point object for less calculations (use in tile render mode).
	 * It holds position of tile's center of this frame (offset + half tile size).
	 */
	public var center(default, null):FlxPoint;
	/**
	 * The half size of this frame (0.5 * sourceSize).
	 */
	public var halfSize(default, null):FlxPoint;
	
	/**
	 * The type of this frame.
	 */
	public var type(default, null):FrameType;
	
	/**
	 * Frame bitmapDatas.
	 * Required for blit render mode and pixel perfect collision detection.
	 */
	private var _bitmapData:BitmapData;
	private var _hReversedBitmapData:BitmapData;
	private var _vReversedBitmapData:BitmapData;
	private var _hvReversedBitmapData:BitmapData;
	
	public function new(parent:FlxGraphic)
	{
		this.parent = parent;
		angle = 0;
		
		sourceSize = FlxPoint.get();
		offset = FlxPoint.get();
		center = FlxPoint.get();
		halfSize = FlxPoint.get();
		
		type = FrameType.REGULAR;
	}
	
	/**
	 * Transforms specified matrix for further rendering.
	 * Required for rotated frame support.
	 * 
	 * @param	mat	Matrix to transform / rotate
	 * @return	Transformed matrix.
	 */
	public function prepareFrameMatrix(mat:FlxMatrix):FlxMatrix
	{
		return mat;
	}
	
	/**
	 * Draws frame on specified BitmapData object (all underlying pixels become unvisible).
	 * 
	 * @param	bmd	BitmapData object to draw this frame on. If bmd is null or doesn't have the same size as frame then new BitmapData created
	 * @return	Modified or newly created BitmapData with frame image on it
	 */
	public function paintOnBitmap(bmd:BitmapData = null):BitmapData
	{
		var result:BitmapData = null;
		
		if (bmd != null && (bmd.width == sourceSize.x && bmd.height == sourceSize.y))
		{
			result = bmd;
			
			var w:Int = bmd.width;
			var h:Int = bmd.height;
			
			if (w > frame.width || h > frame.height)
			{
				RECT.x = RECT.y = 0;
				RECT.width = w;
				RECT.height = h;
				bmd.fillRect(RECT, FlxColor.TRANSPARENT);
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
		
		FlxFrame.POINT.x = offset.x;
		FlxFrame.POINT.y = offset.y;
		result.copyPixels(parent.bitmap, frame, FlxFrame.POINT);
		return result;
	}
	
	/**
	 * Generates BitmapData for this frame object.
	 */
	public function getBitmap():BitmapData
	{
		if (_bitmapData != null)
		{
			return _bitmapData;
		}
		
		return _bitmapData = paintOnBitmap();
	}
	
	/**
	 * Generates horizontally reversed BitmapData for this frame object.
	 */
	public function getHReversedBitmap():BitmapData
	{
		if (_hReversedBitmapData != null)
		{
			return _hReversedBitmapData;
		}
		
		var normalFrame:BitmapData = getBitmap();
		MATRIX.identity();
		MATRIX.scale( -1, 1);
		MATRIX.translate(Std.int(sourceSize.x), 0);
		_hReversedBitmapData = new BitmapData(Std.int(sourceSize.x), Std.int(sourceSize.y), true, FlxColor.TRANSPARENT);
		_hReversedBitmapData.draw(normalFrame, MATRIX);
		return _hReversedBitmapData;
	}
	
	/**
	 * Generates vertically reversed BitmapData for this frame object.
	 */
	public function getVReversedBitmap():BitmapData
	{
		if (_vReversedBitmapData != null)
		{
			return _vReversedBitmapData;
		}
		
		var normalFrame:BitmapData = getBitmap();
		MATRIX.identity();
		MATRIX.scale(1, -1);
		MATRIX.translate(0, Std.int(sourceSize.y));
		_vReversedBitmapData = new BitmapData(Std.int(sourceSize.x), Std.int(sourceSize.y), true, FlxColor.TRANSPARENT);
		_vReversedBitmapData.draw(normalFrame, MATRIX);
		return _vReversedBitmapData;
	}
	
	/**
	 * Generates horizontally and vertically reversed BitmapData for this frame object.
	 */
	public function getHVReversedBitmap():BitmapData
	{
		if (_hvReversedBitmapData != null)
		{
			return _hvReversedBitmapData;
		}
		
		var normalFrame:BitmapData = getBitmap();
		MATRIX.identity();
		MATRIX.scale( -1, -1);
		MATRIX.translate(Std.int(sourceSize.x), Std.int(sourceSize.y));
		_hvReversedBitmapData = new BitmapData(Std.int(sourceSize.x), Std.int(sourceSize.y), true, FlxColor.TRANSPARENT);
		_hvReversedBitmapData.draw(normalFrame, MATRIX);
		return _hvReversedBitmapData;
	}
	
	/**
	 * Frees memory taken by frame BitmapDatas.
	 */
	public inline function destroyBitmaps():Void
	{
		_bitmapData = FlxDestroyUtil.dispose(_bitmapData);
		_hReversedBitmapData = FlxDestroyUtil.dispose(_hReversedBitmapData);
		_vReversedBitmapData = FlxDestroyUtil.dispose(_vReversedBitmapData);
		_hvReversedBitmapData = FlxDestroyUtil.dispose(_hvReversedBitmapData);
	}
	
	public function destroy():Void
	{
		name = null;
		frame = null;
		parent = null;
		sourceSize = FlxDestroyUtil.put(sourceSize);
		offset = FlxDestroyUtil.put(offset);
		center = FlxDestroyUtil.put(center);
		destroyBitmaps();
	}
}