package
{
import away3d.entities.Mesh;
import away3d.materials.ColorMaterial;
import away3d.primitives.SphereGeometry;

import flash.geom.Vector3D;

public class PanoramaLink extends Mesh
	{
		public static const VERTICAL_OFFSET:Number = 2.4;

		public var panoId:String;
		public var yaw_deg:Number;
		public var gScene:String;
		public var gName:String;

		public function PanoramaLink()
		{
			super(new SphereGeometry(0.25), new ColorMaterial(0xff0000));
		}

		public function setPosition():void
		{
			var yaw:Number = (yaw_deg / 180) * Math.PI;
			yaw += Math.PI;
			var pointPosition:Vector3D = new Vector3D(Math.sin(yaw), 0, Math.cos(yaw));
			pointPosition.scaleBy(11);
			position = position.add(pointPosition);
			y = -VERTICAL_OFFSET;
		}


	}
}