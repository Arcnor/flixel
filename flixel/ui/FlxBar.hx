package flixel.ui;

import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.BarFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.ImageFrame;
import flixel.system.layer.DrawStackItem;
import flixel.ui.FlxBar.FlxBarFillDirection;
import flixel.math.FlxAngle;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxGradient;
import flixel.math.FlxPoint;
import flixel.util.FlxStringUtil;

/**
 * FlxBar is a quick and easy way to create a graphical bar which can
 * be used as part of your UI/HUD, or positioned next to a sprite. 
 * It could represent a loader, progress or health bar.
 * 
 * @link http://www.photonstorm.com
 * @author Richard Davey / Photon Storm
 */
class FlxBar extends FlxSprite
{
	/**
	 * fixedPosition controls if the FlxBar sprite is at a fixed location on screen, or tracking its parent
	 */
	public var fixedPosition:Bool = true;
	/**
	 * How many pixels = 1% of the bar (barWidth (or height) / 100)
	 */
	public var pxPerPercent:Float;
	/**
	 * The positionOffset controls how far offset the FlxBar is from the parent sprite (if at all)
	 */
	public var positionOffset(default, null):FlxPoint;
	/**
	 * If this FlxBar should be killed when its empty
	 */
	public var killOnEmpty:Bool = false;
	/**
	 * The percentage of how full the bar is (a value between 0 and 100)
	 */
	public var percent(get, set):Float;
	public var stats(get, null):Map<String, Dynamic>;
	/**
	 * The current value - must always be between min and max
	 */
	@:isVar
	public var value(get, set):Float;
	/**
	 * The minimum value the bar can be (can never be >= max)
	 */
	public var min(default, null):Float;
	/**
	 * The maximum value the bar can be (can never be <= min)
	 */
	public var max(default, null):Float;
	/**
	 * How wide is the range of this bar? (max - min)
	 */
	public var range(default, null):Float;
	/**
	 * What 1% of the bar is equal to in terms of value (range / 100)
	 */
	public var pct(default, null):Float;
	
	public var emptyCallback:Void->Void;
	
	public var filledCallback:Void->Void;
	
	public var parent:Dynamic;
	public var parentVariable:String;
	
	public var barWidth(default, null):Int;
	public var barHeight(default, null):Int;
	
	@:isVar
	public var fillDirection(get, set):FlxBarFillDirection;
	
	private var _emptyBar:BitmapData;
	private var _emptyBarRect:Rectangle;
	private var _emptyBarPoint:Point;
	private var _zeroOffset:Point;
	private var _emptyImage:ImageFrame;
	
	private var _filledBar:BitmapData;
	private var _filledBarRect:Rectangle;
	private var _filledBarPoint:Point;
	
	private var _fillHorizontal:Bool;
	
	#if FLX_RENDER_TILE
	private var _frontGraphic:FlxGraphic;
	private var _frontFrames:BarFrames;
	#else
	private var _canvas:BitmapData;
	private var _filledImage:ImageFrame;
	#end
	
	/**
	 * Create a new FlxBar Object
	 * 
	 * @param	x			The x coordinate location of the resulting bar (in world pixels)
	 * @param	y			The y coordinate location of the resulting bar (in world pixels)
	 * @param	direction 	The fill direction, LEFT_TO_RIGHT by default
	 * @param	width		The width of the bar in pixels
	 * @param	height		The height of the bar in pixels
	 * @param	parentRef	A reference to an object in your game that you wish the bar to track
	 * @param	variable	The variable of the object that is used to determine the bar position. For example if the parent was an FlxSprite this could be "health" to track the health value
	 * @param	min			The minimum value. I.e. for a progress bar this would be zero (nothing loaded yet)
	 * @param	max			The maximum value the bar can reach. I.e. for a progress bar this would typically be 100.
	 * @param	showBorder	Include a 1px border around the bar? (if true it adds +2 to width and height to accommodate it)
	 */
	public function new(x:Float = 0, y:Float = 0, ?direction:FlxBarFillDirection, width:Int = 100, height:Int = 10, ?parentRef:Dynamic, variable:String = "", min:Float = 0, max:Float = 100, showBorder:Bool = false)
	{
		if (direction == null)
		{
			direction = LEFT_TO_RIGHT;
		}
		
		_zeroOffset = new Point();
		
		super(x, y);
		
		barWidth = width;
		barHeight = height;
		
		#if FLX_RENDER_BLIT
		makeGraphic(width, height, FlxColor.WHITE, true);
		#else
		this.width = frameWidth = width;
		this.height = frameHeight = height;
		origin.set(frameWidth * 0.5, frameHeight * 0.5);
		#end
		
		_filledBarPoint = new Point(0, 0);
		
		#if FLX_RENDER_BLIT
 		_canvas = new BitmapData(width, height, true, FlxColor.TRANSPARENT);
		#end
		
		if (parentRef != null)
		{
			parent = parentRef;
			parentVariable = variable;
		}
		
		fillDirection = direction;
		
		setRange(min, max);
		
		createFilledBar(0xff005100, 0xff00F400, showBorder);
		
		// Make sure the bar is drawn
		#if FLX_RENDER_BLIT
		updateBar();
		#end
	}
	
