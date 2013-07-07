/**
 * Date: 7/6/13
 * Time: 7:35 PM
 */
package {
import flash.display.Sprite;
import flash.events.Event;
import flash.events.LocationChangeEvent;
import flash.events.MouseEvent;
import flash.geom.Rectangle;
import flash.media.StageWebView;
import flash.utils.ByteArray;

public class MapView extends Sprite{

	[Embed(source="map.html", mimeType="application/octet-stream")] private static var mapPage:Class;

	private var _bg:Sprite;
	private var _webView:StageWebView;

	public var setValuesCallback:Function;

	public function MapView()
	{
		addEventListener(Event.ADDED_TO_STAGE, init);
	}

	private function init(event:Event):void
	{
		removeEventListener(Event.ADDED_TO_STAGE, init);

		_bg = new Sprite();
		_bg.addEventListener(MouseEvent.CLICK, close);
		addChild(_bg);

		var mapPageBytes:ByteArray = new mapPage as ByteArray;

		_webView = new StageWebView();
		_webView.stage = this.stage;
		_webView.loadString(mapPageBytes.readUTFBytes(mapPageBytes.length));
		_webView.addEventListener(LocationChangeEvent.LOCATION_CHANGING, handleLocation);

		stage.addEventListener(Event.RESIZE, handleResize);
		handleResize(event);
	}

	private function handleLocation(event:LocationChangeEvent):void
	{
		var values:Array = event.location.split("%7C");
		if(setValuesCallback) setValuesCallback(values[0], values[1]);
		close();
	}

	private function handleResize(event:Event):void
	{
		_bg.graphics.clear();
		_bg.graphics.beginFill(0x0, 0.8);
		_bg.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
		_bg.graphics.endFill();

		_webView.viewPort = new Rectangle(70, 70, stage.stageWidth - 140, stage.stageHeight - 150);
	}

	private function close(event:Event = null):void
	{
		if(parent)
		{
			stage.removeEventListener(Event.RESIZE, handleResize);
			_webView.stage = null;
			parent.removeChild(this);
		}
	}

}
}
