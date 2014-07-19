package flixel.graphics.frames;

import flash.display.BitmapData;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.FlxPoint;
import flixel.text.pxText.PxFontSymbol;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import haxe.xml.Fast;

// TODO: provide default font
// TODO: add size, lineHeight, bold, italic props
// TODO: document it...
/**
 * 
 */
class BitmapFont extends FlxFramesCollection
{
	private static var DEFAULT_GLYPHS:String = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";
	
	// TODO: add static methods for retrieving/deleting/saving fonts
	
	private static var fonts:Map<String, BitmapFont> = new Map<String, BitmapFont>();
	
	private static var POINT:Point = new Point();
	
	private static var MATRIX:Matrix = new Matrix();
	
	private static var COLOR_TRANSFORM:ColorTransform = new ColorTransform();
	
	public var size(default, null):Int;
	
	public var lineHeight(default, null):Int;
	
	public var bold:Bool = false;
	
	public var italic:Bool = false;
	
	public var fontName:String;
	
	public var numLetters(default, null):Int = 0;
	
	public var minOffsetX:Int = 0;
	
	/**
	 * Creates a new bitmap font using specified bitmap data and letter input.
	 */
	private function new(parent:FlxGraphic)
	{
		super(parent, FrameCollectionType.FONT);
		parent.persist = true;
		parent.destroyOnNoUse = false;
	}
	
	override public function destroy():Void 
	{
		super.destroy();
		
		fontName = null;
		// TODO: dispose some vars...
	}
	
	/**
	 * Loads font data in AngelCode's format.
	 * 
	 * @param	Source		Font image source.
	 * @param	Data		XML font data.
	 * @return	Generated bitmap font object.
	 */
	// TODO: make it accept only FlxGraphic, String, or BitmapData
	public static function fromAngelCode(Source:Dynamic, Data:Xml):BitmapFont
	{
		var graphic:FlxGraphic = FlxG.bitmap.add(Source, false);
		if (graphic == null)	return null;
		
		var font:BitmapFont = BitmapFont.findFont(graphic);
		if (font != null)
			return font;
		
		if ((graphic == null) || (Data == null)) return null;
		
		font = new BitmapFont(graphic);
		
		var fast:Fast = new Fast(Data.firstElement());
		
		font.lineHeight = Std.parseInt(fast.node.common.att.lineHeight);
		font.size = Std.parseInt(fast.node.info.att.size);
		font.fontName = Std.string(fast.node.info.att.face);
		font.bold = (Std.parseInt(fast.node.info.att.bold) != 0);
		font.italic = (Std.parseInt(fast.node.info.att.italic) != 0);
		
		var glyphFrame:GlyphFrame;
		var frame:Rectangle;
		var offset:FlxPoint;
		var sourceSize:FlxPoint;
		var glyph:String;
		var xOffset:Int, yOffset:Int, xAdvance:Int;
		var glyphWidth:Int, glyphHeight:Int;
		
		var chars = fast.node.chars;
		
		for (char in chars.nodes.char)
		{
			frame = new Rectangle();
			frame.x = Std.parseInt(char.att.x);
			frame.y = Std.parseInt(char.att.y);
			frame.width = Std.parseInt(char.att.width);
			frame.height = Std.parseInt(char.att.height);
			
			xOffset = char.has.xoffset ? Std.parseInt(char.att.xoffset) : 0;
			yOffset = char.has.yoffset ? Std.parseInt(char.att.yoffset) : 0;
			xAdvance = char.has.xadvance ? Std.parseInt(char.att.xadvance) : 0;
			
			offset = FlxPoint.get(xOffset, yOffset);
			sourceSize = FlxPoint.get(frame.width, frame.height);
			
			font.minOffsetX = (font.minOffsetX > xOffset) ? xOffset : font.minOffsetX;
			
			glyph = null;
			
			if (char.has.letter)
			{
				glyph = char.att.letter;
			}
			else if (char.has.id)
			{
				glyph = String.fromCharCode(Std.parseInt(char.att.id));
			}
			
			if (glyph == null) 
			{
				throw 'Invalid font xml data!';
			}
			
			glyph = switch(glyph) 
			{
				case "space": ' ';
				case "&quot;": '"';
				case "&amp;": '&';
				case "&gt;": '>';
				case "&lt;": '<';
				default: glyph;
			}
			
			font.addGlyphFrame(glyph, frame, sourceSize, offset, xAdvance);
		}
		
		return font;
	}
	