	override public function destroy():Void 
	{
		positionOffset = FlxDestroyUtil.put(positionOffset);
		
		#if FLX_RENDER_BLIT
		_canvas = FlxDestroyUtil.dispose(_canvas);
		#else
		_filledBarFrames = null;
		#end
		
		parent = null;
		positionOffset = null;
		emptyCallback = null;
		_emptyBarRect = null;
		_emptyBarPoint = null;
		_zeroOffset = null;
		filledCallback = null;
		_filledBarRect = null;
		_filledBarPoint = null;
		
		_emptyBar = FlxDestroyUtil.dispose(_emptyBar);
		_filledBar = FlxDestroyUtil.dispose(_filledBar);
		
		super.destroy();
	}
	
	/**
	 * Track the parent FlxSprites x/y coordinates. For example if you wanted your sprite to have a floating health-bar above their head.<br />
	 * If your health bar is 10px tall and you wanted it to appear above your sprite, then set offsetY to be -10<br />
	 * If you wanted it to appear below your sprite, and your sprite was 32px tall, then set offsetY to be 32. Same applies to offsetX.
	 * 
	 * @param	offsetX		The offset on X in relation to the origin x/y of the parent
	 * @param	offsetY		The offset on Y in relation to the origin x/y of the parent
	 * @see		stopTrackingParent
	 */
	public function trackParent(offsetX:Int, offsetY:Int):Void
	{
		fixedPosition = false;
		
		positionOffset = FlxPoint.get(offsetX, offsetY);
		
		if (Reflect.hasField(parent, "scrollFactor"))
		{
			scrollFactor.x = parent.scrollFactor.x;
			scrollFactor.y = parent.scrollFactor.y;
		}
	}
	
	/**
	 * Sets a parent for this FlxBar. Instantly replaces any previously set parent and refreshes the bar.
	 * 
	 * @param	parentRef	A reference to an object in your game that you wish the bar to track
	 * @param	variable	The variable of the object that is used to determine the bar position. For example if the parent was an FlxSprite this could be "health" to track the health value
	 * @param	track		If you wish the FlxBar to track the x/y coordinates of parent set to true (default false)
	 * @param	offsetX		The offset on X in relation to the origin x/y of the parent
	 * @param	offsetY		The offset on Y in relation to the origin x/y of the parent
	 */
	public function setParent(parentRef:Dynamic, variable:String, track:Bool = false, offsetX:Int = 0, offsetY:Int = 0):Void
	{
		parent = parentRef;
		parentVariable = variable;
		
		if (track)
		{
			trackParent(offsetX, offsetY);
		}
		
		updateValueFromParent();
		updateBar();
	}
	
	/**
	 * Tells the health bar to stop following the parent sprite. The given posX and posY values are where it will remain on-screen.
	 * 
	 * @param	posX	X coordinate of the health bar now it's no longer tracking the parent sprite
	 * @param	posY	Y coordinate of the health bar now it's no longer tracking the parent sprite
	 */
	public function stopTrackingParent(posX:Int, posY:Int):Void
	{
		fixedPosition = true;
		
		x = posX;
		y = posY;
	}
	
	/**
	 * Sets callbacks which will be triggered when the value of this FlxBar reaches min or max.
	 * Functions will only be called once and not again until the value changes.
	 * Optionally the FlxBar can be killed if it reaches min, but if will fire the empty callback first (if set)
	 * 
	 * @param	onEmpty			The function that is called if the value of this FlxBar reaches min
	 * @param	onFilled		The function that is called if the value of this FlxBar reaches max
	 * @param	killOnEmpty		If set it will call FlxBar.kill() if the value reaches min
	 */
	public function setCallbacks(onEmpty:Void->Void, onFilled:Void->Void, killOnEmpty:Bool = false):Void
	{
		emptyCallback = (onEmpty != null) ? onEmpty: emptyCallback;
		filledCallback = (onFilled != null) ? onFilled : filledCallback;
		this.killOnEmpty = killOnEmpty;
	}
	
