package dk.rumstation.ACIT.algorithms
{
	/**
	 * 
	 * @author kasper helweg jonassen
	 * 
	 */	
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class Beier
	{
		
		// weights
		public static const a : Number = 100;
		public static const p : Number = 0.5;
		public static const b : Number = 2.0;
		
		private var inputBitmap : BitmapData;
		private var outputBitmap : BitmapData;
		
		private var lines : Vector.<Point> = new Vector.<Point>;
		private var linesPrime : Vector.<Point> = new Vector.<Point>;
		
		public function Beier(input : BitmapData, lines : Vector.<Point>, linesPrime : Vector.<Point>)
		{
			this.inputBitmap = input;
			this.outputBitmap = new BitmapData(input.width, input.height);
			
			this.lines = lines;
			this.linesPrime = linesPrime;
		}
		
		public function resample() : void
		{			
			// Constants
			var a : Number = Beier.a;
			var p : Number = Beier.p;
			var b : Number = Beier.b;
			this.outputBitmap.lock();
			
			for (var i : int = 0; i < this.outputBitmap.width; i++) {
				for (var j : int = 0; j < this.outputBitmap.height; j++) {
					
					var DSUM : Point = new Point(0, 0);
					var weightSum : Number = 0; 
					
					// For each line
					for (var k : int = 0; k < this.lines.length; k += 2)
					{
						var X : Point = new Point(i, j);
						var Xprime : Point;
						
						var P : Point = this.lines[k];
						var Q : Point = this.lines[k + 1]
						var QP : Point = this.subtract(Q, P);
						var QPperpendicular : Point = this.getPerpendicular(QP);
						
						var Pprime : Point = this.linesPrime[k];
						var Qprime : Point = this.linesPrime[k + 1]
						var QPprime : Point = this.subtract(Qprime, Pprime);
						var QPprimePerpendicular : Point = this.getPerpendicular(QPprime);
						
						var u : Number = (this.dot(this.subtract(X, P), QP)) / Math.pow(this.length(QP), 2);
						var v : Number = (this.dot(this.subtract(X, P), QPperpendicular)) / this.length(QP);
						
						
						Xprime =  this.add(this.add(Pprime, this.scalerMult(u, QPprime)), this.divide(this.scalerMult(v, QPprimePerpendicular), this.length (QPprime))) ;
						
						var D : Point = this.subtract(Xprime, X);
						var dist : Number;
						var weight : Number;
						
						if (0 < u && u < 1) {
							dist = Math.abs(v);
						} else if (u <= 0) {
							dist = this.distance(P, X);
						} else {
							dist = this.distance(Q, X);
						}
						
						weight = Math.pow(( Math.pow(this.length(QP), p) / (a + dist)), b);
						
						DSUM = this.add(DSUM, this.scalerMult(weight, D));
						weightSum += weight;
					}
					
					Xprime = this.add(X, this.divide(DSUM, weightSum));
					
					var n : Number = this.getPixelBilinear(this.inputBitmap, Xprime.x, Xprime.y);
					this.outputBitmap.setPixel(i, j, n);
				}
			}
			
			this.outputBitmap.unlock();
		}
		
		/**
		 * Returns the final image.
		 * 
		 * @return the warped image
		 * 
		 */		
		public function getImage() : BitmapData
		{
			return this.outputBitmap;
		}
		
		
		//////////////////////////////////////
		// Private vector math helpers
		/////////////////////////////////////
		
		private function subtract(p1 : Point, p2 : Point) : Point
		{
			return new Point(p1.x - p2.x, p1.y - p2.y);  	
		}
		
		private function add(p1 : Point, p2 : Point) : Point
		{
			return new Point(p1.x + p2.x, p1.y + p2.y);  	
		}
		
		private function getPerpendicular(p : Point) : Point
		{
			return new Point(p.y, p.x * -1);
		}
		
		private function dot(p1 : Point, p2 : Point) : Number
		{
			var dot : Number;
			
			dot = p1.x * p2.x + p1.y * p2.y;
			
			return dot;
		}
		
		private function length(p : Point) : Number
		{
			var n : Number = Math.sqrt(Math.pow(p.x, 2) + Math.pow(p.y, 2));
			return n;
		}
		
		private function scalerMult(s : Number, p :  Point) : Point
		{
			return new Point(s * p.x, s * p.y);
		}
		
		private function divide(p : Point, s : Number) : Point
		{
			return new Point(p.x / s, p.y / s);
		}
		
		private function distance(p1 : Point, p2 : Point) : Number
		{
			var n : Number = Math.sqrt(Math.pow(p2.x - p1.x, 2) + Math.pow(p2.y - p1.y, 2));
			return n;
			
		}
		
		//////////////////////////////////////
		// Bilinear sampling / clevR
		/////////////////////////////////////
		
		private function getPixelBilinear(bmd:BitmapData,theX:Number, theY:Number): Number
		{
			
			var x:int;
			var y:int;
			var x_ratio:Number;
			var y_ratio:Number;
			var y_opposite:Number;
			var x_opposite:Number;
			var a:int;
			var be:int;
			var c:int;
			var d:int;
			var red:int;
			var green:int;
			var blue:int;
			
			x = Math.floor(theX);
			y = Math.floor(theY);
			
			if((x < 1) || (y < 1) || ((x + 2) >= bmd.width) || ((y + 2) >= bmd.height))
				return bmd.getPixel(x, y);
			
			x_ratio = theX - x;
			y_ratio = theY - y;
			x_opposite = 1 - x_ratio;
			y_opposite = 1 - y_ratio;
			
			a       = bmd.getPixel(x, y);
			be      = bmd.getPixel(x + 1, y);
			c       = bmd.getPixel(x, y + 1);
			d       = bmd.getPixel(x + 1, y + 1);
			red     = (r(a)  * x_opposite  + r(be)   * x_ratio) * y_opposite + (r(c) * x_opposite  + r(d) * x_ratio) * y_ratio;
			green   = (g(a)  * x_opposite  + g(be)   * x_ratio) * y_opposite + (g(c) * x_opposite  + g(d) * x_ratio) * y_ratio;
			blue    = (b(a)  * x_opposite  + b(be)   * x_ratio) * y_opposite + (b(c) * x_opposite  + b(d) * x_ratio) * y_ratio;
			/*red = r(a);
			green = g(a);
			blue = b(a);*/
			
			if(red < 0)
				red = 0;
			else if(red > 255)
				red = 255;
			if(green < 0)
				
				green = 0;
			else if(green > 255)
				green = 255;
			if(blue < 0)
				blue = 0;
			else if(blue > 255)
				blue = 255;
			
			return (red << 16) | (green << 8) | (blue << 0);
		}
		
		private function r(rgb:int):int {
			return (rgb >> 16) & 0x0FF;
		}
		
		private function g(rgb:int):int {
			return (rgb >> 8) & 0x0FF;
		}
		
		private function b(rgb:int):int {
			return (rgb >> 0) & 0x0FF;
		}
		
	}

}