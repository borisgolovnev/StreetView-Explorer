package
{
	import flash.events.Event;
	import flash.events.EventDispatcher;

	[Event(name="complete", type="flash.events.Event")]
	public class PanoramaLoader extends EventDispatcher
	{
		
		public static function get resourcesUrl():String
		{
			var serverId:int = Math.floor(Math.random() * 4);
			return "http://cbks"+serverId+".google.com/cbk";
		}
		
		public static function get mapsUrl():String
		{
			return "https://maps.google.com/cbk";
		}
		
		
	}
}