	/**
	 * Set the minimum and maximum allowed values for the FlxBar
	 * 
	 * @param	min			The minimum value. I.e. for a progress bar this would be zero (nothing loaded yet)
	 * @param	max			The maximum value the bar can reach. I.e. for a progress bar this would typically be 100.
	 */
	public function setRange(min:Float, max:Float):Void
	{
		if (max <= min)
		{
			throw "FlxBar: max cannot be less than or equal to min";
			return;
		}
		
		this.min = min;
		this.max = max;
		this.range = max - min;
		this.pct = range / 100;
		
		pxPerPercent = (_fillHorizontal == true) ? barWidth / 100 : barHeight / 100;
		
		if (!Math.isNaN(value))
		{
			value = Math.max(min, Math.min(value, max));
		}
		else
		{
			value = min;
		}
		
		#if FLX_RENDER_TILE
		updateFrameData();
		#end
	}
	
	/**
	 * Creates a solid-colour filled health bar in the given colours, with optional 1px thick border.<br />
	 * All colour values are in 0xAARRGGBB format, so if you want a slightly transparent health bar give it lower AA values.
	 * 
	 * @param	empty		The color of the bar when empty in 0xAARRGGBB format (the background colour)
	 * @param	fill		The color of the bar when full in 0xAARRGGBB format (the foreground colour)
	 * @param	showBorder	Should the bar be outlined with a 1px solid border?
	 * @param	border		The border colour in 0xAARRGGBB format
	 */
	public function createFilledBar(empty:Int, fill:Int, showBorder:Bool = false, border:Int = 0xffffffff):Void
	{
		#if FLX_RENDER_TILE
		var emptyA:Int = (empty >> 24) & 255;
		var emptyRGB:Int = empty & 0x00ffffff;
		var fillA:Int = (fill >> 24) & 255;
		var fillRGB:Int = fill & 0x00ffffff;
		var borderA:Int = (border >> 24) & 255;
		var borderRGB:Int = border & 0x00ffffff;
		
		var emptyKey:String = "empty: " + _barWidth + "x" + _barHeight + ":" + emptyA + "." + emptyRGB + "showBorder: " + showBorder;
		var filledKey:String = "filled: " + _barWidth + "x" + _barHeight + ":" + fillA + "." + fillRGB + "showBorder: " + showBorder;
		if (showBorder)
		{
			emptyKey = emptyKey + "border: " + borderA + "." + borderRGB;
			filledKey = filledKey + "border: " + borderA + "." + borderRGB;
		}
		#end
		
		if (showBorder)
		{
		#if FLX_RENDER_TILE
			if (FlxG.bitmap.checkCache(emptyKey) == false)
			{
				var _emptyBar = new BitmapData(_barWidth, _barHeight, true, border);
				_emptyBar.fillRect(new Rectangle(1, 1, _barWidth - 2, _barHeight - 2), empty);
				
				FlxG.bitmap.add(_emptyBar, false, emptyKey);
			}
			
			if (FlxG.bitmap.checkCache(filledKey) == false)
			{
				var _filledBar = new BitmapData(_barWidth, _barHeight, true, border);
				_filledBar.fillRect(new Rectangle(1, 1, _barWidth - 2, _barHeight - 2), fill);
				
				FlxG.bitmap.add(_filledBar, false, filledKey);
			}
		#else
			_emptyBar = new BitmapData(barWidth, barHeight, true, border);
			_emptyBar.fillRect(new Rectangle(1, 1, barWidth - 2, barHeight - 2), empty);
			
			_filledBar = new BitmapData(barWidth, barHeight, true, border);
			_filledBar.fillRect(new Rectangle(1, 1, barWidth - 2, barHeight - 2), fill);
		#end
		}
		else
		{
		#if FLX_RENDER_TILE
			if (FlxG.bitmap.checkCache(emptyKey) == false)
			{
				var _emptyBar = new BitmapData(barWidth, barHeight, true, empty);
				FlxG.bitmap.add(_emptyBar, false, emptyKey);
			}
			
			if (FlxG.bitmap.checkCache(filledKey) == false)
			{
				var _filledBar = new BitmapData(_barWidth, _barHeight, true, fill);
				FlxG.bitmap.add(_filledBar, false, filledKey);
			}
		#else
			_emptyBar = new BitmapData(barWidth, barHeight, true, empty);
			_filledBar = new BitmapData(barWidth, barHeight, true, fill);
		#end
		}
		
		#if FLX_RENDER_BLIT
		_filledBarRect = new Rectangle(0, 0, _filledBar.width, _filledBar.height);
		_emptyBarRect = new Rectangle(0, 0, _emptyBar.width, _emptyBar.height);
		#else
		graphic = FlxG.bitmap.get(emptyKey);
		setFrontGraphic(FlxG.bitmap.get(filledKey));
		
		updateFrameData();
		#end
	}
	
