package
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;

	
	[Event(name="progress", type="flash.events.ProgressEvent")]
	[Event(name="complete", type="flash.events.Event")]
	[Event(name="TILE_LOADED", type="PanoramaEvent")]
	public class PanoramaTextureLoader extends PanoramaLoader
	{
		
		
		private var _loaders:Vector.<Vector.<Loader>>;
		private var _tiles:Vector.<Vector.<BitmapData>>;
		private var _panorama:Panorama;
		private var _zoomLevel:int;
		
		private var _actualWidth:int;
		private var _actualHeight:int;
		private var _tilesWidth:int;
		private var _tilesHeight:int;
		private var _completeImage:BitmapData;
		
		private var _tilesLoaded:int;
		
		
		public function PanoramaTextureLoader()
		{
		}
		
		public function loadData(panorama:Panorama, zoomLevel:int):void
		{
			_panorama = panorama;
			_zoomLevel = zoomLevel;
			_tilesLoaded = 0;

			//calculating the real dimensions of full image at current zoom level
			var downscaleTimes:int = 5 - zoomLevel;
			_actualWidth = _panorama.image_width;
			_actualHeight = _panorama.image_height;
			
			for(var i:int = 0; i<downscaleTimes; i++)
			{
				_actualWidth = Math.floor(_actualWidth / 2);
				_actualHeight = Math.floor(_actualHeight / 2);
			}
			
			_tilesWidth = Math.ceil(_actualWidth / _panorama.tile_width);
			_tilesHeight = Math.ceil(_actualHeight / _panorama.tile_height);

			_loaders = new Vector.<Vector.<Loader>>(_tilesHeight, true);
			_tiles = new Vector.<Vector.<BitmapData>>(_tilesHeight, true);
			for(var ty:int = 0; ty < _tilesHeight; ty++)
			{
				_loaders[ty] = new Vector.<Loader>(_tilesWidth, true);
				_tiles[ty] = new Vector.<BitmapData>(_tilesWidth, true);
				for(var tx:int = 0; tx < _tilesWidth; tx++)
				{
					loadTile(tx, ty);
				}
			}
			
		}
		
		private function loadTile(x:int, y:int):void
		{
			var tileLoader:Loader = new Loader();
			var rq:URLRequest = new URLRequest(resourcesUrl);
			
			rq.data = new URLVariables();
			rq.data.output = "tile";
			rq.data.zoom = _zoomLevel;
			rq.data.x = x;
			rq.data.y = y;
			rq.data.fover = 2;
			rq.data.onerr = 3;
			rq.data.renderer = "spherical";
			rq.data.cb_client = "maps_sv";
			rq.data.v = 4;
			rq.data.panoid = _panorama.panoId;
			
			rq.method = URLRequestMethod.GET;
			
			tileLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, handleTileLoaded);
			tileLoader.load(rq);
			
			_loaders[y][x] = tileLoader;
		}
		
		private function handleTileLoaded(event:Event):void
		{
			(event.target as LoaderInfo).removeEventListener(Event.COMPLETE, handleTileLoaded);
			_tilesLoaded++;

			//getting loaded tile position
			var tileEvent:PanoramaEvent = new PanoramaEvent(PanoramaEvent.TILE_LOADED);
			outer:for(var ty:int = 0; ty < _tilesHeight; ty++)
			{
				for(var tx:int = 0; tx < _tilesWidth; tx++)
				{
					if(_loaders[ty][tx] == (event.target as LoaderInfo).loader)
					{
						tileEvent.tileX = tx;
						tileEvent.tileY = ty;
						break outer;
					}
				}
			}

			//saving tile bitmap to _tiles
			if(_loaders[tileEvent.tileY][tileEvent.tileX].content is Bitmap)
			{
				_tiles[tileEvent.tileY][tileEvent.tileX] = (_loaders[tileEvent.tileY][tileEvent.tileX].content as Bitmap).bitmapData;
			}


			//dispatching events
			dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, _tilesLoaded, _tilesWidth*_tilesHeight));
			dispatchEvent(tileEvent);
			if(_tilesLoaded == _tilesWidth*_tilesHeight)
			{
				dispatchEvent(new PanoramaEvent(PanoramaEvent.PANORAMA_LOADED));
			}
		}


		
		public function get tilesWidth():int
		{
			return _tilesWidth;
		}

		public function get tilesHeight():int
		{
			return _tilesHeight;
		}
		
		
		
		public function get actualWidth():int
		{
			return _actualWidth;
		}

		public function get actualHeight():int
		{
			return _actualHeight;
		}
		
		
		
		public function get completeImage():BitmapData
		{
			if(!_completeImage && _tiles.length > 0)
			{
				var scale:Number = 2048 / _actualWidth;
				_completeImage = new BitmapData(2048, 1024, false, 0x0);
				for(var ty:int = 0; ty < _tilesHeight; ty++)
				{
					for(var tx:int = 0; tx < _tilesWidth; tx++)
					{
						//_completeImage.copyPixels(, _tiles[ty][tx].rect, new Point(tx * _panorama.tile_width, ty * _panorama.tile_height));
						_completeImage.draw(_tiles[ty][tx], new Matrix(scale, 0, 0, scale, tx * _panorama.tile_width * scale, ty * _panorama.tile_height * scale), null, null, null, true);
					}
				}
			}
			
			return _completeImage;
		}

		public function get tiles():Vector.<Vector.<BitmapData>>
		{
			return _tiles;
		}

		
		
		
	}
}