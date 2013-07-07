/**
 * Date: 6/30/13
 * Time: 5:37 PM
 */
package {
import flash.events.Event;

public class PanoramaEvent extends Event{

	public static const PANORAMA_LOADED:String = "PANORAMA_LOADED";
	public static const TILE_LOADED:String = "TILE_LOADED";

	public var tileX:int;
	public var tileY:int;

	public function PanoramaEvent(type:String, bubbles:Boolean = false, cancellable:Boolean = false)
	{
		super(type, bubbles, cancellable);
	}


}
}