	/**
	 * Creates a gradient filled health bar using the given colour ranges, with optional 1px thick border.<br />
	 * All colour values are in 0xAARRGGBB format, so if you want a slightly transparent health bar give it lower AA values.
	 * 
	 * @param	empty		Array of colour values used to create the gradient of the health bar when empty, each colour must be in 0xAARRGGBB format (the background colour)
	 * @param	fill		Array of colour values used to create the gradient of the health bar when full, each colour must be in 0xAARRGGBB format (the foreground colour)
	 * @param	chunkSize	If you want a more old-skool looking chunky gradient, increase this value!
	 * @param	rotation	Angle of the gradient in degrees. 90 = top to bottom, 180 = left to right. Any angle is valid
	 * @param	showBorder	Should the bar be outlined with a 1px solid border?
	 * @param	border		The border colour in 0xAARRGGBB format
	 */
	public function createGradientBar(empty:Array<Int>, fill:Array<Int>, chunkSize:Int = 1, rotation:Int = 180, showBorder:Bool = false, border:Int = 0xffffffff):Void
	{
		#if FLX_RENDER_TILE
		var colA:Int;
		var colRGB:Int;
		
		var emptyKey:String = "Gradient: " + _barWidth + " x " + _barHeight + ", colors: [";
		for (col in empty)
		{
			colA = (col >> 24) & 255;
			colRGB = col & 0x00ffffff;
			
			emptyKey = emptyKey + colRGB + "_" + colA + ", ";
		}
		emptyKey = emptyKey + "], chunkSize: " + chunkSize + ", rotation: " + rotation + "showBorder: " + showBorder;
		
		var filledKey:String = "Gradient: " + _barWidth + " x " + _barHeight + ", colors: [";
		for (col in fill)
		{
			colA = (col >> 24) & 255;
			colRGB = col & 0x00ffffff;
			
			filledKey = filledKey + colRGB + "_" + colA + ", ";
		}
		filledKey = filledKey + "], chunkSize: " + chunkSize + ", rotation: " + rotation + "showBorder: " + showBorder;
		
		if (showBorder)
		{
			var borderA:Int = (border >> 24) & 255;
			var borderRGB:Int = border & 0x00ffffff;
			
			emptyKey = emptyKey + "border: " + borderA + "." + borderRGB;
			filledKey = filledKey + "border: " + borderA + "." + borderRGB;
		}
		#end
		
		if (showBorder)
		{
			#if FLX_RENDER_BLIT
			_emptyBar = new BitmapData(barWidth, barHeight, true, border);
			FlxGradient.overlayGradientOnBitmapData(_emptyBar, barWidth - 2, barHeight - 2, empty, 1, 1, chunkSize, rotation);
			
			_filledBar = new BitmapData(barWidth, barHeight, true, border);
			FlxGradient.overlayGradientOnBitmapData(_filledBar, barWidth - 2, barHeight - 2, fill, 1, 1, chunkSize, rotation);
			#else
			if (FlxG.bitmap.checkCache(emptyKey) == false)
			{
				var _emptyBar = new BitmapData(barWidth, barHeight, true, border);
				FlxGradient.overlayGradientOnBitmapData(_emptyBar, barWidth - 2, barHeight - 2, empty, 1, 1, chunkSize, rotation);
				FlxG.bitmap.add(_emptyBar, false, emptyKey);
			}
			
			if (FlxG.bitmap.checkCache(filledKey) == false)
			{
				var _filledBar = new BitmapData(barWidth, barHeight, true, border);
				FlxGradient.overlayGradientOnBitmapData(_filledBar, barWidth - 2, barHeight - 2, fill, 1, 1, chunkSize, rotation);
				FlxG.bitmap.add(_filledBar, false, filledKey);
			}
			#end
		}
		else
		{
			#if FLX_RENDER_BLIT
			_emptyBar = FlxGradient.createGradientBitmapData(barWidth, barHeight, empty, chunkSize, rotation);
			_filledBar = FlxGradient.createGradientBitmapData(barWidth, barHeight, fill, chunkSize, rotation);
			#else
			if (FlxG.bitmap.checkCache(emptyKey) == false)
			{
				var _emptyBar = FlxGradient.createGradientBitmapData(barWidth, barHeight, empty, chunkSize, rotation);
				FlxG.bitmap.add(_emptyBar, false, emptyKey);
			}
			
			if (FlxG.bitmap.checkCache(filledKey) == false)
			{
				var _filledBar = FlxGradient.createGradientBitmapData(_barWidth, _barHeight, fill, chunkSize, rotation);
				FlxG.bitmap.add(_filledBar, false, filledKey);
			}
			#end
		}
		
		#if FLX_RENDER_BLIT
		_emptyBarRect = new Rectangle(0, 0, _emptyBar.width, _emptyBar.height);
		_filledBarRect = new Rectangle(0, 0, _filledBar.width, _filledBar.height);
		#else
		graphic = FlxG.bitmap.get(emptyKey);
		setFrontGraphic(FlxG.bitmap.get(filledKey));
		
		updateFrameData();
		#end
	}
	
