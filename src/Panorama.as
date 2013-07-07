package
{

import away3d.containers.ObjectContainer3D;
import away3d.core.base.Geometry;
import away3d.core.base.SubGeometry;
import away3d.entities.Mesh;
import away3d.materials.TextureMaterial;
import away3d.primitives.SphereGeometry;
import away3d.textures.BitmapTexture;

import caurina.transitions.Tweener;

import flash.display.BitmapData;
import flash.geom.Vector3D;
import flash.utils.ByteArray;
import flash.utils.Endian;

public class Panorama
	{
		
		public static const PANOID_LENGTH:int = 22;
		public static const SKY_DISTANCE:int = 700;


		// google data properties
		public var image_date:String;
		public var image_width:Number;
		public var image_height:Number;
		public var tile_width:Number;
		public var tile_height:Number;
		public var numZoomLevels:int;
		public var latitude:Number;
		public var longitude:Number;
		public var panoId:String;
		public var panoramaYawDeg:Number;
		
		public var copyright:String;
		public var text:String;
		public var region:String;
		public var country:String;


		public var projectionType:String;
		public var world:World;
		public var readyForDisplay:Boolean;
		
		protected var _depthMapWidth:int;
		protected var _depthMapHeight:int;
		protected var _depthMapIndices:ByteArray;
		protected var _depthMapPlanes:Vector.<Vector3D>;
		
		protected var _links:Vector.<PanoramaLink>;
		protected var _panoMapWidth:int;
		protected var _panoMapHeight:int;
		protected var _panoMapIndices:ByteArray;
		protected var _panoIds:Vector.<String>;
		
		protected var _textureLoader:PanoramaTextureLoader;
		protected var _model:ObjectContainer3D;
		


		
		public function Panorama()
		{
			_links = new Vector.<PanoramaLink>;
			_model = new ObjectContainer3D();
		}
		
		public static function createFromXmlData(data:XML):Panorama
		{
			var pan:Panorama = new Panorama;
			
			pan.image_date = data.child("data_properties").@image_date;
			pan.image_width = data.child("data_properties").@image_width;
			pan.image_height = data.child("data_properties").@image_height;
			pan.tile_width = data.child("data_properties").@tile_width;
			pan.tile_height = data.child("data_properties").@tile_height;
			pan.numZoomLevels = data.child("data_properties").@num_zoom_levels;
			pan.latitude = data.child("data_properties").@lat;
			pan.longitude = data.child("data_properties").@lng;
			pan.panoId = data.child("data_properties").@pano_id;

			pan.copyright = data.child("data_properties").child("copyright");
			pan.text = data.child("data_properties").child("text");
			pan.region = data.child("data_properties").child("region");
			pan.country = data.child("data_properties").child("country");

			pan.panoramaYawDeg = data.child("projection_properties").@pano_yaw_deg;
			pan._model.yaw(pan.panoramaYawDeg);

			for each(var element:XML in data.child("annotation_properties").child("link"))
			{
				var newLink:PanoramaLink = new PanoramaLink();
				newLink.gName = element.child("link_text");
				newLink.panoId = element.@pano_id;
				newLink.yaw_deg = element.@yaw_deg;
				newLink.gScene = element.@scene;

				newLink.setPosition();
				pan.links.push(newLink);
			}
			
			if(data.child("model").length())
			{
				var tmpBa:ByteArray;
				
				tmpBa = Base64.decodeToByteArray(data.child("model").child("depth_map"));
				tmpBa.uncompress();
				pan.setDepthData(tmpBa);
				
				tmpBa = Base64.decodeToByteArray(data.child("model").child("pano_map"));
				tmpBa.uncompress();
				pan.setPanoData(tmpBa);
				
				pan.loadTexture();
			}
			
			return pan;
		}

		


		public function setDepthData(value:ByteArray):void
		{
			value.endian = Endian.LITTLE_ENDIAN;
			
			var headerSize:int = value.readUnsignedByte();
			var numPanos:int = value.readUnsignedShort();
			_depthMapWidth = value.readUnsignedShort();
			_depthMapHeight = value.readUnsignedShort();
			var panoIndicesOffset:int = value.readUnsignedByte();
			
			if (headerSize != 8 || panoIndicesOffset != 8)
				throw new Error("Unexpected depth map header");
			
			var i:int;
			value.position = panoIndicesOffset;
			_depthMapIndices = new ByteArray;
			value.readBytes(_depthMapIndices, 0, _depthMapWidth * _depthMapHeight);
			
			value.position = panoIndicesOffset + _depthMapWidth * _depthMapHeight;
			_depthMapPlanes = new Vector.<Vector3D>();
			for(i = 0; i<numPanos; i++)
			{
				if(value.bytesAvailable < 8) break;
				var newPlane:Vector3D = new Vector3D();
				newPlane = new Vector3D(value.readFloat(), value.readFloat(), value.readFloat(), value.readFloat());
				_depthMapPlanes.push(newPlane);
			}
			
		}

		public function setPanoData(value:ByteArray):void
		{
			value.endian = Endian.LITTLE_ENDIAN;
			
			var headerSize:int = value[0];
			var numPanos:int = value[1] | (value[2] << 8);
			_panoMapWidth = value[3] | (value[4] << 8);
			_panoMapHeight = value[5] | (value[6] << 8);
			var panoIndicesOffset:int = value[7];
			
			var i:int;
			value.position = panoIndicesOffset;
			_panoMapIndices = new ByteArray;
			value.readBytes(_panoMapIndices, 0, _panoMapWidth * _panoMapHeight);
			
			value.position = panoIndicesOffset + _panoMapWidth * _panoMapHeight;
			_panoIds = new Vector.<String>();
			for(i = 0; i<numPanos; i++)
			{
				if(value.bytesAvailable < PANOID_LENGTH) break;
				_panoIds.push(value.readUTFBytes(PANOID_LENGTH));
			}
		}

		public function getVertexAtAzimuthElevation(x:Number, y:Number):Vector3D
		{
			if(x > _depthMapWidth) x = _depthMapWidth;
			if(y > _depthMapHeight) y = _depthMapHeight;

			var rad_azimuth:Number = x / (_depthMapWidth - 1.0) * Math.PI*2;
			var rad_elevation:Number = y / (_depthMapHeight - 1.0) * Math.PI;
			
			//Calculate the cartesian position of this vertex (if it was at unit distance)
			var vertex:Vector3D = new Vector3D;
			vertex.x = Math.sin(rad_elevation) * Math.sin(rad_azimuth);
			vertex.y = Math.sin(rad_elevation) * Math.cos(rad_azimuth);
			vertex.z = Math.cos(rad_elevation);
			var distance:Number = 1;
			
			////Calculate distance of point according to the depth map data.

			var depthMapIndex:int = _depthMapIndices[y * _depthMapWidth + x];
			if (depthMapIndex == 0) {
				//Distance of sky
				distance = SKY_DISTANCE;
			} else {
				var plane:Vector3D = _depthMapPlanes[depthMapIndex];
				distance = -plane.w / (plane.x * vertex.x + plane.y * vertex.y + -plane.z * vertex.z);
				if(distance > SKY_DISTANCE || distance < 0) distance = SKY_DISTANCE;
			}
			vertex.w = distance;
			vertex.scaleBy(distance);
			return vertex;
		}
		
		public function loadTexture(zoomLevel:int = 3):void
		{
			_textureLoader = new PanoramaTextureLoader();
			_textureLoader.loadData(this, zoomLevel);
			_textureLoader.addEventListener(PanoramaEvent.TILE_LOADED, addMeshForTile);
			_textureLoader.addEventListener(PanoramaEvent.PANORAMA_LOADED, markAsLoaded);
		}

		private function markAsLoaded(event:PanoramaEvent):void
		{
			readyForDisplay = true;
		}


		protected function addMeshForTile(event:PanoramaEvent):void
		{
			var tileWidthInDepthCoordinates:Number = (tile_width * (512 / _textureLoader.actualWidth));
			var tileHeightInDepthCoordinates:Number = (tile_height * (256 / _textureLoader.actualHeight));
			var ix:int = event.tileX;
			var iy:int = event.tileY;

			//if(ix != 2 || iy !=2) continue;
			//part of depth data birmap representing current tile
			var vertices:Vector.<Number> = new Vector.<Number>();
			var indices:Vector.<uint> = new Vector.<uint>();
			var uvs:Vector.<Number> = new Vector.<Number>();

			var rely:int = 0;
			var numRows:int = Math.ceil(((iy + 1) * (tileHeightInDepthCoordinates)) - int(iy * tileHeightInDepthCoordinates));
			var stride:int = Math.ceil(((ix + 1) * (tileWidthInDepthCoordinates)) - int(ix * tileWidthInDepthCoordinates));

			for(var ty:int = iy * tileHeightInDepthCoordinates; ty < (iy + 1) * (tileHeightInDepthCoordinates); ty++)
			{
				var relx:int = 0;

				for(var tx:int = ix * tileWidthInDepthCoordinates; tx < (ix + 1) * (tileWidthInDepthCoordinates); tx++)
				{
					var vertex:Vector3D = getVertexAtAzimuthElevation(tx, ty);

					vertices.push(vertex.x, vertex.z, vertex.y);
					uvs.push(relx / (stride - 1), rely / (numRows - 1));

					if(relx > 0 && rely > 0)
					{
						indices.push((relx - 1) + (rely - 1) * stride);
						indices.push(relx + rely * stride);
						indices.push((relx - 1) + rely * stride);

						indices.push((relx - 1) + (rely - 1) * stride);
						indices.push(relx + (rely - 1) * stride);
						indices.push(relx + rely * stride);
					}
					relx ++;
				}
				rely ++;
			}

			var tileTexture:BitmapTexture = new BitmapTexture(_textureLoader.tiles[iy][ix]);
			var mat:TextureMaterial = new TextureMaterial(tileTexture);
			mat.specular = 0;
			mat.ambient = 0;
			mat.alpha = 0;
			Tweener.addTween(mat, {alpha:1, time:1, transition:'linear'});

			var subGeom:SubGeometry = new SubGeometry();
			var geometry:Geometry = new Geometry();
			geometry.addSubGeometry(subGeom);
			//var m:Mesh = new Mesh(geometry, new ColorMaterial(Math.random() * 0xffffff));
			var m:Mesh = new Mesh(geometry, mat);

			subGeom.updateVertexData(vertices);
			subGeom.updateIndexData(indices);
			subGeom.updateUVData(uvs);

			_model.addChild(m);
		}

		
		public function get links():Vector.<PanoramaLink>
		{
			return _links;
		}
		
		public function get depthBitmap():BitmapData
		{
			var result:BitmapData = new BitmapData(_depthMapWidth, _depthMapHeight, false, 0x0);
			var maxValue:uint = 0;
			for(var iy:int = 0; iy < _depthMapHeight; iy++)
			{
				for(var ix:int = 0; ix < _depthMapWidth; ix++)
				{
					var vertex:Vector3D = getVertexAtAzimuthElevation(ix, iy);
					var current:uint = vertex.w;
					if(current > maxValue) maxValue = current;
					result.setPixel(ix, iy, current | current << 8 | current << 16);
				}
			}
			return result;
		}
		
		
		public function get panoSphere():Geometry
		{
			
			var sphere:SphereGeometry = new SphereGeometry(128, _depthMapWidth/2 - 1, _depthMapHeight/2 - 1);
			
			for(var iy:int = 0; iy < _depthMapHeight; iy += 2)
			{
				for(var ix:int = 0; ix < _depthMapWidth; ix += 2)
				{
					var vertexIndex:int = ((iy/2) * _depthMapWidth/2 + (ix/2)) * 3;
					var vertex:Vector3D = getVertexAtAzimuthElevation(ix, iy);
					sphere.subGeometries[0].vertexData[vertexIndex] = vertex.x;
					sphere.subGeometries[0].vertexData[vertexIndex + 1] = vertex.z;
					sphere.subGeometries[0].vertexData[vertexIndex + 2] = vertex.y;
				}
			}
			
			return sphere;
		}
		
		
		public function get containsModelData():Boolean
		{
			return _depthMapWidth > 0;
		}

		public function get textureLoader():PanoramaTextureLoader
		{
			return _textureLoader;
		}

		public function get model():ObjectContainer3D
		{
			return _model;
		}


	}
}