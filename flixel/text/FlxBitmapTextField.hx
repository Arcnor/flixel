package flixel.text;

import flash.display.BitmapData;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.BitmapFont;
import flixel.system.layer.DrawStackItem;
import flixel.text.FlxText.FlxTextAlign;
import flixel.math.FlxAngle;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;

/**
 * Extends FlxSprite to support rendering text.
 * Can tint, fade, rotate and scale just like a sprite.
 * Doesn't really animate though, as far as I know.
 */
class FlxBitmapTextField extends FlxSprite
{
	/**
	 * 
	 */
	@:isVar
	public var font(default, set):BitmapFont;
	
	/**
	 * 
	 */
	@:isVar
	public var text(default, set):String = "";
	
	private var _lines:Array<String> = [];
	
	/**
	 * 
	 */
	@:isVar
	public var alignment(default, set):FlxTextAlign = FlxTextAlign.LEFT;
	
	/**
	 * 
	 */
	@:isVar
	public var lineSpacing(default, set):Int = 0;
	
	/**
	 * 
	 */
	@:isVar
	public var letterSpacing(default, set):Int = 0;
	
	/**
	 * 
	 */
	@:isVar
	public var autoUpperCase(default, set):Bool = false;
	
	/**
	 * 
	 */
	@:isVar
	public var wordWrap(default, set):Bool = true;
	
	/**
	 * Whether word wrapping algorithm should wrap lines by words or by single character
	 */
	@:isVar 
	public var wrapByWord(default, set):Bool = false;
	
	/**
	 * 
	 */
	@:isVar
	public var fixedWidth(default, set):Bool;
	
	/**
	 * 
	 */
	@:isVar
	public var numSpacesInTab(default, set):Int = 4;
	private var _tabSpaces:String = "    ";
	
	/**
	 * 
	 */
	@:isVar
	public var textColor(default, set):FlxColor = 0x0;
	
	/**
	 * 
	 */
	@:isVar
	public var useTextColor(default, set):Bool = true;
	
	/**
	 * 
	 */
	@:isVar
	public var outline(default, set):Bool = false;
	
	/**
	 * 
	 */
	@:isVar
	public var outlineColor(default, set):FlxColor = 0x0;
	
	/**
	 * 
	 */
	@:isVar
	public var shadow(default, set):Bool = false;
	
	/**
	 * 
	 */
	@:isVar
	public var shadowColor(default, set):FlxColor = 0x0;
	
	/**
	 * 
	 */
	@:isVar
	public var multiLine(default, set):Bool = false;
	
	/**
	 * 
	 */
	@:isVar
	public var numLines(default, set):Int = 0;
	
	/**
	 * 
	 */
	@:isVar
	public var fontScale(default, set):Float = 1;
	
	/**
	 * 
	 */
	private var _pendingTextChange:Bool = false;
	/**
	 * 
	 */
	private var _pendingGraphicChange:Bool = false;
	
	#if FLX_RENDER_TILE
	private var _drawData:Array<Float>;
	private var _bgDrawData:Array<Float>;
	#else
	private var textGlyphs:BitmapGlyphCollection;
	private var shadowGlyphs:BitmapGlyphCollection;
	private var outlineGlyphs:BitmapGlyphCollection;
	#end
	
	/**
	 * Constructs a new text field component.
	 * @param 	font	Optional parameter for component's font prop
	 */
	public function new(?font:BitmapFont) 
	{
		super();
		
		width = 2;
		alpha = 1;
		
		if (font == null)
		{
			font = BitmapFont.getDefault();
		}
		
		this.font = font;
		
		#if FLX_RENDER_BLIT
		pixels = new BitmapData(1, 1, true, FlxColor.TRANSPARENT);
		#else
		pixels = _font.parent.bitmap;
		_drawData = [];
		_bgDrawData = [];
		#end
		
		_pendingTextChange = true;
		_pendingGraphicChange = true;
	}
	
	/**
	 * Clears all resources used.
	 */
	override public function destroy():Void 
	{
		font = null;
		text = null;
		_lines = [];
		
		#if FLX_RENDER_TILE
		_drawData = null;
		_bgDrawData = null;
		#else
		textGlyphs = FlxDestroyUtil.destroy(textGlyphs);
		shadowGlyphs = FlxDestroyUtil.destroy(shadowGlyphs);
		outlineGlyphs = FlxDestroyUtil.destroy(outlineGlyphs);
		#end
		
		super.destroy();
	}
	
