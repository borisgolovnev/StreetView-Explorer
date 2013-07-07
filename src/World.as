/**
 * Date: 6/30/13
 * Time: 2:24 PM
 */
package {
import away3d.containers.Scene3D;
import away3d.containers.View3D;
import away3d.controllers.FirstPersonController;
import away3d.entities.Mesh;
import away3d.materials.ColorMaterial;
import away3d.materials.TextureMaterial;
import away3d.primitives.SphereGeometry;

import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.geom.Vector3D;
import flash.ui.Keyboard;

public class World extends Sprite
{

	private static const MAX_PANORAMAS:int = 10;

	private var _view:View3D;
	private var _scene:Scene3D;
	private var _camController:FirstPersonController;

	//movement variables
	private const _drag:Number = 0.5;
	private const _walkIncrement:Number = 0.5;
	private const _strafeIncrement:Number = 0.5;
	private const _elevationIncrement:Number = 0.25;
	private var _walkSpeed:Number = 0;
	private var _strafeSpeed:Number = 0;
	private var _elevationSpeed:Number = 0;
	private var _walkAcceleration:Number = 0;
	private var _strafeAcceleration:Number = 0;
	private var _elevationAcceleration:Number = 0;

	//rotation variables
	private var _move:Boolean = false;
	private var _lastMouseX:Number;
	private var _lastMouseY:Number;

	private var _loadedPanoramas:Vector.<Panorama>;
	private var _pendingPanoramaIds:Vector.<String>;

	public function World() {
		_loadedPanoramas = new Vector.<Panorama>();
		_pendingPanoramaIds = new Vector.<String>();

		_scene = new Scene3D();
		_view = new View3D(_scene);
		addChild(_view);

		//setup the camera
		_view.camera.z = 0;
		_view.camera.y = 0;
		_view.camera.lens.near = 1;

		_camController = new FirstPersonController(_view.camera);
		_camController.tiltAngle = 0;

		var _sun:Mesh = new Mesh(new SphereGeometry(0.7), new ColorMaterial(0xffff00, 0.5));
		_scene.addChild(_sun);

		addEventListener(Event.ADDED_TO_STAGE, init);
	}

	private function init(event:Event):void
	{
		removeEventListener(Event.ADDED_TO_STAGE, init);

		//setup the render loop
		addEventListener(Event.ENTER_FRAME, _onEnterFrame);
		stage.addEventListener(Event.RESIZE, onResize);
		onResize();

		stage.addEventListener(MouseEvent.MOUSE_DOWN, startDragCam);
		stage.addEventListener(MouseEvent.MOUSE_UP, stopDragCam);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);

		//loadPanoramaById("fdf84mxPDjYRiDpTFfcPnA");
	}

	public function navigateToLatLon(lat:String, lon:String):void
	{
		removeAll();
		var loader:PanoramaDataLoader = new PanoramaDataLoader();
		loader.loadPanoramaForLatLng(Number(lat), Number(lon));
		loader.addEventListener(Event.COMPLETE, addPanorama);

		_camController.targetObject.position = new Vector3D();
	}


	public function loadPanoramaById(id:String, position:Vector3D = null):void
	{
		_pendingPanoramaIds.push(id);
		if(!position) position = new Vector3D();
		var loader:PanoramaDataLoader = new PanoramaDataLoader();
		loader.targetPosition = position;
		loader.loadPanoramaWithId(id);
		loader.addEventListener(Event.COMPLETE, addPanorama);
	}

	protected function addPanorama(event:Event):void
	{
		var panoramaLoader:PanoramaDataLoader = event.target as PanoramaDataLoader;
		var panorama:Panorama = panoramaLoader.loadedPanorama;
		panorama.world = this;
		if(panoramaLoader.targetPosition) panorama.model.position = panoramaLoader.targetPosition;
		_loadedPanoramas.push(panorama);
		for each(var plink:PanoramaLink in panorama.links)
		{
			plink.position = plink.position.add(panorama.model.position);
			_scene.addChild(plink);
		}
		_scene.addChild(panorama.model);
	}

	protected function removePanorama(panorama:Panorama):void
	{
		for each(var link:PanoramaLink in panorama.links)
		{
			_scene.removeChild(link);
			link.dispose();
		}
		_pendingPanoramaIds.splice(_pendingPanoramaIds.indexOf(panorama.panoId), 1);
		_loadedPanoramas.splice(_loadedPanoramas.indexOf(panorama), 1);
		_scene.removeChild(panorama.model);
		for(var i:int = 0; i<panorama.model.numChildren; i++)
		{
			var mesh:Mesh = panorama.model.getChildAt(i) as Mesh;
			(mesh.material as TextureMaterial).dispose();
			mesh.dispose();
		}
		panorama.model.dispose();
	}

	public function removeAll():void
	{
		while(_loadedPanoramas.length)
		{
			removePanorama(_loadedPanoramas[0]);
		}
	}




	//controls and stuff

	/**
	 * Key down listener for camera control
	 */
	private function onKeyDown(event:KeyboardEvent):void
	{
		switch (event.keyCode) {
			case Keyboard.UP:
			case Keyboard.W:
				_walkAcceleration = _walkIncrement;
				break;
			case Keyboard.DOWN:
			case Keyboard.S:
				_walkAcceleration = -_walkIncrement;
				break;
			case Keyboard.LEFT:
			case Keyboard.A:
				_strafeAcceleration = -_strafeIncrement;
				break;
			case Keyboard.RIGHT:
			case Keyboard.D:
				_strafeAcceleration = _strafeIncrement;
				break;
			case Keyboard.EQUAL:
				_elevationAcceleration = _elevationIncrement;
				break;
			case Keyboard.MINUS:
				_elevationAcceleration = -_elevationIncrement;
				break;
		}
	}

	/**
	 * Key up listener for camera control
	 */
	private function onKeyUp(event:KeyboardEvent):void
	{
		switch (event.keyCode) {
			case Keyboard.UP:
			case Keyboard.W:
			case Keyboard.DOWN:
			case Keyboard.S:
				_walkAcceleration = 0;
				break;
			case Keyboard.LEFT:
			case Keyboard.A:
			case Keyboard.RIGHT:
			case Keyboard.D:
				_strafeAcceleration = 0;
				break;
			case Keyboard.EQUAL:
			case Keyboard.MINUS:
				_elevationAcceleration = 0;
				break;
		}
	}


	protected function stopDragCam(event:MouseEvent):void
	{
		_move = false;
	}

	protected function startDragCam(event:MouseEvent):void
	{
		_move = true;
		_lastMouseX = stage.mouseX;
		_lastMouseY = stage.mouseY;
	}


	/**
	 * render loop
	 */
	private function _onEnterFrame(e:Event):void
	{
		if (_move) {
			_camController.panAngle += 0.3*(stage.mouseX - _lastMouseX);
			_camController.tiltAngle += 0.3*(stage.mouseY - _lastMouseY);
			_lastMouseX = stage.mouseX;
			_lastMouseY = stage.mouseY;
		}

		if (_walkSpeed || _walkAcceleration)
		{
			_walkSpeed = (_walkSpeed + _walkAcceleration)*_drag;
			if (Math.abs(_walkSpeed) < 0.01) _walkSpeed = 0;
			_camController.incrementWalk(_walkSpeed);
		}

		if (_strafeSpeed || _strafeAcceleration)
		{
			_strafeSpeed = (_strafeSpeed + _strafeAcceleration)*_drag;
			if (Math.abs(_strafeSpeed) < 0.01) _strafeSpeed = 0;
			_camController.incrementStrafe(_strafeSpeed);
		}

		if (_elevationSpeed || _elevationAcceleration)
		{
			_elevationSpeed = (_elevationSpeed + _elevationAcceleration)*_drag;
			if(Math.abs(_elevationSpeed) < 0.01) _elevationSpeed = 0;
			_view.camera.y += _elevationSpeed;
		}

		var newDistance:Number;
		var nearDistance:Number = 9000;
		var farDistance:Number = 0;
		var closestPanorama:Panorama;
		var farthestPanorama:Panorama;
		var panorama:Panorama;
		for each(panorama in _loadedPanoramas)
		{
			newDistance = Vector3D.distance(panorama.model.position, _view.camera.position);
			if(newDistance < nearDistance)
			{
				nearDistance = newDistance;
				closestPanorama = panorama;
			}
			if(newDistance > farDistance)
			{
				farDistance = newDistance;
				farthestPanorama = panorama;
			}
			for each(var link:PanoramaLink in panorama.links)
			{
				if(_pendingPanoramaIds.indexOf(link.panoId) >= 0) continue;
				if(Vector3D.distance(link.position, _view.camera.position) < 5)
				{
					this.loadPanoramaById(link.panoId, link.position.add(new Vector3D(0.0, PanoramaLink.VERTICAL_OFFSET, 0.0)));
				}
			}
		}
		if(_loadedPanoramas.length > MAX_PANORAMAS && farthestPanorama && farthestPanorama != closestPanorama)
		{
			removePanorama(farthestPanorama);
		}

		if(closestPanorama && closestPanorama.readyForDisplay)
		{
			for each(panorama in _loadedPanoramas)
			{
				panorama.model.visible = panorama == closestPanorama;
			}
		}

		_view.render();
	}




	/**
	 * stage listener for resize events
	 */
	private function onResize(event:Event = null):void
	{
		_view.width = stage.stageWidth;
		_view.height = stage.stageHeight;
	}



}
}
