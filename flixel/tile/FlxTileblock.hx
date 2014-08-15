package flixel.tile;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.TileFrames;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.system.layer.DrawStackItem;
import flixel.math.FlxAngle;
import flixel.math.FlxRandom;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import openfl.geom.Point;

/**
 * This is a basic "environment object" class, used to create simple walls and floors.
 * It can be filled with a random selection of tiles to quickly add detail.
 */
class FlxTileblock extends FlxSprite
{
	/**
	 * Creates a new FlxBlock object with the specified position and size.
	 * 
	 * @param	X			The X position of the block.
	 * @param	Y			The Y position of the block.
	 * @param	Width		The width of the block.
	 * @param	Height		The height of the block.
	 */
	public function new(X:Int, Y:Int, Width:Int, Height:Int)
	{
		super(X, Y);
		makeGraphic(Width, Height, FlxColor.TRANSPARENT, true);
		active = false;
		immovable = true;
		moves = false;
	}
	
	/**
	 * Fills the block with a randomly arranged selection of frames.
	 * 
	 * @param	TileFrames		The frames that should fill this block.
	 * @param	Empties			The number of "empty" tiles to add to the auto-fill algorithm (e.g. 8 tiles + 4 empties = 1/3 of block will be open holes).
	 * @return	This tile block.
	 */
	public function loadFrames(tileFrames:TileFrames, empties:Int = 0):FlxTileblock
	{
		if (tileFrames == null)
		{
			return this;
		}
		
		// First create a tile brush
		var sprite:FlxSprite = new FlxSprite();
		sprite.frames = tileFrames;
		var spriteWidth:Int = Std.int(sprite.width);
		var spriteHeight:Int = Std.int(sprite.height);
		var total:Int = sprite.numFrames + empties;
		
		// Then prep the "canvas" as it were (just doublechecking that the size is on tile boundaries)
		var regen:Bool = false;
		
		if (width % spriteWidth != 0)
		{
			width = Std.int((width / spriteWidth + 1)) * spriteWidth;
			regen = true;
		}
		
		if (height % spriteHeight != 0)
		{
			height = Std.int((height / spriteHeight + 1)) * spriteHeight;
			regen = true;
		}
		
		if (regen)
		{
			makeGraphic(Std.int(width), Std.int(height), 0, true);
		}
		else
		{
			FlxSpriteUtil.fill(this, 0);
		}
		
		// Stamp random tiles onto the canvas
		var row:Int = 0;
		var column:Int;
		var destinationX:Int;
		var destinationY:Int = 0;
		var widthInTiles:Int = Std.int(width / spriteWidth);
		var heightInTiles:Int = Std.int(height / spriteHeight);
		
		while (row < heightInTiles)
		{
			destinationX = 0;
			column = 0;
			
			while (column < widthInTiles)
			{
				if (FlxRandom.float() * total > empties)
				{
					sprite.animation.randomFrame();
					sprite.drawFrame();
					stamp(sprite, destinationX, destinationY);
				}
				
				destinationX += spriteWidth;
				column++;
			}
			
			destinationY += spriteHeight;
			row++;
		}
		
		sprite.destroy();
		dirty = true;
		return this;
	}
	
	/**
	 * Fills the block with a randomly arranged selection of graphics from the image provided.
	 * 
	 * @param	TileGraphic 	The graphic class that contains the tiles that should fill this block.
	 * @param	TileWidth		The width of a single tile in the graphic.
	 * @param	TileHeight		The height of a single tile in the graphic.
	 * @param	Empties			The number of "empty" tiles to add to the auto-fill algorithm (e.g. 8 tiles + 4 empties = 1/3 of block will be open holes).
	 * @return	This tile block.
	 */
	public function loadTiles(TileGraphic:FlxGraphicAsset, TileWidth:Int = 0, TileHeight:Int = 0, Empties:Int = 0):FlxTileblock
	{
		if (TileGraphic == null)
		{
			return this;
		}
		
		var graph:FlxGraphic = FlxG.bitmap.add(TileGraphic);
		
		if (TileWidth == 0)
		{
			TileWidth = graph.height;
			TileWidth = (TileWidth > graph.width) ? graph.width : TileWidth;
		}
		
		if (TileHeight == 0)
		{
			TileHeight = TileWidth;
			TileHeight = (TileHeight > graph.height) ? graph.height : TileHeight;
		}
		
		var tileFrames:TileFrames = TileFrames.fromGraphic(graphic, new Point(TileWidth, TileHeight));
		return this.loadFrames(tileFrames, Empties);
	}
}