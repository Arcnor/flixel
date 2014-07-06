package flixel.graphics.frames;

/**
 * Just enumeration of all types of frame collections.
 * Added for faster type detection with less usage of casting.
 */
enum FrameCollectionType 
{
	IMAGE;
	SPRITESHEET;
	ATLAS;
	FONT; 	// TODO: implement it
	BAR;	// TODO: implement it
	USER(type:String);
}