	/**
	 * Creates a health bar filled using the given bitmap images.<br />
	 * You can provide "empty" (background) and "fill" (foreground) images. either one or both images (empty / fill), and use the optional empty/fill colour values 
	 * All colour values are in 0xAARRGGBB format, so if you want a slightly transparent health bar give it lower AA values.
	 * 
	 * @param	empty				Bitmap image used as the background (empty part) of the health bar, if null the emptyBackground colour is used
	 * @param	fill				Bitmap image used as the foreground (filled part) of the health bar, if null the fillBackground colour is used
	 * @param	emptyBackground		If no background (empty) image is given, use this colour value instead. 0xAARRGGBB format
	 * @param	fillBackground		If no foreground (fill) image is given, use this colour value instead. 0xAARRGGBB format
	 */
	public function createImageBar(?empty:Dynamic, ?fill:Dynamic, emptyBackground:Int = 0xff000000, fillBackground:Int = 0xff00ff00):Void
	{
		var emptyGraphics:FlxGraphic = FlxG.bitmap.add(empty);
		var filledGraphics:FlxGraphic = FlxG.bitmap.add(fill);
		
		var emptyBitmapData:BitmapData = (emptyGraphics != null) ? emptyGraphics.bitmap : null; 
		var fillBitmapData:BitmapData = (filledGraphics != null) ? filledGraphics.bitmap : null;
		
	#if FLX_RENDER_TILE
		var emptyKey:String = "";
		var filledKey:String = "";
		
		if (empty != null)
		{
			if (Std.is(empty, Class))
			{
				emptyKey += Type.getClassName(cast(empty, Class<Dynamic>));
			}
			else if (Std.is(empty, BitmapData))
			{
				emptyKey = FlxG.bitmap.findKeyForBitmap(empty);
				if (emptyKey == null)
				{
					emptyKey = FlxG.bitmap.getUniqueKey("bar_empty");
				}
			}
			else if (Std.is(empty, String))
			{
				emptyKey += empty;
			}
		}
		
		if (fill != null)
		{
			if (Std.is(fill, Class))
			{
				filledKey += Type.getClassName(cast(fill, Class<Dynamic>));
			}
			else if (Std.is(fill, BitmapData))
			{
				filledKey = FlxG.bitmap.findKeyForBitmap(fill);
				if (filledKey == null)
				{
					filledKey = FlxG.bitmap.getUniqueKey("bar_filled");
				}
			}
			else if (Std.is(fill, String))
			{
				filledKey += fill;
			}
		}
		
		var emptyBackgroundA:Int = (emptyBackground >> 24) & 255;
		var emptyBackgroundRGB:Int = emptyBackground & 0x00ffffff;
		var fillBackgroundA:Int = (fillBackground >> 24) & 255;
		var fillBackgroundRGB:Int = fillBackground & 0x00ffffff;
		
		emptyKey += "emptyBackground: " + emptyBackgroundA + "." + emptyBackgroundRGB;
		filledKey += "fillBackground: " + fillBackgroundA + "." + fillBackgroundRGB;
	#end
		
		if (empty == null && fill == null)
		{
			return;
		}
		
		if (empty != null && fill == null)
		{
			//	If empty is set, but fill is not ...
		#if FLX_RENDER_BLIT
			_emptyBar = emptyBitmapData;
			_emptyBarRect = new Rectangle(0, 0, _emptyBar.width, _emptyBar.height);
			
			barWidth = Std.int(_emptyBarRect.width);
			barHeight = Std.int(_emptyBarRect.height);
			
			_filledBar = new BitmapData(barWidth, barHeight, true, fillBackground);
			_filledBarRect = new Rectangle(0, 0, barWidth, barHeight);
		#else
			_barWidth = emptyBitmapData.width;
			_barHeight = emptyBitmapData.height;
			
			// TODO: continue from here
			if (FlxG.bitmap.checkCache(emptyKey) == false)
			{
				FlxG.bitmap.add(emptyBitmapData, false, emptyKey);
			}
			
			if (FlxG.bitmap.checkCache(filledKey) == false)
			{
				var _filledBar = new BitmapData(barWidth, barHeight, true, fillBackground);
				FlxG.bitmap.add(_filledBar, false, filledKey);
			}
		#end
		}
		else if (empty == null && fill != null)
		{
			//	If fill is set, but empty is not ...
			#if FLX_RENDER_BLIT
			_filledBar = fillBitmapData;
			_filledBarRect = new Rectangle(0, 0, _filledBar.width, _filledBar.height);
			
			barWidth = Std.int(_filledBarRect.width);
			barHeight = Std.int(_filledBarRect.height);
			
			_emptyBar = new BitmapData(barWidth, barHeight, true, emptyBackground);
			_emptyBarRect = new Rectangle(0, 0, barWidth, barHeight);
			#else
			_barWidth = fillBitmapData.width;
			_barHeight = fillBitmapData.height;
			
			if (FlxG.bitmap.checkCache(emptyKey) == false)
			{
				var _emptyBar = new BitmapData(_barWidth, _barHeight, true, emptyBackground);
				FlxG.bitmap.add(_emptyBar, false, emptyKey);
			}
			
			if (FlxG.bitmap.checkCache(filledKey) == false)
			{
				FlxG.bitmap.add(fillBitmapData, false, filledKey);
			}
			#end	
		}
		else if (empty != null && fill != null)
		{
			//	If both are set
			#if FLX_RENDER_BLIT
			_emptyBar = emptyBitmapData;
			_emptyBarRect = new Rectangle(0, 0, _emptyBar.width, _emptyBar.height);
			
			_filledBar = fillBitmapData;
			_filledBarRect = new Rectangle(0, 0, _filledBar.width, _filledBar.height);
			
			barWidth = Std.int(_emptyBarRect.width);
			barHeight = Std.int(_emptyBarRect.height);
			#else
			barWidth = emptyBitmapData.width;
			barHeight = emptyBitmapData.height;
			
			if (FlxG.bitmap.checkCache(emptyKey) == false)
			{
				FlxG.bitmap.add(emptyBitmapData, false, emptyKey);
			}
			
			if (FlxG.bitmap.checkCache(filledKey) == false)
			{
				FlxG.bitmap.add(fillBitmapData, false, filledKey);
			}
			#end
		}
		
		#if FLX_RENDER_BLIT
		_canvas = new BitmapData(barWidth, barHeight, true, 0x0);
		#else
		graphic = FlxG.bitmap.get(emptyKey);
		setFrontGraphic(FlxG.bitmap.get(filledKey));
		
		updateFrameData();
		#end
		
		if (_fillHorizontal)
		{
			pxPerPercent = barWidth / 100;
		}
		else
		{
			pxPerPercent = barHeight / 100;
		}
	}
	
