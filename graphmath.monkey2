#rem
	TimelineFX Module by Peter Rigby
	
	Copyright (c) 2017 Peter J Rigby
	
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

#END

Namespace timelinefx

#Rem monkeydoc @hidden
#End
Const BEZIER_ACCURACY:Float = 0.01

#Rem monkeydoc @hidden
#End
Function GetQuadBezier:tlPoint(p0:tlPoint, p1:tlPoint, p2:tlPoint, t:Float, ymin:Float, ymax:Float, clamp:Int = True)
	Local b:tlPoint = New tlPoint
	b.x = Pow( (1 - t), 2) * p0.x + 2 * t * (1 - t) * p1.x + Pow(t, 2) * p2.x
	b.y = Pow( (1 - t), 2) * p0.y + 2 * t * (1 - t) * p1.y + Pow(t, 2) * p2.y
	If b.x < p0.x Then b.x = p0.x
	If b.x > p2.x Then b.x = p2.x
	If clamp
		If b.y < ymin Then b.y = ymin
		If b.y > ymax Then b.y = ymax
	End If
	Return b
End Function

#Rem monkeydoc @hidden
#End
Function GetCubicBezier:tlPoint(p0:tlPoint, p1:tlPoint, p2:tlPoint, p3:tlPoint, t:Float, ymin:Float, ymax:Float, clamp:Int = True)
	Local b:tlPoint = New tlPoint
	b.x = Pow( (1 - t), 3) * p0.x + 3 * t * Pow( (1 - t), 2) * p1.x + 3 * Pow(t, 2) * (1 - t) * p2.x + Pow(t, 3) * p3.x
	b.y = Pow( (1 - t), 3) * p0.y + 3 * t * Pow( (1 - t), 2) * p1.y + 3 * Pow(t, 2) * (1 - t) * p2.y + Pow(t, 3) * p3.y
	If b.x < p0.x Then b.x = p0.x
	If b.x > p3.x Then b.x = p3.x
	If clamp
		If b.y < ymin Then b.y = ymin
		If b.y > ymax Then b.y = ymax
	End If
	Return b
End Function

#Rem monkeydoc @hidden
#End
Class tlPoint
	
	Field x:Float
	Field y:Float
	
	Field q0:tlPoint
	Field q1:tlPoint
	
	Field selected:Int
	
	Field side:Int
		
	Method New(x:Float = 0, y:Float = 0)
		Self.x = x
		Self.y = y
	End 
	
End
