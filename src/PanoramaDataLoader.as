package
{
	import flash.events.Event;
import flash.geom.Vector3D;
import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;

	public class PanoramaDataLoader extends PanoramaLoader
	{
		public var targetPosition:Vector3D;
		
		private var _ldr:URLLoader;
		private var _loadingById:Boolean = false;
		private var _loadedPanorama:Panorama;
		
		public function PanoramaDataLoader()
		{
			super();

		}
		
		public function loadPanoramaForLatLng(lat:Number, lon:Number):void
		{
			_loadingById = false;
			
			var rq:URLRequest = new URLRequest(mapsUrl);
			rq.data = new URLVariables();
			rq.data.output = "xml";
			rq.data.hl = "en";
			rq.data.ll = lat.toString()+","+lon.toString();
			rq.data.radius = 50;
			rq.data.cb_client = "maps_sv";
			rq.data.v = 4;
			rq.data.it = "all";
			
			rq.method = URLRequestMethod.GET;

			_ldr = new URLLoader();
			_ldr.addEventListener(Event.COMPLETE, handleLatLonLookupComplete);
			_ldr.load(rq);
		}
		
		public function loadPanoramaWithId(id:String):void
		{
			_loadingById = true;
			
			var rq:URLRequest = new URLRequest(resourcesUrl);
			rq.data = new URLVariables();
			rq.data.output = "xml";
			rq.data.hl = "en";
			rq.data.cb_client = "maps_sv";
			rq.data.v = 4;
			
			rq.data.dm = 1;
			rq.data.pm = 1;
			rq.data.ph = 1;
			rq.data.renderer = "cubic,spherical";
			rq.data.panoid = id;
			
			rq.method = URLRequestMethod.GET;

			_ldr = new URLLoader();
			_ldr.addEventListener(Event.COMPLETE, handleLoaderComplete);
			_ldr.load(rq);
		}

		protected function handleLatLonLookupComplete(event:Event):void
		{
			var xmldata:XML = new XML(_ldr.data);
			_loadedPanorama = Panorama.createFromXmlData(xmldata);
			if(_loadedPanorama && _loadedPanorama.panoId)	loadPanoramaWithId(_loadedPanorama.panoId);
		}

		protected function handleLoaderComplete(event:Event):void
		{
			var xmldata:XML = new XML(_ldr.data);
			_loadedPanorama = Panorama.createFromXmlData(xmldata);
			
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		public function get loadedPanorama():Panorama
		{
			return _loadedPanorama;
		}
		
		
	}
}