	private function get_fillDirection():FlxBarFillDirection
	{
		return fillDirection;
	}
	
	/**
	 * Set the direction from which the health bar will fill-up. Default is from left to right. Change takes effect immediately.
	 * 
	 * @param	direction	The fill direction, LEFT_TO_RIGHT by default
	 */
	private function set_fillDirection(direction:FlxBarFillDirection):FlxBarFillDirection
	{
		fillDirection = direction;
		
		switch (direction)
		{
			case LEFT_TO_RIGHT, RIGHT_TO_LEFT, HORIZONTAL_INSIDE_OUT, HORIZONTAL_OUTSIDE_IN:
				_fillHorizontal = true;
				
			case TOP_TO_BOTTOM, BOTTOM_TO_TOP, VERTICAL_INSIDE_OUT, VERTICAL_OUTSIDE_IN:
				_fillHorizontal = false;
		}
		
		#if FLX_RENDER_TILE
		updateFrameData();
		#end
		
		return fillDirection;
	}
	
	private function updateValueFromParent():Void
	{
		updateValue(Reflect.getProperty(parent, parentVariable));
	}
	
	private function updateValue(newValue:Float):Void
	{
		value = Math.max(min, Math.min(newValue, max));
		
		if (value == min && emptyCallback != null)
		{
			emptyCallback();
		}
		
		if (value == max && filledCallback != null)
		{
			filledCallback();
		}
		
		if (value == min && killOnEmpty)
		{
			kill();
		}
	}
	
