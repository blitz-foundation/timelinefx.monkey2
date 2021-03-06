#rem
	Copyright (c) 2016 Peter J Rigby
	
	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.
	
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.

#end

Namespace timelinefx

#Rem monkeydoc A 2d vector class
#End
Struct tlVector2
	
	Public
	
	Field x:Float
	Field y:Float
	Field invalid:Int

	#Rem monkeydoc Make a new vector
		@param x
		@param y
		@param invalid You can ignore this for the most part, but because Structs cannot be null you might need to work around that in which case you can use this
	#End
	Method New(x:Float = 0, y:Float = 0, invalid:int = false)
		self.x = x
		self.y = y
		self.invalid = invalid
	End

	#Rem monkeydoc Find out if the vector is valid (an equivalent for null)
	#End
	Property Invalid:int()
		return invalid
	Setter(v:Int)
		invalid = true
	End
	
	#Rem monkeydoc Clone the vector
		@return tlVector
	#End
	Method Clone:tlVector2()
		Return New tlVector2(x, y)
	End
	
	#Rem monkeydoc Move the vector
		@param distance_x Float
		@param distance_y Float
		@return tlVector
	#End
	Method Move:tlVector2(distance_x:Float, distance_y:Float)
		Return New tlVector2(x + distance_x, y + distance_y)
	End
	
	#Rem monkeydoc Move the vector
		@param distance tlVector of the distance to move by
		@return tlVector
	#End
	Method MoveByVector:tlVector2(distance:tlVector2)
		Return New tlVector2(x + distance.x, y + distance.y)
	End

	#Rem monkeydoc Position the vector
		@param v tlVector of new position
		@return tlVector
	#End
	Method SetPositionByVector:tlVector2(v:tlVector2)
		return New tlVector2(v.x, v.y)
	End

	#Rem monkeydoc Subtract a vector
		@param v tlVector to substract
		@return tlVector
	#End
	Method SubtractVector:tlVector2(v:tlVector2)
		Return New tlVector2(x - v.x, y - v.y)
	End

	#Rem monkeydoc Add a vector
		@param v tlVector to add
		@return tlVector
	#End
	Method AddVector:tlVector2(v:tlVector2)
		Return New tlVector2(x + v.x, y + v.y)
	End

	#Rem monkeydoc Multiply a vector
		@param v tlVector to multiply
		@return tlVector
	#End
	Method Multiply:tlVector2(v:tlVector2)
		Return New tlVector2(x * v.x, y * v.y)
	End

	#Rem monkeydoc Divide a vector
		@param v tlVector to divide
		@return tlVector
	#End
	Method Divide:tlVector2(factor:Float)
		Return New tlVector2(x / factor, y / factor)
	End
	
	#Rem monkeydoc @hidden
	#End
	Operator+:tlVector2( v:tlVector2 )
	  Return New tlVector2( x + v.x, y + v.y )
	End

	#Rem monkeydoc @hidden
	#End
	Operator-:tlVector2( v:tlVector2 )
	  Return New tlVector2( x - v.x,y - v.y )
	End

	#Rem monkeydoc @hidden
	#End
	Operator*:tlVector2( v:tlVector2 )
	  Return New tlVector2( x * v.x,y * v.y )
	End

	#Rem monkeydoc @hidden
	#End
	Operator*:tlVector2( v:float )
	  Return New tlVector2( x * v,y * v )
	End

	#Rem monkeydoc @hidden
	#End
	Operator/:tlVector2( v:tlVector2 )
	  Return New tlVector2( x / v.x,y / v.y )
	End

	#Rem monkeydoc @hidden
	#End
	Operator+=( v:tlVector2 )
		x += v.x
		y += v.y
	End

	#Rem monkeydoc @hidden
	#End
	Operator-=( v:tlVector2 )
		x -= v.x
		y -= v.y
	End

	#Rem monkeydoc @hidden
	#End
	Operator*=( v:tlVector2 )
		x *= v.x
		y *= v.y
	End

	#Rem monkeydoc @hidden
	#End
	Operator*=( v:float )
		x *= v
		y *= v
	End

	#Rem monkeydoc @hidden
	#End
	Operator/=( v:tlVector2 )
		x /= v.x
		y /= v.y
	End

	#Rem monkeydoc Scale the vector
		@param scale Float to scale by
		@return tlVector
	#End
	Method Scale:tlVector2(scale:Float)
		Return New tlVector2(x * scale, y * scale)
	End

	#Rem monkeydoc Normalise the vector to a specific limit
		@param limit Float to limit by
		@return tlVector
	#End
	Method Limit:tlVector2(limit:Float)
		Local l:Float = Length()
		If l > limit
			local v:tlVector2 = Normalise()
			v = v.Scale(limit)
			return v
		End If
		return self
	End

	#Rem monkeydoc Mirror the vector
		@return tlVector
	#End
	Method Mirror:tlVector2()
		Return New tlVector2(-x, -y)
	End

	#Rem monkeydoc Get the length of the vector
		@return tlVector
	#End
	Method Length:Float()
		Return Sqrt(x * x + y * y)
	End

	#Rem monkeydoc Find out if the vector has length
		@return bool True if it has length
	#End
	Method HasLength:Int()
		Return x <> 0 And y <> 0
	End

	#Rem monkeydoc Get the Unit Vector (same as normalise)
		@return tlVector
	#End
	Method Unit:tlVector2()
		Local length:Float = Length()
		If length
			return New tlVector2(x / length, y / length)
		End If
		Return Clone()
	End

	#Rem monkeydoc Get the normal of the vector
		@return tlVector
	#End
	Method Normal:tlVector2()
		Return New tlVector2(-y, x)
	End
	
	#Rem monkeydoc Get the left hand normal of the vector
		@return tlVector
	#End
	Method LeftNormal:tlVector2()
		Return New tlVector2(y, -x)
	End

	#Rem monkeydoc Normalise the vector
		@return tlVector
	#End
	Method Normalise:tlVector2()
		Local length:Float = Length()
		If length
			Return New tlVector2(x/length, y/length) 
		End If
		Return self
	End

	#Rem monkeydoc Normalise to a specific length
		@return tlVector
	#End
	Method NormaliseTo:tlVector2(v:Float = 1)
		Local length:Float = Length()
		If length
			return New tlVector2(x/(length*v),y/(length*v))
		End If
		return self
	End

	#Rem monkeydoc Get the dot product of this vector and another
		@param v tlVector to get the dot product with
		@return tlVector
	#End
	Method DotProduct:Float(v:tlVector2)
		Return x * v.x + y * v.y
	End

	#Rem monkeydoc Get the angle of the vector *Needs updating to work with radians*
		@return tlVector
	#End
	Method Angle:Float()
		Return ATan2(x, y) 
	End

	#Rem monkeydoc Get the string representation of the vector
		@return String
	#End
	Method ToString:String()
		Return x + ", " + y
	End
	
End