	override public function update():Void 
	{
		if (_pendingTextChange)
		{
			updateLines();
			_pendingTextChange = true;
		}
		
		if (_pendingGraphicChange)
		{
			updateBitmapData();
		}
		
		super.update();
	}
	
	#if FLX_RENDER_BLIT
	override public function draw():Void 
	{
		if (_pendingTextChange)
		{
			updateBitmapData();
		}
		
		super.draw();
	}
	#else
	override public function draw():Void 
	{
		if (_pendingTextChange)
		{
			updateBitmapData();
		}
		
		var textLength:Int = Std.int(_drawData.length / 6);

		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists || !isOnScreen(camera))
			{
				continue;
			}
			
			_point.x = (x - (camera.scroll.x * scrollFactor.x) - (offset.x)) + origin.x;
			_point.y = (y - (camera.scroll.y * scrollFactor.y) - (offset.y)) + origin.y;
			
			var csx:Float = 1;
			var ssy:Float = 0;
			var ssx:Float = 0;
			var csy:Float = 1;
			var x1:Float = 0;
			var y1:Float = 0;
			
			if (!isSimpleRender(camera))
			{
				if (_angleChanged)
				{
					var radians:Float = angle * FlxAngle.TO_RAD;
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
			}
			
			if (_background)
			{
				var currTileX = _bgDrawData[1] - x1;
				var currTileY = _bgDrawData[2] - y1;
				
				var relativeX = (currTileX * csx - currTileY * ssy);
				var relativeY = (currTileX * ssx + currTileY * csy);
				
				_point.set(currTileX, currTileY).add(relativeX, relativeY);
				
				var bgDrawItem = camera.getDrawStackItem(FlxG.bitmap.whitePixel, true, _blendInt, antialiasing);
				bgDrawItem.setDrawData(_point, _bgDrawData[0],
					csx * width, ssx * width, -ssy * height, csy * height,
					FlxColor.fromRGBFloat(_bgDrawData[3], _bgDrawData[4], _bgDrawData[5]), alpha * camera.alpha);
			}
			
			var j = 0;
			while (j < textLength)
			{
				var drawItem = camera.getDrawStackItem(graphic, true, _blendInt, antialiasing);
				
				drawItem.position = j * 6;
				
				var currTileX = _drawData[drawItem.position + 1] - x1;
				var currTileY = _drawData[drawItem.position + 2] - y1;
				
				var relativeX = (currTileX * csx - currTileY * ssy);
				var relativeY = (currTileX * ssx + currTileY * csy);
				
				_point.set(currTileX, currTileY).add(relativeX, relativeY);
				
				var red = _drawData[drawItem.position + 3];
				var green = _drawData[drawItem.position + 4];
				var blue = _drawData[drawItem.position + 5];
				
				drawItem.setDrawData(_point, _drawData[drawItem.position],
					csx * fontScale, ssx * fontScale, -ssy * fontScale, csy * fontScale,
					FlxColor.fromRGBFloat(red, green, blue), alpha * camera.alpha);

				j++;
			}
			
			#if !FLX_NO_DEBUG
			FlxBasic.visibleCount++;
			#end
		}
	}
	
	override private function set_color(Color:FlxColor):FlxColor
	{
		super.set_color(Color);
		_pendingTextChange = true;
		return color;
	}
	#end
	
	private function set_textColor(value:FlxColor):FlxColor 
	{
		if (textColor != value)
		{
			textColor = value;
			updateTextGlyphs();
			_pendingTextChange = true;
		}
		
		return value;
	}
	
	private function set_useTextColor(value:Bool):Bool 
	{
		if (useTextColor != value)
		{
			useTextColor = value;
			updateTextGlyphs();
			_pendingTextChange = true;
		}
		
		return value;
	}
	
	override private function set_alpha(value:Float):Float
	{
		#if FLX_RENDER_BLIT
		super.set_alpha(value);
		#else
		alpha = value;
		_pendingTextChange = true;
		#end
		
		return value;
	}
	
	// TODO: override calcFrame (maybe)
	
	private function set_text(value:String):String 
	{
		if (value != text)
		{
			text = value;
			_pendingTextChange = true;
		}
		
		return value;
	}
	
	private function updateLines():Void 
	{
		var tmp:String = (autoUpperCase) ? text.toUpperCase() : text;
		
		_lines = tmp.split("\n");
		
		if (fixedWidth)
		{
			if (wordWrap)
			{
				wrap();
			}
			else
			{
				cutLines();
			}
		}
		
		if (!multiLine)
		{
			_lines = [_lines[0]];
		}
		
		computeTextSize();
		
		_pendingTextChange = false;
	}
	
	/**
	 * Calculates the size of text field.
	 */
	private function computeTextSize():Void 
	{
		var textWidth:Int = Math.ceil(width);
		var textHeight:Int = Math.ceil(font.lineHeight * scale * _lines.length);
		
		if (!fixedWidth)
		{
			textWidth = Math.ceil(getMaxLineWidth());
		}
		
		// TODO: use these var for pixels dimensions
		frameWidth = textWidth;
		frameHeight = textHeight;
	}
	
	private function getMaxLineWidth():Float
	{
		var max:Float = 0;
		for (line in _lines)
		{
			max = Math.max(max, getLineWidth(line));
		}
		return max;
	}
	
	private function getLineWidth(line:String):Float
	{
		var spaceWidth:Float = font.spaceWidth * fontScale;
		var tabWidth:Float = spaceWidth * numSpacesInTab;
		
		var lineLength:Int = line.length;	// lenght of the current line
		var lineWidth:Float = 0;
		
		var char:String; 					// current character in word
		var charWidth:Float = 0;			// the width of current character
		
		for (c in 0...lineLength)
		{
			char = line.charAt(c);
			
			if (char == ' ')
			{
				charWidth = spaceWidth;
			}
			else if (char == '\t')
			{
				charWidth = tabWidth;
			}
			else
			{
				charWidth = (font.glyphs.exists(char)) ? font.glyphs.get(char).xAdvance * fontScale : 0;
			}
			
			lineWidth += (charWidth + letterSpacing);
		}
		
		if (lineLength > 0)
		{
			lineWidth -= letterSpacing;
		}
		
		return lineWidth;
	}
	
	/**
	 * Just cuts the lines which are too long to fit in the field.
	 */
	private function cutLines():Void 
	{
		var newLines:Array<String> = [];
		
		var lineLength:Int;			// lenght of the current line
		
		var c:Int;					// char index
		var char:String; 			// current character in word
		var charWidth:Float = 0;	// the width of current character
		
		var subLine:String;			// current subline to assemble
		var subLineWidth:Float;		// the width of current subline
		
		var spaceWidth:Float = font.spaceWidth * fontScale;
		var tabWidth:Float = spaceWidth * numSpacesInTab;
		
		for (line in _lines)
		{
			lineLength = line.length;
			subLine = "";
			subLineWidth = 0;
			
			c = 0;
			while (c < lineLength)
			{
				char = line.charAt(c);
				
				if (char == ' ')
				{
					charWidth = spaceWidth;
				}
				else if (char == '\t')
				{
					charWidth = tabWidth;
				}
				else
				{
					charWidth = (font.glyphs.exists(char)) ? font.glyphs.get(char).xAdvance * fontScale : 0;
				}
				charWidth += letterSpacing;
				
				if (subLineWidth + charWidth > width)
				{
					subLine += char;
					newLines.push(subLine);
					subLine = "";
					subLineWidth = 0;
					c = lineLength;
				}
				else
				{
					subLine += char;
					subLineWidth += charWidth;
				}
				
				c++;
			}
		}
		
		_lines = newLines;
	}
	
	/**
	 * Automatically wraps text by figuring out how many characters can fit on a
	 * single line, and splitting the remainder onto a new line.
	 */
	private function wrap():Void
	{
		// subdivide lines
		var newLines:Array<String> = [];
		var words:Array<String>;			// the array of words in the current line
		
		for (line in _lines)
		{
			words = [];
			// split this line into words
			splitLineIntoWords(line, words);
			
			if (wrapByWord)
			{
				wrapLineByWord(words, newLines);
			}
			else
			{
				wrapLineByCharacter(words, newLines);
			}
		}
		
		_lines = newLines;
	}
	
	/**
	 * Helper function for splitting line of text into separate words.
	 * 
	 * @param	line	line to split.
	 * @param	words	result array to fill with words.
	 */
	private function splitLineIntoWords(line:String, words:Array<String>):Void
	{
		var word:String = "";				// current word to process
		var isSpaceWord:Bool = false; 		// whether current word consists of spaces or not
		var lineLength:Int = line.length;	// lenght of the current line
		
		var c:Int = 0;						// char index on the line
		var char:String; 					// current character in word
		
		while (c < lineLength)
		{
			char = line.charAt(c);
			switch(char)
			{
				case ' ', '\t': {
					if (!isSpaceWord)
					{
						isSpaceWord = true;
						
						if (word != "")
						{
							words.push(word);
							word = "";
						}
					}
					
					word += char;
				}
				case '-': {
					if (isSpaceWord && word != "")
					{
						isSpaceWord = false;
						words.push(word);
						words.push(char);
					}
					else if (isSpaceWord == false)
					{
						words.push(word + char);
					}
					
					word = "";
				}
				default: {
					if (isSpaceWord && word != "")
					{
						isSpaceWord = false;
						words.push(word);
						word = "";
					}
					
					word += char;
				}
			}
			
			c++;
		}
		
		if (word != "") words.push(word);
		
	}
	
	/**
	 * Wraps provided line by words.
	 * 
	 * @param	words		The array of words in the line to process.
	 * @param	newLines	Array to fill with result lines.
	 */
	private function wrapLineByWord(words:Array<String>, newLines:Array<String>):Void
	{
		var numWords:Int = words.length;	// number of words in the current line
		var w:Int;							// word index in the current line
		var word:String;					// current word to process
		var wordWidth:Float;				// total width of current word
		var wordLength:Int;					// number of letters in current word
		
		var isSpaceWord:Bool = false; 		// whether current word consists of spaces or not
		
		var char:String; 					// current character in word
		var charWidth:Float = 0;			// the width of current character
		
		var subLines:Array<String> = [];	// helper array for subdividing lines
		
		var subLine:String;					// current subline to assemble
		var subLineWidth:Float;				// the width of current subline
		
		var spaceWidth:Float = font.spaceWidth * fontScale;
		var tabWidth:Float = spaceWidth * numSpacesInTab;
		
		if (numWords > 0)
		{
			w = 0;
			subLineWidth = 0;
			subLine = "";
			
			while (w < numWords)
			{
				wordWidth = 0;
				word = words[w];
				wordLength = word.length;
				
				isSpaceWord = (word.charAt(0) == ' ' || word.charAt(0) == '\t');
				
				for (c in 0...wordLength)
				{
					char = word.charAt(c);
					
					if (char == ' ')
					{
						charWidth = spaceWidth;
					}
					else if (char == '\t')
					{
						charWidth = tabWidth;
					}
					else
					{
						charWidth = (font.glyphs.exists(char)) ? font.glyphs.get(char).xAdvance * fontScale : 0;
					}
					
					wordWidth += charWidth + letterSpacing;
				}
				
				if (subLineWidth + wordWidth > width)
				{
					if (isSpaceWord)
					{
						subLines.push(subLine);
						subLine = "";
						subLineWidth = 0;
					}
					else if (subLine != "") // new line isn't empty so we should add it to sublines array and start another one
					{
						subLines.push(subLine);
						subLine = word;
						subLineWidth = wordWidth;
					}
					else					// the line is too tight to hold even one word
					{
						subLine = word;
						subLineWidth = wordWidth;
					}
				}
				else
				{
					subLine += word;
					subLineWidth += wordWidth;
				}
				
				w++;
			}
			
			if (subLine != "")
			{
				subLines.push(subLine);
			}
		}
		
		for (subline in subLines)
		{
			newLines.push(subline);
		}
	}
	
	/**
	 * Wraps provided line by characters (as in standart flash text fields).
	 * 
	 * @param	words		The array of words in the line to process.
	 * @param	newLines	Array to fill with result lines.
	 */
	private function wrapLineByCharacter(words:Array<String>, newLines:Array<String>):Void
	{
		var numWords:Int = words.length;	// number of words in the current line
		var w:Int;							// word index in the current line
		var word:String;					// current word to process
		var wordLength:Int;					// number of letters in current word
		
		var isSpaceWord:Bool = false; 		// whether current word consists of spaces or not
		
		var char:String; 					// current character in word
		var c:Int;							// char index
		var charWidth:Float = 0;			// the width of current character
		
		var subLines:Array<String> = [];	// helper array for subdividing lines
		
		var subLine:String;					// current subline to assemble
		var subLineWidth:Float;				// the width of current subline
		
		var spaceWidth:Float = font.spaceWidth * fontScale;
		var tabWidth:Float = spaceWidth * numSpacesInTab;
		
		if (numWords > 0)
		{
			w = 0;
			subLineWidth = 0;
			subLine = "";
			
			while (w < numWords)
			{
				word = words[w];
				wordLength = word.length;
				
				isSpaceWord = (word.charAt(0) == ' ' || word.charAt(0) == '\t');
				
				c = 0;
				
				while (c < wordLength)
				{
					char = word.charAt(c);
					
					if (char == ' ')
					{
						charWidth = spaceWidth;
					}
					else if (char == '\t')
					{
						charWidth = tabWidth;
					}
					else
					{
						charWidth = (font.glyphs.exists(char)) ? font.glyphs.get(char).xAdvance * fontScale : 0;
					}
					charWidth += letterSpacing;
					
					if (subLineWidth + charWidth > width)
					{
						if (isSpaceWord) // new line ends with space / tab char, so we push it to sublines array, skip all the rest spaces and start another line
						{
							subLines.push(subLine);
							c = wordLength;
							subLine = "";
							subLineWidth = 0;
						}
						else if (subLine != "") // new line isn't empty so we should add it to sublines array and start another one
						{
							subLines.push(subLine);
							subLine = char;
							subLineWidth = charWidth;
						}
						else	// the line is too tight to hold even one glyph
						{
							subLine = char;
							subLineWidth = charWidth;
						}
					}
					else
					{
						subLine += char;
						subLineWidth += charWidth;
						charWidth;
					}
					
					c++;
				}
				
				w++;
			}
			
			if (subLine != "")
			{
				subLines.push(subLine);
			}
		}
		
		for (subline in subLines)
		{
			newLines.push(subline);
		}
	}
	
	/**
	 * Internal method for updating the view of the text component
	 */
	private function updateBitmapData():Void 
	{
		if (!_pendingGraphicChange) 
		{
			return;
		}
		
		if (font == null)
		{
			return;
		}
		
		var preparedText:String = (autoUpperCase) ? text.toUpperCase() : text;
		var calcFieldWidth:Int = 0;
		var rows:Array<String> = [];
		
		#if FLX_RENDER_BLIT
		var fontHeight:Int = Math.floor(font.getFontHeight() * fontScale);
		#else
		var fontHeight:Int = font.getFontHeight();
		#end
		
		// Cut text into pices
		var lineComplete:Bool;
		
		// Get words
		var lines:Array<String> = preparedText.split("\n");
		var i:Int = -1;
		var j:Int = -1;
		
		if (!multiLine)
		{
			lines = [lines[0]];
		}
		
		var wordLength:Int;
		var word:String;
		var tempStr:String;
		
		while (++i < lines.length) 
		{
			if (fixedWidth)
			{
				lineComplete = false;
				var words:Array<String> = [];
				
				if (!wordWrap)
				{
					words = lines[i].split("\t").join(_tabSpaces).split(" ");
				}
				else
				{
					words = lines[i].split("\t").join(" \t ").split(" ");
				}
				
				if (words.length > 0) 
				{
					var wordPos:Int = 0;
					var txt:String = "";
					
					while (!lineComplete) 
					{
						word = words[wordPos];
						var changed:Bool = false;
						var currentRow:String = txt + word;
						
						if (wordWrap)
						{
							var prevWord:String = (wordPos > 0) ? words[wordPos - 1] : "";
							var nextWord:String = (wordPos < words.length) ? words[wordPos + 1] : "";
							if (prevWord != "\t") currentRow += " ";
							
							if (font.getTextWidth(currentRow, letterSpacing, fontScale) > width) 
							{
								if (txt == "")
								{
									words.splice(0, 1);
								}
								else
								{
									rows.push(txt.substr(0, txt.length - 1));
								}
								
								txt = "";
								
								if (multiLine)
								{
									if (word == "\t" && (wordPos < words.length))
									{
										words.splice(0, wordPos + 1);
									}
									else
									{
										words.splice(0, wordPos);
									}
								}
								else
								{
									words.splice(0, words.length);
								}
								
								wordPos = 0;
								changed = true;
							}
							else
							{
								if (word == "\t")
								{
									txt += _tabSpaces;
								}
								if (nextWord == "\t" || prevWord == "\t")
								{
									txt += word;
								}
								else
								{
									txt += word + " ";
								}
								wordPos++;
							}
						}
						else
						{
							if (font.getTextWidth(currentRow, letterSpacing, fontScale) > width) 
							{
								if (word != "")
								{
									j = 0;
									tempStr = "";
									wordLength = word.length;
									while (j < wordLength)
									{
										currentRow = txt + word.charAt(j);
										
										if (font.getTextWidth(currentRow, letterSpacing, fontScale) > width) 
										{
											rows.push(txt.substr(0, txt.length - 1));
											txt = "";
											word = "";
											wordPos = words.length;
											j = wordLength;
											changed = true;
										}
										else
										{
											txt += word.charAt(j);
										}
										
										j++;
									}
								}
								else
								{
									changed = false;
									wordPos = words.length;
								}
							}
							else
							{
								txt += word + " ";
								wordPos++;
							}
						}
						
						if (wordPos >= words.length) 
						{
							if (!changed) 
							{
								calcFieldWidth = Std.int(Math.max(calcFieldWidth, font.getTextWidth(txt, letterSpacing, fontScale)));
								rows.push(txt);
							}
							lineComplete = true;
						}
					}
				}
				else
				{
					rows.push("");
				}
			}
			else
			{
				var lineWithoutTabs:String = lines[i].split("\t").join(_tabSpaces);
				calcFieldWidth = Std.int(Math.max(calcFieldWidth, font.getTextWidth(lineWithoutTabs, letterSpacing, fontScale)));
				rows.push(lineWithoutTabs);
			}
		}
		
		var finalWidth:Int = (fixedWidth) ? Std.int(width) : calcFieldWidth + (outline ? 2 : 0);
		
		#if FLX_RENDER_BLIT
		var finalHeight:Int = Std.int(Math.max(1, (rows.length * fontHeight + (shadow ? 1 : 0)) + (outline ? 2 : 0))) + ((rows.length >= 1) ? lineSpacing * (rows.length - 1) : 0);
		#else
		
		var finalHeight:Int = Std.int(Math.max(1, (rows.length * fontHeight * fontScale + (shadow ? 1 : 0)) + (outline ? 2 : 0))) + ((rows.length >= 1) ? lineSpacing * (rows.length - 1) : 0);
		
		width = frameWidth = finalWidth;
		height = frameHeight = finalHeight;
		frames = 1;
		origin.x = width * 0.5;
		origin.y = height * 0.5;
		
		_halfWidth = origin.x;
		_halfHeight = origin.y;
		#end
		
		#if FLX_RENDER_BLIT
		if (pixels == null || (finalWidth != pixels.width || finalHeight != pixels.height)) 
		{
			pixels = new BitmapData(finalWidth, finalHeight, true, FlxColor.TRANSPARENT);
		} 
		else 
		{
			pixels.fillRect(graphic.bitmap.rect, FlxColor.TRANSPARENT);
		}
		#else
		_drawData.splice(0, _drawData.length);
		_bgDrawData.splice(0, _bgDrawData.length);
		
		if (graphic == null)
		{
			return;
		}
		
		// Draw background
		if (_background)
		{
			// Tile_ID
			_bgDrawData.push(_font.bgTileID);		
			_bgDrawData.push( -_halfWidth);
			_bgDrawData.push( -_halfHeight);
			
			#if FLX_RENDER_TILE
			var colorMultiplier:Float = 1 / (255 * 255);
			
			var red:Float = (_backgroundColor >> 16) * colorMultiplier;
			var green:Float = (_backgroundColor >> 8 & 0xff) * colorMultiplier;
			var blue:Float = (_backgroundColor & 0xff) * colorMultiplier;
			
			red *= (color >> 16);
			green *= (color >> 8 & 0xff);
			blue *= (color & 0xff);
			#end
			
			_bgDrawData.push(red);
			_bgDrawData.push(green);
			_bgDrawData.push(blue);
		}
		#end
		
		if (fontScale > 0)
		{
			#if FLX_RENDER_BLIT
			pixels.lock();
			#end
			
			// Render text
			var row:Int = 0;
			
			for (t in rows) 
			{
				// LEFT
				var ox:Int = 0;
				var oy:Int = 0;
				
				if (alignment == FlxTextAlign.CENTER) 
				{
					if (fixedWidth)
					{
						ox = Std.int((width - font.getTextWidth(t, letterSpacing, fontScale)) / 2);
					}
					else
					{
						ox = Std.int((finalWidth - font.getTextWidth(t, letterSpacing, fontScale)) / 2);
					}
				}
				if (alignment == FlxTextAlign.RIGHT) 
				{
					if (fixedWidth)
					{
						ox = Std.int(width) - Std.int(font.getTextWidth(t, letterSpacing, fontScale));
					}
					else
					{
						ox = finalWidth - Std.int(font.getTextWidth(t, letterSpacing, fontScale));
					}
				}
				if (outline) 
				{
					for (py in 0...(2 + 1)) 
					{
						for (px in 0...(2 + 1)) 
						{
							#if FLX_RENDER_BLIT
							font.render(pixels, outlineGlyphs, t, outlineColor, px + ox, py + row * (fontHeight + lineSpacing), letterSpacing);
							#else
							font.render(_drawData, t, outlineColor, color, alpha, px + ox - _halfWidth, py + row * (fontHeight * fontScale + lineSpacing) - _halfHeight, letterSpacing, fontScale);
							#end
						}
					}
					ox += 1;
					oy += 1;
				}
				if (shadow) 
				{
					#if FLX_RENDER_BLIT
					font.render(pixels, shadowGlyphs, t, shadowColor, 1 + ox, 1 + oy + row * (fontHeight + lineSpacing), letterSpacing);
					#else
					font.render(_drawData, t, shadowColor, color, alpha, 1 + ox - _halfWidth, 1 + oy + row * (fontHeight * fontScale + _lineSpacing) - _halfHeight, letterSpacing, fontScale);
					#end
				}
				
				#if FLX_RENDER_BLIT
				font.render(pixels, textGlyphs, t, textColor, ox, oy + row * (fontHeight + lineSpacing), letterSpacing);
				#else
				font.render(_drawData, t, textColor, color, alpha, ox - _halfWidth, oy + row * (fontHeight * fontScale + lineSpacing) - _halfHeight, letterSpacing, fontScale, useTextColor);
				#end
				row++;
			}
			
			#if FLX_RENDER_BLIT
			pixels.unlock();
			frame.destroyBitmaps();
			dirty = true;
			#end
		}
		
		_pendingTextChange = false;
	}
	
	/**
	 * Sets the width of the text field. If the text does not fit, it will spread on multiple lines.
	 */
	override private function set_width(value:Float):Float
	{
		value = Std.int(value);
		
		// TODO: if width is <= 0 then set fixed width to false
		
		if (value < 1) 
		{
			value = 1;
		}
		if (value != width)
		{
			_pendingTextChange = true;
		}
		
		return super.set_width(value);
	}
	
	private function set_alignment(value:FlxTextAlign):FlxTextAlign 
	{
		if (alignment != value && alignment != FlxTextAlign.JUSTIFY)
		{
			alignment = value;
			_pendingTextChange = true;
		}
		
		return value;
	}
	
	private function set_multiLine(value:Bool):Bool 
	{
		if (multiLine != value)
		{
			multiLine = value;
			_pendingTextChange = true;
		}
		
		return value;
	}
	
	private function set_font(value:BitmapFont):BitmapFont 
	{
		if (font != value)
		{
			font = value;
			_pendingTextChange = true;
			
			#if FLX_RENDER_TILE
			pixels = _font.pixels;
			#end
		}
		
		return value;
	}
	
	private function set_lineSpacing(value:Int):Int
	{
		if (lineSpacing != value)
		{
			lineSpacing = Std.int(Math.abs(value));
			_pendingTextChange = true;
		}
		
		return lineSpacing;
	}
	
	private function set_letterSpacing(value:Int):Int
	{
		var tmp:Int = Std.int(Math.abs(value));
		
		if (tmp != letterSpacing)
		{
			letterSpacing = tmp;
			_pendingTextChange = true;
		}
		
		return letterSpacing;
	}
	
	private function set_autoUpperCase(value:Bool):Bool 
	{
		if (autoUpperCase != value)
		{
			autoUpperCase = value;
			_pendingTextChange = true;
		}
		
		return autoUpperCase;
	}
	
	private function set_wordWrap(value:Bool):Bool 
	{
		if (wordWrap != value)
		{
			wordWrap = value;
			_pendingTextChange = true;
		}
		
		return wordWrap;
	}
	
	private function set_wrapByWord(value:Bool):Bool
	{
		if (wrapByWord != value)
		{
			wrapByWord = value;
			_pendingTextChange = true;
		}
		
		return value;
	}
	
	private function set_fixedWidth(value:Bool):Bool 
	{
		if (fixedWidth != value)
		{
			fixedWidth = value;
			_pendingTextChange = true;
		}
		
		return fixedWidth;
	}
	
	private function set_fontScale(value:Float):Float
	{
		var tmp:Float = Math.abs(value);
		
		if (tmp != fontScale)
		{
			fontScale = tmp;
			updateTextGlyphs();
			updateShadowGlyphs();
			updateOutlineGlyphs();
			_pendingTextChange = true;
		}
		
		return value;
	}
	
	private function set_numSpacesInTab(value:Int):Int 
	{
		if (numSpacesInTab != value && value > 0)
		{
			numSpacesInTab = value;
			_tabSpaces = "";
			
			for (i in 0...value)
			{
				_tabSpaces += " ";
			}
			
			_pendingTextChange = true;
		}
		
		return value;
	}
	
	private function set_outline(value:Bool):Bool 
	{
		if (outline != value)
		{
			outline = value;
			shadow = false;
			updateOutlineGlyphs();
			_pendingTextChange = true;
		}
		
		return value;
	}
	
	private function set_outlineColor(value:Int):Int 
	{
		if (outlineColor != value)
		{
			outlineColor = value;
			updateOutlineGlyphs();
			_pendingTextChange = true;
		}
		
		return value;
	}
	
	private function set_shadow(value:Bool):Bool
	{
		if (shadow != value)
		{
			shadow = value;
			outline = false;
			updateShadowGlyphs();
			_pendingTextChange = true;
		}
		
		return value;
	}
	
	private function set_shadowColor(value:Int):Int 
	{
		if (shadowColor != value)
		{
			shadowColor = value;
			updateShadowGlyphs();
			_pendingTextChange = true;
		}
		
		return value;
	}
	
	private function set_numLines(value:Int):Int
	{
		// TODO: actually implement this feature
		
		return numLines = value;
	}
	
	private function updateTextGlyphs():Void
	{
		#if FLX_RENDER_BLIT
		textGlyphs = FlxDestroyUtil.destroy(textGlyphs);
		textGlyphs = font.prepareGlyphs(fontScale, textColor, useTextColor);
		#end
	}
	
	private function updateShadowGlyphs():Void
	{
		#if FLX_RENDER_BLIT
		if (!shadow)	return;
		shadowGlyphs = FlxDestroyUtil.destroy(shadowGlyphs);
		shadowGlyphs = font.prepareGlyphs(fontScale, shadowColor);
		#end
	}
	
	private function updateOutlineGlyphs():Void
	{
		#if FLX_RENDER_BLIT
		if (!outline)	return;
		outlineGlyphs = FlxDestroyUtil.destroy(outlineGlyphs);
		outlineGlyphs = font.prepareGlyphs(fontScale, outlineColor);
		#end
	}
}