	/**
	 * Load bitmap font in XNA/Pixelizer format.
	 * 
	 * @param	source			Source image for this font.
	 * @param	letters			String of glyphs contained in the source image, in order (ex. " abcdefghijklmnopqrstuvwxyz"). Defaults to DEFAULT_GLYPHS.
	 * @param	glyphBGColor	An additional background color to remove. Defaults to 0xFF202020, often used for glyphs background.
	 * @return	
	 */
	// TODO: make it accept only FlxGraphic, String, or BitmapData
	public static function fromXNA(source:Dynamic, letters:String = null, glyphBGColor:Int = FlxColor.TRANSPARENT):BitmapFont
	{
		var graphic:FlxGraphic = FlxG.bitmap.add(source, false);
		if (graphic == null)	return null;
		
		var font:BitmapFont = BitmapFont.findFont(graphic);
		if (font != null)
			return font;
		
		letters = (letters == null) ? DEFAULT_GLYPHS : letters;
		
		if (graphic == null) return null;
		
		font = new BitmapFont(graphic);
		font.fontName = graphic.key;
		
		var bmd:BitmapData = graphic.bitmap;
		var globalBGColor:Int = bmd.getPixel(0, 0);
		var cy:Int = 0;
		var cx:Int;
		var letterIdx:Int = 0;
		var glyph:String;
		var numLetters:Int = letters.length;
		var rect:Rectangle;
		var sourceSize:FlxPoint;
		var offset:FlxPoint;
		var xAdvance:Int;
		
		while (cy < bmd.height && letterIdx < numLetters)
		{
			var rowHeight:Int = 0;
			cx = 0;
			
			while (cx < bmd.width && letterIdx < numLetters)
			{
				if (Std.int(bmd.getPixel(cx, cy)) != globalBGColor) 
				{
					// found non bg pixel
					var gx:Int = cx;
					var gy:Int = cy;
					
					// find width and height of glyph
					while (Std.int(bmd.getPixel(gx, cy)) != globalBGColor) gx++;
					while (Std.int(bmd.getPixel(cx, gy)) != globalBGColor) gy++;
					
					var gw:Int = gx - cx;
					var gh:Int = gy - cy;
					
					glyph = letters.charAt(letterIdx);
					
					rect = new Rectangle(cx, cy, gw, gh);
					
					offset = FlxPoint.get(0, 0);
					sourceSize = FlxPoint.get(gw, gh);
					
					xAdvance = gw;
					
					font.addGlyphFrame(glyph, rect, sourceSize, offset, xAdvance);
					
					// store max size
					if (gh > rowHeight) rowHeight = gh;
					if (gh > font.size) font.size = gh;
					
					// go to next glyph
					cx += gw;
					letterIdx++;
				}
				
				cx++;
			}
			
			// next row
			cy += (rowHeight + 1);
		}
		
		font.lineHeight = font.size;
		
		// remove background color
		POINT.x = POINT.y = 0;
		var bgColor32:Int = bmd.getPixel32(0, 0);
		bmd.threshold(bmd, bmd.rect, POINT, "==", bgColor32, 0x00000000, 0xFFFFFFFF, true);
		
		if (glyphBGColor != FlxColor.TRANSPARENT)
		{
			bmd.threshold(bmd, bmd.rect, POINT, "==", glyphBGColor, FlxColor.TRANSPARENT, FlxColor.WHITE, true);
		}
		
		return font;
	}
	
