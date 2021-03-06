#Rem
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

#End

Namespace timelinefx

using timelinefx..

'Types of collision
#Rem monkeydoc Used as the value representing a Box collision
#End
Const tlBOX_COLLISION:Int = 0
#Rem monkeydoc Used as the value representing a Circle collision
#End
Const tlCIRCLE_COLLISION:Int = 1
#Rem monkeydoc Used as the value representing a Polygon collision
#End
Const tlPOLY_COLLISION:Int = 2
#Rem monkeydoc Used as the value representing a Line collision
#End
Const tlLINE_COLLISION:Int = 3

#Rem monkeydoc Class for storing the results of a collision
	You can use CheckCollision to check for a collision between 2 objects which will return a [[tlCollisionResult]]
#End
Struct tlCollisionResult

	Private

	Field willintersect:Int = True
	Field intersecting:Int = True
	Field rayorigininside:Int
	Field translationvector:tlVector2
	Field surfacenormal:tlVector2
	Field rayintersection:tlVector2
	Field hassurfacenormal:Int = false
	Field hasintersection:Int = false
	Field raydistance:Float
	Field nocollision:Int
	
	Public
	
	Field source:tlBox
	Field target:tlBox
	
	#Rem monkeydoc Find out if the last collision check is intersecting
	#End
	Property Intersecting:Int() 
		Return intersecting
	Setter(v:int)
		intersecting = v
	End
	
	#Rem monkeydoc Find out if the last collision check found a collision
	#End
	Property IsColliding:Int() 
		Return intersecting
	End

	Property NoCollision:Int()
		Return nocollision
	Setter (v:Int)
		nocollision = v
	End
	
	#Rem monkeydoc Find out if the last collision check is intersecting
		Knowing if there will be an intersection allows you to adjust the position of objects so that visually they will never overlap. To do this
		you can use the information stored in the translation vector, which is the vector describing how much the objects need to move so that they no longer
		overlap. See [[TranslationVector]]
	#End
	Property WillIntersect:Int() 
		Return willintersect
	Setter (v:int)
		willintersect = v
	End

	#rem monkeydoc Find out if the last ray cast found that the ray originated inside the boundary
	#end
	Property RayOriginInside:Int() 
		Return rayorigininside
	Setter (v:int)
		rayorigininside = v
	End

	#rem monkeydoc Get the distance from the ray origin to the instersection point
	#End
	Property RayDistance:Float() 
		Return raydistance
	Setter (v:float)
		raydistance = v
	End
	
	#Rem monkeydoc Get the translation vector of the collision
		If the collision check finds that either the objects are intersecting, or they will intersect based on velocity vector of object, then the translation vector hold exactly
		how much they do or will overlap. This can then be used to move the 2 objects apart to prevent them overlapping. Handy if you have a wall that you don't
		want a player to move through. See [[PreventOverlap]] to automate this process further.
	#End
	Property TranslationVector:tlVector2() 
		Return translationvector
	Setter(v:tlVector2)
		translationvector = v
	End
	
	#Rem monkeydoc Get the intersection point of the raycast
		If a ray cast has been performed and the ray successfully connected, then this will return the point of intersection as a [[tlVector2]].
	#End
	Property RayIntersection:tlVector2() 
		Return rayintersection
	Setter (vec:tlVector2)
		rayintersection = vec
		hasintersection = True
	End

	#Rem monkeydoc Get the surface normal of the collision
	#End
	Property SurfaceNormal:tlVector2() 
		Return surfacenormal
	Setter (vec:tlVector2)
		surfacenormal = vec
		hassurfacenormal = True
	End

	#Rem monkeydoc Find out if the collision has an intersection
	#End
	Property HasIntersection:int()
		Return hasintersection
	End

	#Rem monkeydoc GFind out if the collision as a surface normal
	#End
	Property HasSurfaceNormal:int()
		Return hassurfacenormal
	End
	
	#Rem monkeydoc Get the surface normal that the ray hits
		If a ray cast has been performed and the ray successfully connected, then this will return the normal vector of the surface being hit.
	#End
	Property RaySurfaceNormal:tlVector2() 
		Return surfacenormal
	End
	
	#Rem monkeydoc The Source boundary of a collision check
	#End
	Property SourceBoundary:tlBox() 
		Return source
	End
	
	#Rem monkeydoc The Target boundary of a collision check
	#End
	Property TargetBoundary:tlBox() 
		Return target
	End

	#Rem monkeydoc Get the rebound vector
		Returns New [[tlVector2]] with the resulting rebound vector
		When an object collides with a surface you may want to know a resulting vector based on bounce and friction. So you can call this
		and pass the velocity vector of the incoming object, and the amount of bounce and friction to have, where a bounce value of 1 and a friction value of 0
		will result in a perfect bounce.
		@param v The impact vector
		@param friction Friction can be used to dampen the impact
		@param bounce The amount of elasticity in the bounce
	#End
	Method GetReboundVector:tlVector2(v:tlVector2, friction:Float = 0, bounce:Float = 1)
		
		If hassurfacenormal And (intersecting Or willintersect)
			If v.DotProduct(surfacenormal) < 0
				Local Vn:tlVector2 = surfacenormal.Scale(v.DotProduct(surfacenormal))
				Local Vt:tlVector2 = v.SubtractVector(Vn)
		
				Return Vt.Scale(1 - friction).AddVector(Vn.Scale(-bounce))
			End If
		EndIf
		
		Return v
	End
End

#Rem monkeydoc Collision box class
	This class is a bounding box that can be used to check for collisions between objects. See [[CheckCollision]]