	/**
	 * Called when the health bar detects a change in the health of the parent.
	 */
	private function updateBar():Void
	{
		#if FLX_RENDER_BLIT
		if (_fillHorizontal)
		{
			_filledBarRect.width = Std.int(percent * pxPerPercent);
		}
		else
		{
			_filledBarRect.height = Std.int(percent * pxPerPercent);
		}
		
		_canvas.copyPixels(_emptyBar, _emptyBarRect, _zeroOffset);
		
		if (percent > 0)
		{
			switch (fillDirection)
			{
				case LEFT_TO_RIGHT, TOP_TO_BOTTOM:
					//	Already handled above
				
				case BOTTOM_TO_TOP:
					_filledBarRect.y = barHeight - _filledBarRect.height;
					_filledBarPoint.y = barHeight - _filledBarRect.height;
					
				case RIGHT_TO_LEFT:
					_filledBarRect.x = barWidth - _filledBarRect.width;
					_filledBarPoint.x = barWidth - _filledBarRect.width;
					
				case HORIZONTAL_INSIDE_OUT:
					_filledBarRect.x = Std.int((barWidth / 2) - (_filledBarRect.width / 2));
					_filledBarPoint.x = Std.int((barWidth / 2) - (_filledBarRect.width / 2));
				
				case HORIZONTAL_OUTSIDE_IN:
					_filledBarRect.width = Std.int(100 - percent * pxPerPercent);
					_filledBarPoint.x = Std.int((barWidth - _filledBarRect.width) / 2);
				
				case VERTICAL_INSIDE_OUT:
					_filledBarRect.y = Std.int((barHeight / 2) - (_filledBarRect.height / 2));
					_filledBarPoint.y = Std.int((barHeight / 2) - (_filledBarRect.height / 2));
					
				case VERTICAL_OUTSIDE_IN:
					_filledBarRect.height = Std.int(100 - percent * pxPerPercent);
					_filledBarPoint.y = Std.int((barHeight - _filledBarRect.height) / 2);
			}
			
			_canvas.copyPixels(_filledBar, _filledBarRect, _filledBarPoint);
		}
		
		pixels = _canvas;
		#end
	}
	
	override public function update():Void
	{
		if (parent != null)
		{
			if (Reflect.getProperty(parent, parentVariable) != value)
			{
				updateValueFromParent();
				updateBar();
			}
			
			if (fixedPosition == false)
			{
				x = parent.x + positionOffset.x;
				y = parent.y + positionOffset.y;
			}
		}
		
		super.update();
	}
	
	#if FLX_RENDER_TILE
	override public function draw():Void 
	{
		if (_frontGraphic == null || graphic == null)
		{
			return;
		}
		
		var percentFrame:Int = 2 * (Math.floor(percent) - 1);
		var drawItem:DrawStackItem;
		
		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists || !isOnScreen(camera))
			{
				continue;
			}
			drawItem = camera.getDrawStackItem(graphic, isColored, _blendInt, antialiasing);
			
			_point.x = x - (camera.scroll.x * scrollFactor.x) - (offset.x) + origin.x;
			_point.y = y - (camera.scroll.y * scrollFactor.y) - (offset.y) + origin.y;

			var csx:Float = 1;
			var ssy:Float = 0;
			var ssx:Float = 0;
			var csy:Float = 1;
			var x1:Float = 0;
			var y1:Float = 0;
			var x2:Float = 0;
			var y2:Float = 0;

			if (!isSimpleRender(camera))
			{
				if (_angleChanged)
				{
					var radians:Float = -angle * FlxAngle.TO_RAD;
					_sinAngle = Math.sin(radians);
					_cosAngle = Math.cos(radians);
					_angleChanged = false;
				}
				
				csx = _cosAngle * scale.x;
				ssy = _sinAngle * scale.y;
				ssx = _sinAngle * scale.x;
				csy = _cosAngle * scale.y;
				
				x1 = (origin.x - _halfWidth);
				y1 = (origin.y - _halfHeight);
				x2 = x1 * csx + y1 * ssy;
				y2 = -x1 * ssx + y1 * csy;
			}

			// Draw empty bar
			_point.subtract(x2, y2);
			drawItem.setDrawData(_point, _emptyBarFrameID, csx, -ssx, ssy, csy, isColored, color, alpha * camera.alpha);
			
			// Draw filled bar
			drawItem = camera.getDrawStackItem(_frontGraphic, isColored, _blendInt, antialiasing);
			
			if (percentFrame >= 0)
			{
				var currTileX:Float = -x1;
				var currTileY:Float = -y1;
				
				if (_fillHorizontal)
				{
					currTileX += _filledBarFrames[percentFrame];
				}
				else
				{
					currTileY += _filledBarFrames[percentFrame];
				}
				
				var relativeX:Float = (currTileX * csx + currTileY * ssy);
				var relativeY:Float = (-currTileX * ssx + currTileY * csy);
				
				_point.add(relativeX, relativeY);
				drawItem.setDrawData(_point, _filledBarFrames[percentFrame + 1], csx, -ssx, ssy, csy);
			}
			