	// TODO: check it...
	/**
	 * Loads monospace bitmap font.
	 * 
	 * @param	source		Source image for this font.
	 * @param	letters		The characters used in the font set, in display order. You can use the TEXT_SET consts for common font set arrangements.
	 * @param	charSize	The size of each character in the font set.
	 * @param	region		The region of image to use for the font. Default is null which means that the whole image will be used.
	 * @param	spacing		Spaces between characters in the font set. Default is null which means no spaces.
	 * @return
	 */
	// TODO: make it accept only FlxGraphic, String, or BitmapData
	public static function fromMonospace(source:Dynamic, letters:String = null, charSize:Point, region:Rectangle = null, spacing:Point = null):BitmapFont
	{
		var graphic:FlxGraphic = FlxG.bitmap.add(source, false);
		if (graphic == null)	return null;
		
		var font:BitmapFont = BitmapFont.findFont(graphic);
		if (font != null)
			return font;
		
		letters = (letters == null) ? DEFAULT_GLYPHS : letters;
		
		if (graphic == null) return null;
		
		region = (region == null) ? graphic.bitmap.rect : region;
		spacing = (spacing == null) ? new Point(0, 0) : spacing;
		
		var bitmapWidth:Int = Std.int(region.width);
		var bitmapHeight:Int = Std.int(region.height);
		
		var startX:Int = Std.int(region.x);
		var startY:Int = Std.int(region.y);
		
		var xSpacing:Int = Std.int(spacing.x);
		var ySpacing:Int = Std.int(spacing.y);
		
		var charWidth:Int = Std.int(charSize.x);
		var charHeight:Int = Std.int(charSize.y);
		
		var spacedWidth:Int = charWidth + xSpacing;
		var spacedHeight:Int = charHeight + ySpacing;
		
		var numRows:Int = (charHeight == 0) ? 1 : Std.int((bitmapHeight + ySpacing) / spacedHeight);
		var numCols:Int = (charWidth == 0) ? 1 : Std.int((bitmapWidth + xSpacing) / spacedWidth);
		
		font = new BitmapFont(graphic);
		font.fontName = graphic.key;
		font.lineHeight = font.size = charHeight;
		
		var charRect:Rectangle;
		var sourceSize:FlxPoint;
		var offset:FlxPoint;
		var xAdvance:Int = charWidth;
		var letterIndex:Int = 0;
		var numLetters:Int = letters.length;
		
		for (j in 0...(numRows))
		{
			for (i in 0...(numCols))
			{
				charRect = new Rectangle(startX + i * spacedWidth, startY + j * spacedHeight, charWidth, charHeight);
				sourceSize = FlxPoint.get(charWidth, charHeight);
				offset = FlxPoint.get(0, 0);
				font.addGlyphFrame(letters.charAt(letterIndex), charRect, sourceSize, offset, xAdvance);
				
				letterIndex++;
				
				if (letterIndex >= numLetters)
				{
					return font;
				}
			}
		}
		
		return font;
	}
	
	// TODO: document it...
	/**
	 * 
	 * 
	 * @param	glyph
	 * @param	frame
	 * @param	sourceSize
	 * @param	offset
	 * @param	xAdvance
	 */
	private function addGlyphFrame(glyph:String, frame:Rectangle, sourceSize:FlxPoint, offset:FlxPoint, xAdvance:Int):Void
	{
		var glyphFrame:GlyphFrame = new GlyphFrame(parent);
		glyphFrame.name = glyph;
		glyphFrame.sourceSize.copyFrom(sourceSize);
		glyphFrame.halfSize.set(0.5 * sourceSize.x, 0.5 * sourceSize.y);
		glyphFrame.offset.copyFrom(offset);
		glyphFrame.frame = frame;
		glyphFrame.center.set(frame.width * 0.5, frame.height * 0.5);
		
		sourceSize.put();
		offset.put();
		
		#if FLX_RENDER_TILE
		glyphFrame.tileID = parent.tilesheet.addTileRect(frame, new Point(0.5 * frame.width, 0.5 * frame.height));
		#end
		
		frames.push(glyphFrame);
		framesHash.set(glyph, glyphFrame);
	}
	
	private static inline function findFont(graphic:FlxGraphic):BitmapFont
	{
		var bitmapFonts:Array<BitmapFont> = cast graphic.getFramesCollections(FrameCollectionType.FONT);
		if (bitmapFonts.length > 0 && bitmapFonts[0] != null)
		{
			return bitmapFonts[0];
		}
		
		return null;
	}
	
