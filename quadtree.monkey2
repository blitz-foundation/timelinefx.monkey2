#Rem
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

#End
Namespace timelinefx

Using timelinefx..
Using std.collections..
Using std.random..

#Rem monkeydoc @hidden
#End
Const MAX_NODE_LEVELS:Int = 1
#Rem monkeydoc @hidden
#End
Const MAX_PER_NODE:Int = 2

#Rem monkeydoc Quadtree type for managing a quadtree
	Rather then go on about what a quadtree is, here's some useful resources I used myself to find out about them:
	[[http://en.wikipedia.org/wiki/Quadtree]], [[http://www.kyleschouviller.com/wsuxna/quadtree-source-included/ and http://www.heroicvirtuecreations.com/QuadTree.html]]

	Quadtrees vary with each implementation based on the users needs. I've tried to be flexible here with a emphasis on handling objects that will
	move about a lot. If an object moves within a quadtree then it will generally have to be re-added to the quadtree, so I've implemented that possibility here.
	Thankfully there's no need to rebuild the quadtree every time an object moves, the object just removes and adds itself back to the tree, and it will only do it if
	it's moved outside of its containing [[tlQuadTreeNode]].

	When I say object, I mean a [[tlBox]], which is a simple axis aligned bounding box type that can be added to the quadtree, the more complex [[tlCircle]], [[tlLine]] and
	[[tlPolygon]] which extend [[tlBox]] can also be added, but the quadtree will only concern itself with bounding boxes when a query is made on the
	quadtree.

	Using the quadtree is simple enough, create a new quadtree with whatever dimensions you want and then use [[tlQuadTree.AddBox]] to add bounding boxes to it. In
	your main loop you might want to put [[RunQuadtreeMaintenance]] which tidies up the quadtree by finding empty partitions and deleting them. Of course
	the whole point of a quadtree is to find out which objects are within a particular area so that you can do collision checking, rendering, updating or whatever. To do that,
	you can query the quadtree by simply calling either [[tlQuadTree.ForEachObjectInArea]] or [[tlQuadTree.ForEachObjectInBox]] which will run a callback function of your choice to perform your
	specific tasks on them. There's also queries available to check for objects within a radius by using, [[tlQuadTree.ForEachObjectInRange]] and [[tlQuadTree.ForEachObjectInCircle]], and also
	for lines and rays using [[tlQuadTree.ForEachObjectAlongLine]] and [[tlQuadTree.RayCast]].

	Implementing this quadtree within your game will probably involve including [[tlBox]], [[tlCircle]], [[tlLine]] or [[tlPolygon]] as a field within your entity/actor etc types.
	When your actors move about, just make sure you update the position of the Box as well using [[tlBox.Position]] or [[tlBox.Move]]. When this happens all the necessary updating
	of the quadtree will happen automatically behind the scenes. Be aware that if an object moves outside of the quadtree bounds it will drop out of the quadtree.

	## FAQ:

	##### What happens when a object overlaps more then one quadtreenode?

	The object is added to each node it overlaps. No object will ever be added to a node that has children, they will be moved down the quadtree to the bottom level of that branch.

	##### What happens when an object is found more then once because it is contained within more than 1 node?

	tlBoxs are aware if they have already been found and a callback has been made within the same search, so a callback will never be made twice on
	the same search query.

	##### What happens if a node no longer contains more then the maximium allowed for a node, are it's objects moved back up the tree?

	No, onced a node is partioned and objects moved down, they're there to stay, however if you [[RunQuadtreeMaintenance]] then empty nodes will be unpartitioned. I
	didn't think it was worth the overhead to worry about moving objects back up the tree again.

	##### What collision checking is done when calling, for example, [[tlQuadTree.ForEachObjectInArea]]?

	The quadtree will just concern itself with doing callbacks on objects it finds with rect->rect collision in the case of _QueryQuadtreeArea_, and circle->rect
	collision in the case of [[tlQuadTree.ForEachObjectInRange]]. Once you've found those objects you can then go on and do more complex collision checking such as poly->poly. If
	however you only need to check for rect->rect then you can assume a hit straight away as the quadtree will only callback actual hits, potential hits are
	already excluded automatically if their bounding box is outside the area being queried.

	##### What are potential hits?

	A potential hit would be an object in the same quadtree node that the area check overlaps. So if the area you're checking a collision for overlaps
	2 quadnodes, all the objects in those 2 nodes would be considered potential hits. I decided that I may aswell cull any of those bounding boxes that
	don't overlap the area being checked before doing the callback so that the amount of potential hits is reduced further, and to save wasting the time doing it in the callback function.
	This applies to both [[tlQuadTree.ForEachObjectInArea]] and [[tlQuadTree.ForEachObjectInRange]] functions, but as mentioned before, it will only cull according to bounding boxes, you'll have
	to do a further check in your callback to manage the more complex poly->poly, poly->rect etc., collisions.

	##### If I have to use a callback function, how can I do stuff with an object without resorting to globals?

	When you run a [[QueryQuadtreeArea]] (of any type) you can pass an object that will be passed through to the callback function. So the call back function
	you create should look like: `Function MyCallBackFunction(ObjectFoundInQuadtree:Object, MyData:object)` So your data could be anything such as a bullet
	or pLayer ship etc., and assuming that object has a tlBox field you can do further collision checks between the 2. If you don't need to pass any
	data then just leave it null.

	##### How do I know what kind of tlBox has been passed back from from the quadtree?

	Boxes have a field called collisiontype which you can find out using the property [[timelinefx.tlBox.CollisionType]]. This will return either [[tlBOX_COLLISION]],
	[[tlCIRCLE_COLLISION]], [[tlPOLY_COLLISION]] or [[tlLINE_COLLISION]]. The chances are though, that you won't need to know the type, as a call to [[CheckCollision]]
	will automatically determine the type and perform the appropriate collision check.

	##### Can I have more then one quadtree

	Yes you can create as many quadtrees as you want, however, bear in mind that a [[tlBox]] can only ever exist in 1 quadtree at a time. In most cases, with
	the use of Layers, 1 quadtree will probably be enough.

	##### How do the Layers work?

	You can put boxes onto different Layers of the quadtree to help organise your collisions and optimise too. Each Layer has it's own separate quadtree
	which can be defined according to how you need it to be optimised. See [[SetLayerConfig]]. So you could put a load of enemy objects onto one Layer
	and the pLayer objects onto another. This will speed things up when an enemy might have to query the quadtree to see if the pLayer is nearby because
	the Layer that the pLayer is on won't be so cluttered with other objects. If you need to check for collisions between many objects vs many other objects,
	then you should try to put those objects onto the same Layer. This way when each object checks for a collision with an object on the same Layer it
	can skip having to query the quadtree, because each tlbox already knows what quadtree nodes it exists in, so it can check against other objects in the same
	node straight away without having to drill down into the quadtree each time.

	@example

	#Import "<mojo>"
	#Import "<std>"
	'Import the TimelineFX Module
	#Import "<timelinefx>"

	'We need the following namespaces 
	Using std..
	Using mojo..
	Using timelinefx..

	Class Game Extends Window

		'Field to store the quadtree
		Field QTree:tlQuadTree
		
		'field for our box that will used to query the quad tree
		Field player:tlBox
		
		'A Field to store the canvas
		Field currentCanvas:Canvas

		Method New()
			'create the quadtree and make it the same size as the window. Here we're making it so that the maximum number of times it can
			'be subdivided is 5, and it will sub divide a when 10 objects are added to a quad. These numbers you can change To tweak performance
			'It will vary depending on how you use the quadtree
			QTree = New tlQuadTree(0, 0, Width, Height, 5, 10) 
			
			'Populate the quadtree with a bunch of objects
			For Local c:Int = 1 To 1000
				Local t:Int = Rnd(3)
				Local rect:tlBox
				Local x:Float = Rnd() * Width 
				Local y:Float = Rnd() * Height
				Select t
					Case 0
						'Create a Basic bounding box boundary
						rect = New tlBox(x, y, 10, 10, 0)
					Case 1
						'Create a circle Boundary
						rect = New tlCircle(x, y, 5, 0)
					Case 2
						'Create a polygon boundary
						Local verts:= New Float[](- 10.0, -10.0, -15.0, 0.0, -10.0, 10.0, 10.0, 10.0, 15.0, 0.0, 10.0, -10.0)
						rect = New tlPolygon(x, y, verts, 0)
				End Select
				'Add the boundary to the quadtree
				QTree.AddBox(rect)
			Next
			
			player = New tlBox(0, 0, 50, 50)
		End
		
		Method OnRender( canvas:Canvas ) Override
		
			currentCanvas = canvas
		
			App.RequestRender()
		
			canvas.Clear( New Color(0,0,0,1) )
				
			canvas.BlendMode = BlendMode.Alpha
			
			'position the player box
			player.Position(Mouse.X, Mouse.Y)
			Local time:=App.Millisecs
			'when space is pressed, draw everything on the screen. We do this by calling "ForEachObjectInArea", and define the area as the screen size. We also
			'pass the DrawScreen interface which will be called by the quadtree if it finds something in the are. We also pass the layers that we want to check.
			If Keyboard.KeyDown(Key.Space) QTree.ForEachObjectInArea(0, 0, Width, Height, Self, DrawScreenCallBack, New Int[](0, 1, 2))
			
			'Check for objects within a box using "ForEachObjectWithinBox", passing our player box. We also pass the player as "Data" which is forwarded on to the
			'DrawBoxAction so we can use it to find out if it is actually colliding with anything. We pass the DrawBoxAction interface
			'we created which will be called when the qaudtree finds something within the bounding box of the object. We also pass the layers that we want to check.
			QTree.ForEachObjectInBox(player, self, DrawBoxCallBack, New Int[](0, 1, 2))
			
			'Draw the player box
			player.Draw(canvas)
			time = App.Millisecs - time
			
			canvas.DrawText(time, 10, 10)
		
		End

	End

	'These are our call back fuctions where we can decide what to do with each object found in the quadtree query.
	'The parameters will contain the object found and any data that you pass through to the query.
	Function DrawBoxCallBack:Void(foundobject:Object, data:Object)
		'Use casting to create a local rect of whatever boundary object the quad tree has found.
		'This could be either a tlBoundary, tlBoundaryCircle, tlBoundaryLine or tlBoundaryPoly
		Local rect:tlBox = Cast<tlBox>(foundobject)
		'We used the data variable to pass the Game object. This could be
		'any object, such as a game entity, which could have a field containing a tlBoundary representing
		'its bounding box/poly etc.
		Local thegame:= Cast<Game>(data)
		'Do a collision check and store the result
		Local collisionresult:tlCollisionResult = CheckCollision(thegame.player, rect)
		'If there is a collision
		If collisionresult.Intersecting = True
			'if we can check for the type of collision like this, you can have either tlPOLY_COLLISION, tlBOX_COLLISION, tlLINE_COLLISION,tlCIRCLE_COLLISION
			If rect.CollisionType = tlPOLY_COLLISION
				'For any polygon collisions rotate the polygon
				Cast<tlPolygon>(rect).RotateDegrees(1)
			
				'because the polygon has move it needs to be updated within the quadtree.
				Cast<tlPolygon>(rect).UpdateWithinQuadtree()
			End If
			
			'Draw the object that collided with the player box in a different colour
			thegame.currentCanvas.Color = New Color(0, 1, 0)
			rect.Draw(thegame.currentCanvas)
		End If
	End

	Function DrawScreenCallBack:Void(o:Object, data:Object)
		'Use casting to create a local rect of whatever boundary object the quad tree has found.
		'This could be either a tlBoundary, tlBoundaryCircle, tlBoundaryLine or tlBoundaryPoly
		'Note that the Box object has a Data field that you could use to store another object, say your game entity.
		Local rect:tlBox = Cast<tlBox>(o)
		Local thegame:=Cast<Game>(data)
		thegame.currentCanvas.Color = New Color(0.5, 0.5, 0.5)
		
		'Draw the box that was found
		rect.Draw(thegame.currentCanvas)
	End

	Function Main()

		New AppInstance
		
		New Game
		
		App.Run()

	End

	@end
#End
Class tlQuadTree
	#Rem monkeydoc @hidden
	#End
	Field Box:tlBox
	#Rem monkeydoc @hidden
	#End
	Field rootnode:tlQuadTreeNode[]
	#Rem monkeydoc @hidden
	#End
	Field objectsfound:Int
	#Rem monkeydoc @hidden
	#End
	Field objectsupdated:Int
	#Rem monkeydoc @hidden
	#End
	Field totalobjectsintree:Int
	#Rem monkeydoc @hidden
	#End
	Field min_nodewidth:Float
	#Rem monkeydoc @hidden
	#End
	Field min_nodeheight:Float
	#Rem monkeydoc @hidden
	#End
	Field objectsprocessed:Int
	#Rem monkeydoc @hidden
	#End
	Field dimension:Int
	#Rem monkeydoc @hidden
	#End
	Field maxLayers:Int
	#Rem monkeydoc @hidden
	#End
	Field layerconfigs:tlLayerConfig[]
	#Rem monkeydoc @hidden
	#End
	Field AreaCheckCount:=New Int[8]
	#Rem monkeydoc @hidden
	#End
	Field areacheckindex:Int = -1
	#Rem monkeydoc @hidden
	#End
	Field restack:Stack<tlBox>
	#Rem monkeydoc @hidden
	#End
	Field remove:Stack<tlBox>
	
	#Rem monkeydoc Create a new [[tlQuadTree]]
		Creates a new quad tree with the coordinates and dimensions given. _maxlevels_ determines how many times the quadtree can be sub divided. A
		quadtreenode is only subdivided when a certain amount of objects have been added, which is set by passing _maxpernode_. There's no optimum values for
		these, it largely depends on your specific needs, so you will probably do well to experiment. Set maxLayers to determine exactly how many Layers
		your want the quadtree to have.
		@param x Position of the quadtree (top left corner)
		@param y Position of the quadtree (top left corner)
		@param w Width of the quadtree
		@param h Height of the quadtree
		@param maxlevels This is how many times the quadtree can be subdivided, default = 4
		@param maxpernode The number of objects placed into a quad before it's subdivived, default = 4
		@param maxlayers The number of layers in the quadtree- useful for organsing your game objects, default = 8
	#End
	Method New(x:Float, y:Float, w:Float, h:Float, maxlevels:Int = 4, maxpernode:Int = 4, _maxLayers:Int = 8)
		Box = New tlBox(x, y, w, h)
		maxLayers = _maxLayers
		rootnode = New tlQuadTreeNode[maxLayers]
		dimension = 2 Shl (maxlevels - 1)
		min_nodewidth = w / dimension
		min_nodeheight = h / dimension
		layerconfigs = New tlLayerConfig[maxLayers]
		For Local l:Int = 0 To maxLayers - 1
			rootnode[l] = New tlQuadTreeNode(x, y, w, h, Self, l)
			rootnode[l].dimension = dimension
			layerconfigs[l] = New tlLayerConfig
			layerconfigs[l].MaxNodeLevels = maxlevels
			layerconfigs[l].MaxPerNode = maxpernode
			layerconfigs[l].MapDimension = dimension
			layerconfigs[l].MinNodeWidth = w / layerconfigs[l].MapDimension
			layerconfigs[l].MinNodeHeight = h / layerconfigs[l].MapDimension
			layerconfigs[l].GridMap = New tlQuadTreeNode[dimension * dimension]
			For Local x:Int = 0 To dimension - 1
				For Local y:Int = 0 To dimension - 1
					layerconfigs[l].GridMap[x * dimension + y] = rootnode[l]
				Next
			Next
		Next
		restack = New Stack<tlBox>
		remove = New Stack<tlBox>
	End
	
	#Rem monkeydoc Configure a Layer of the quadtree
		As the quadtree is broken up into Layers, this means you can configure each Layer to have a specific number of maximum levels
		and objects per node. This helps you to be more specific about how you optimise your quadtree. You should configure the Layers immediately
		after creating the quadtree and before anything is added to the tree. Layers can not be reconfigured once the quadtree has had objects added
		to it.
		@param Layer The layer index to configure
		@param maxpernode The number of objects placed into a quad before it's subdivived
		@param maxlayers The number of layers in the quadtree- useful for organsing your game objects
	#End
	Method SetLayerConfig(Layer:Int, maxlevels:Int, maxpernode:Int)
		If Layer < maxLayers And Layer >= 0
			layerconfigs[Layer].MaxNodeLevels = maxlevels
			layerconfigs[Layer].MaxPerNode = maxpernode
			layerconfigs[Layer].MapDimension = 2 Shl (maxlevels - 1)
			layerconfigs[Layer].MinNodeWidth = Box.Width / layerconfigs[Layer].MapDimension
			layerconfigs[Layer].MinNodeHeight = Box.Height / layerconfigs[Layer].MapDimension
			layerconfigs[Layer].GridMap = New tlQuadTreeNode[layerconfigs[Layer].MapDimension * layerconfigs[Layer].MapDimension]
			For Local x:Int = 0 To layerconfigs[Layer].MapDimension - 1
				For Local y:Int = 0 To layerconfigs[Layer].MapDimension - 1
					layerconfigs[Layer].GridMap[x * layerconfigs[Layer].MapDimension + y] = rootnode[Layer]
				Next
			Next
			rootnode[Layer].dimension = layerconfigs[Layer].MapDimension
		Else
			Print "Layer does not exist"
		End If
	End
	
	#Rem monkeydoc Add a new bounding box to the Quadtree
		A quadtree isn't much use without any objects. Use this to add a [[tlBox]] to the quadtree. If the bounding box does not overlap the
		quadtree then null is returned.
		@param box The box to be added to the quadtree
		@return False if the box doesn't overlap the qaudtree, otherwise True.
	#End
	Method AddBox:Int(box:tlBox)
		If Box.BoundingBoxOverlap(box)
			box.quadtree = Self
			rootnode[box.CollisionLayer].AddBox(box)
			totalobjectsintree += 1
			Return True
		End if
			
		Return False
	End
		
	#Rem monkeydoc Query the Quadtree to find objects with an area
		When you want to find objects within a particular area of the quadtree you can use this method.  Pass the area coordinates and dimensions
		that you want to check, an object that can be anything that you want to pass through to the callback function, and the function callback that you want
		to perform whatever tasks you need on the objects that are found within the area.
		The callback function you create needs to have 2 parameters: ReturnedObject:object which will be the tlBox/circle/poly, and Data:object which can be
		and object you want to pass through to the call back function.
		@param x x coordinate of area
		@param y y coordinate of area
		@param w Width of the area
		@param h Height of the area
		@param Data any object object to pass to the query
		@param onFoundObject A function pointer to function where you can perform whatever tasks you need to with the objects found.
		@param Layer Array of layers in the quadtree that you want to search
	#End
	Method ForEachObjectInArea(x:Float, y:Float, w:Float, h:Float, Data:Object, onFoundObject:void(ReturnedObject:Object, Data:Object), Layer:Int[])
		Local area:tlBox = New tlBox(x, y, w, h)
		areacheckindex += 1
		AreaCheckCount[areacheckindex] = GetUniqueNumber()
		objectsfound = 0
		For Local c:Int = 0 To Layer.Length - 1
			rootnode[Layer[c]].ForEachInAreaDo(area, Data, onFoundObject, False)
		Next
		areacheckindex-=1
		ReAddBoxes()
	End
	
	#Rem monkeydoc Query the quadtree to find objects within a [[tlBox]]
		This does the same thing as [[ForEachObjectInArea]] except you can pass a [[tlBox]] instead to query the quadtree.
		@param area A tlBox that will be used to define the area that is searched
		@param Data any object object to pass to the query
		@param onFoundObject A function pointer to function where you can perform whatever tasks you need to with the objects found.
		@param Layer Array of layers in the quadtree that you want to search
	#End
	Method ForEachObjectInBox(area:tlBox, Data:Object, onFoundObject:void(ReturnedObject:Object, Data:Object), Layer:Int[])
		objectsfound = 0
		areacheckindex+=1
		AreaCheckCount[areacheckindex] = GetUniqueNumber()
		For Local c:Int = 0 To Layer.Length - 1
			rootnode[Layer[c]].ForEachInAreaDo(area, Data, onFoundObject, True)
		Next
		areacheckindex-=1
		ReAddBoxes()
	End
	
	#Rem monkeydoc Query the quadtree to find objects within a _tlBox_
		This does the same thing as [[ForEachObjectInBox]] except it returns a stack of objects that it finds
		@param area A tlBox that will be used to define the area that is searched
		@param Layer Array of layers in the quadtree that you want to search
		@param GetData If set to true then the Data field within the tlBox will be returned rather than the box itself
		@return A stack of objects that was found
	#End
	Method GetObjectsInBox:Stack<Object>(area:tlBox, Layer:Int[], GetData:Int = False)
		objectsfound = 0
		areacheckindex+=1
		AreaCheckCount[areacheckindex] = GetUniqueNumber()
		Local list:Stack<Object> = New Stack<Object>
		For Local c:Int = 0 To Layer.Length - 1
			list = rootnode[Layer[c]].GetEachInArea(area, True, list, GetData)
		Next
		areacheckindex-=1
		Return list
	End
	
	#Rem monkeydoc Query the quadtree to find objects within a certain radius
		This will query the quadtree and do a callback on any objects it finds within a given radius.
		@param x x coordinate of range
		@param y y coordinate of range
		@param radius Radius of the range
		@param Data any object object to pass to the query
		@param onFoundObject A function pointer to function where you can perform whatever tasks you need to with the objects found.
		@param Layer Array of layers in the quadtree that you want to search
	#End
	Method ForEachObjectWithinRange(x:Float, y:Float, radius:Float, Data:Object, onFoundObject:void(ReturnedObject:Object, Data:Object), Layer:Int[])
		Local range:tlCircle = New tlCircle(x, y, radius)
		objectsfound = 0
		areacheckindex+=1
		AreaCheckCount[areacheckindex] = GetUniqueNumber()
		For Local c:Int = 0 To Layer.Length - 1
			rootnode[Layer[c]].ForEachWithinRangeDo(range, Data, onFoundObject)
		Next
		areacheckindex-=1
	End
	
	#Rem monkeydoc Query the quadtree to find objects within a [[tlCircle]]
		@param circle A tlCircle that will be used to define the area that is searched
		@param Data any object object to pass to the query
		@param onFoundObject A callback that contains a pointer to the function that will be called for any objects found in the area
		@param Layer Array of layers in the quadtree that you want to search
	#End
	Method ForEachObjectInCircle(circle:tlCircle, Data:Object, onFoundObject:void(ReturnedObject:Object, Data:Object), Layer:Int[])
		objectsfound = 0
		areacheckindex+=1
		AreaCheckCount[areacheckindex] = GetUniqueNumber()
		For Local c:Int = 0 To Layer.Length - 1
			rootnode[Layer[c]].ForEachWithinRangeDo(circle, Data, onFoundObject)
		Next
		areacheckindex-=1
	End
	
	#Rem monkeydoc Query the quadtree to find objects within a [[tlCircle]]
		@param circle A tlCircle that will be used to define the area that is searched
		@param Layer Array of layers in the quadtree that you want to search
		@param GetData If set to true then the Data field within the tlBox will be returned rather than the box itself
		@return A stack of objects that was found
	#End
	Method GetObjectsInCircle:Stack<Object>(circle:tlCircle, Layer:Int[], GetData:Int = False, Limit:Int = 0)
		objectsfound = 0
		areacheckindex+=1
		AreaCheckCount[areacheckindex] = GetUniqueNumber()
		Local list:= New Stack<Object>
		For Local c:Int = 0 To Layer.Length - 1
			rootnode[Layer[c]].GetEachInRange(circle, True, list, GetData, Limit)
		Next
		areacheckindex-=1
		Return list
	End
	
	#Rem monkeydoc Query a quadtree with a [[tlLine]]
		This will query the quadtree with a line and perform a callback on all the objects the [[tlLine]] intersects. Pass the quadtree to do the query on, the
		[[tlLine]] to query with, an object you want to pass through to the callback, and the callback itself. It's worth noting that the callback also requires
		you have a [[tlCollisionResult]] parameter which will be passed to the callback function with information about the results of the raycast.
		@param line A [[tlLine]] that will be used to define the area that is searched
		@param Data any object object to pass to the query
		@param onFoundObject A function pointer to function where you can perform whatever tasks you need to with the objects found.
		@param Layer Array of layers in the quadtree that you want to search
		@return False if the line has no length, otherwise if it successfully runs the query
	#End
	Method ForEachObjectAlongLine:Int(line:tlLine, data:Object, onFoundObject:void(ReturnedObject:Object, Data:Object, Result:tlCollisionResult), Layer:Int[])
		Local d:tlVector2 = New tlVector2(line.TFormVertices[1].x - line.TFormVertices[0].x, line.TFormVertices[1].y - line.TFormVertices[0].y)
		Local maxdistance:Float = d.DotProduct(d)
		d.Normalise()
		
		If Not d.x And Not d.y
			Return False
		End If

		objectsfound = 0
		areacheckindex+=1
		AreaCheckCount[areacheckindex] = GetUniqueNumber()
		
		Local x1:Float = line.TFormVertices[0].x + line.World.x
		Local y1:Float = line.TFormVertices[0].y + line.World.y

		For Local c:Int = 0 To Layer.Length - 1
			Local tMaxX:Float = 0 
			Local tMaxY:Float = 0
			Local direction:Int
			
			Local StepX:Int = 0
			Local StepY:Int = 0
			
			Local DeltaX:Float = 0
			Local DeltaY:Float = 0

			Local x:Int = x1 / min_nodewidth
			Local y:Int = y1 / min_nodeheight

			Local wx:Float = x * min_nodewidth
			Local wy:Float = y * min_nodeheight
			
			If d.x < 0
				StepX = -1
				tMaxX = (wx - x1) / d.x
				DeltaX = (min_nodewidth) / -d.x
			ElseIf d.x > 0
				StepX = 1
				tMaxX = (wx - x1 + min_nodewidth) / d.x
				DeltaX = (min_nodewidth) / d.x
			Else
				StepX = 0
				direction = 1
				DeltaX = 0
			End If
			
			If d.y < 0
				StepY = -1
				tMaxY = (wy - y1) / d.y
				DeltaY = (min_nodeheight) / -d.y
			ElseIf d.y > 0
				StepY = 1
				tMaxY = (wy - y1 + min_nodeheight) / d.y
				DeltaY = (min_nodeheight) / d.y
			Else
				StepY = 0
				direction = 2
				DeltaY = 0
			End If
			
			Local lastquad:tlQuadTreeNode = Null
			
			Local dv:tlVector2 = New tlVector2(0, 0)
			Local endofline:Int
			
			'if line starts outside of quadtree
			If x < 0 Or x >= dimension Or y < 0 Or y >= dimension
				Local result:tlCollisionResult = rootnode[Layer[c]].Box.LineCollide(line)
				If result.NoCollision Return False
				If result.Intersecting
					Select direction
						Case 0
							While x < 0 Or x >= dimension Or y < 0 Or y >= dimension
								If tMaxX < tMaxY
									tMaxX+=DeltaX
									x = x + StepX
								Else
									tMaxY+=DeltaY
									y = y + StepY
								End If
							Wend
						Case 1
							While y < 0 Or y >= dimension
								tMaxY+=DeltaY
								y+=StepY
							Wend
						Case 2
							While x < 0 Or x >= dimension
								tMaxX+=DeltaX
								x+=StepX
							Wend
					End Select
				Else
					Return False
				End If
			End If
			
			Select direction
				Case 0
					While x >= 0 And x < dimension And y >= 0 And y < dimension
						If layerconfigs[Layer[c]].GridMap[x + y * dimension] <> lastquad
							layerconfigs[Layer[c]].GridMap[x + y * dimension].ForEachObjectAlongLine(line, data, onFoundObject)
						End If
						lastquad = layerconfigs[Layer[c]].GridMap[x + y * dimension]
						
						dv = New tlVector2(layerconfigs[Layer[c]].GridMap[x + y * dimension].Box.World.x - x1, layerconfigs[Layer[c]].GridMap[x + y * dimension].Box.World.y - y1)
						If endofline Exit
						If dv.DotProduct(dv) > maxdistance endofline = True
						
						If tMaxX < tMaxY
							tMaxX+=DeltaX
							x = x + StepX
						Else
							tMaxY+=DeltaY
							y = y + StepY
						End If
					Wend
				Case 1	'vertically only
					While y >= 0 And y < dimension
						If layerconfigs[Layer[c]].GridMap[x + y * dimension] <> lastquad
							layerconfigs[Layer[c]].GridMap[x + y * dimension].ForEachObjectAlongLine(line, data, onFoundObject)
						End If
						lastquad = layerconfigs[Layer[c]].GridMap[x + y * dimension]
						
						dv = New tlVector2(layerconfigs[Layer[c]].GridMap[x + y * dimension].Box.World.x - x1, layerconfigs[Layer[c]].GridMap[x + y * dimension].Box.World.y - y1)
						If endofline Exit
						If dv.DotProduct(dv) > maxdistance endofline = True
						
						tMaxY+=DeltaY
						y+=StepY
					Wend
				Case 2	'horizontally only
					While x >= 0 And x < dimension
						If layerconfigs[Layer[c]].GridMap[x + y * dimension] <> lastquad
							layerconfigs[Layer[c]].GridMap[x + y * dimension].ForEachObjectAlongLine(line, data, onFoundObject)
						End If
						lastquad = layerconfigs[Layer[c]].GridMap[x + y * dimension]
						
						dv = New tlVector2(layerconfigs[Layer[c]].GridMap[x + y * dimension].Box.World.x - x1, layerconfigs[Layer[c]].GridMap[x + y * dimension].Box.World.y - y1)
						If endofline Exit
						If dv.DotProduct(dv) > maxdistance endofline = True
						
						tMaxX+=DeltaX
						x+=StepX
					Wend
			End Select
		Next
		
		areacheckindex-=1
		
		Return True
	End
	
	#Rem monkeydoc Query a quadtree with a ray of given length
		This will query the quadtree with a raycast and perform a callback on the first object hit by the ray with a function pointer you pass
		@param px x coordinate of the starting point of the ray
		@param py y coordinate of the starting point of the ray
		@param d tlVector2 describing the direction of the raycast
		@param maxdistance The maximum distance of the ray cast, or 0 for infinite
		@param onFoundObject A function pointer to function where you can perform whatever tasks you need to with the objects found.
		@param Layer Array of layers in the quadtree that you want to search
		@return False If no objects were hit, otherwise returns true
	#End
	Method RayCast:Int(px:Float, py:Float, d:tlVector2, maxdistance:Float = 0, Data:Object, onFoundObject:void(ReturnedObject:Object, Data:Object, Result:tlCollisionResult), Layer:Int[])

		objectsfound = 0
		areacheckindex+=1
		AreaCheckCount[areacheckindex] = GetUniqueNumber()

		local dx:float = d.x
		local dy:float = d.y
		
		d = d.Normalise()

		If Not d.x And Not d.y
			areacheckindex-=1
			Return False
		End If

		Local px2:Float = px
		Local py2:Float = py
		
		px-=Box.tl_corner.x
		py-=Box.tl_corner.y
		
		Local objectfound:Int
		
		For Local c:Int = 0 To Layer.Length - 1

			Local tMaxX:Float = 0 
			Local tMaxY:Float = 0
			Local direction:Int
			
			Local StepX:Int = 0
			Local StepY:Int = 0
			
			Local DeltaX:Float = 0
			Local DeltaY:Float = 0

			Local x:Int = px / layerconfigs[Layer[c]].MinNodeWidth
			Local y:Int = py / layerconfigs[Layer[c]].MinNodeHeight

			Local wx:Float = x * layerconfigs[Layer[c]].MinNodeWidth
			Local wy:Float = y * layerconfigs[Layer[c]].MinNodeHeight
			
			If d.x < 0
				StepX = -1
				tMaxX = (wx - px) / d.x
				DeltaX = (layerconfigs[Layer[c]].MinNodeWidth) / -d.x
			ElseIf d.x > 0
				StepX = 1
				tMaxX = (wx - px + layerconfigs[Layer[c]].MinNodeWidth) / d.x
				DeltaX = (layerconfigs[Layer[c]].MinNodeWidth) / d.x
			Else
				StepX = 0
				direction = 1
				DeltaX = 0
			End If
			
			If d.y < 0
				StepY = -1
				tMaxY = (wy - py) / d.y
				DeltaY = (layerconfigs[Layer[c]].MinNodeHeight) / -d.y
			ElseIf d.y > 0
				StepY = 1
				tMaxY = (wy - py + layerconfigs[Layer[c]].MinNodeHeight) / d.y
				DeltaY = (layerconfigs[Layer[c]].MinNodeHeight) / d.y
			Else
				StepY = 0
				direction = 2
				DeltaY = 0
			End If
			
			Local lastquad:tlQuadTreeNode = Null
			Local layerdimension:=layerconfigs[Layer[c]].MapDimension
			
			Select direction
				Case 0
					While x >= 0 And x < layerdimension And y >= 0 And y < layerdimension And Not objectfound
						If layerconfigs[Layer[c]].GridMap[x + y * layerdimension] <> lastquad
							objectfound = layerconfigs[Layer[c]].GridMap[x + y * layerdimension].RayCast(px2, py2, dx, dy, maxdistance, Data, onFoundObject)
							layerconfigs[Layer[c]].GridMap[x + y * layerdimension].highlight = true
						End If
						lastquad = layerconfigs[Layer[c]].GridMap[x + y * layerdimension]
						If(tMaxX < tMaxY)
							tMaxX+=DeltaX
							x = x + StepX
						Else
							tMaxY = tMaxY + DeltaY
							y = y + StepY
						End If
					Wend
				Case 1	'vertically only
					While y >= 0 And y < layerdimension And Not objectfound
						If layerconfigs[Layer[c]].GridMap[x + y * layerdimension] <> lastquad
							objectfound = layerconfigs[Layer[c]].GridMap[x + y * layerdimension].RayCast(px2, py2, dx, dy, maxdistance, Data, onFoundObject)
							layerconfigs[Layer[c]].GridMap[x + y * layerdimension].highlight = true
						End If
						lastquad = layerconfigs[Layer[c]].GridMap[x + y * layerdimension]
						tMaxY+=DeltaY
						y = y + StepY
					Wend
				Case 2	'horizontally only
					While x >= 0 And x < layerdimension And Not objectfound
						If layerconfigs[Layer[c]].GridMap[x + y * layerdimension] <> lastquad
							objectfound = layerconfigs[Layer[c]].GridMap[x + y * layerdimension].RayCast(px2, py2, dx, dy, maxdistance, Data, onFoundObject)
							layerconfigs[Layer[c]].GridMap[x + y * layerdimension].highlight = true
						End If
						lastquad = layerconfigs[Layer[c]].GridMap[x + y * layerdimension]
						tMaxX+=DeltaX
						x = x + StepX
					Wend
			End Select
		Next
		
		areacheckindex-=1
				
		If objectfound
			objectsfound = 1
			Return True
		End If
		
		Return False
		
	End
	
	#Rem monkeydoc Find out how many objects were found on the last query
		Use this to retrieve the amount of object that were found when the last query was run.
		@return Number of objects found.
	#End
	Method GetObjectsFound:Int()
		Return objectsfound
	End
	
	#Rem monkeydoc Find out how many objects are currently in the quadtree
		Use this to retrieve the total amount of objects that are stored in the quadtree.
		@return Number of Total Objects in Tree
	#End
	Method GetTotalObjects:Int()
		Return totalobjectsintree
	End
	
	#Rem monkeydoc Get the width of the [[tlQuadtree]]
		@return Overal width of the quadtree
	#End
	Method GetWidth:Int()
		Return Box.Width
	End
	
	#Rem monkeydoc Get the height of the [[tlQuadtree]]
		@return Overal height of the quadtree
	#End
	Method GetHeight:Int()
		Return Box.Height
	End
	
	#Rem monkeydoc Perform some house keeping on the quadtree
		This will search the quadtree on the specified Layers for any empty quad tree nodes and unpartition them if necessary.
	#End
	Method RunMaintenance(Layer:Int[])
		For Local c:Int = 0 To Layer.Length - 1
			rootnode[Layer[c]].UnpartitionEmptyQuads()
		Next
	End
	
	#Rem monkeydoc Draw a Layer of the quadtree
		This can be used for debugging purposes. *Warning: This will be very slow if the quadtree has more then 6 or 7 levels!*
	#End
	Method Draw(canvas:Canvas, offsetx:Float = 0, offsety:Float = 0, Layer:Int = 0, all:int=true)
		If Layer >= 0 And Layer < maxLayers
			rootnode[Layer].Draw(canvas, offsetx, offsety, all)
		Else
			Print "Can't draw quadtree, Layer spefied that doesn't exist"
		End If
	End

	#Rem monkeydoc unhiglight all quad nodes, mainly for debugging purposes
		This can be used for debugging purposes.
	#End
	Method UnHighlight(Layer:int = 0)
		If Layer >= 0 And Layer < maxLayers
			rootnode[Layer].UnHighlight()
		Else
			Print "Layer spefied doesn't exist"
		End If
	End

	#Rem monkeydoc @hidden
	#End
	Method CountAllObjects:Int()
		Local amount:int = 0
		For Local c:Int = 0 To rootnode.Length - 1
			amount += rootnode[c].CountObjects()
		Next

		Return amount
	End

	#Rem monkeydoc Add the [[tlBox]] to the remove list
		This will add a [[tlBox]] to the queue for removal next time you call [[CleanUp]]. It's important to use this if you're removing items from the quadtree during a query because otherwise you
		will run into a "concurrent list modification error". At the end of your update loop you can call [[CleanUp]] to remove those items from the quadtree in a batch. Note that if you are using a [[tlGameObject]]
		then [[tlGameObject.Destroy]] will do this automatically, but you'll still need to call [[CleanUp]]
		@param r [[tlBox]]
	#End
	Method AddForRemoval(r:tlBox)
		remove.Add(r)
		r.dead = true
	End

	#Rem monkeydoc Remove marked objects
		Run this at the end of your logic loop or whenever you want to remove objects from the quadtree that have been 
		marked for removal. Objects are marked whenever you call [[MarkForRemoval]] on a [[tlBox]], use [[AddForRemoval]] or [[tlGameobject.Destroy]]
	#End
	Method CleanUp()
		For Local r:=Eachin remove
			r.RemoveFromQuadTree()
		Next
		remove.Clear()
	End

	'Internal Stuff-----------------------------------
	#Rem monkeydoc @hidden
	#End
	Method UpdateRect(r:tlBox)
		if not r.dead
			'This is run automatically when a tlBox decides it needs to be moved within the quadtree
			objectsupdated+=1
			restack.Add(r)
		end if
	End

	#Rem monkeydoc @hidden
	#End
	Method ReAddBoxes()
		For Local r:=Eachin restack
			if not r.dead
				r.RemoveFromQuadTree()
				AddBox(r)
			end if
		Next
		restack.Clear()
	End

	#Rem monkeydoc @hidden
	#End
	Method AddBoxRestack(r:tlBox)
		restack.Add(r)
	End

	#Rem monkeydoc @hidden
	#End
	Method GetQuadNode:tlQuadTreeNode(x:Float, y:Float, Layer:Int)
		Local tx:Int = x / layerconfigs[Layer].MinNodeWidth
		Local ty:Int = y / layerconfigs[Layer].MinNodeHeight
		If tx >= 0 And tx < dimension And ty >= 0 And ty < dimension
			Return layerconfigs[Layer].GridMap[tx + ty * layerconfigs[Layer].MapDimension]
		End If
		Return Null
	End

	#Rem monkeydoc @hidden
	#End
	Method GetUniqueNumber:Int()
		Return Rnd(-2147483647, 2147483647)
	End
End

#Rem monkeydoc @hidden
#End
Class tlQuadTreeNode
	Field parenttree:tlQuadTree
	Field parent:tlQuadTreeNode
	'Node layout:
	'01
	'23
	Field childnode:=New tlQuadTreeNode[4]
	Field Box:tlBox
	Field objects:List<tlBox>
	Field numberofobjects:Int
	Field nodelevel:Int
	Field partitioned:Int
	Field gridx:Int
	Field gridy:Int
	Field dimension:Int
	Field Layer:Int

	Field highlight:int = false
	
	'Internal Stuff------------------------------------
	'This whole type should be handled automatically by the quadtree it belongs to, so you don't have to worry about it.
	#Rem monkeydoc @hidden
	#End
	Method New(x:Float, y:Float, w:Float, h:Float, _parenttree:tlQuadTree, _Layer:Int, parentnode:tlQuadTreeNode = Null, gridref:Int = -1)
		Box = New tlBox(x, y, w, h)
		parenttree = _parenttree
		Layer = _Layer
		If parentnode
			nodelevel = parentnode.nodelevel + 1
			parent = parentnode
		Else
			nodelevel = 1
		End If
		objects = New List<tlBox>
		If parentnode
			dimension = parentnode.dimension / 2
			Select gridref
				Case 0
					gridx = parentnode.gridx
					gridy = parentnode.gridy
				Case 1
					gridx = parentnode.gridx + dimension
					gridy = parentnode.gridy
				Case 2
					gridx = parentnode.gridx
					gridy = parentnode.gridy + dimension
				Case 3
					gridx = parentnode.gridx + dimension
					gridy = parentnode.gridy + dimension
			End Select
			For Local x:Int = 0 To dimension - 1
				For Local y:Int = 0 To dimension - 1
					parenttree.layerconfigs[Layer].GridMap[(x + gridx) + ((y + gridy) * parenttree.layerconfigs[Layer].MapDimension)] = Self
				Next
			Next
		End If
	End

	#Rem monkeydoc @hidden
	#End
	Method CountObjects:Int()
		Local amount:Int = 0
		amount += objects.Count()
		If (partitioned)
			For Local c:Int = 0 to 3
				amount += childnode[c].CountObjects()
			Next
		End If
		Return amount
	End
	
	#Rem monkeydoc @hidden
	#End
	Method Partition()
		'When this quadtreenode contains more objects then parenttree.maxpernode it is partitioned
		childnode[0] = New tlQuadTreeNode(Box.tl_corner.x, Box.tl_corner.y, Box.Width / 2, Box.Height / 2, parenttree, Layer, Self, 0)
		childnode[1] = New tlQuadTreeNode(Box.tl_corner.x + Box.Width / 2, Box.tl_corner.y, Box.Width / 2, Box.Height / 2, parenttree, Layer, Self, 1)
		childnode[2] = New tlQuadTreeNode(Box.tl_corner.x, Box.tl_corner.y + Box.Height / 2, Box.Width / 2, Box.Height / 2, parenttree, Layer, Self, 2)
		childnode[3] = New tlQuadTreeNode(Box.tl_corner.x + Box.Width / 2, Box.tl_corner.y + Box.Height / 2, Box.Width / 2, Box.Height / 2, parenttree, Layer, Self, 3)
		partitioned = True
	End

	#Rem monkeydoc @hidden
	#End
	Method AddBox(r:tlBox)
		'Adds a new bounding box to the node, and partitions/moves objects down the tree as necessary.
		If partitioned
			MoveRectDown(r)
		Else
			objects.Add(r)
			numberofobjects+=1
			r.AddQuad(Self)
			If nodelevel < parenttree.layerconfigs[Layer].MaxNodeLevels And numberofobjects + 1 > parenttree.layerconfigs[Layer].MaxPerNode
				If Not partitioned Partition()
				local rects:=objects.All()
				local box:tlBox
				while not rects.AtEnd
					box = rects.Current
					box.RemoveQuad(self)
					numberofobjects-=1
					MoveRectDown(box)
					rects.Erase()
				Wend
			End If
		End If
	End

	#Rem monkeydoc @hidden
	#End
	Method RemoveRect(r:tlBox, listRemove:Int = true)
		'Mark the Box for removal
		r.remove = true
		numberofobjects-=1
	End

	#Rem monkeydoc @hidden
	#End
	Method MoveRectDown(r:tlBox)
		'moves a bounding box down the quadtree to any children it overlaps
		If childnode[0].Box.BoundingBoxOverlap(r) childnode[0].AddBox(r)
		If childnode[1].Box.BoundingBoxOverlap(r) childnode[1].AddBox(r)
		If childnode[2].Box.BoundingBoxOverlap(r) childnode[2].AddBox(r)
		If childnode[3].Box.BoundingBoxOverlap(r) childnode[3].AddBox(r)
	End

	#Rem monkeydoc @hidden
	#End
	Method ForEachInAreaDo(area:tlBox, Data:Object, onFoundObject:void(ReturnedObject:Object, Data:Object), velocitycheck:Int)
		'run a callback on objects found within the nodes that the area overlaps
		Local checkindex:Int = parenttree.areacheckindex
		If Box.BoundingBoxOverlap(area, velocitycheck)
			If partitioned
				If Not objects.Empty
					local rects:=objects.All()
					local r:tlBox
					While not rects.AtEnd
						r = rects.Current
						If r.AreaCheckCount[checkindex] <> parenttree.AreaCheckCount[checkindex] And r <> area
							If r.BoundingBoxOverlap(area, True)
								onFoundObject(r, Data)
							End If
							r.AreaCheckCount[checkindex] = parenttree.AreaCheckCount[checkindex]
							parenttree.objectsfound+=1
							parenttree.objectsprocessed+=1
						End If
						if r.remove
							r.remove = False
							rects.Erase()
						Else
							rects.Bump()
						End If
					Wend
				End If
				childnode[0].ForEachInAreaDo(area, Data, onFoundObject, velocitycheck)
				childnode[1].ForEachInAreaDo(area, Data, onFoundObject, velocitycheck)
				childnode[2].ForEachInAreaDo(area, Data, onFoundObject, velocitycheck)
				childnode[3].ForEachInAreaDo(area, Data, onFoundObject, velocitycheck)
			Else
				If Not objects.Empty
					local rects:=objects.All()
					local r:tlBox
					While not rects.AtEnd
						r = rects.Current
						If r.AreaCheckCount[checkindex] <> parenttree.AreaCheckCount[checkindex] And r <> area
							If r.BoundingBoxOverlap(area, True)
								onFoundObject(r, Data)
							End If
							r.AreaCheckCount[checkindex] = parenttree.AreaCheckCount[checkindex]
							parenttree.objectsfound+=1
							parenttree.objectsprocessed+=1
						End If
						if r.remove
							r.remove = False
							rects.Erase()
						Else
							rects.Bump()
						End If
					Wend
				End If
			End If
		End If
	End

	#Rem monkeydoc @hidden
	#End
	Method GetEachInArea:Stack<Object>(area:tlBox, velocitycheck:Int, list:Stack<Object>, GetData:Int)
		'run a callback on objects found within the nodes that the area overlaps
		Local checkindex:Int = parenttree.areacheckindex
		If Box.BoundingBoxOverlap(area, velocitycheck)
			If partitioned
				If Not objects.Empty
					Local last:Object = objects.Last
					For Local r:tlBox = EachIn objects
						If r.AreaCheckCount[checkindex] <> parenttree.AreaCheckCount[checkindex] And r <> area
							If r.BoundingBoxOverlap(area, True)
								Select GetData
									Case True
										list.Add(r.Data)
									Case False
										list.Add(r)
								End Select
							End If
							r.AreaCheckCount[checkindex] = parenttree.AreaCheckCount[checkindex]
							parenttree.objectsfound+=1
							parenttree.objectsprocessed+=1
							If last = r Exit
						End If
					Next
				End If
				list = childnode[0].GetEachInArea(area, velocitycheck, list, GetData)
				list = childnode[1].GetEachInArea(area, velocitycheck, list, GetData)
				list = childnode[2].GetEachInArea(area, velocitycheck, list, GetData)
				list = childnode[3].GetEachInArea(area, velocitycheck, list, GetData)
			Else
				If Not objects.Empty
					Local last:Object = objects.Last
					For Local r:tlBox = EachIn objects
						If r.AreaCheckCount[checkindex] <> parenttree.AreaCheckCount[checkindex] And r <> area
							If r.BoundingBoxOverlap(area, True)
								Select GetData
									Case True
										list.Add(r.Data)
									Case False
										list.Add(r)
								End Select
							End If
							r.AreaCheckCount[checkindex] = parenttree.AreaCheckCount[checkindex]
							parenttree.objectsfound+=1
							parenttree.objectsprocessed+=1
							If last = r Exit
						End If
					Next
				End If
			End If
		End If
		Return list
	End

	#Rem monkeydoc @hidden
	#End
	Method ForEachWithinRangeDo(Range:tlCircle, Data:Object, onFoundObject:void(ReturnedObject:Object, Data:Object))
		'run a callback on objects found within the nodes that the circle overlaps
		Local checkindex:Int = parenttree.areacheckindex
		If Box.CircleOverlap(Range)
			If partitioned
				If Not objects.Empty
					local rects:=objects.All()
					local r:tlBox
					While not rects.AtEnd
						r = rects.Current
						If r.AreaCheckCount[checkindex] <> parenttree.AreaCheckCount[checkindex] And r <> Range
							If r.CircleOverlap(Range)
								onFoundObject(r, Data)
							End If
							r.AreaCheckCount[checkindex] = parenttree.AreaCheckCount[checkindex]
							parenttree.objectsfound+=1
							parenttree.objectsprocessed+=1
						End If
						if r.remove
							r.remove = False
							rects.Erase()
						Else
							rects.Bump()
						End If
					Wend
				End If
				childnode[0].ForEachWithinRangeDo(Range, Data, onFoundObject)
				childnode[1].ForEachWithinRangeDo(Range, Data, onFoundObject)
				childnode[2].ForEachWithinRangeDo(Range, Data, onFoundObject)
				childnode[3].ForEachWithinRangeDo(Range, Data, onFoundObject)
			Else
				If Not objects.Empty
					local rects:=objects.All()
					local r:tlBox
					While not rects.AtEnd
						r = rects.Current
						If r.AreaCheckCount[checkindex] <> parenttree.AreaCheckCount[checkindex] And r <> Range
							If r.CircleOverlap(Range)
								onFoundObject(r, Data)
							End If
							r.AreaCheckCount[checkindex] = parenttree.AreaCheckCount[checkindex]
							parenttree.objectsfound+=1
							parenttree.objectsprocessed+=1
						End If
						if r.remove
							r.remove = False
							rects.Erase()
						Else
							rects.Bump()
						End If
					Wend
				End If
			End If
		End If
	End

	#Rem monkeydoc @hidden
	#End
	Method GetEachInRange:Stack<Object>(Range:tlCircle, velocitycheck:Int, list:Stack<Object>, GetData:Int, Limit:Int)
		'run a callback on objects found within the nodes that the circle overlaps
		Local checkindex:Int = parenttree.areacheckindex
		If Limit > 0 And parenttree.objectsfound >= Limit
			Return list
		End If
		If Box.CircleOverlap(Range)
			If partitioned
				If Not objects.Empty
					Local last:Object = objects.Last
					For Local r:tlBox = EachIn objects
						If r.AreaCheckCount[checkindex] <> parenttree.AreaCheckCount[checkindex] And Range <> r
							If Range.BoundingBoxOverlap(r, True)
								Select GetData
									Case True
										list.Add(r.Data)
									Case False
										list.Add(r)
								End Select
							End If
							r.AreaCheckCount[checkindex] = parenttree.AreaCheckCount[checkindex]
							parenttree.objectsfound+=1
							parenttree.objectsprocessed+=1
							If Limit > 0 And parenttree.objectsfound >= Limit
								Return list
							End If
						End If
						If last = r Exit
					Next
				End If
				list = childnode[0].GetEachInRange(Range, velocitycheck, list, GetData, Limit)
				list = childnode[1].GetEachInRange(Range, velocitycheck, list, GetData, Limit)
				list = childnode[2].GetEachInRange(Range, velocitycheck, list, GetData, Limit)
				list = childnode[3].GetEachInRange(Range, velocitycheck, list, GetData, Limit)
			Else
				If Not objects.Empty
					Local last:Object = objects.Last
					For Local r:tlBox = EachIn objects
						If r.AreaCheckCount[checkindex] <> parenttree.AreaCheckCount[checkindex] And Range <> r
							If Range.BoundingBoxOverlap(r, True)
								Select GetData
									Case True
										list.Add(r.Data)
									Case False
										list.Add(r)
								End Select
							End If
							r.AreaCheckCount[checkindex] = parenttree.AreaCheckCount[checkindex]
							parenttree.objectsfound+=1
							parenttree.objectsprocessed+=1
							If Limit > 0 And parenttree.objectsfound >= Limit
								Return list
							End If
						End If
						If last = r Exit
					Next
				End If
			End If
		End If
		Return list
	End

	#Rem monkeydoc @hidden
	#End
	Method ForEachObjectAlongLine(Line:tlLine, Data:Object, onFoundObject:void(ReturnedObject:Object, Data:Object, Result:tlCollisionResult))
		Local result:tlCollisionResult
		Local checkindex:Int = parenttree.areacheckindex

		if not objects.Empty
			local rects:=objects.All()
			local r:tlBox
			While not rects.AtEnd
				r = rects.Current
				If r.AreaCheckCount[checkindex] <> parenttree.AreaCheckCount[checkindex] And Line <> r
					result = r.LineCollide(Line)
					If not result.NoCollision
						If result.Intersecting Or result.WillIntersect
							onFoundObject(r, Data, result)
							r.AreaCheckCount[checkindex] = parenttree.AreaCheckCount[checkindex]
							parenttree.objectsfound+=1
							parenttree.objectsprocessed+=1
						End If
					End If
				End If
				if r.remove
					r.remove = False
					rects.Erase()
				Else
					rects.Bump()
				End If
			wend
		End If
	End

	#Rem monkeydoc @hidden
	#End
	Method RayCast:Int(px:Float, py:Float, dx:Float, dy:Float, maxdistance:Int, Data:Object, onFoundObject:void(ReturnedObject:Object, Data:Object, Result:tlCollisionResult))
		
		Local result:tlCollisionResult
		Local nearestobject:tlBox
		Local nearestresult:tlCollisionResult
		Local mindistance:Float = $7fffffff

		if not objects.Empty
			local rects:=objects.All()
			local r:tlBox
			While not rects.AtEnd
				r = rects.Current
				result = r.RayCollide(px, py, dx, dy, maxdistance)
				If result.RayOriginInside
					mindistance = result.RayDistance
					nearestresult = result
					nearestobject = r
					Exit
				End If
				If result.RayDistance < mindistance And result.HasIntersection And Box.PointInside(result.RayIntersection.x, result.RayIntersection.y)
					mindistance = result.RayDistance
					nearestresult = result
					nearestobject = r
				End If
				rects.Bump()
			Wend
		End If
		
		If nearestobject
			onFoundObject(nearestobject, Data, nearestresult)
			Return True
		End If
		
		Return False
		
	End

	#Rem monkeydoc @hidden
	#End
	Method UnpartitionEmptyQuads()
		'This is run when RunMaintenance is run in the quadtree type.
		If partitioned
			If childnode[0] childnode[0].UnpartitionEmptyQuads()
			If childnode[1] childnode[1].UnpartitionEmptyQuads()
			If childnode[2] childnode[2].UnpartitionEmptyQuads()
			If childnode[3] childnode[3].UnpartitionEmptyQuads()
		Else
			If parent parent.DeleteEmptyPartitions()
		End If
	End

	#Rem monkeydoc @hidden
	#End
	Method DeleteEmptyPartitions()
		'deletes the partitions from this node
		If childnode[0].numberofobjects + childnode[1].numberofobjects + childnode[2].numberofobjects + childnode[3].numberofobjects = 0
			If Not childnode[0].partitioned And Not childnode[1].partitioned And Not childnode[2].partitioned And Not childnode[3].partitioned
				partitioned = False
				childnode[0] = Null
				childnode[1] = Null
				childnode[2] = Null
				childnode[3] = Null
			End If
		End If
	End

	#Rem monkeydoc @hidden
	#End
	Method Draw(canvas:Canvas, offsetx:Float = 0, offsety:Float = 0, all:int = true)
		'called when the draw method is called in tlQuadTreeNode
		if highlight and not all
			canvas.Color = New Color( 0, 1, 0 )
			Box.Draw(canvas, offsetx, offsety)
		Elseif all
			canvas.Color = New Color( 1, 1, 1 )
			Box.Draw(canvas, offsetx, offsety)
		End If

		If partitioned
			childnode[0].Draw(canvas, offsetx, offsety)
			childnode[1].Draw(canvas, offsetx, offsety)
			childnode[2].Draw(canvas, offsetx, offsety)
			childnode[3].Draw(canvas, offsetx, offsety)
		End If
	End

	Method UnHighlight()
		highlight = False
		If partitioned
			childnode[0].UnHighlight()
			childnode[1].UnHighlight()
			childnode[2].UnHighlight()
			childnode[3].UnHighlight()
		End If
	End

	#Rem monkeydoc @hidden
	#End
	Method ToString:string()
		return gridx + ", " + gridy
	End
End

#Rem monkeydoc @hidden
#End
Class tlLayerConfig
	field MaxNodeLevels:int
	field MaxPerNode:int
	field MapDimension:int
	field MinNodeWidth:int
	field MinNodeHeight:int
	field GridMap:tlQuadTreeNode[]
End