			#if !FLX_NO_DEBUG
			FlxBasic.visibleCount++;
			#end
		}
	}
	
	override private function set_pixels(Pixels:BitmapData):BitmapData
	{
		return Pixels; // hack
	}
	
	override public function isSimpleRender(?camera:FlxCamera):Bool
	{ 
		return (angle == 0) && (scale.x == 1) && (scale.y == 1);
	}
	#end
	
	#if FLX_RENDER_TILE
	public function updateFrameData():Void 
	{	
		if (graphic == null || _frontGraphic == null)
		{
			return;
		}
		
		_emptyBarFrameID = graphic.tilesheet.addTileRect(new Rectangle(0, 0, _barWidth, _barHeight), new Point(0.5 * _barWidth, 0.5 * _barHeight));
		_filledBarFrames = [];
		
		var frameRelativePosition:Float;
		var frameX:Float;
		var frameY:Float;
		var frameWidth:Float = 0;
		var frameHeight:Float = 0;
		
		for (i in 0...100)
		{
			frameX = 0;
			frameY = 0;
			
			switch (_fillDirection)
			{
				case LEFT_TO_RIGHT:
					frameWidth = _barWidth * i / 100;
					frameHeight = _barHeight;
					_filledBarFrames.push(0.5 * (frameWidth -_barWidth));
					
				case TOP_TO_BOTTOM:
					frameWidth = _barWidth;
					frameHeight = _barHeight * i / 100;
					_filledBarFrames.push(0.5 * (frameHeight - _barHeight));
				
				case BOTTOM_TO_TOP:
					frameWidth = _barWidth;
					frameHeight = _barHeight * i / 100;
					frameY += (_barHeight - frameHeight);
					_filledBarFrames.push(0.5 * (_barHeight - frameHeight));
					
				case RIGHT_TO_LEFT:
					frameWidth = _barWidth * i / 100;
					frameHeight = _barHeight;
					frameX += (_barWidth - frameWidth);
					_filledBarFrames.push(0.5 * (_barWidth - frameWidth));
					
				case HORIZONTAL_INSIDE_OUT:
					frameWidth = _barWidth * i / 100;
					frameHeight = _barHeight;
					frameX += (0.5 * (_barWidth - frameWidth));
					_filledBarFrames.push(0);
					
				case HORIZONTAL_OUTSIDE_IN:
					frameWidth = _barWidth * (100 - i) / 100;
					frameHeight = _barHeight;
					frameX += 0.5 * (_barWidth - frameWidth);
					_filledBarFrames.push(0);
					
				case VERTICAL_INSIDE_OUT:
					frameWidth = _barWidth;
					frameHeight = _barHeight * i / 100;
					frameY += (0.5 * (_barHeight - frameHeight));
					_filledBarFrames.push(0);
					
				case VERTICAL_OUTSIDE_IN:
					frameWidth = _barWidth;
					frameHeight = _barHeight * (100 - i) / 100;
					frameY += (0.5 * (_barHeight - frameHeight));
					_filledBarFrames.push(0);
			}
			
			_filledBarFrames.push(_frontGraphic.tilesheet.addTileRect(new Rectangle(frameX, frameY, frameWidth, frameHeight), new Point(0.5 * frameWidth, 0.5 * frameHeight)));
		}
	}
	#end
	
	#if FLX_RENDER_TILE
	private function setFrontGraphic(value:FlxGraphic):Void
	{
		if (_frontGraphic != null && _frontGraphic != value)
		{
			_frontGraphic.useCount--;
		}
		
		if (_frontGraphic != value && value != null)
		{
			value.useCount++;
		}
		_frontGraphic = value;
	}
	#end
	
	override public function toString():String
	{
		return FlxStringUtil.getDebugString([ 
			LabelValuePair.weak("min", min),
			LabelValuePair.weak("max", max),
			LabelValuePair.weak("range", range),
			LabelValuePair.weak("%", pct),
			LabelValuePair.weak("px/%", pxPerPercent),
			LabelValuePair.weak("value", value)]);
	}
	
	private function get_stats():Map<String, Dynamic>
	{
		var data = new Map<String, Dynamic>();
		data.set("min", min);
		data.set("max", max);
		data.set("range", range);
		data.set("pct", pct);
		data.set("pxPerPct", pxPerPercent);
		data.set("fillH", _fillHorizontal);
		
		return data;
	}
	
	private function get_percent():Float
	{
		#if neko
		if (value == null) 
		{
			value = min;
		}
		#end

		if (value > max)
		{
			return 100;
		}
		
		return Math.floor((value / range) * 100);
	}

	private function set_percent(newPct:Float):Float
	{
		if (newPct >= 0 && newPct <= 100)
		{
			updateValue(pct * newPct);
			updateBar();
		}
		return newPct;
	}
	
	private function set_value(newValue:Float):Float
	{
		updateValue(newValue);
		updateBar();
		return newValue;
	}
	
	private function get_value():Float
	{
		return value;
	}
}

enum FlxBarFillDirection
{
	LEFT_TO_RIGHT;
	RIGHT_TO_LEFT;
	TOP_TO_BOTTOM;
	BOTTOM_TO_TOP;
	HORIZONTAL_INSIDE_OUT;
	HORIZONTAL_OUTSIDE_IN;
	VERTICAL_INSIDE_OUT;
	VERTICAL_OUTSIDE_IN;
}