	/**
	 * Renders a string of text onto bitmap data using the font.
	 * 
	 * @param	PxBitmapData	Where to render the text.
	 * @param	PxText			Test to render.
	 * @param	PxColor			Color of text to render.
	 * @param	PxOffsetX		X position of thext output.
	 * @param	PxOffsetY		Y position of thext output.
	 */
	/*#if FLX_RENDER_BLIT 
	public function render(PxBitmapData:BitmapData, PxFontData:Array<BitmapData>, PxText:String, PxColor:FlxColor, PxOffsetX:Int, PxOffsetY:Int, PxLetterSpacing:Int):Void 
	#else
	public function render(DrawData:Array<Float>, PxText:String, PxColor:FlxColor, PxSecondColor:FlxColor, PxAlpha:Float, PxOffsetX:Float, PxOffsetY:Float, PxLetterSpacing:Int, PxScale:Float, PxUseColor:Bool = true):Void 
	#end
	{
		_point.x = PxOffsetX;
		_point.y = PxOffsetY;
		
		#if FLX_RENDER_BLIT
		var glyph:BitmapData;
		#else
		var glyph:PxFontSymbol;
		var glyphWidth:Int;
		
		if (PxUseColor)
		{
			PxSecondColor = PxColor * PxSecondColor;
		}
		#end
		
		for (i in 0...PxText.length) 
		{
			var charCode:Int = PxText.charCodeAt(i);
			
			#if FLX_RENDER_BLIT
			glyph = PxFontData[charCode];
			if (glyph != null) 
			#else
			glyph = _glyphs.get(charCode);
			if (_glyphs.exists(charCode))
			#end
			{
				#if FLX_RENDER_BLIT
				PxBitmapData.copyPixels(glyph, glyph.rect, _point, null, null, true);
				_point.x += glyph.width + PxLetterSpacing;
				#else
				glyphWidth = glyph.xadvance;
				
				// Tile_ID
				DrawData.push(glyph.tileID);
				// X
				DrawData.push(_point.x + glyph.xoffset * PxScale);	
				// Y
				DrawData.push(_point.y + glyph.yoffset * PxScale);	
				DrawData.push(PxSecondColor.redFloat);
				DrawData.push(PxSecondColor.greenFloat);
				DrawData.push(PxSecondColor.blueFloat);
				
				_point.x += glyphWidth * PxScale + PxLetterSpacing;
				#end
			}
		}
	}*/
	
	/**
	 * Returns the width of a certain test string.
	 * 
	 * @param	PxText	String to measure.
	 * @param	PxLetterSpacing	distance between letters
	 * @param	PxFontScale	"size" of the font
	 * @return	Width in pixels.
	 */
	/*public function getTextWidth(PxText:String, PxLetterSpacing:Int = 0, PxFontScale:Float = 1):Int 
	{
		var w:Int = 0;
		
		var textLength:Int = PxText.length;
		
		for (i in 0...(textLength)) 
		{
			var charCode:Int = PxText.charCodeAt(i);
			
			#if FLX_RENDER_BLIT
			var glyph:BitmapData = _glyphs[charCode];
			
			if (glyph != null)
			{
				
				w += glyph.width;
			}
			#else
			if (_glyphs.exists(charCode)) 
			{
				
				w += _glyphs.get(charCode).xadvance;
			}
			#end
		}
		
		w = Math.round(w * PxFontScale);
		
		if (textLength > 1)
		{
			w += (textLength - 1) * PxLetterSpacing;
		}
		
		return w;
	}*/
	
	/*
	#if FLX_RENDER_BLIT
	/**
	 * Serializes font data to cryptic bit string.
	 * 
	 * @return	Cryptic string with font as bits.
	 */
	public function getFontData():String 
	{
		var output:String = "";
		
		for (i in 0...(_glyphString.length)) 
		{
			var charCode:Int = _glyphString.charCodeAt(i);
			var glyph:BitmapData = _glyphs[charCode];
			output += _glyphString.substr(i, 1);
			output += glyph.width;
			output += glyph.height;
			
			for (py in 0...(glyph.height)) 
			{
				for (px in 0...(glyph.width)) 
				{
					output += (glyph.getPixel32(px, py) != 0 ? "1":"0");
				}
			}
		}
		
		return output;
	}
	#end
	*/
}