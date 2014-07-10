package flixel.graphics.frames;

/**
 * Just enumeration of all types of frame collections.
 * Added for faster type detection with less usage of casting.
 */
enum FrameCollectionType 
{
	IMAGE;
	TILES;
	ATLAS;
	FONT; 											// TODO: implement it
	BAR(type:flixel.ui.FlxBar.FlxBarFillDirection);
	CLIPPED;										// TODO: implement it
	USER(type:String);
}