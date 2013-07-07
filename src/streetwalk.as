package
{

import com.bit101.components.InputText;
import com.bit101.components.PushButton;
import com.bit101.utils.MinimalConfigurator;

import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;

[SWF(frameRate="60")]
	public class streetwalk extends Sprite
	{

		private var _world:World;
		public var latitude:InputText;
		public var longitude:InputText;

		public function streetwalk()
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;

			_world = new World();
			addChild(_world);

			var xml:XML =
			<comps>
				<VBox x="10" y="10">
					<PushButton x="10" y="40" label="map" event="click:showMap"/>
					<HBox>
						<Label text="Latitude:"/>
						<InputText id="latitude" text="55.752676" width="140" restrict="0-9.\-" />
					</HBox>
					<HBox>
						<Label text="Longitude:"/>
						<InputText id="longitude" text="37.586153" width="140" restrict="0-9.\-" />
					</HBox>
					<PushButton x="10" y="40" label="go" event="click:onClick"/>
				</VBox>
			</comps>;

			var config:MinimalConfigurator = new MinimalConfigurator(this);
			config.parseXML(xml);
		}


		public function onClick(event:Event):void
		{
			_world.navigateToLatLon(latitude.text, longitude.text);
			trace(latitude.text, longitude.text);
		}


		public function showMap(event:Event):void
		{
			var map:MapView = new MapView();
			map.setValuesCallback = function(lat:String, lon:String):void
			{
				latitude.text = lat;
				longitude.text = lon;
			};
			addChild(map);
		}

		
	}
}