#End
Class tlBox

	Private

	Field vertices:tlVector2[]
	Field tformvertices:tlVector2[]
	Field normals:tlVector2[]
	Field tformmatrix:tlMatrix2 = New tlMatrix2
	
	Field width:Float
	Field height:Float

	Field collisiontype:Int
	
	Field world:tlVector2
	Field boxoffset:tlVector2 = New tlVector2
	
	Field scale:tlVector2 = New tlVector2(1, 1)
	Field velocity:tlVector2 = New tlVector2
	
	'colour
	Field red:Float = 255
	Field green:Float = 255
	Field blue:Float = 255
	Field alpha:Float = 1
		
	Field data:Object
		
	Public
	#Rem monkeydoc @hidden
	#End
	Field handle:tlVector2 
	#Rem monkeydoc @hidden
	#End
	Field worldhandle:tlVector2
	
	#Rem monkeydoc @hidden
	#End
	Field quad:tlQuadTreeNode
	#Rem monkeydoc @hidden
	#End
	Field quadlist:Stack<tlQuadTreeNode>	'list of quad nodes this rect is in
	#Rem monkeydoc @hidden
	#End
	Field quads:Int							'number of quads the rect is in
	#Rem monkeydoc @hidden
	#End
	Field AreaCheckCount:=New Int[8]

	#Rem monkeydoc @hidden
	#End
	Field collisionlayer:Int
	
	#Rem monkeydoc @hidden
	#End
	Field quadtree:tlQuadTree
	
	#Rem monkeydoc @hidden
	#End
	Field tl_corner:tlVector2			'top left corner
	#Rem monkeydoc @hidden
	#End
	Field br_corner:tlVector2			'bottom right corner

	#Rem monkeydoc @hidden
	#End
	Field remove:int 					'set to 1 to mark for removal
	#Rem monkeydoc @hidden
	#End
	Field dead:int 				

	#Rem monkeydoc @hidden
	#End
	field highlight:int = false

	#Rem monkeydoc Constructor
	#End
	Method New()
	End
	
	#Rem monkeydoc [[tlBox]] Constructor
		@param x Top left y coordinate
		@param y Top Left x coordinate
		@param w Width of the box
		@param h Height of the box
		@param layer The layer that the box is on, used for quadtrees
		@param data any [[Object]] associated with the box

	    @example
	    	Local box:=New tlBox(100, 100, 50, 50, 0)
	    @end
	#End
	Method New(x:Float, y:Float, w:Float, h:Float, layer:Int = 0, data:Object = Null)
		If w < 0
			x += w
			w = Abs(w)
		End If
		If h < 0
			y+=h
			h = Abs(h)
		End If
		vertices = New tlVector2[4]
		handle = New tlVector2(w / 2, h / 2)
		vertices[0] = New tlVector2(-handle.x, -handle.y)
		vertices[1] = New tlVector2(-handle.x, h - handle.y)
		vertices[2] = New tlVector2(w - handle.x, h - handle.y)
		vertices[3] = New tlVector2(w - handle.x, -handle.y)
		normals = New tlVector2[4]
		tformvertices = New tlVector2[4]
		For Local c:Int = 0 To 3
			normals[c] = New tlVector2
			tformvertices[c] = New tlVector2
		Next
		handle = New tlVector2
		tl_corner = New tlVector2(0, 0)
		br_corner = New tlVector2(0, 0)
		world = New tlVector2(x + w / 2, y + h / 2)
		worldhandle = world+handle
		TForm()
		UpdateNormals()
		collisionlayer = layer
		quadlist = New Stack<tlQuadTreeNode>
		quadlist.Reserve(5)
		self.data = data
		
	End
	
	#Rem monkeydoc @hidden
	#End
	Method Color(r:Float, g:Float, b:Float)
		red = r
		green = g
		blue = b
	End
	
	#Rem monkeydoc Reset the dimensions of the box to a new width and height
		@param x Top left y coordinate
		@param y Top Left x coordinate
		@param w Width of the box
		@param h Height of the box
	#End
	Method ReDimension(x:Float, y:Float, w:Float, h:Float)
		If w < 0
			x += w
			w = Abs(w)
		End If
		If h < 0
			y+=h
			h = Abs(h)
		End If
		handle = New tlVector2(w / 2, h / 2)
		vertices[0] = New tlVector2(-handle.x, -handle.y)
		vertices[1] = New tlVector2(-handle.x, h - handle.y)
		vertices[2] = New tlVector2(w - handle.x, h - handle.y)
		vertices[3] = New tlVector2(w - handle.x, -handle.y)
		handle = New tlVector2
		world = New tlVector2(x + w / 2, y + h / 2)
		worldhandle = world + handle
		TForm()
		UpdateNormals()
	End
	
	#Rem monkeydoc Get the vertices array of the [[tlBox]]
	#End
	Property Vertices:tlVector2[]()
		Return vertices
	End
	
	#Rem monkeydoc The data property of the box. 
		You can use this to store and retrieve any [[Object]] you want to associate with the box
	#End
	Property Data:Object() 
		Return data
	Setter (d:Object)
		data = d
	End
	
	#Rem monkeydoc Get the collision layer that this boundary is on
		Every boundary can exist on a sepcific layer from 0-31 to make it easier to handle what objects you want to collide with each other.
	#End
	Property CollisionLayer:Int()
		Return collisionlayer
	Setter (layer:Int) 
		collisionlayer = layer
	End
	
	#Rem monkeydoc Set the position of the bounding box.
		This sets the position of the top left corner of the bounding box. If the box is within quadtree it will automatically update itself
		within it.
		@param x
		@param y
	#End
	Method Position(x:Float, y:Float) Virtual
		tl_corner = tl_corner.Move(x - world.x, y - world.y)
		br_corner = br_corner.Move(x - world.x, y - world.y)
		world = New tlVector2(x, y)
		worldhandle = New tlVector2(handle.x + world.x, handle.y + world.y)
		UpdateWithinQuadtree()
	End
	
	#Rem monkeydoc Move the bounding box by a given amount.
		This sets the position of the top left corner of the bounding box by moving it by the x and y amount. If the box is within quadtree it 
		will automatically update itself within it.
		@param x Distance to move left or right
		@param y Distance to move up or down
	#End
	Method Move(x:Float, y:Float) Virtual
		world = world.Move(x, y)
		worldhandle = world.AddVector(handle)
		tl_corner = tl_corner.Move(x, y)
		br_corner = br_corner.Move(x, y)
		UpdateWithinQuadtree()
	End
	
	#Rem monkeydoc Set the handle of the boundary
		setting the handle let's you offset where the boundary exists in the world. By default the handle is located at the center of the boudary.
		@param x x offset
		@param y y offset
	#End
	Method SetHandlePosition(x:Float, y:Float)
		handle = New tlVector2(x, y)
		worldhandle = world.AddVector(handle)
		TForm()
	End

	#Rem monkeydoc Update the box within the quadatree
		If you move an object that exists within a quadtreee, it's important to update it's position with this method
	#End
	Method UpdateWithinQuadtree()
		If NeedsMoving()
			quadtree.UpdateRect(Self)
		Endif
	End

	#Rem monkeydoc The current velocity vector
	#End
	Property Velocity:tlVector2()
		return velocity
	End
	
	#Rem monkeydoc Update the position of the boundary
		You can use this method to update it's position according to its current velocity vector
	#End
	Method UpdatePosition()
		Move(velocity.x, velocity.y)
	End
	
	#Rem monkeydoc Get the x world coordinate of the boundary
		You can use this to find out the current x coordinate of the boundary. This would be especially useful if you have just used [[PreventOverlap]]
		and need to know the new position of the object to update your game object.
		@return _Float_ with the current x coordinate
	#End
	Method WorldX:Float()
		Return world.x
	End
	
	#Rem monkeydoc Get the y world coordinate of the boundary
		You can use this to find out the current x coordinate of the boundary. This would be especially useful if you have just used [[PreventOverlap]]
		and need to know the new position of the object to update your game object.
		@return _Float_ with the current y coordinate
	#End
	Method WorldY:Float()
		Return world.y
	End
	
	#Rem monkeydoc Get the y world coordinate of the boundary
		You can use this to find out the current coordinates of the boundary. This would be especially useful if you have just used [[PreventOverlap]]
		and need to know the new position of the object to update your game object.
		@return _tlVector_ with the current y coordinate
	#End
	Property World:tlVector2()
		Return world
	End
	
	#Rem monkeydoc The current width of the box
	#End
	Property Width:Float() 
		Return width
	End
	
	#Rem monkeydoc The current height of the box
	#End
	Property Height:Float() 
		Return height
	End
	
	#Rem monkeydoc The collision type of the box
		Either tlBOX_COLLISION, tlCIRCLE_COLLISION tlLINE_COLLISION or tlPOLY_COLLISION
	#End
	Property CollisionType:Int() 
		Return collisiontype
	End
	
	#Rem monkeydoc Set the velocity of the boundary
		It's important to set the velocity of the boundary so that collisions can be more accurately calculated. If you're attaching this
		to an entity in your game then you'll just need to match this to your entities velocity.
		@param x x velocity
		@param y y velocity
	#End
	Method SetVelocity(velocity_x:Float, velocity_y:Float)
		velocity = New tlVector2(velocity_x, velocity_y)
	End
	
	#Rem monkeydoc Set the velocity vector of the boundary
		It's important to set the velocity of the boundary so that collisions can be more accurately calculated. If you're attaching this
		to an entity in your game then you'll just need to match this to your entities velocity.
		@param vector [[tlVector2]] of the velocity
	#End
	Method SetVelocityVector(vector:tlVector2)
		velocity = vector
	End
	
	#Rem monkeydoc Set the scale of the Box
		This sets scale of the Box.
	#End
	Method SetScale(x:Float, y:Float) Virtual
		scale = New tlVector2(x, y)
		TForm()
	End
	
	#Rem monkeydoc Find out if a point is within the bounding box
		Use this to find out if a point at x,y falls with the bounding box of this [[tlBox]]
		@param x x coordinate of point
		@param y y coordinate of point
		@return True if the point is within, otherwise false
	#End
	Method PointInside:Int(x:Float, y:Float) Virtual
		Return x >= tl_corner.x And x <= br_corner.x And y >= tl_corner.y And y <= br_corner.y
	End
	
	#Rem monkeydoc Compare this [[tlBox]] with another to see if they overlap
		Use this to find out if this [[tlBox]] overlaps the [[tlBox]] you pass to it. This is a very simple overlap to see if the bounding box overlaps only
		Set VelocityCheck to true if you want to see if they will overlap next frame based on their velocities.
		@param rect [[tlBox]] to check with
		@return True if they do overlap, otherwise false
	#End
	Method BoundingBoxOverlap:Int(rect:tlBox, velocitycheck:Int = False) Virtual
		Local check1:Int = tl_corner.x <= rect.br_corner.x And br_corner.x >= rect.tl_corner.x And tl_corner.y <= rect.br_corner.y And br_corner.y >= rect.tl_corner.y
		If velocitycheck
			Local check2:Int = tl_corner.x + velocity.x <= rect.br_corner.x + rect.velocity.x And br_corner.x + velocity.x >= rect.tl_corner.x + rect.velocity.x And tl_corner.y + velocity.y <= rect.br_corner.y + rect.velocity.y And br_corner.y + velocity.y >= rect.tl_corner.y + rect.velocity.y
			If check2 Return True
		End If
		Return check1
	End
		
	#Rem monkeydoc Find out if a [[tlBox]] lies within this objects bounding box
		If you need to know whether a [[tlBox]] you pass to this method, lies entirely with this [[tlBox]] (no overlapping) then you can use this method. 
		#Remember, if you call this method from a poly, line or circle, it will only check against the bounding boxes.
		@param rect [[tlBox]] to check with
		@return True if it is within, otherwise false
	#End
	Method RectWithin:Int(rect:tlBox) Virtual
		Return tl_corner.x < rect.tl_corner.x And br_corner.x > rect.br_corner.x And tl_corner.y < rect.tl_corner.y And br_corner.y > rect.br_corner.y
	End
	
	#Rem monkeydoc Compare this [[tlBox]] with a [[tlCircle]]
		This will perfrom a simple bounding box to circle collision check on the [[tlCircle]] you pass to it. 
		@param circle [[tlCircle]] to check with
		@return True if they overlap, otherwise false
	#End
	Method CircleOverlap:Int(circle:tlCircle) Virtual
		If Not BoundingBoxOverlap(circle) Return False
		If PointInside(circle.worldhandle.x, circle.worldhandle.y) Return True
		If LineToCircle(tl_corner.x, tl_corner.y, br_corner.x, tl_corner.y, circle.worldhandle.x, circle.worldhandle.y, circle.radius) Return True
		If LineToCircle(br_corner.x, tl_corner.y, br_corner.x, br_corner.y, circle.worldhandle.x, circle.worldhandle.y, circle.radius) Return True
		If LineToCircle(br_corner.x, br_corner.y, tl_corner.x, br_corner.y, circle.worldhandle.x, circle.worldhandle.y, circle.radius) Return True
		If LineToCircle(tl_corner.x, br_corner.y, tl_corner.x, tl_corner.y, circle.worldhandle.x, circle.worldhandle.y, circle.radius) Return True

		Return False
	End
	
	#Rem monkeydoc Check for a collision with another [[tlBox]]
		Use this to check for a collision with another [[tlBox]] that you pass to the method. You can then use the information stored in 
		[[tlCollisionResult]] to perform various things based on the result of the collision check.
		@param box The [[tlBox]] to check with
		@return [[tlCollisionResult]] type containing info about the collision
	#End
	Method BoxCollide:tlCollisionResult(box:tlBox) Virtual
		
		Local result:tlCollisionResult = New tlCollisionResult
		
		Local min0:Float
		Local max0:Float
		Local min1:Float
		Local max1:Float
		
		Local overlapdistance:Float
		Local veloverlapdistance:Float
		Local minoverlapdistance:Float = $7fffffff
		
		For Local c:Int = 0 To 1
		
			Select c
				Case 0
					min0 = tl_corner.y
					max0 = br_corner.y
					min1 = box.tl_corner.y
					max1 = box.br_corner.y
					
					overlapdistance = IntervalDistance(min0, max0, min1, max1)
					If overlapdistance > 0
						result.Intersecting = False
					End If
					
					If velocity.y Or box.velocity.y
						If velocity.y
							min0+=velocity.y
							max0+=velocity.y
						End If
						If box.velocity.y
							min1+=box.velocity.y
							max1+=box.velocity.y
						End If
						veloverlapdistance = IntervalDistance(min0, max0, min1, max1)
						If veloverlapdistance > 0
							result.WillIntersect = False
						Else
							overlapdistance = veloverlapdistance
						End If
					Else
						result.WillIntersect = False
					End If
				
					If Not result.Intersecting And Not result.WillIntersect Return result

					
					overlapdistance = Abs(overlapdistance)
								
					If overlapdistance < minoverlapdistance
						minoverlapdistance = overlapdistance
						If worldhandle.y > box.worldhandle.y
							result.TranslationVector = New tlVector2(0, minoverlapdistance)
						Else
							result.TranslationVector = New tlVector2(0, -minoverlapdistance)
						End If
					End If
					
				Case 1
					min0 = tl_corner.x
					max0 = br_corner.x
					min1 = box.tl_corner.x
					max1 = box.br_corner.x
					
					overlapdistance = IntervalDistance(min0, max0, min1, max1)
					If overlapdistance > 0
						result.Intersecting = False
					End If
					
					If velocity.x Or box.velocity.x
						If velocity.x
							min0+=velocity.x
							max0+=velocity.x
						End If
						If box.velocity.x
							min1+=box.velocity.x
							max1+=box.velocity.x
						End If
						veloverlapdistance = IntervalDistance(min0, max0, min1, max1)
						If veloverlapdistance > 0
							result.WillIntersect = False
						Else
							overlapdistance = veloverlapdistance
						End If
					Else
						result.WillIntersect = False
					End If
			
					If Not result.Intersecting And Not result.WillIntersect Return result

					
					overlapdistance = Abs(overlapdistance)
								
					If overlapdistance < minoverlapdistance
						minoverlapdistance = overlapdistance
						If worldhandle.x > box.worldhandle.x
							result.TranslationVector = New tlVector2(minoverlapdistance, 0)
						Else
							result.TranslationVector = New tlVector2(-minoverlapdistance, 0)
						End If
					End If
					
			End Select
			
		Next
		
		result.source = Self
		result.target = box
		Return result
	
	End
	
	#Rem monkeydoc Check for a collision with a [[tlCircle]]
		Use this to check for a collision with a [[tlCircle]] that you pass to the method. You can then use the information stored in 
		[[tlCollisionResult]] to perform various things based on the result of the collision check.
		@param circle The [[tlCircle]] to check with
		@return [[tlCollisionResult]] type containing info about the collision
	#End
	Method CircleCollide:tlCollisionResult(circle:tlCircle) Virtual
		Local result:tlCollisionResult = New tlCollisionResult
		If Not BoundingBoxOverlap(circle, True) 
			result.NoCollision = True
			Return result
		End If
		
		Local axis:tlVector2
		
		Local min0:Float
		Local max0:Float
		Local min1:Float
		Local max1:Float
		
		Local dotoffset:Float
		
		Local velocityoffset0:Float
		Local velocityoffset1:Float
		
		Local overlapdistance:Float
		Local veloverlapdistance:Float
		Local minoverlapdistance:Float = $7fffffff
		
		
		Local woffset:tlVector2 = New tlVector2(world.x - circle.world.x, world.y - circle.world.y)

		For Local c:Int = 0 To 2
			
			If c < 2
				axis = normals[c]
			Else
				axis = GetVoronoiAxis(circle.worldhandle)
				If axis.Invalid Exit
			End If
			
			Project(axis, Varptr(min0), Varptr(max0))
			circle.Project(axis, Varptr(min1), Varptr(max1))
			
			dotoffset = axis.DotProduct(woffset)
			
			min0 += dotoffset
			max0 += dotoffset
			
			overlapdistance = IntervalDistance(min0, max0, min1, max1)
			If overlapdistance > 0
				result.Intersecting = False
			End If
			
			If velocity.x Or velocity.y Or circle.velocity.x Or circle.velocity.y
				If velocity.x Or velocity.y
					velocityoffset0 = axis.DotProduct(velocity)
					min0 += velocityoffset0
					max0 += velocityoffset0
				End If
				If circle.velocity.x Or circle.velocity.y
					velocityoffset1 = axis.DotProduct(circle.velocity)
					min1 += velocityoffset1
					max1 += velocityoffset1
				End If
				veloverlapdistance = IntervalDistance(min0, max0, min1, max1)
				If veloverlapdistance > 0
					result.WillIntersect = False
				Else
					overlapdistance = veloverlapdistance
				End If
			Else
				result.WillIntersect = False
			End If
			
			If Not result.Intersecting And Not result.WillIntersect Return result

			
			overlapdistance = Abs(overlapdistance)
						
			If overlapdistance < minoverlapdistance
				minoverlapdistance = overlapdistance
				result.SurfaceNormal = axis.Clone()
				Local polytopolyvec:tlVector2 = worldhandle.SubtractVector(circle.worldhandle)

				If polytopolyvec.DotProduct(result.SurfaceNormal) < 0 result.SurfaceNormal = result.SurfaceNormal.Mirror()

			End If
			
		Next
		
		result.TranslationVector = result.SurfaceNormal.Scale(minoverlapdistance)

		result.source = Self
		result.target = circle
		Return result
	End

	#Rem monkeydoc Check for a collision with a [[tlLine]]
		Use this to check for a collision with a [[tlLine]] that you pass to the method. You can then use the information stored in 
		[[tlCollisionResult]] to perform various things based on the result of the collision check.
		@param line The [[tlLine]] to check with
		@return [[tlCollisionResult]] type containing info about the collision
	#End
	Method LineCollide:tlCollisionResult(line:tlLine) Virtual
		Local result:tlCollisionResult = New tlCollisionResult

		If Not BoundingBoxOverlap(line, True)
			result.NoCollision = True
			Return result
		End If
		
		Local axis:tlVector2
		
		Local min0:Float
		Local max0:Float
		Local min1:Float
		Local max1:Float
		
		Local dotoffset:Float
		
		Local velocityoffset0:Float
		Local velocityoffset1:Float
		
		Local overlapdistance:Float
		Local veloverlapdistance:Float
		Local minoverlapdistance:Float = $7fffffff
		
		
		Local woffset:tlVector2 = New tlVector2(world.x - line.world.x, world.y - line.world.y)
		
		For Local c:Int = 0 To 3
		
			If c < 2
				axis = line.normals[c]
			Else
				axis = normals[c - 1]
			End If
		
			Project(axis, Varptr(min0), Varptr(max0))
			line.Project(axis, Varptr(min1), Varptr(max1))
			
			dotoffset = axis.DotProduct(woffset)
			
			min0 += dotoffset
			max0 += dotoffset
			
			overlapdistance = IntervalDistance(min0, max0, min1, max1)
			If overlapdistance > 0
				result.Intersecting = False
			End If
			
			If velocity.x Or velocity.y Or line.velocity.x Or line.velocity.y
				If velocity.x Or velocity.y
					velocityoffset0 = axis.DotProduct(velocity)
					min0+=velocityoffset0
					max0+=velocityoffset0
				End If
				If line.velocity.x Or line.velocity.y
					velocityoffset1 = axis.DotProduct(line.velocity)
					min1+=velocityoffset1
					max1+=velocityoffset1
				End If
				veloverlapdistance = IntervalDistance(min0, max0, min1, max1)
				If veloverlapdistance > 0
					result.WillIntersect = False
				Else
					overlapdistance = veloverlapdistance
				End If
			Else
				result.WillIntersect = False
			End If
			
			If Not result.Intersecting And Not result.WillIntersect Return result

			
			overlapdistance = Abs(overlapdistance)
						
			If overlapdistance < minoverlapdistance
				minoverlapdistance = overlapdistance
				result.SurfaceNormal = axis.Clone()
				Local vec:tlVector2 = worldhandle.SubtractVector(line.worldhandle)

				If vec.DotProduct(result.SurfaceNormal) < 0 result.SurfaceNormal = result.SurfaceNormal.Mirror()

			End If
			
		Next
		
		result.TranslationVector = result.SurfaceNormal.Scale(minoverlapdistance)

		result.source = Self
		result.target = line
		Return result
	End

	#Rem monkeydoc Check for a collision with a [[tlPolygon]]
		Use this to check for a collision with a [[tlPolygon]] that you pass to the method. You can then use the information stored in 
		[[tlCollisionResult]] to perform various things based on the result of the collision check.
		@param poly The [[tlPolygon]] to check with
		@return [[tlCollisionResult]] type containing info about the collision
	#End
	Method PolyCollide:tlCollisionResult(poly:tlPolygon) Virtual
		Local result:tlCollisionResult = New tlCollisionResult

		If Not BoundingBoxOverlap(poly, True)
			result.NoCollision = True
			Return result
		End If
		
		Local axis:tlVector2
		
		Local min0:Float
		Local max0:Float
		Local min1:Float
		Local max1:Float
		
		Local dotoffset:Float
		
		Local velocityoffset0:Float
		Local velocityoffset1:Float
		
		Local overlapdistance:Float
		Local veloverlapdistance:Float
		Local minoverlapdistance:Float = $7fffffff
		
		Local woffset:tlVector2 = New tlVector2(world.x - poly.world.x, world.y - poly.world.y)

		For Local c:Int = 0 To poly.vertices.Length + 1
		
			If c < poly.vertices.Length
				axis = poly.normals[c]
			Else
				axis = normals[c - poly.vertices.Length]
			End If
		
			Project(axis, Varptr(min0), Varptr(max0))
			poly.Project(axis, Varptr(min1), Varptr(max1))
			
			dotoffset = axis.DotProduct(woffset)
			
			min0+=dotoffset
			max0+=dotoffset
			
			overlapdistance = IntervalDistance(min0, max0, min1, max1)
			If overlapdistance > 0
				result.Intersecting = False
			End If
			
			If velocity.x Or velocity.y Or poly.velocity.x Or poly.velocity.y
				If velocity.x Or velocity.y
					velocityoffset0 = axis.DotProduct(velocity)
					min0+=velocityoffset0
					max0+=velocityoffset0
				End If
				If poly.velocity.x Or poly.velocity.y
					velocityoffset1 = axis.DotProduct(poly.velocity)
					min1+=velocityoffset1
					max1+=velocityoffset1
				End If
				veloverlapdistance = IntervalDistance(min0, max0, min1, max1)
				If veloverlapdistance > 0
					result.WillIntersect = False
				Else
					overlapdistance = veloverlapdistance
				End If
			Else
				result.WillIntersect = False
			End If
			
			If Not result.Intersecting And Not result.WillIntersect Return result

			
			overlapdistance = Abs(overlapdistance)
						
			If overlapdistance < minoverlapdistance
				minoverlapdistance = overlapdistance
				result.SurfaceNormal = axis.Clone()
				Local vec:tlVector2 = worldhandle.SubtractVector(poly.worldhandle)
				If vec.DotProduct(result.SurfaceNormal) < 0 result.SurfaceNormal = result.SurfaceNormal.Mirror()
			End If
			
		Next
		result.TranslationVector = result.SurfaceNormal.Scale(minoverlapdistance)

		result.source = Self
		result.target = poly
		Return result
	End
	
	#Rem monkeydoc See is a ray collides with this [[tlBox]]
		Returns [[tlCollisionResult]] with the results of the collision
		You can use this to test for a collision with a ray. Pass the origin of the ray with px and py, and set the direction of the ray with dx and dy.
		dx and dy will be normalised and extended infinitely, if maxdistance equals 0 (default), otherwise set maxdistance to how ever far you want the ray 
		to extend to. If the ray starts inside the box then result.RayOriginInside will be set to true.
		@param px x origin of the ray
		@param py y origin of the ray
		@param dx x direction of the ray
		@param dy y direction of the ray
		@param maxdistance maximum distance of the ray, or 0 for inifinate
		@return [[tlCollisionResult]] type containing info about the collision
	#End
	Method RayCollide:tlCollisionResult(px:Float, py:Float, dx:Float, dy:Float, maxdistance:Float = 0) Virtual
		
		Local result:tlCollisionResult = New tlCollisionResult
		
		If PointInside(px, py)
			result.RayOriginInside = True
			result.RayIntersection = New tlVector2(0, 0)
			Return result
		End If
		
		Local p:tlVector2 = New tlVector2(px, py)
		Local d:tlVector2 = New tlVector2(dx, dy)
		
		Local raydot:Float
		Local edge:tlVector2
		Local iedge:tlVector2
		
		Local vw:tlVector2
		Local intersect:tlVector2
		Local distance:Float
		
		d = d.Normalise()
		
		For Local c:Int = 0 To 3
			raydot = d.DotProduct(normals[c])
			If raydot < 0 And p.SubtractVector(tformvertices[c].AddVector(world)).DotProduct(normals[c]) > 0
				vw = tformvertices[c].AddVector(world)
				distance = normals[c].DotProduct(p.SubtractVector(vw))
				distance = Abs(distance / raydot)
				If (maxdistance > 0 And distance <= maxdistance) Or maxdistance = 0
					intersect = d.Scale(distance).AddVector(p)
					vw = intersect.SubtractVector(world)
					If c = 0
						edge = tformvertices[3].SubtractVector(tformvertices[c])
						iedge = tformvertices[3].SubtractVector(vw)
					Else
						edge = tformvertices[c - 1].SubtractVector(tformvertices[c])
						iedge = tformvertices[c - 1].SubtractVector(vw)
					End If
					raydot = edge.DotProduct(iedge)
					If raydot >= 0 And raydot <= edge.DotProduct(edge)
						result.RayIntersection = intersect
						result.SurfaceNormal = normals[c]
						result.RayDistance = distance
						result.target = Self
						Return result
					End If
				End If
			End If
		Next
		
		result.Intersecting = False
		result.WillIntersect = False
		
		Return result
	
	End
	
	#Rem monkeydoc Draw this tlBox
		Use this if you need to draw the bounding box for debugging purposes
		@param canvas The mojo canvas to draw with
		@param offsetx x amount of any offset
		@param offsety y amount of any offset
		@param boundingbox Set to true to also draw the bounding box (not relevant for [[tlBox]])
	#End
	Method Draw(canvas:Canvas, offsetx:Float = 0, offsety:Float = 0, boundingbox:Int = False) Virtual
		if highlight canvas.Color = New Color( 0, 1, 0 )

		canvas.DrawLine(tl_corner.x - offsetx, tl_corner.y - offsety, br_corner.x - offsetx, tl_corner.y - offsety)
		canvas.DrawLine(br_corner.x - offsetx, tl_corner.y - offsety, br_corner.x - offsetx, br_corner.y - offsety)
		canvas.DrawLine(br_corner.x - offsetx, br_corner.y - offsety, tl_corner.x - offsetx, br_corner.y - offsety)
		canvas.DrawLine(tl_corner.x - offsetx, br_corner.y - offsety, tl_corner.x - offsetx, tl_corner.y - offsety)
	End
	
	#Rem monkeydoc Get the collision type of the Box
		The collision type can help you determine what type of collision you should be performing on objects calledback from quadtree queries.
		@return _int_ Either tlBOX_COLLISION, tlCIRCLE_COLLISION, tlLINE_COLLISION or tlPOLY_COLLISION
	#End
	Method GetCollisionType:Int()
		Return collisiontype
	End
	
	#Rem monkeydoc Prevent the boundary from overlapping another based on the result of a collision.
		When you check for a collision, the results of that collision are stored with a [[tlCollisionResult]]. This can be passed to this method
		to prevent 2 boundaries from overlapping. If push is set to true, then the source boundary will push the target boundary along it's velocity vector.
		@param result The [[tlCollisionResult]] with the collison data to use to move the objects apart
		@param push Set to true if you want the box to push away the colliding object
	#End
	Method PreventOverlap(result:tlCollisionResult, push:Int = False)
		If not result.NoCollision
			If Not push
				If result.WillIntersect
					If Self = result.source
						Move(result.TranslationVector.x, result.TranslationVector.y)
					Else
						result.target.Move(-result.TranslationVector.x, -result.TranslationVector.y)
					End If
				ElseIf result.Intersecting
					If Self = result.source
						Move(result.TranslationVector.x, result.TranslationVector.y)
					Else
						Move(-result.TranslationVector.x, -result.TranslationVector.y)
					End If
				End If
			Else
				If result.WillIntersect
					If Self = result.source
						result.target.Move(-result.TranslationVector.x, -result.TranslationVector.y)
					Else
						result.source.Move(result.TranslationVector.x, result.TranslationVector.y)
					End If
				ElseIf result.Intersecting
					If Self = result.source
						result.target.Move(-result.TranslationVector.x, -result.TranslationVector.y)
					Else
						result.source.Move(result.TranslationVector.x, result.TranslationVector.y)
					End If
				End If
			End If
		End If
	End
	
	#Rem monkeydoc Repel boundaries that overlap
		Rather then simply preventing an overlap outright, this will ease a boundary away slowly until it no longer overlaps. This can 
		be useful to separate groups of entities away from each other in a more smooth fashion. As with [[PreventOverlap]] set push to true to push
		the other entity away.
		@param result The [[tlCollisionResult]] with the collison data to use to move the objects apart
		@param push Set to true if you want the box to push away the colliding object
		@param factor the amount to repel the objects
	#End
	Method Repel(result:tlCollisionResult, push:Int = False, factor:Float = 0.1)
		If not result.NoCollision
			If Not push
				If result.WillIntersect
					If Self = result.source
						Move(result.TranslationVector.x * factor, result.TranslationVector.y * factor)
					Else
						result.target.Move(-result.TranslationVector.x * factor, -result.TranslationVector.y * factor)
					End If
				ElseIf result.Intersecting
					If Self = result.source
						Move(result.TranslationVector.x * factor, result.TranslationVector.y * factor)
					Else
						Move(-result.TranslationVector.x * factor, -result.TranslationVector.y * factor)
					End If
				End If
			Else
				If result.WillIntersect
					If Self = result.source
						result.target.Move(-result.TranslationVector.x * factor, -result.TranslationVector.y * factor)
					Else
						result.source.Move(result.TranslationVector.x * factor, result.TranslationVector.y * factor)
					End If
				ElseIf result.Intersecting
					If Self = result.source
						result.target.Move(-result.TranslationVector.x * factor, -result.TranslationVector.y * factor)
					Else
						result.source.Move(result.TranslationVector.x * factor, result.TranslationVector.y * factor)
					End If
				End If
			End If
		End If
	End
	
	#Rem monkeydoc Separate boundaries that overlap
		This is slightly different to _Repel_ in that both objects will be moved away from each other according to the 2 factors
		you pass to it. So you can either push them away from each other equally or you can weight one or the other.
		@param result The [[tlCollisionResult]] with the collison data to use to move the objects apart
		@param push Set to true if you want the box to push away the colliding object
		@param sourcefactor the amount the source object is separated
		@param targetfactor the amount the target object is separated
	#End
	Method Separate(result:tlCollisionResult, sourcefactor:Float = 0.1, targetfactor:Float = 0.1)
		If not result.NoCollision
			If result.WillIntersect
				result.target.Move(-result.TranslationVector.x * targetfactor, -result.TranslationVector.y * targetfactor)
				result.source.Move(result.TranslationVector.x * sourcefactor, result.TranslationVector.y * sourcefactor)
			ElseIf result.Intersecting
				result.target.Move(-result.TranslationVector.x * targetfactor, -result.TranslationVector.y * targetfactor)
				result.source.Move(result.TranslationVector.x * sourcefactor, result.TranslationVector.y * sourcefactor)
			End If
		End If
	End

	'internal stuff---------------------------------
	#Rem monkeydoc @hidden
	#End	
	Method AddQuad(q:tlQuadTreeNode)
		'tlBoundaries are aware of all the quadtreenodes they exist within, so when they're added to a node, that node is added to the Box's list of nodes.
		quadlist.Add(q)
		quads += 1
	End

	#Rem monkeydoc @hidden
	#End	
	Method RemoveQuad(q:tlQuadTreeNode)
		'Removes a node from the boundaries list of nodes.
		quadlist.Remove(q)
		quads -= 1
	End
	#Rem monkeydoc @hidden
	#End	
	Method RemoveFromQuadTree()
		If quadtree
			Local nodes:=quadlist.All()
			While not nodes.AtEnd
				local q:=nodes.Current
				q.numberofobjects-=1
				q.objects.Remove(Self)
				nodes.Erase()
			wend
			quadtree.totalobjectsintree -= 1
		End If
	End

	#Rem monkeydoc @hidden
	#End	
	Method AddForRemoval()
		If quadtree
			quadtree.AddForRemoval(self)
		End If
	End

	Private
	#Rem monkeydoc @hidden
	#End	
	Method EmptyQuadList()
		Local nodes:=quadlist.All()
		While not nodes.AtEnd
			local q:=nodes.Current
			nodes.Erase()
		wend
	End

	#Rem monkeydoc @hidden
	#End	
	Method SetQuad(q:tlQuadTreeNode)
		'tlBoundaries are aware of all the quadtreenodes they exist within, so when they're added to a node, that node is added to the Box's list of nodes.
		quad = q
	End Method

	#Rem monkeydoc @hidden
	#End	
	Method GetVoronoiAxis:tlVector2(point:tlVector2) Virtual
		'Finds the voronoi region of a point and returns the axis vector between the nearest vertex and the point.
		'returns null is the region is an edge rather then a vector.
		If point.x >= tl_corner.x And point.x <= br_corner.x Return New tlVector2(0, 0, true)
		If point.y >= tl_corner.y And point.y <= br_corner.y Return New tlVector2(0, 0, true)
		
		Local axis:tlVector2
		
		If point.x < tl_corner.x And point.y < tl_corner.y
			axis = point.SubtractVector(tl_corner)
			axis = axis.Normalise()
			Return axis
		ElseIf point.x > br_corner.x And point.y < tl_corner.y
			axis = New tlVector2(point.x - br_corner.x, point.y - tl_corner.y)
			axis = axis.Normalise()
			Return axis
		ElseIf point.x < tl_corner.x And point.y > br_corner.y
			axis = New tlVector2(point.x - tl_corner.x, point.y - br_corner.y)
			axis = axis.Normalise()
			Return axis
		ElseIf point.x > br_corner.x And point.y > br_corner.y
			axis = point.SubtractVector(br_corner)
			axis = axis.Normalise()
			Return axis
		End If
		
		Return New tlVector2(0, 0, true)
		
	End

	#Rem monkeydoc @hidden
	#End
	Property TFormVertices:tlVector2[]()
		Return tformvertices
	End
	
	Method NeedsMoving:Int()
		'This determines whether the tlBox needs to move within the quadtree. If it exists within more then 1 quad (ie., it overlaps quads), then 
		'it will always be moved as there's no easy way to say whether it still overlaps the same nodes or not (atleast not without more Box check which 
		'I don't think's worth it). If it only exists within 1 node then it does a quick check to see if it is still contained entirely within that node, otherwise
		'it adds itself back into the quadtree
		If quads > 1
			Return True
		ElseIf quads = 1
			If Not quadlist.Empty
				Local q:tlQuadTreeNode = quadlist.Top
				If q
					If q.Box.RectWithin(Self)
						Return False
					Else
						Return True
					End If
				End If
			End If 
		EndIf

		Return False
	End

	#Rem monkeydoc @hidden
	#End
	Method UpdateNormals() Virtual
		Local v1:tlVector2 = tformvertices[3]
		Local v2:tlVector2
		For Local c:Int = 0 To 3
			v2 = tformvertices[c]
			normals[c] = New tlVector2(-(v2.y - v1.y), v2.x - v1.x)
			normals[c] = normals[c].Normalise()
			v1 = v2
		Next
	End
	
	#Rem monkeydoc @hidden
	#End
	Method ResetBoundingBox()
		'Reset the bounding box. Performed before it's updated.
		tl_corner.x = $7fffffff
		tl_corner.y = $7fffffff
		br_corner.x = -$7fffffff
		br_corner.y = -$7fffffff
	End
	
	#Rem monkeydoc @hidden
	#End
	Method TFormBoundingBox()
		'After the bounding box is updated, it needs to be moved into world space.
		boxoffset.x = tl_corner.x
		boxoffset.y = tl_corner.y
		tl_corner.x+=world.x
		tl_corner.y+=world.y
		br_corner.x+=world.x
		br_corner.y+=world.y
	End
	
	#Rem monkeydoc @hidden
	#End
	Method UpdateDimensions() Virtual
		'If the scale of the poly has changed then the width and height values need to be updated
		width = br_corner.x - tl_corner.x
		height = br_corner.y - tl_corner.y
	End
	
	#Rem monkeydoc @hidden
	#End
	Method TForm() Virtual
		ResetBoundingBox()
		For Local i:Int = 0 To 3
			tformvertices[i] = New tlVector2(vertices[i].x + handle.x, vertices[i].y + handle.y)
			tformvertices[i].x*=scale.x
			tformvertices[i].y*=scale.y
			UpdateBoundingBox(tformvertices[i].x, tformvertices[i].y)
		Next
		UpdateDimensions()
		TFormBoundingBox()
	End
	
	#Rem monkeydoc @hidden
	#End
	Method UpdateBoundingBox(x:Float, y:Float)
		'When the scale/angle of the poly changes, its bounding box needs to be updated, and that's what happens here.
		tl_corner = New tlVector2(Min(tl_corner.x, x), Min(tl_corner.y, y))
		br_corner = New tlVector2(Max(x, br_corner.x), Max(y, br_corner.y))
	End
	
	#Rem monkeydoc @hidden
	#End
	Method Project(axis:tlVector2, minv:Float Ptr, maxv:Float Ptr) Virtual
		'This projects the Box onto an axis and lets us know the min and max dotproduct values
		Local dotproduct:Float = axis.DotProduct(tformvertices[0])
		'Local dothandle:Float = axis.DotProduct(handle)
		Cast<Float Ptr>(minv)[0] = dotproduct
		Cast<Float Ptr>(maxv)[0] = dotproduct
		For Local c:Int = 1 To 3
			dotproduct = tformvertices[c].DotProduct(axis)
			If dotproduct < Cast<Float Ptr>(minv)[0]
				Cast<Float Ptr>(minv)[0] = dotproduct
			ElseIf dotproduct > Cast<Float Ptr>(maxv)[0]
				Cast<Float Ptr>(maxv)[0] = dotproduct
			End If
		Next
	End

End

#Rem monkeydoc Collision circle class, extends _tlBox
#End
Class tlCircle Extends tlBox
	
	#Rem monkeydoc @hidden
	#End
	Field radius:Float
	#Rem monkeydoc @hidden
	#End
	Field tformradius:Float
	
	#Rem monkeydoc [[tlBox]] Constructor
		Create a new [[tlCircle]] at the given coordinates with the given radius. The coordinates will represent where the center of the circle is located
		in the world. You can also assign some data to the boundary as handy way to store some extra info about the boundary.

		@param x Top left y coordinate
		@param y Top Left x coordinate
		@param radius Radius of the circle
		@param layer The layer that the circle is on, used for quadtrees
		@param data any [[Object]] associated with the box

	    @example
	    	Local box:=New tlCircle(100, 100, 50, 0)
	    @end
	#End
	Method New(x:Float, y:Float, radius:Float, layer:Int = 0, data:Object = Null)
		self.radius = radius
		tl_corner = New tlVector2(x - radius, y - radius)
		br_corner = New tlVector2(x + radius, y + radius)
		world = New tlVector2(x, y)
		worldhandle = world.AddVector(handle)
		width = radius * 2
		height = radius * 2
		collisiontype = tlCIRCLE_COLLISION
		tformradius = radius
		collisionlayer = layer
		self.data = data
		quadlist = New Stack<tlQuadTreeNode>
		quadlist.Reserve(5)
	End
	
	#Rem monkeydoc The current radius of the box
	#End
	Property Radius:Float() 
		Return radius
	End
	
	#Rem monkeydoc Find out if a point is within the circle
		Use this to find out if a point at x,y falls within this [[tlCircle]]
		@param x x coordinate of point
		@param y y coordinate of point
		@return True if the point is within, otherwise false
	#End
	Method PointInside:Int(x:Float, y:Float) Override
		Return GetDistance(x, y, worldhandle.x, worldhandle.y) <= radius
	End
	
	#Rem monkeydoc Compare this [[tlCircle]] with another to see if they overlap
		Use this to find out if this [[tlCircle]] overlaps the [[tlCircle]] you pass to it. This is a very simple overlap to see if the bounding box overlaps only
		Set VelocityCheck to true if you want to see if they will overlap next frame based on their velocities.
		@param circle [[tlCircle]] to check with
		@return True if they do overlap, otherwise false
	#End
	Method CircleOverlap:Int(circle:tlCircle) Override
		Return GetDistance(worldhandle.x, worldhandle.y, circle.worldhandle.x, circle.worldhandle.y) <= radius + circle.radius
	End
	
	#Rem monkeydoc Compare this [[tlCircle]] with a [[tlBox]] to see if they overlap
		Use this to find out if this [[tlCircle]] overlaps the [[tlBox]] you pass to it. This is a very simple overlap to see if the bounding box overlaps only
		Set VelocityCheck to true if you want to see if they will overlap next frame based on their velocities.
		@param rect [[tlBox]] to check with
		@return True if they do overlap, otherwise false
	#End
	Method BoundingBoxOverlap:Int(rect:tlBox, velocitycheck:Int = False) Override
		If Not Super.BoundingBoxOverlap(rect, velocitycheck) Return False
		If worldhandle.x >= rect.tl_corner.x And worldhandle.x <= rect.br_corner.x And worldhandle.y >= rect.tl_corner.y And worldhandle.y <= rect.br_corner.y Return True
		If LineToCircle(rect.tl_corner.x, rect.tl_corner.y, rect.br_corner.x, rect.tl_corner.y, worldhandle.x, worldhandle.y, tformradius) Return True
		If LineToCircle(rect.br_corner.x, rect.tl_corner.y, rect.br_corner.x, rect.br_corner.y, worldhandle.x, worldhandle.y, tformradius) Return True
		If LineToCircle(rect.br_corner.x, rect.br_corner.y, rect.tl_corner.x, rect.br_corner.y, worldhandle.x, worldhandle.y, tformradius) Return True
		If LineToCircle(rect.tl_corner.x, rect.br_corner.y, rect.tl_corner.x, rect.tl_corner.y, worldhandle.x, worldhandle.y, tformradius) Return True

		Return false
	End
	
	#Rem monkeydoc Check for a collision with another [[tlBox]]
		Use this to check for a collision with another [[tlBox]] that you pass to the method. You can then use the information stored in 
		[[tlCollisionResult]] to perform various things based on the result of the collision check.
		@param box The [[tlBox]] to check with
		@return [[tlCollisionResult]] type containing info about the collision
	#End
	Method BoxCollide:tlCollisionResult(box:tlBox) Override
		Local result:tlCollisionResult = New tlCollisionResult

		If Not Super.BoundingBoxOverlap(box, True)
			result.NoCollision = True
			Return result
		End If
		
		Local axis:tlVector2
		
		Local min0:Float
		Local max0:Float
		Local min1:Float
		Local max1:Float
		
		Local dotoffset:Float
		
		Local velocityoffset0:Float
		Local velocityoffset1:Float
		
		Local overlapdistance:Float
		Local veloverlapdistance:Float
		Local minoverlapdistance:Float = $7fffffff
		
		Local woffset:tlVector2 = New tlVector2(world.x - box.world.x, world.y - box.world.y)

		For Local c:Int = 0 To 2
			
			If c < 2
				axis = box.normals[c]
			Else
				axis = box.GetVoronoiAxis(worldhandle)
				If axis.Invalid	Exit
			End If
		
			Project(axis, Varptr(min0), Varptr(max0))
			box.Project(axis, Varptr(min1), Varptr(max1))
			
			dotoffset = axis.DotProduct(woffset)
			
			min0+=dotoffset
			max0+=dotoffset
			
			overlapdistance = IntervalDistance(min0, max0, min1, max1)
			If overlapdistance > 0
				result.Intersecting = False
			End If
			
			If velocity.x Or velocity.y Or box.velocity.x Or box.velocity.y
				If velocity.x Or velocity.y
					velocityoffset0 = axis.DotProduct(velocity)
					min0+=velocityoffset0
					max0+=velocityoffset0
				End If
				If box.velocity.x Or box.velocity.y
					velocityoffset1 = axis.DotProduct(box.velocity)
					min1+=velocityoffset1
					max1+=velocityoffset1
				End If
				veloverlapdistance = IntervalDistance(min0, max0, min1, max1)
				If veloverlapdistance > 0
					result.WillIntersect = False
				Else
					overlapdistance = veloverlapdistance
				End If
			Else
				result.WillIntersect = False
			End If
			
			If Not result.Intersecting And Not result.WillIntersect Return result
			
			overlapdistance = Abs(overlapdistance)
						
			If overlapdistance < minoverlapdistance
				minoverlapdistance = overlapdistance
				result.SurfaceNormal = axis.Clone()
				Local polytopolyvec:tlVector2 = worldhandle.SubtractVector(box.worldhandle)
				If polytopolyvec.DotProduct(result.SurfaceNormal) < 0 result.SurfaceNormal = result.SurfaceNormal.Mirror()

			End If
			
		Next

		result.TranslationVector = result.SurfaceNormal.Scale(minoverlapdistance)

		result.source = Self
		result.target = box
		Return result
	End
	
	#Rem monkeydoc Check for a collision with a [[tlCircle]]
		Use this to check for a collision with a [[tlCircle]] that you pass to the method. You can then use the information stored in 
		[[tlCollisionResult]] to perform various things based on the result of the collision check.
		@param circle The [[tlCircle]] to check with
		@return [[tlCollisionResult]] type containing info about the collision
	#End
	Method CircleCollide:tlCollisionResult(circle:tlCircle) Override
		Local result:tlCollisionResult = New tlCollisionResult

		If Not Super.BoundingBoxOverlap(circle, True)
			result.NoCollision = True
			Return result
		End If
		
		Local axis:tlVector2
		
		Local min0:Float
		Local max0:Float
		Local min1:Float
		Local max1:Float
		
		Local dotoffset:Float
		
		Local velocityoffset0:Float
		Local velocityoffset1:Float
		
		Local overlapdistance:Float
		Local veloverlapdistance:Float
		Local minoverlapdistance:Float = $7fffffff
		
		
		Local woffset:tlVector2 = New tlVector2(world.x - circle.world.x, world.y - circle.world.y)

		axis = circle.world.SubtractVector(worldhandle)
		axis = axis.Normalise()
		
		dotoffset = axis.DotProduct(woffset)
		
		Project(axis, Varptr(min0), Varptr(max0))
		circle.Project(axis, Varptr(min1), Varptr(max1))
		
		min0+=dotoffset
		max0+=dotoffset
		
		overlapdistance = IntervalDistance(min0, max0, min1, max1)
		If overlapdistance > 0
			result.Intersecting = False
		End If
		
		If velocity.x Or velocity.y Or circle.velocity.x Or circle.velocity.y
			If velocity.x Or velocity.y
				velocityoffset0 = axis.DotProduct(velocity)
				min0+=velocityoffset0
				max0+=velocityoffset0
			End If
			If circle.velocity.x Or circle.velocity.y
				velocityoffset1 = axis.DotProduct(circle.velocity)
				min1+=velocityoffset1
				max1+=velocityoffset1
			End If
			veloverlapdistance = IntervalDistance(min0, max0, min1, max1)
			If veloverlapdistance > 0
				result.WillIntersect = False
			Else
				overlapdistance = veloverlapdistance
			End If
		Else
			result.WillIntersect = False
		End If
		
		If Not result.Intersecting And Not result.WillIntersect Return result
		
		overlapdistance = Abs(overlapdistance)
					
		If overlapdistance < minoverlapdistance
			minoverlapdistance = overlapdistance
			result.SurfaceNormal = axis.Clone()
			Local vec:tlVector2 = worldhandle.SubtractVector(circle.worldhandle)
			If vec.DotProduct(result.SurfaceNormal) < 0 result.SurfaceNormal = result.SurfaceNormal.Mirror()
		End If
					
		result.TranslationVector = result.SurfaceNormal.Scale(minoverlapdistance)

		result.source = Self
		result.target = circle
		Return result
	End

	#Rem monkeydoc Check for a collision with a [[tlLine]]
		Use this to check for a collision with a [[tlLine]] that you pass to the method. You can then use the information stored in 
		[[tlCollisionResult]] to perform various things based on the result of the collision check.
		@param line The [[tlLine]] to check with
		@return [[tlCollisionResult]] type containing info about the collision
	#End
	Method LineCollide:tlCollisionResult(line:tlLine) Override
		Local result:tlCollisionResult = New tlCollisionResult

		If Not Super.BoundingBoxOverlap(line, True)
			result.NoCollision = True
			Return result
		End If
		
		Local axis:tlVector2
		
		Local min0:Float
		Local max0:Float
		Local min1:Float
		Local max1:Float
		
		Local dotoffset:Float
		
		Local velocityoffset0:Float
		Local velocityoffset1:Float
		
		Local overlapdistance:Float
		Local veloverlapdistance:Float
		Local minoverlapdistance:Float = $7fffffff
		
		
		Local woffset:tlVector2 = New tlVector2(world.x - line.world.x, world.y - line.world.y)

		For Local c:Int = 0 To 2
		
			If c = 2
				axis = line.GetVoronoiAxis(worldhandle)
				If axis.Invalid Exit
				
				Project(axis, Varptr(min0), Varptr(max0))
				line.Project(axis, Varptr(min1), Varptr(max1))
			Else
				axis = line.normals[c]
	
				Project(axis, Varptr(min0), Varptr(max0))
				line.Project(axis, Varptr(min1), Varptr(max1))
			End If
			
			dotoffset = axis.DotProduct(woffset)
			
			min0+=dotoffset
			max0+=dotoffset
			
			overlapdistance = IntervalDistance(min0, max0, min1, max1)
			If overlapdistance > 0
				result.Intersecting = False
			End If
			
			If velocity.x Or velocity.y Or line.velocity.x Or line.velocity.y
				If velocity.x Or velocity.y
					velocityoffset0 = axis.DotProduct(velocity)
					min0+=velocityoffset0
					max0+=velocityoffset0
				End If
				If line.velocity.x Or line.velocity.y
					velocityoffset1 = axis.DotProduct(line.velocity)
					min1+=velocityoffset1
					max1+=velocityoffset1
				End If
				veloverlapdistance = IntervalDistance(min0, max0, min1, max1)
				If veloverlapdistance > 0
					result.WillIntersect = False
				Else
					overlapdistance = veloverlapdistance
				End If
			Else
				result.WillIntersect = False
			End If
			
			If Not result.Intersecting And Not result.WillIntersect Return result
			
			overlapdistance = Abs(overlapdistance)
						
			If overlapdistance < minoverlapdistance
				minoverlapdistance = overlapdistance
				result.SurfaceNormal = axis.Clone()
				Local polytocirclevec:tlVector2 = worldhandle.SubtractVector(line.worldhandle)
				If polytocirclevec.DotProduct(result.SurfaceNormal) < 0 result.SurfaceNormal = result.SurfaceNormal.Mirror()

			End If
			
		Next
		
		result.TranslationVector = result.SurfaceNormal.Scale(minoverlapdistance)

		result.source = Self
		result.target = line
		Return result
	End
	
	#Rem monkeydoc Check for a collision with a [[tlPolygon]]
		Use this to check for a collision with a [[tlPolygon]] that you pass to the method. You can then use the information stored in 
		[[tlCollisionResult]] to perform various things based on the result of the collision check.
		@param poly The [[tlPolygon]] to check with
		@return [[tlCollisionResult]] type containing info about the collision
	#End
	Method PolyCollide:tlCollisionResult(poly:tlPolygon) Override
		Local result:tlCollisionResult = New tlCollisionResult

		If Not Super.BoundingBoxOverlap(poly, True)
			result.NoCollision = True
			Return result
		End If
		
		Local axis:tlVector2
		
		Local min0:Float
		Local max0:Float
		Local min1:Float
		Local max1:Float
		
		Local dotoffset:Float
		
		Local velocityoffset0:Float
		Local velocityoffset1:Float
		
		Local overlapdistance:Float
		Local veloverlapdistance:Float
		Local minoverlapdistance:Float = $7fffffff
		
		
		Local woffset:tlVector2 = New tlVector2(world.x - poly.world.x, world.y - poly.world.y)

		For Local c:Int = 0 To poly.vertices.Length
		
			If c = poly.tformvertices.Length
				axis = poly.GetVoronoiAxis(worldhandle)
				If axis.Invalid Exit
				
				Project(axis, Varptr(min0), Varptr(max0))
				poly.Project(axis, Varptr(min1), Varptr(max1))
			Else
				axis = poly.normals[c]
	
				Project(axis, Varptr(min0), Varptr(max0))
				poly.Project(axis, Varptr(min1), Varptr(max1))
			End If
			
			dotoffset = axis.DotProduct(woffset)
			
			min0+=dotoffset
			max0+=dotoffset
			
			overlapdistance = IntervalDistance(min0, max0, min1, max1)
			If overlapdistance > 0
				result.Intersecting = False
			End If
			
			If velocity.x Or velocity.y Or poly.velocity.x Or poly.velocity.y
				If velocity.x Or velocity.y
					velocityoffset0 = axis.DotProduct(velocity)
					min0+=velocityoffset0
					max0+=velocityoffset0
				End If
				If poly.velocity.x Or poly.velocity.y
					velocityoffset1 = axis.DotProduct(poly.velocity)
					min1+=velocityoffset1
					max1+=velocityoffset1
				End If
				veloverlapdistance = IntervalDistance(min0, max0, min1, max1)
				If veloverlapdistance > 0
					result.WillIntersect = False
				Else
					overlapdistance = veloverlapdistance
				End If
			Else
				result.WillIntersect = False
			End If
			
			If Not result.Intersecting And Not result.WillIntersect Return result
			
			overlapdistance = Abs(overlapdistance)
						
			If overlapdistance < minoverlapdistance
				minoverlapdistance = overlapdistance
				result.SurfaceNormal = axis.Clone()
				Local vec:tlVector2 = worldhandle.SubtractVector(poly.worldhandle)
				If vec.DotProduct(result.SurfaceNormal) < 0 result.SurfaceNormal = result.SurfaceNormal.Mirror()

			End If
			
		Next
		
		result.TranslationVector = result.SurfaceNormal.Scale(minoverlapdistance)

		result.source = Self
		result.target = poly
		Return result
	End
	
	#Rem monkeydoc See is a ray collides with this [[tlCircle]]
		Returns [[tlCollisionResult]] with the results of the collision
		You can use this to test for a collision with a ray. Pass the origin of the ray with px and py, and set the direction of the ray with dx and dy.
		dx and dy will be normalised and extended infinitely, if maxdistance equals 0 (default), otherwise set maxdistance to how ever far you want the ray 
		to extend to. If the ray starts inside the box then result.RayOriginInside will be set to true.
		@param px x origin of the ray
		@param py y origin of the ray
		@param dx x direction of the ray
		@param dy y direction of the ray
		@param maxdistance maximum distance of the ray, or 0 for inifinate
		@return [[tlCollisionResult]] type containing info about the collision
	#End
	Method RayCollide:tlCollisionResult(px:Float, py:Float, dx:Float, dy:Float, maxdistance:Float = 0) Override
		
		Local result:tlCollisionResult = New tlCollisionResult
		
		If PointInside(px, py)
			result.RayOriginInside = True
			result.RayIntersection = New tlVector2(0, 0)
			Return result
		End If
		
		Local p:tlVector2 = New tlVector2(px, py)
		Local dv:tlVector2 = New tlVector2(dx, dy)
		
		dv = dv.Normalise()

		Local cp:tlVector2 = p.SubtractVector(worldhandle)
		
		Local a:Float = dv.DotProduct(dv)
		Local b:Float = dv.DotProduct(cp) * 2
		Local c:Float = cp.DotProduct(cp) - (tformradius * tformradius)
		
		Local q:Float = b * b - (4 * a * c)
		
		If Not maxdistance maxdistance = $7fffffff
		
		If q >= 0
			
			Local sq:Float = Sqrt(q)
			Local d:Float = 1 / (2 * a) 	
			Local u0:Float = (-b + sq) * d
			Local u1:Float = (-b - sq) * d

			Local u:Float
			
			If u1 < 0
				If u0 >= 0
					u = u0
				Else
					result.Intersecting = False
				End If
			ElseIf u0 < 0
				u = u1
			Else
				If u1 < u0
					u = u1
				Else
					u = u0
				EndIf
			End If
			
			If result.Intersecting And u <= maxdistance
				result.RayIntersection = New tlVector2(px + u * dx, py + u * dy)
				result.SurfaceNormal = result.RayIntersection.SubtractVector(worldhandle)
				result.SurfaceNormal = result.SurfaceNormal.Normalise()

				result.RayDistance = u
				result.target = Self
				Return result
			End If
			
		End If
		
		result.Intersecting = False
		result.WillIntersect = False
		
		Return result
	
	End
	
	#Rem monkeydoc Set the Box of the circle
		this lets you change the size and location of the [[tlCircle]]
		@param x x coordinate
		@param y y coordinate
	#End
	Method SetCircle(x:Float, y:Float, _radius:Float)
		radius = _radius
		tl_corner = New tlVector2(x - radius, y - radius)
		br_corner = New tlVector2(x + radius, y + radius)
		world = New tlVector2(x, y)
		worldhandle = world.AddVector(handle)
		width = radius * 2
		height = radius * 2
'		If needsmoving() quadtree.UpdateRect(Self)
	End
	
	#Rem monkeydoc Draw this tlBox
		Use this if you need to draw the bounding box for debugging purposes
		@param canvas The mojo canvas to draw with
		@param offsetx x amount of any offset
		@param offsety y amount of any offset
		@param boundingbox Set to true to also draw the bounding box
	#End
	Method Draw(canvas:Canvas, offsetx:Float = 0, offsety:Float = 0, boundingbox:Int = False) Override
		if(highlight) canvas.Color = New Color( 0, 255, 0 )
		canvas.DrawOval (worldhandle.x - tformradius - offsetx, worldhandle.y - tformradius - offsety, width, height)
		If boundingbox Super.Draw(canvas, offsetx, offsety, boundingbox)
	End
	
	'internal stuff--------------------
	#Rem monkeydoc @hidden
	#End
	Method Project(axis:tlVector2, minv:Float Ptr, maxv:Float Ptr) Override
		'This projects the circle onto an axis and lets us know the min and max dotproduct values
		Local dothandle:Float = axis.DotProduct(handle)
		Cast<Float Ptr>(minv)[0] = -tformradius + dothandle
		Cast<Float Ptr>(maxv)[0] = tformradius + dothandle
	End
	
	#Rem monkeydoc @hidden
	#End
	Method UpdateDimensions() Override
		'If the scale of the poly has changed then the width and height values need to be updated
		tl_corner = New tlVector2(worldhandle.x - tformradius, worldhandle.y - tformradius)
		br_corner = New tlVector2(worldhandle.x + tformradius, worldhandle.y + tformradius)
		width = br_corner.x - tl_corner.x
		height = br_corner.y - tl_corner.y
	End
	
	#Rem monkeydoc @hidden
	#End
	Method TForm() Override
		tformradius = radius * Max(scale.x, scale.y)
		UpdateDimensions()
	End
End

#Rem monkeydoc Collision polygon class
#End
Class tlPolygon Extends tlBox
	
	#Rem monkeydoc @hidden
	#End
	Field angle:Float

	#Rem monkeydoc Constructor
	#End
	Method New()
	End
	
	#Rem monkeydoc [[tlPolygon]] Constructor

	    | `Note:` |
	    |:-----------|
	    | Polygon must be convex (no internal angles > 180deg)

		@param x Top left y coordinate
		@param y Top Left x coordinate
		@param verts Array of vertices that descibe the Polygon
		@param layer The layer that the box is on, used for quadtrees
		@param data any [[Object]] associated with the box

	    @example
	    	Local box:=New tlPolygon(100, 100, new Float[](- 10.0, -10.0, -15.0, 0.0, -10.0, 10.0, 10.0, 10.0, 15.0, 0.0, 10.0, -10.0), 0)
	    @end
	#End
	Method New(x:Float, y:Float, verts:Float[], layer:Int = 0, data:Object = Null, centerhandle:Int = True)
		world = New tlVector2(x, y)
		vertices = New tlVector2[verts.Length / 2]
		tformvertices = New tlVector2[verts.Length / 2]
		normals = New tlVector2[verts.Length / 2]
		tl_corner = New tlVector2(0, 0)
		br_corner = New tlVector2(0, 0)
		For Local c:Int = 0 To vertices.Length - 1
			vertices[c] = New tlVector2(verts[c * 2], verts[c * 2 + 1])
			If centerhandle
				handle.x+=vertices[c].x
				handle.y+=vertices[c].y
			End If
			tformvertices[c] = New tlVector2(0, 0)
			normals[c] = New tlVector2(0, 0)
		Next
		If centerhandle
			handle.x/=vertices.Length
			handle.y/=vertices.Length
		End If
		For Local c:Int = 0 To vertices.Length - 1
			vertices[c] = vertices[c].SubtractVector(handle)
		Next
		handle = New tlVector2(0, 0)
		worldhandle = world.AddVector(handle)
		collisiontype = tlPOLY_COLLISION
		tformmatrix.Set(Cos(angle) * scale.x, Sin(angle) * scale.y, -Sin(angle) * scale.x, Cos(angle) * scale.y)
		TForm()
		collisionlayer = layer
		self.data = data
		quadlist = New Stack<tlQuadTreeNode>
		quadlist.Reserve(5)
	End
	
	#Rem monkeydoc [[tlPolygon]] Constructor

	    | `Note:` |
	    |:-----------|
	    | Polygon must be convex (no internal angles > 180deg)

		@param verts Array of vertices that descibe the Polygon
		@param layer The layer that the box is on, used for quadtrees
		@param data any [[Object]] associated with the box

	    @example
	    	Local box:=New tlPolygon(new Float[](- 10.0, -10.0, -15.0, 0.0, -10.0, 10.0, 10.0, 10.0, 15.0, 0.0, 10.0, -10.0), 0)
	    @end
	#End
	Method New(verts:Float[], layer:Int = 0, data:Object = Null)
		world = New tlVector2(0, 0)
		vertices = New tlVector2[verts.Length / 2]
		tformvertices = New tlVector2[verts.Length / 2]
		normals = New tlVector2[verts.Length / 2]
		
		tl_corner = New tlVector2(0, 0)
		br_corner = New tlVector2(0, 0)
		For Local c:Int = 0 To vertices.Length - 1
			vertices[c] = New tlVector2(verts[c * 2], verts[c * 2 + 1])
			world.x+=vertices[c].x
			world.y+=vertices[c].y
			tformvertices[c] = New tlVector2(0, 0)
			normals[c] = New tlVector2(0, 0)
		Next
		world.x/=vertices.Length
		world.y/=vertices.Length
		For Local c:Int = 0 To vertices.Length - 1
			vertices[c] = vertices[c].SubtractVector(world)
		Next
		handle = New tlVector2(0, 0)
		worldhandle = handle.AddVector(handle)
		collisiontype = tlPOLY_COLLISION
		tformmatrix.Set(Cos(angle) * scale.x, Sin(angle) * scale.y, -Sin(angle) * scale.x, Cos(angle) * scale.y)
		TForm()
		collisionlayer = layer
		self.data = data
	End
	
	#Rem monkeydoc Rotate the polygon 
		This will rotate the polygon by the given amount
		@param angle The amount of radians to rotate by
	#End
	Method Rotate(angle:Float)
		Self.angle += angle
		tformmatrix.Set(Cos(Self.angle), Sin(Self.angle), -Sin(Self.angle), Cos(Self.angle))
		TForm()
	End

	#Rem monkeydoc Rotate the polygon 
		This will rotate the polygon by the given amount
		@param angle The amount of degrees to rotate by
	#End
	Method RotateDegrees(angle:double)
		angle = DegRad(angle)
		Self.angle += angle
		tformmatrix.Set(Cos(Self.angle), Sin(Self.angle), -Sin(Self.angle), Cos(Self.angle))
		TForm()
	End
	
	#Rem monkeydoc Set the angle of the polygon
		This will adjust the angle of the polygon by the given amount.
		@param angle The angle to set to in radians
	#End
	Method SetAngle(angle:Float)
		self.angle = angle
		tformmatrix.Set(Cos(angle), Sin(angle), -Sin(angle), Cos(angle))
		TForm()
'		If needsmoving() quadtree.UpdateRect(Self)
	End

	#Rem monkeydoc Set the angle of the polygon
		This will adjust the angle of the polygon by the given amount.
		@param angle The angle to set to in degrees
	#End
	Method SetAngleDegrees(angle:Double)
		angle = DegRad(angle)
		self.angle = angle
		tformmatrix.Set(Cos(angle), Sin(angle), -Sin(angle), Cos(angle))
		TForm()
'		If needsmoving() quadtree.UpdateRect(Self)
	End
	
	#Rem monkeydoc Set the position of the Poly.
		This sets the position of the top left corner of the Polygon. If the box is within quadtree it will automatically update itself
		within it.
		@param x
		@param y
	#End
	Method Position(x:Float, y:Float) Override
		tl_corner = tl_corner.Move(x - world.x, y - world.y)
		br_corner = br_corner.Move(x - world.x, y - world.y)
		world = New tlVector2(x, y)
		If handle.x Or handle.y
			TForm()
		Else
			worldhandle = world.AddVector(handle)
		End If
'		If needsmoving() quadtree.UpdateRect(Self)
	End
	
	#Rem monkeydoc Move the bounding box by a given amount.
		This sets the position of the top left corner of the bounding box by moving it by the x and y amount. If the box is within quadtree it 
		will automatically update itself within it.
		@param x Distance to move left or right
		@param y Distance to move up or down
	#End
	Method Move(x:Float, y:Float) Override
		world = world.Move(x, y)
		If handle.x Or handle.y
			TForm()
		Else
			worldhandle = world.AddVector(handle)
			tl_corner = tl_corner.Move(x, y)
			br_corner = br_corner.Move(x, y)
		End If
'		If needsmoving() quadtree.UpdateRect(Self)
	End
	
	#Rem monkeydoc Set the scale of the Polygon
		This sets scale of the polygon.
		@param x horizontal scale amount
		@param y verticle scale amount
	#End
	Method SetScale(x:Float, y:Float) Override
		ResetBoundingBox()
		scale.x = x
		scale.y = y
		TForm()
'		If needsmoving() quadtree.UpdateRect(Self)
	End
	
	#Rem monkeydoc Find out if a point is within the [[tlPolygon]]
		Use this to find out if a point at x,y falls with the [[tlPolygon]]
		@param x x coordinate of point
		@param y y coordinate of point
		@return True if the point is within, otherwise false
	#End
	Method PointInside:Int(x:Float, y:Float) Override
		
		Local x1:Float = tformvertices[tformvertices.Length - 1].x + world.x
		Local y1:Float = tformvertices[tformvertices.Length - 1].y + world.y
		Local cur_quad:Int = GetQuad(x, y, x1, y1)
		Local next_quad:Int
		Local total:Int
		
		For Local i:Int = 0 Until tformvertices.Length
			Local x2:Float = tformvertices[i].x + world.x
			Local y2:Float = tformvertices[i].y + world.y
			next_quad = GetQuad(x, y, x2, y2)
			Local diff:Int = next_quad - cur_quad
			
			Select diff
			Case 2, -2
				If (x2 - (((y2 - y) * (x1 - x2)) / (y1 - y2))) < x
					diff = -diff
				EndIf
			Case 3
				diff = -1
			Case -3
				diff = 1
			End Select
			
			total+=diff
			cur_quad = next_quad
			x1 = x2
			y1 = y2
		Next
		
		If Abs(total)=4 Then Return True 

		Return False
	End
	
	#Rem monkeydoc Check for a collision with a [[tlBox]]
		Use this to check for a collision with a [[tlBox]] that you pass to the method. You can then use the information stored in 
		[[tlCollisionResult]] to perform various things based on the result of the collision check.
		@param box The [[tlBox]] to check with
		@return [[tlCollisionResult]] type containing info about the collision
	#End
	Method BoxCollide:tlCollisionResult(Box:tlBox) Override
		Local result:tlCollisionResult = New tlCollisionResult

		If Not Super.BoundingBoxOverlap(Box, True)
			result.NoCollision = True
			Return result
		End If
		
		Local axis:tlVector2
		
		Local min0:Float
		Local max0:Float
		Local min1:Float
		Local max1:Float
		
		Local dotoffset:Float
		
		Local velocityoffset0:Float
		Local velocityoffset1:Float
		
		Local overlapdistance:Float
		Local veloverlapdistance:Float
		Local minoverlapdistance:Float = $7fffffff
		
		Local woffset:tlVector2 = New tlVector2(world.x - Box.world.x, world.y - Box.world.y)

		For Local c:Int = 0 To vertices.Length + 1
		
			If c < vertices.Length
				axis = normals[c]
			Else
				axis = Box.normals[c - vertices.Length]
			End If
		
			Project(axis, Varptr(min0), Varptr(max0))
			Box.Project(axis, Varptr(min1), Varptr(max1))
			
			dotoffset = axis.DotProduct(woffset)
			
			min0+=dotoffset
			max0+=dotoffset
			
			overlapdistance = IntervalDistance(min0, max0, min1, max1)
			If overlapdistance > 0
				result.Intersecting = False
			End If
			
			If velocity.x Or velocity.y Or Box.velocity.x Or Box.velocity.y
				If velocity.x Or velocity.y
					velocityoffset0 = axis.DotProduct(velocity)
					min0+=velocityoffset0
					max0+=velocityoffset0
				End If
				If Box.velocity.x Or Box.velocity.y
					velocityoffset1 = axis.DotProduct(Box.velocity)
					min1+=velocityoffset1
					max1+=velocityoffset1
				End If
				veloverlapdistance = IntervalDistance(min0, max0, min1, max1)
				If veloverlapdistance > 0
					result.WillIntersect = False
				Else
					overlapdistance = veloverlapdistance
				End If
			Else
				result.WillIntersect = False
			End If
			
			If Not result.Intersecting And Not result.WillIntersect Return result
			
			overlapdistance = Abs(overlapdistance)
						
			If overlapdistance < minoverlapdistance
				minoverlapdistance = overlapdistance
				result.SurfaceNormal = axis.Clone()
				Local vec:tlVector2 = worldhandle.SubtractVector(Box.worldhandle)
				If vec.DotProduct(result.SurfaceNormal) < 0 result.SurfaceNormal = result.SurfaceNormal.Mirror()
			End If
			
		Next
		result.TranslationVector = result.SurfaceNormal.Scale(minoverlapdistance)

		result.source = Self
		result.target = Box
		Return result
	End
	
	#Rem monkeydoc Check for a collision with a [[tlCircle]]
		Use this to check for a collision with a [[tlCircle]] that you pass to the method. You can then use the information stored in 
		[[tlCollisionResult]] to perform various things based on the result of the collision check.
		@param circle The [[tlCircle]] to check with
		@return [[tlCollisionResult]] type containing info about the collision
	#End
	Method CircleCollide:tlCollisionResult(circle:tlCircle) Override
		Local result:tlCollisionResult = New tlCollisionResult

		If Not Super.BoundingBoxOverlap(circle, True)
			result.NoCollision = True
			Return result
		End If
		
		Local axis:tlVector2
		
		Local min0:Float
		Local max0:Float
		Local min1:Float
		Local max1:Float
		
		Local dotoffset:Float
		
		Local velocityoffset0:Float
		Local velocityoffset1:Float
		
		Local overlapdistance:Float
		Local veloverlapdistance:Float
		Local minoverlapdistance:Float = $7fffffff
		
		
		Local woffset:tlVector2 = New tlVector2(world.x - circle.world.x, world.y - circle.world.y)

		For Local c:Int = 0 To vertices.Length
		
			If c = tformvertices.Length
				axis = GetVoronoiAxis(circle.worldhandle)
				If axis.Invalid Exit
				
				Project(axis, Varptr(min0), Varptr(max0))
				circle.Project(axis, Varptr(min1), Varptr(max1))
			Else
				axis = normals[c]
	
				Project(axis, Varptr(min0), Varptr(max0))
				circle.Project(axis, Varptr(min1), Varptr(max1))
			End If
			
			dotoffset = axis.DotProduct(woffset)
			
			min0+=dotoffset
			max0+=dotoffset
			
			overlapdistance = IntervalDistance(min0, max0, min1, max1)
			If overlapdistance > 0
				result.Intersecting = False
			End If
			
			If velocity.x Or velocity.y Or circle.velocity.x Or circle.velocity.y
				If velocity.x Or velocity.y
					velocityoffset0 = axis.DotProduct(velocity)
					min0+=velocityoffset0
					max0+=velocityoffset0
				End If
				If circle.velocity.x Or circle.velocity.y
					velocityoffset1 = axis.DotProduct(circle.velocity)
					min1+=velocityoffset1
					max1+=velocityoffset1
				End If
				veloverlapdistance = IntervalDistance(min0, max0, min1, max1)
				If veloverlapdistance > 0
					result.WillIntersect = False
				Else
					overlapdistance = veloverlapdistance
				End If
			Else
				result.WillIntersect = False
			End If
			
			If Not result.Intersecting And Not result.WillIntersect Return result
			
			overlapdistance = Abs(overlapdistance)
						
			If overlapdistance < minoverlapdistance
				minoverlapdistance = overlapdistance
				result.SurfaceNormal = axis.Clone()
				Local polytocirclevec:tlVector2 = worldhandle.SubtractVector(circle.worldhandle)
				If polytocirclevec.DotProduct(result.SurfaceNormal) < 0 result.SurfaceNormal = result.SurfaceNormal.Mirror()

			End If
			
		Next
		
		result.TranslationVector = result.SurfaceNormal.Scale(minoverlapdistance)

		result.source = Self
		result.target = circle
		Return result
	End
	
	#Rem monkeydoc Check for a collision with a [[tlLine]]
		Use this to check for a collision with a [[tlLine]] that you pass to the method. You can then use the information stored in 
		[[tlCollisionResult]] to perform various things based on the result of the collision check.
		@param line The [[tlLine]] to check with
		@return [[tlCollisionResult]] type containing info about the collision
	#End
	Method LineCollide:tlCollisionResult(Line:tlLine) Override
		Local result:tlCollisionResult = New tlCollisionResult

		If Not Super.BoundingBoxOverlap(Line, True)
			result.NoCollision = True
			Return result
		End If
		
		Local axis:tlVector2
		
		Local min0:Float
		Local max0:Float
		Local min1:Float
		Local max1:Float
		
		Local dotoffset:Float
		
		Local velocityoffset0:Float
		Local velocityoffset1:Float
		
		Local overlapdistance:Float
		Local veloverlapdistance:Float
		Local minoverlapdistance:Float = $7fffffff
		
		
		Local woffset:tlVector2 = New tlVector2(world.x - Line.world.x, world.y - Line.world.y)

		For Local c:Int = 0 To 2 + vertices.Length - 1
		
			If c < 2
				axis = Line.normals[c]
			Else
				axis = normals[c - 2]
			End If
		
			Project(axis, Varptr(min0), Varptr(max0))
			Line.Project(axis, Varptr(min1), Varptr(max1))
			
			dotoffset = axis.DotProduct(woffset)
			
			min0+=dotoffset
			max0+=dotoffset
			
			overlapdistance = IntervalDistance(min0, max0, min1, max1)
			If overlapdistance > 0
				result.Intersecting = False
			End If
			
			If velocity.x Or velocity.y Or Line.velocity.x Or Line.velocity.y
				If velocity.x Or velocity.y
					velocityoffset0 = axis.DotProduct(velocity)
					min0+=velocityoffset0
					max0+=velocityoffset0
				End If
				If Line.velocity.x Or Line.velocity.y
					velocityoffset1 = axis.DotProduct(Line.velocity)
					min1+=velocityoffset1
					max1+=velocityoffset1
				End If
				veloverlapdistance = IntervalDistance(min0, max0, min1, max1)
				If veloverlapdistance > 0
					result.WillIntersect = False
				Else
					overlapdistance = veloverlapdistance
				End If
			Else
				result.WillIntersect = False
			End If
			
			If Not result.Intersecting And Not result.WillIntersect Return result
			
			overlapdistance = Abs(overlapdistance)
						
			If overlapdistance < minoverlapdistance
				minoverlapdistance = overlapdistance
				result.SurfaceNormal = axis.Clone()
				Local polytopolyvec:tlVector2 = worldhandle.SubtractVector(Line.worldhandle)
				If polytopolyvec.DotProduct(result.SurfaceNormal) < 0 result.SurfaceNormal = result.SurfaceNormal.Mirror()

			End If
			
		Next
		
		result.TranslationVector = result.SurfaceNormal.Scale(minoverlapdistance)

		result.source = Self
		result.target = Line
		Return result
	End
	
	#Rem monkeydoc Check for a collision with a [[tlPolygon]]
		Use this to check for a collision with a [[tlPolygon]] that you pass to the method. You can then use the information stored in 
		[[tlCollisionResult]] to perform various things based on the result of the collision check.
		@param poly The [[tlPolygon]] to check with
		@return [[tlCollisionResult]] type containing info about the collision
	#End
	Method PolyCollide:tlCollisionResult(poly:tlPolygon) Override
		Local result:tlCollisionResult = New tlCollisionResult

		If Not Super.BoundingBoxOverlap(poly, True)
			result.NoCollision = True
			Return result
		End If
		
		Local axis:tlVector2

		Local min0:Float
		Local max0:Float
		Local min1:Float
		Local max1:Float
		
		Local dotoffset:Float
		
		Local velocityoffset0:Float
		Local velocityoffset1:Float
		
		Local overlapdistance:Float
		Local veloverlapdistance:Float
		Local minoverlapdistance:Float = $7fffffff
		
		
		Local woffset:tlVector2 = New tlVector2(world.x - poly.world.x, world.y - poly.world.y)

		For Local c:Int = 0 To vertices.Length + poly.vertices.Length - 1
		
			If c < vertices.Length
				axis = normals[c]
			Else
				axis = poly.normals[c - vertices.Length]
			End If
		
			Project(axis, Varptr(min0), Varptr(max0))
			poly.Project(axis, Varptr(min1), Varptr(max1))
			
			dotoffset = axis.DotProduct(woffset)
			
			min0+=dotoffset
			max0+=dotoffset
			
			overlapdistance = IntervalDistance(min0, max0, min1, max1)
			If overlapdistance > 0
				result.Intersecting = False
			End If
			
			If velocity.x Or velocity.y Or poly.velocity.x Or poly.velocity.y
				If velocity.x Or velocity.y
					velocityoffset0 = axis.DotProduct(velocity)
					min0+=velocityoffset0
					max0+=velocityoffset0
				End If
				If poly.velocity.x Or poly.velocity.y
					velocityoffset1 = axis.DotProduct(poly.velocity)
					min1+=velocityoffset1
					max1+=velocityoffset1
				End If
				veloverlapdistance = IntervalDistance(min0, max0, min1, max1)
				If veloverlapdistance > 0
					result.WillIntersect = False
				Else
					overlapdistance = veloverlapdistance
				End If
			Else
				result.WillIntersect = False
			End If
			
			If Not result.Intersecting And Not result.WillIntersect Return result
			
			overlapdistance = Abs(overlapdistance)
						
			If overlapdistance < minoverlapdistance
				minoverlapdistance = overlapdistance
				result.SurfaceNormal = axis.Clone()
				Local polytopolyvec:tlVector2 = worldhandle.SubtractVector(poly.worldhandle)
				If polytopolyvec.DotProduct(result.SurfaceNormal) < 0 result.SurfaceNormal = result.SurfaceNormal.Mirror()

			End If
			
		Next
		
		result.TranslationVector = result.SurfaceNormal.Scale(minoverlapdistance)
		result.source = Self
		result.target = poly
		Return result
	End
	
	#Rem monkeydoc See is a ray collides with this [[tlPolygon]]
		Returns [[tlCollisionResult]] with the results of the collision
		You can use this to test for a collision with a ray. Pass the origin of the ray with px and py, and set the direction of the ray with dx and dy.
		dx and dy will be normalised and extended infinitely, if maxdistance equals 0 (default), otherwise set maxdistance to how ever far you want the ray 
		to extend to. If the ray starts inside the box then result.RayOriginInside will be set to true.
		@param px x origin of the ray
		@param py y origin of the ray
		@param dx x direction of the ray
		@param dy y direction of the ray
		@param maxdistance maximum distance of the ray, or 0 for inifinate
		@return [[tlCollisionResult]] type containing info about the collision
	#End
	Method RayCollide:tlCollisionResult(px:Float, py:Float, dx:Float, dy:Float, maxdistance:Float = 0) Override
		Local result:tlCollisionResult = New tlCollisionResult
		
		If PointInside(px, py)
			result.RayOriginInside = True
			result.RayIntersection = New tlVector2(0, 0)
			Return result
		End If
		
		Local p:tlVector2 = New tlVector2(px, py)
		Local d:tlVector2 = New tlVector2(dx, dy)
		
		Local raydot:Float
		Local edge:tlVector2
		Local iedge:tlVector2
		
		Local vw:tlVector2
		Local intersect:tlVector2
		Local distance:Float
		
		d = d.Normalise()
		
		For Local c:Int = 0 To vertices.Length - 1
			raydot = d.DotProduct(normals[c])
			If raydot < 0 And p.SubtractVector(tformvertices[c].AddVector(world)).DotProduct(normals[c]) > 0
				vw = tformvertices[c].AddVector(world)
				distance = normals[c].DotProduct(p.SubtractVector(vw))
				distance = Abs(distance / raydot)
				If (maxdistance > 0 And distance <= maxdistance) Or maxdistance = 0
					intersect = d.Scale(distance).AddVector(p)
					vw = intersect.SubtractVector(world)
					If c = 0
						edge = tformvertices[vertices.Length - 1].SubtractVector(tformvertices[c])
						iedge = tformvertices[vertices.Length - 1].SubtractVector(vw)
					Else
						edge = tformvertices[c - 1].SubtractVector(tformvertices[c])
						iedge = tformvertices[c - 1].SubtractVector(vw)
					End If
					raydot = edge.DotProduct(iedge)
					If raydot >= 0 And raydot <= edge.DotProduct(edge)
						result.RayIntersection = intersect
						result.SurfaceNormal = normals[c]
						result.RayDistance = distance
						result.target = Self
						Return result
					End If
				End If
			End If
		Next
		
		result.Intersecting = False
		result.WillIntersect = False
		
		Return result
	
	End
	
	#Rem monkeydoc Draw this tlBox
		Use this if you need to draw the polygon for debugging purposes
		@param canvas The mojo canvas to draw with
		@param offsetx x amount of any offset
		@param offsety y amount of any offset
		@param boundingbox Set to true to also draw the bounding box
	#End
	Method Draw(canvas:Canvas, offsetx:Float = 0, offsety:Float = 0, boundingbox:Int = False) Override
		if(highlight) canvas.Color = New Color( 0, 255, 0 )
		Local v1:tlVector2 = tformvertices[tformvertices.Length - 1]
		Local v2:tlVector2
		For Local c:Int = 0 To tformvertices.Length - 1
			v2 = tformvertices[c]
			canvas.DrawLine(v1.x + world.x - offsetx, v1.y + world.y - offsety, v2.x + world.x - offsetx, v2.y + world.y - offsety)
			'canvas.DrawLine worldhandle.x, worldhandle.y, worldhandle.x + normals[c].x * 20, worldhandle.y + normals[c].y * 20
			v1 = v2
		Next
		If boundingbox Super.Draw(canvas, offsetx, offsety, boundingbox)
	End
	
	'internal stuff---------------------------------
	#Rem monkeydoc @hidden
	#End	
	Method TForm() Override
		'This transforms the polygon according to the current scale/angle. Both local and transformed vertices are stored within the type, which
		'while takes more memory, makes things a bit easier, and I think a bit faster. The memory overhead is extrremely low unless you have stupendously
		'complex polys!
		Local updateworldhandle:Int
		If handle.x Or handle.y
			updateworldhandle = True
			worldhandle = New tlVector2(0, 0)
		End If
		ResetBoundingBox()
		For Local i:Int = 0 To vertices.Length - 1
			tformvertices[i] = New tlVector2(scale.x * vertices[i].x + handle.x, scale.y * vertices[i].y + handle.y)
			tformvertices[i] = tformmatrix.TransformVector(tformvertices[i])
			UpdateBoundingBox(tformvertices[i].x, tformvertices[i].y)
			If updateworldhandle
				worldhandle.x+=tformvertices[i].x
				worldhandle.y+=tformvertices[i].y
			End If
		Next
		If updateworldhandle
			worldhandle.x/=tformvertices.Length
			worldhandle.y/=tformvertices.Length
			worldhandle = worldhandle.AddVector(world)
		End If
		UpdateNormals()
		UpdateDimensions()
		TFormBoundingBox()
	End
	
	#Rem monkeydoc @hidden
	#End	
	Method UpdateNormals() Override
		Local v1:tlVector2 = tformvertices[tformvertices.Length - 1]
		Local v2:tlVector2
		For Local c:Int = 0 To tformvertices.Length - 1
			v2 = tformvertices[c]
			normals[c] = New tlVector2(-(v2.y - v1.y), v2.x - v1.x)
			normals[c] = normals[c].Normalise()
			v1 = v2
		Next
	End
	
	#Rem monkeydoc @hidden
	#End	
	Method GetVoronoiAxis:tlVector2(point:tlVector2) Override
		
		Local v1:tlVector2 = tformvertices[tformvertices.Length - 1].AddVector(worldhandle)
		Local v2:tlVector2
		Local v3:tlVector2
		Local edge:tlVector2
		Local vc:tlVector2
		Local dot:Float
		
		For Local c:Int = 0 To tformvertices.Length - 1
			v2 = tformvertices[c].AddVector(world)
			edge = v2.SubtractVector(v1)
			vc = point.SubtractVector(v1)
			dot = vc.DotProduct(edge)
			If dot > edge.DotProduct(edge)
				If c + 1 < tformvertices.Length Then v3 = tformvertices[c + 1].AddVector(worldhandle) Else v3 = tformvertices[0].AddVector(worldhandle)
				edge = v3.SubtractVector(v2)
				vc = point.SubtractVector(v2)
				dot = edge.DotProduct(vc)
				If dot < 0
					vc = vc.Normalise()
					Return vc
				End If
			ElseIf dot < 0
				Select c
					Case 0
						v3 = tformvertices[tformvertices.Length - 2].AddVector(worldhandle)
					Case 1
						v3 = tformvertices[tformvertices.Length - 1].AddVector(worldhandle)
					Default
						v3 = tformvertices[c - 2].AddVector(worldhandle)
				End Select
				edge = v1.SubtractVector(v3)
				vc = point.SubtractVector(v3)
				dot = edge.DotProduct(vc)
				If dot > edge.DotProduct(edge)
					vc = vc.Normalise()
					Return vc
				End If
			Else
				If vc.DotProduct(edge.Normal()) > 0
					Return New tlVector2
				End If
			End If
			v1 = v2
		Next
		
		Return New tlVector2(0, 0, true)
		
	End
	
	#Rem monkeydoc @hidden
	#End	
	Method Project(axis:tlVector2, minv:float Ptr, maxv:float Ptr) Override
		'This projects the poly onto an axis and lets us know the min and max dotproduct values
		Local dotproduct:Float = axis.DotProduct(tformvertices[0])
		Cast<Float Ptr>(minv)[0] = dotproduct
		Cast<Float Ptr>(maxv)[0] = dotproduct
		For Local c:Int = 1 To tformvertices.Length - 1
			dotproduct = tformvertices[c].DotProduct(axis)
			If dotproduct < Cast<Float Ptr>(minv)[0]
				Cast<Float Ptr>(minv)[0] = dotproduct
			ElseIf dotproduct > Cast<Float Ptr>(maxv)[0]
				Cast<Float Ptr>(maxv)[0] = dotproduct
			End If
		Next
	End
	
End

#Rem monkeydoc Collision line class
#End
Class tlLine Extends tlPolygon
	
	#Rem monkeydoc [[tlBox]] Constructor
		@param x1 First x point of the line
		@param y1 First y point of the line
		@param x2 Second x point of the line
		@param y2 Second y point of the line
		@param layer The layer that the box is on, used for quadtrees
		@param data any [[Object]] associated with the box

	    @example
	    	Local box:=New tlLine(0, 0, 50, 100, 0)
	    @end
	#End
	Method New(x1:Float, y1:Float, x2:Float, y2:Float, layer:Int = 0, data:Object = Null)
		vertices = New tlVector2[2]
		tformvertices = New tlVector2[2]
		normals = New tlVector2[2]
		tl_corner = New tlVector2(0, 0)
		br_corner = New tlVector2(0, 0)
		vertices[0] = New tlVector2(0, 0)
		vertices[1] = New tlVector2(x2 - x1, y2 - y1)
		For Local c:Int = 0 To 1
			tformvertices[c] = New tlVector2(0, 0)
			normals[c] = New tlVector2(0, 0)
		Next
		handle = New tlVector2(vertices[1].x / 2, vertices[1].y / 2)
		For Local c:Int = 0 To vertices.Length - 1
			vertices[c] = vertices[c].SubtractVector(handle)
		Next
		world = New tlVector2(x1 + handle.x, y1 + handle.y)
		handle = New tlVector2(0, 0)
		worldhandle = world.AddVector(handle)
		collisiontype = tlLINE_COLLISION
		tformmatrix.Set(Cos(angle) * scale.x, Sin(angle) * scale.y, -Sin(angle) * scale.x, Cos(angle) * scale.y)
		TForm()
		collisionlayer = layer
		Self.data = data
		quadlist = New Stack<tlQuadTreeNode>
		quadlist.Reserve(5)
	End
	
	#Rem monkeydoc Check for a collision with a [[tlBox]]
		Use this to check for a collision with a [[tlBox]] that you pass to the method. You can then use the information stored in 
		[[tlCollisionResult]] to perform various things based on the result of the collision check.
		@param box The [[tlBox]] to check with
		@return [[tlCollisionResult]] type containing info about the collision
	#End
	Method BoxCollide:tlCollisionResult(Box:tlBox) Override
		Local result:tlCollisionResult = New tlCollisionResult

		If Not Super.BoundingBoxOverlap(Box, True)
			result.NoCollision = True
			Return result
		End If
		
		Local axis:tlVector2
		
		Local min0:Float
		Local max0:Float
		Local min1:Float
		Local max1:Float
		
		Local dotoffset:Float
		
		Local velocityoffset0:Float
		Local velocityoffset1:Float
		
		Local overlapdistance:Float
		Local veloverlapdistance:Float
		Local minoverlapdistance:Float = $7fffffff
		
		Local woffset:tlVector2 = New tlVector2(world.x - Box.world.x, world.y - Box.world.y)
		
		For Local c:Int = 0 To 3
		
			If c < 2
				axis = normals[c]
			Else
				axis = Box.normals[c - 1]
			End If
		
			Project(axis, Varptr(min0), Varptr(max0))
			Box.Project(axis, Varptr(min1), Varptr(max1))
			
			dotoffset = axis.DotProduct(woffset)
			
			min0+=dotoffset
			max0+=dotoffset
			
			overlapdistance = IntervalDistance(min0, max0, min1, max1)
			If overlapdistance > 0
				result.Intersecting = False
			End If
			
			If velocity.x Or velocity.y Or Box.velocity.x Or Box.velocity.y
				If velocity.x Or velocity.y
					velocityoffset0 = axis.DotProduct(velocity)
					min0+=velocityoffset0
					max0+=velocityoffset0
				End If
				If Box.velocity.x Or Box.velocity.y
					velocityoffset1 = axis.DotProduct(Box.velocity)
					min1+=velocityoffset1
					max1+=velocityoffset1
				End If
				veloverlapdistance = IntervalDistance(min0, max0, min1, max1)
				If veloverlapdistance > 0
					result.WillIntersect = False
				Else
					overlapdistance = veloverlapdistance
				End If
			Else
				result.WillIntersect = False
			End If
			
			If Not result.Intersecting And Not result.WillIntersect Return result
			
			overlapdistance = Abs(overlapdistance)
						
			If overlapdistance < minoverlapdistance
				minoverlapdistance = overlapdistance
				result.SurfaceNormal = axis.Clone()
				Local vec:tlVector2 = world.SubtractVector(Box.world)
				If vec.DotProduct(result.SurfaceNormal) < 0 result.SurfaceNormal = result.SurfaceNormal.Mirror()
			End If
			
		Next

		result.TranslationVector = result.SurfaceNormal.Scale(minoverlapdistance)
		result.source = Self
		result.target = Box
		Return result
	End
	
	#Rem monkeydoc Check for a collision with a [[tlCircle]]
		Use this to check for a collision with a [[tlCircle]] that you pass to the method. You can then use the information stored in 
		[[tlCollisionResult]] to perform various things based on the result of the collision check.
		@param circle The [[tlCircle]] to check with
		@return [[tlCollisionResult]] type containing info about the collision
	#End
	Method CircleCollide:tlCollisionResult(circle:tlCircle) Override
		Local result:tlCollisionResult = New tlCollisionResult

		If Not Super.BoundingBoxOverlap(circle, True)
			result.NoCollision = True
			Return result
		End If
		
		Local axis:tlVector2
		
		Local min0:Float
		Local max0:Float
		Local min1:Float
		Local max1:Float
		
		Local dotoffset:Float
		
		Local velocityoffset0:Float
		Local velocityoffset1:Float
		
		Local overlapdistance:Float
		Local veloverlapdistance:Float
		Local minoverlapdistance:Float = $7fffffff
		
		
		Local woffset:tlVector2 = New tlVector2(world.x - circle.world.x, world.y - circle.world.y)

		For Local c:Int = 0 To 2
		
			If c = 2
				axis = GetVoronoiAxis(circle.world)
				If axis.Invalid Exit
				
				Project(axis, Varptr(min0), Varptr(max0))
				circle.Project(axis, Varptr(min1), Varptr(max1))
			Else
				axis = normals[c]
	
				Project(axis, Varptr(min0), Varptr(max0))
				circle.Project(axis, Varptr(min1), Varptr(max1))
			End If
			
			dotoffset = axis.DotProduct(woffset)
			
			min0+=dotoffset
			max0+=dotoffset
			
			overlapdistance = IntervalDistance(min0, max0, min1, max1)
			If overlapdistance > 0
				result.Intersecting = False
			End If
			
			If velocity.x Or velocity.y Or circle.velocity.x Or circle.velocity.y
				If velocity.x Or velocity.y
					velocityoffset0 = axis.DotProduct(velocity)
					min0+=velocityoffset0
					max0+=velocityoffset0
				End If
				If circle.velocity.x Or circle.velocity.y
					velocityoffset1 = axis.DotProduct(circle.velocity)
					min1+=velocityoffset1
					max1+=velocityoffset1
				End If
				veloverlapdistance = IntervalDistance(min0, max0, min1, max1)
				If veloverlapdistance > 0
					result.WillIntersect = False
				Else
					overlapdistance = veloverlapdistance
				End If
			Else
				result.WillIntersect = False
			End If
			
			If Not result.Intersecting And Not result.WillIntersect Return result
			
			overlapdistance = Abs(overlapdistance)
						
			If overlapdistance < minoverlapdistance
				minoverlapdistance = overlapdistance
				result.SurfaceNormal = axis.Clone()
				Local polytocirclevec:tlVector2 = worldhandle.SubtractVector(circle.worldhandle)
				If polytocirclevec.DotProduct(result.SurfaceNormal) < 0 result.SurfaceNormal = result.SurfaceNormal.Mirror()
			End If
			
		Next
		
		result.TranslationVector = result.SurfaceNormal.Scale(minoverlapdistance)
		result.source = Self
		result.target = circle
		Return result
	End
	
	#Rem monkeydoc Check for a collision with a [[tlLine]]
		Use this to check for a collision with a [[tlLine]] that you pass to the method. You can then use the information stored in 
		[[tlCollisionResult]] to perform various things based on the result of the collision check.
		@param line The [[tlLine]] to check with
		@return [[tlCollisionResult]] type containing info about the collision
	#End
	Method LineCollide:tlCollisionResult(line:tlLine) Override
		Local result:tlCollisionResult = New tlCollisionResult

		If Not Super.BoundingBoxOverlap(line, True)
			result.NoCollision = True
			Return result
		End If
		
		Local axis:tlVector2
		
		Local min0:Float
		Local max0:Float
		Local min1:Float
		Local max1:Float
		
		Local dotoffset:Float
		
		Local velocityoffset0:Float
		Local velocityoffset1:Float
		
		Local overlapdistance:Float
		Local veloverlapdistance:Float
		Local minoverlapdistance:Float = $7fffffff
		
		
		Local woffset:tlVector2 = New tlVector2(world.x - line.world.x, world.y - line.world.y)

		For Local c:Int = 0 To 3
		
			If c < 2
				axis = normals[c]
			Else
				axis = line.normals[c - 2]
			End If
		
			Project(axis, Varptr(min0), Varptr(max0))
			line.Project(axis, Varptr(min1), Varptr(max1))
			
			dotoffset = axis.DotProduct(woffset)
			
			min0+=dotoffset
			max0+=dotoffset
			
			overlapdistance = IntervalDistance(min0, max0, min1, max1)
			If overlapdistance > 0
				result.Intersecting = False
			End If
			
			If velocity.x Or velocity.y Or line.velocity.x Or line.velocity.y
				If velocity.x Or velocity.y
					velocityoffset0 = axis.DotProduct(velocity)
					min0+=velocityoffset0
					max0+=velocityoffset0
				End If
				If line.velocity.x Or line.velocity.y
					velocityoffset1 = axis.DotProduct(line.velocity)
					min1+=velocityoffset1
					max1+=velocityoffset1
				End If
				veloverlapdistance = IntervalDistance(min0, max0, min1, max1)
				If veloverlapdistance > 0
					result.WillIntersect = False
				Else
					overlapdistance = veloverlapdistance
				End If
			Else
				result.WillIntersect = False
			End If
			
			If Not result.Intersecting And Not result.WillIntersect Return result
			
			overlapdistance = Abs(overlapdistance)
						
			If overlapdistance < minoverlapdistance
				minoverlapdistance = overlapdistance
				result.SurfaceNormal = axis.Clone()
				Local polytopolyvec:tlVector2 = worldhandle.SubtractVector(line.worldhandle)
				If polytopolyvec.DotProduct(result.SurfaceNormal) < 0 result.SurfaceNormal = result.SurfaceNormal.Mirror()
			End If
			
		Next
		
		result.TranslationVector = result.SurfaceNormal.Scale(minoverlapdistance)
		result.source = Self
		result.target = line
		Return result
	End
	
	#Rem monkeydoc Check for a collision with a [[tlPolygon]]
		Use this to check for a collision with a [[tlPolygon]] that you pass to the method. You can then use the information stored in 
		[[tlCollisionResult]] to perform various things based on the result of the collision check.
		@param poly The [[tlPolygon]] to check with
		@return [[tlCollisionResult]] type containing info about the collision
	#End
	Method PolyCollide:tlCollisionResult(poly:tlPolygon) Override
		Local result:tlCollisionResult = New tlCollisionResult

		If Not Super.BoundingBoxOverlap(poly, True)
			result.NoCollision = True
			Return result
		End If
		
		Local axis:tlVector2
		
		Local min0:Float
		Local max0:Float
		Local min1:Float
		Local max1:Float
		
		Local dotoffset:Float
		
		Local velocityoffset0:Float
		Local velocityoffset1:Float
		
		Local overlapdistance:Float
		Local veloverlapdistance:Float
		Local minoverlapdistance:Float = $7fffffff
		
		
		Local woffset:tlVector2 = New tlVector2(world.x - poly.world.x, world.y - poly.world.y)

		For Local c:Int = 0 To 2 + poly.vertices.Length - 1
		
			If c < 2
				axis = normals[c]
			Else
				axis = poly.normals[c - 2]
			End If
		
			Project(axis, Varptr(min0), Varptr(max0))
			poly.Project(axis, Varptr(min1), Varptr(max1))
			
			dotoffset = axis.DotProduct(woffset)
			
			min0+=dotoffset
			max0+=dotoffset
			
			overlapdistance = IntervalDistance(min0, max0, min1, max1)
			If overlapdistance > 0
				result.Intersecting = False
			End If
			
			If velocity.x Or velocity.y Or poly.velocity.x Or poly.velocity.y
				If velocity.x Or velocity.y
					velocityoffset0 = axis.DotProduct(velocity)
					min0+=velocityoffset0
					max0 += velocityoffset0
				End If
				If poly.velocity.x Or poly.velocity.y
					velocityoffset1 = axis.DotProduct(poly.velocity)
					min1+=velocityoffset1
					max1+=velocityoffset1
				End If
				veloverlapdistance = IntervalDistance(min0, max0, min1, max1)
				If veloverlapdistance > 0
					result.WillIntersect = False
				Else
					overlapdistance = veloverlapdistance
				End If
			Else
				result.WillIntersect = False
			End If
			
			If Not result.Intersecting And Not result.WillIntersect Return result
			
			overlapdistance = Abs(overlapdistance)
						
			If overlapdistance < minoverlapdistance
				minoverlapdistance = overlapdistance
				result.SurfaceNormal = axis.Clone()
				Local polytopolyvec:tlVector2 = worldhandle.SubtractVector(poly.worldhandle)
				If polytopolyvec.DotProduct(result.SurfaceNormal) < 0 result.SurfaceNormal = result.SurfaceNormal.Mirror()
			End If
			
		Next
		
		result.TranslationVector = result.SurfaceNormal.Scale(minoverlapdistance)
		result.source = Self
		result.target = poly
		Return result
	End
	
	#Rem monkeydoc See is a ray collides with this [[tlLine]]
		Returns [[tlCollisionResult]] with the results of the collision
		You can use this to test for a collision with a ray. Pass the origin of the ray with px and py, and set the direction of the ray with dx and dy.
		dx and dy will be normalised and extended infinitely, if maxdistance equals 0 (default), otherwise set maxdistance to how ever far you want the ray 
		to extend to.
		@param px x origin of the ray
		@param py y origin of the ray
		@param dx x direction of the ray
		@param dy y direction of the ray
		@param maxdistance maximum distance of the ray, or 0 for inifinate
		@return [[tlCollisionResult]] type containing info about the collision
	#End
	Method RayCollide:tlCollisionResult(px:Float, py:Float, dx:Float, dy:Float, maxdistance:Float = 0) Override
		
		Local result:tlCollisionResult = New tlCollisionResult
		
		Local p:tlVector2 = New tlVector2(px, py)
		Local d:tlVector2 = New tlVector2(dx, dy)
		
		Local raydot:Float
		Local edge:tlVector2
		Local iedge:tlVector2
		
		Local vw:tlVector2
		Local intersect:tlVector2
		Local distance:Float
		
		d = d.Normalise()
		
		For Local c:Int = 0 To 1
			raydot = d.DotProduct(normals[c])
			If raydot < 0 And p.SubtractVector(tformvertices[c].AddVector(world)).DotProduct(normals[c]) > 0
				vw = tformvertices[c].AddVector(world)
				distance = normals[c].DotProduct(p.SubtractVector(vw))
				distance = Abs(distance / raydot)
				If (maxdistance > 0 And distance <= maxdistance) Or maxdistance = 0
					intersect = d.Scale(distance).AddVector(p)
					vw = intersect.SubtractVector(world)
					If c = 0
						edge = tformvertices[1].SubtractVector(tformvertices[0])
						iedge = tformvertices[1].SubtractVector(vw)
					Else
						edge = tformvertices[0].SubtractVector(tformvertices[1])
						iedge = tformvertices[0].SubtractVector(vw)
					End If
					raydot = edge.DotProduct(iedge)
					If raydot >= 0 And raydot <= edge.DotProduct(edge)
						result.RayIntersection = intersect
						result.SurfaceNormal = normals[c]
						result.RayDistance = distance
						result.target = Self
						Return result
					End If
				End If
			End If
		Next
		
		result.Intersecting = False
		result.WillIntersect = False
		
		Return result
	
	End
	
	'internal stuff---------------------------------
	#Rem monkeydoc @hidden
	#End
	Method GetVoronoiAxis:tlVector2(point:tlVector2) Override
		
		Local edge:tlVector2
		Local vc:tlVector2
		Local dot:Float
		
		point = point.SubtractVector(worldhandle)
		
		edge = tformvertices[1].SubtractVector(tformvertices[0])
		vc = point.SubtractVector(tformvertices[0])
		dot = vc.DotProduct(edge)
		
		If dot > edge.DotProduct(edge)
			vc = point.SubtractVector(tformvertices[1])
			vc = vc.Normalise()
			Return vc
		ElseIf dot < 0
			vc = vc.Normalise()
			Return vc
		Else
			Return New tlVector2(0, 0, true)
		End If
		
		Return New tlVector2(0, 0, true)
		
	End
	
	#Rem monkeydoc @hidden
	#End
	Method TForm() Override
		'This transforms the line according to the current scale/angle. Both local and transformed vertices are stored within the type, which
		'while takes more memory, makes things a bit easier, and I think a bit faster!
		ResetBoundingBox()
		tformvertices[0] = New tlVector2(scale.x * vertices[0].x + handle.x, scale.x * vertices[0].y + handle.y)
		tformvertices[0] = tformmatrix.TransformVector(tformvertices[0])
		UpdateBoundingBox(tformvertices[0].x, tformvertices[0].y)
		tformvertices[1] = New tlVector2(scale.x * vertices[1].x + handle.x, scale.x * vertices[1].y + handle.y)
		tformvertices[1] = tformmatrix.TransformVector(tformvertices[1])
		UpdateBoundingBox(tformvertices[1].x, tformvertices[1].y)
		If handle.x Or handle.y
			worldhandle.x = (tformvertices[0].x + tformvertices[1].x) / 2
			worldhandle.y = (tformvertices[0].y + tformvertices[1].y) / 2
			worldhandle = worldhandle.AddVector(world)
		End If
		UpdateNormals()
		UpdateDimensions()
		TFormBoundingBox()
	End
	
	#Rem monkeydoc @hidden
	#End
	Method UpdateNormals() Override
		normals[0] = New tlVector2(-(tformvertices[1].y - tformvertices[0].y), tformvertices[1].x - tformvertices[0].x)
		normals[1] = New tlVector2(-(tformvertices[0].y - tformvertices[1].y), tformvertices[0].x - tformvertices[1].x)
		normals[0] = normals[0].Normalise()
		normals[1] = normals[1].Normalise()
	End
	
	#Rem monkeydoc @hidden
	#End
	Method Project(axis:tlVector2, minv:Float Ptr, maxv:Float Ptr) Override
		'This projects the line onto an axis and lets us know the min and max dotproduct values
		Local dotproduct:Float = axis.DotProduct(tformvertices[0])
		Cast<Float Ptr>(minv)[0] = dotproduct
		Cast<Float Ptr>(maxv)[0] = dotproduct
		dotproduct = tformvertices[1].DotProduct(axis)
		If dotproduct < Cast<Float Ptr>(minv)[0]
			Cast<Float Ptr>(minv)[0] = dotproduct
		ElseIf dotproduct > Cast<Float Ptr>(maxv)[0]
			Cast<Float Ptr>(maxv)[0] = dotproduct
		End If
	End

End



'Helper Functions
#Rem monkeydoc See if a ray collides with a boundary
	You can use this to test for a collision with a ray and any type of boundary: [[tlBox]], [[tlCircle]], [[tlLine]] and [[tlPolygon]]. 
	Pass the origin of the ray with px and py, and set the direction of the raycast with dx and dy vector. dx and dy will be normalised and extended 
	infinitely if maxdistance equals 0 (default), otherwise set maxdistance to how ever far you want the ray to extend to before stopping. If the ray starts 
	inside the poly then result.RayOriginInside will be set to true. You can find the angle of reflection to bounce the ray using [[ReboundVector]]. 
	@param target [[tlBox]] you're checking against
	@param px x origin of the ray
	@param py y origin of the ray
	@param dx x direction of the ray
	@param dy y direction of the ray
	@param maxdistance maximum distance of the ray, or 0 for inifinate
	@return [[tlCollisionResult]] with the results of the collision
#End
Function CheckRayCollision:tlCollisionResult(target:tlBox, px:Float, py:Float, dx:Float, dy:Float, maxdistance:Float = 0)
	
	Return target.RayCollide(px, py, dx, dy, maxdistance)

End Function

#Rem monkeydoc Do a Line to Circle collision check
	Returns True if line and circle overlap
	x1, y1 and x2, y2 represent the beginning and end line coordinates, and px, py and r represent the circle coordinates and radius. 
	@param x1 First x point of the line
	@param y1 First y point of the line
	@param x2 Second x point of the line
	@param y2 Second y point of the line
	@param px x coordinate of the circle
	@param py y coordinate of the circle
	@param r Radius of the circle
	@return True if the line and circle overlap
#End
Function LineToCircle:Int(x1:Float, y1:Float, x2:Float, y2:Float, px:Float, py:Float, r:Float)
	
	Local sx:Float = x2-x1
	Local sy:Float = y2-y1
	
	Local q:Float = ((px-x1) * (x2-x1) + (py - y1) * (y2-y1)) / (sx*sx + sy*sy)
	
	If q < 0.0 Then q = 0.0
	If q > 1.0 Then q = 1.0
	
	Local cx:Float = (1 - q) * x1 + q * x2
	Local cy:Float = (1 - q) * y1 + q * y2
	
	If GetDistance(px, py, cx, cy) < r
		Return True
	End IF
	
	Return False
	
End Function

#Rem monkeydoc Do a Line to Line collision check
	@param x0 First x point of the first line
	@param y0 First y point of the first line
	@param x1 Second x point of the first line
	@param y1 Second y point of the first line
	@param x2 First x point of the second line
	@param y2 First y point of the second line
	@param x3 Second x point of the second line
	@param y3 Second y point of the second line
	@return True if lines overlap
#End
Function LinesCross:Int(x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float)
	  
	Local n:Float=(y0-y2)*(x3-x2)-(x0-x2)*(y3-y2)
	Local d:Float=(x1-x0)*(y3-y2)-(y1-y0)*(x3-x2)
	
	If Abs(d) < 0.0001
		Return False
	Else
		Local Sn:Float = (y0 - y2) * (x1 - x0) - (x0 - x2) * (y1 - y0)
		Local AB:Float=n/d
		If AB>0.0 And AB<1.0
			Local CD:Float=Sn/d
			If CD > 0.0 And CD < 1.0 Return True
		End If
	EndIf
	
	Return False

End Function

#Rem monkeydoc @hidden
#End
Function GetQuad:Int(axis_x:Float, axis_y:Float, vert_x:Float, vert_y:Float)
	If vert_x<axis_x
		If vert_y<axis_y
			Return 1
		Else
			Return 4
		EndIf
	Else
		If vert_y<axis_y
			Return 2
		Else
			Return 3
		EndIf	
	EndIf
	Return 0
End Function

#Rem monkeydoc Check if a point is with a field of view
	@param observerx x coordinate of the observer
	@param observery y coordinate of the observer
	@param fov The field of view in degrees
	@param direction The direction in degrees the obverser is looking in
	@param pointx x coordinate of the point being checked
	@param pointy y coordinate of the point being checked
	@return True if if point is withing observers fov, otherwise false
#End
Function WithinFieldOfView:Int(observerx:Float, observery:Float, fov:Float, direction:Float, pointx:Float, pointy:Float)
	Return (AngleDifference(GetDirection(observerx, observery, pointx, pointy), direction) <= fov *.5)
End Function

#Rem monkeydoc Return the nearest point on a line to the center of a circle
	Returns NearestPoint_x and NearestPoint_y
	x1, y1 and x2, y2 represent the beginning and end line coordinates, and px, py and r represent the circle coordinates and radius. 
	@param x1 First x point of the line
	@param y1 First y point of the line
	@param x2 Second x point of the line
	@param y2 Second y point of the line
	@param px x coordinate of the circle
	@param py y coordinate of the circle
	@param r Radius of the circle
	@return array of x/y coordinate of nearest point
#End
Function NearestPointToCircle:Float[](x1:Float, y1:Float, x2:Float, y2:Float, px:Float, py:Float, r:Float)
	
	Local sx:Float = x2-x1
	Local sy:Float = y2-y1

	local points:=New float[2]
	
	Local q:Float = ((px-x1) * (x2-x1) + (py - y1) * (y2-y1)) / (sx*sx + sy*sy)
	
	If q < 0.0 Then q = 0.0
	If q > 1.0 Then q = 1.0
	
	points[0] = (1 - q) * x1 + q * x2
	points[1] = (1 - q) * y1 + q * y2

	return points
	
End Function

#Rem monkeydoc @hidden
#End
Function IntervalDistance:Float(min0:Float, max0:Float, min1:Float, max1:Float)
	If min0 < min1
		Return min1 - max0
	End If
	
	Return min0 - max1
End Function

#Rem monkeydoc Create a new tlBox
	Creates a new Bounding box that you can use for collision checking and adding to a [[tlQuadTree]]. Use layer to specify a particular layer
	to place the box on so that you can more easily organise your collisions. You use 0, 1..and so on up to 31.
	to place the boundary on all layers.
	@param x Top left y coordinate
	@param y Top Left x coordinate
	@param w Width of the box
	@param h Height of the box
	@param layer The layer that the box is on, used for quadtrees
	@param data any [[Object]] associated with the box
	@return tlBox

    @example
    	Local box:=CreateBox(100, 100, 50, 50, 0)
    @end
#End
Function CreateBox:tlBox(x:Float, y:Float, w:Float, h:Float, layer:Int = 0, data:object = null)
	Return New tlBox(x, y, w, h, layer, data)
End Function

#Rem monkeydoc Create a [[tlLine]]
	Create a new [[tlLine]] at the coordinates given, x1 and y1 being the start of the line and x2 and y2 being the end. The will placed exactly
	according to the coordinates you give, but it's worth bearing in mind that the handle of the line will be at the center point along the line. Therefore
	the world coordinates will be set to half way point along the line. Use layer to specify a particular layer
	to place the box on so that you can more easily organise your collisions. You use 0, 1..and so on up to 31.
	to place the boundary on all layers.
	@param x1 First x point of the line
	@param y1 First y point of the line
	@param x2 Second x point of the line
	@param y2 Second y point of the line
	@param layer The layer that the box is on, used for quadtrees
	@param data any [[Object]] associated with the box
	@return tlLine

    @example
    	Local box:=CreateLine(0, 0, 50, 100, 0)
    @end
#End
Function CreateLine:tlLine(x1:Float, y1:Float, x2:Float, y2:Float, layer:Int = 0, data:Object = null)
	Return New tlLine(x1, y1, x2, y2, layer, data)
End Function

#Rem monkeydoc Create a [[tlCircle]]
	Returns New [[tlLine]]
	Create a new [[tlCircle]] at the given coordinates with the given radius. The coordinates will represent the center of the circle. Use layer to specify a particular layer
	to place the box on so that you can more easily organise your collisions. You use 0, 1..and so on up to 31.
	to place the boundary on all layers.
	@param x Top left y coordinate
	@param y Top Left x coordinate
	@param radius Radius of the circle
	@param layer The layer that the circle is on, used for quadtrees
	@param data any [[Object]] associated with the box

    @example
    	Local box:=CreateCircle(100, 100, 50, 0)
    @end
#End
Function CreateCircle:tlCircle(x:Float, y:Float, radius:Float, layer:Int = 0, data:Object = null)
	Return New tlCircle(x, y, radius, layer, data)
End Function

#Rem monkeydoc Create a [[tlPolygon]]
	Returns New [[tlPolygon]], or Null if verts[] contained the wrong amount.
	Create a new [[tlPolygon]] at the given coordinates with the given array of vertices. The coordinates will represent the center of the polygon which is
	automatically calculated. The array must contain more then 5 values (2 per vertex) and be an even number or null will be returned. The coordinates of
	the vertices in the array are arranged like so: [x,y,x,y,x,y .. etc]. Use layer to specify a particular layer
	to place the box on so that you can more easily organise your collisions. You use 0, 1, 2..and so on up to 31
	to place the boundary on all layers.

    | `Note:` |
    |:-----------|
    | Polygon must be convex (no internal angles > 180deg)

	@param x Top left y coordinate
	@param y Top Left x coordinate
	@param verts Array of vertices that descibe the Polygon
	@param layer The layer that the box is on, used for quadtrees
	@param data any [[Object]] associated with the box

    @example
    	Local box:=CreatePolygon(100, 100, new Float[](- 10.0, -10.0, -15.0, 0.0, -10.0, 10.0, 10.0, 10.0, 15.0, 0.0, 10.0, -10.0), 0)
    @end
#End
Function CreatePolygon:tlPolygon(x:Float, y:Float, verts:Float[], layer:Int = 0, data:Object = null)
	Return New tlPolygon(x, y, verts, layer, data)
End Function

#Rem monkeydoc Check for a collision between 2 Boundaries
	You can use this function to check for collisions between any type of boundary: [[tlBox]], [[tlCircle]], [[tlLine]] and [[tlPolygon]]. The [[tlCollisionResult]]
	can then be used to determine what you want to do if a collision happened (or will happen). See [[PreventOverlap]] to make boundaries block or push
	each other.
	@param source [[tlBox]] object
	@param target [[tlBox]] object
	@return [[tlCollisionResult]]
#End
Function CheckCollision:tlCollisionResult(source:tlBox, target:tlBox)
	Select source.CollisionType
		Case tlBOX_COLLISION
			Select target.CollisionType
				Case tlBOX_COLLISION
					Return source.BoxCollide(target)
				Case tlCIRCLE_COLLISION
					Return source.CircleCollide(Cast<tlCircle>(target))
				Case tlPOLY_COLLISION
					Return source.PolyCollide(Cast<tlPolygon>(target))
				Case tlLINE_COLLISION
					Return source.LineCollide(Cast<tlLine>(target))
			End Select
		Case tlCIRCLE_COLLISION
			Select target.CollisionType
				Case tlBOX_COLLISION
					Return Cast<tlCircle>(source).BoxCollide(target)
				Case tlCIRCLE_COLLISION
					Return Cast<tlCircle>(source).CircleCollide(Cast<tlCircle>(target))
				Case tlPOLY_COLLISION
					Return Cast<tlCircle>(source).PolyCollide(Cast<tlPolygon>(target))
				Case tlLINE_COLLISION
					Return Cast<tlCircle>(source).LineCollide(Cast<tlLine>(target))
			End Select
		Case tlPOLY_COLLISION
			Select target.CollisionType
				Case tlBOX_COLLISION
					Return Cast<tlPolygon>(source).BoxCollide(target)
				Case tlCIRCLE_COLLISION
					Return Cast<tlPolygon>(source).CircleCollide(Cast<tlCircle>(target))
				Case tlPOLY_COLLISION
					Return Cast<tlPolygon>(source).PolyCollide(Cast<tlPolygon>(target))
				Case tlLINE_COLLISION
					Return Cast<tlPolygon>(source).LineCollide(Cast<tlLine>(target))
			End Select
		Case tlLINE_COLLISION
			Select target.CollisionType
				Case tlBOX_COLLISION
					Return Cast<tlLine>(source).BoxCollide(target)
				Case tlCIRCLE_COLLISION
					Return Cast<tlLine>(source).CircleCollide(Cast<tlCircle>(target))
				Case tlPOLY_COLLISION
					Return Cast<tlLine>(source).PolyCollide(Cast<tlPolygon>(target))
				Case tlLINE_COLLISION
					Return Cast<tlLine>(source).LineCollide(Cast<tlLine>(target))
			End Select
	End Select

	Return null
End Function

#Rem monkeydoc Prevent boundaries from overlapping, based on a [[tlCollisionResult]]
	After you have retrieved a [[tlCollisionResult]] from calling [[CheckCollision]] you can call this function to separate 2 boundaries from each other.
	If push is false (default) then the source boundary will be stopped by the target boundary, otherwsie the source bouandry will push the target boundary
	along it's veloctity vector and the normal of the edge it's pushing against.

	| `Note:` |
    |:-----------| 
    |Remember that after an overlap has been been prevented, the coordinates of the boundary wil have change in order to separate it from the other	boundary, so remember to update any other objects coordinates to match this (such as your game object). If your game object is dictating where the boundary is located then it might inadvertantly place the bouandary back inside the object it's colliding with causing strange things to happen.
	
	@param result _tlCollisionResult with the source and target that you want to prevent a n overlap on
	@param push False (default) if you want the source object stopped by the target, otherwise set to true for the source object to push the target object.
#End
Function PreventOverlap(result:tlCollisionResult, push:Int = False)
	If not result.NoCollision
		If result.source
			result.source.PreventOverlap(result, push)
		End If
	End If
End Function