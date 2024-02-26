# Copyright (C) 2024 Claudio Z. (cloudofoz)
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

@tool
extends Path2D

#---------------------------------------------------------------------------------------------------
# CONSTANTS
#---------------------------------------------------------------------------------------------------

# Enable the creation of a default curve when this class is instantiated
const LP_CREATE_DEFAULT_CURVE = true

# Enable the creation of a default curve width profile when this class is instatiated
const LP_CREATE_DEFAULT_PROFILE = true

# Size in pixels of the default curve
const LP_DEFAULT_CURVE_SIZE = 400

# Size in pixels of the default curve width
const LP_DEFAULT_CURVE_WIDTH = 25

#---------------------------------------------------------------------------------------------------
# PRIVATE VARIABLES
#---------------------------------------------------------------------------------------------------

var lp_line: Line2D = null

#---------------------------------------------------------------------------------------------------
# PUBLIC VARIABLES
#---------------------------------------------------------------------------------------------------

@export_category("LinePath2D")

## Sets the Path2D 'Curve2D' resource
##
## Note: Please, use this variable to change the curve and not the original Path2D property
##			Reason: It's not currently possible to override the parent setter:
##					'Path2D.set_curve(value)'.
##			Reference: https://github.com/godotengine/godot-proposals/issues/8045
@export var _curve: Curve2D = null:
	set(value):
		if(curve && curve.changed.is_connected(lp_build_line)): 
			curve.changed.disconnect(lp_build_line)
		curve = value
		if(curve): 
			curve.changed.connect(lp_build_line)
		lp_build_line()
	get:
		return curve

## Sets the width of the curve
@export var width: float = LP_DEFAULT_CURVE_WIDTH:
	set(value):
		if(!lp_line): return
		lp_line.width = value
		#lp_line.draw.emit()
	get:
		return lp_line.width if lp_line else LP_DEFAULT_CURVE_WIDTH

## Use this [Curve] to modify the line width profile
@export var width_profile: Curve:
	set(value):
		if(!lp_line): return
		lp_line.width_curve = value
		#lp_line.draw.emit()
	get:
		return lp_line.width_curve if lp_line else null


@export_group("Fill", "fill_")

## Default path color
@export var fill_default_color: Color = Color.WHITE:
	set(value):
		if(lp_line): lp_line.default_color = value
	get:
		return lp_line.default_color if lp_line else Color.WHITE

## Fill the path with a gradient
@export var fill_gradient: Gradient = null:
	set(value):
		if(lp_line): lp_line.gradient = value
	get:
		return lp_line.gradient if lp_line else null

## Fill the path with a texture
@export var fill_texture: Texture2D = null:
	set(value):
		if(lp_line): lp_line.texture = value
	get:
		return lp_line.texture if lp_line else null

## Change the texture fill mode
@export_enum("None: 0", "Tile: 1", "Stretch: 2")
var fill_texture_mode: int = Line2D.LINE_TEXTURE_NONE:
	set(value):
		if(lp_line): lp_line.texture_mode = value
	get:
		return lp_line.texture_mode if lp_line else Line2D.LINE_TEXTURE_NONE

## Sets the material (CanvasMaterial2D or ShaderMaterial)
#@export var fill_material: Material = null:
	#set(value):
		#if(!lp_line): return
		#if(!(value is CanvasItemMaterial) && !(value is ShaderMaterial)):
			#lp_line.material = null
			#return
		#lp_line.material = value
	#get:
		#return lp_line.material if lp_line else null


@export_group("Capping", "cap_")

## The style of connection between segments of the polyline
@export_enum("Sharp: 0", "Bevel: 1", "Round: 2")
var cap_joint_mode: int = Line2D.LINE_JOINT_SHARP:
	set(value):
		if(lp_line): lp_line.joint_mode = value
	get:
		return lp_line.joint_mode if lp_line else 0

## The style of the beginning of the polyline
@export_enum("None: 0", "Box: 1", "Round: 1")
var cap_begin_cap: int = Line2D.LINE_CAP_NONE:
	set(value): 
		if(lp_line): lp_line.begin_cap_mode = value
	get:
		return lp_line.begin_cap_mode if lp_line else Line2D.LINE_CAP_NONE

## The style of the ending of the polyline
@export_enum("None: 0", "Box: 1", "Round: 1")
var cap_end_cap: int = Line2D.LINE_CAP_NONE:
	set(value): 
		if(lp_line): lp_line.end_cap_mode = value
	get:
		return lp_line.end_cap_mode if lp_line else Line2D.LINE_CAP_NONE

## If true and the polyline has more than two segments,
## the first and the last point will be connected by a segment
@export var cap_close_curve: bool = false:
	set(value): 
		if(lp_line): lp_line.closed = value
	get:
		return lp_line.closed if lp_line else false


@export_group("Border", "border_")

## Determines the miter limit of the polyline
@export var border_sharp_limit: float = 2.0:
	set(value):
		if(lp_line): lp_line.sharp_limit = value
	get:
		return lp_line.sharp_limit if lp_line else 2.0

## The smoothness of the rounded joints and caps
@export var border_round_precision: int = 8:
	set(value):
		if(lp_line): lp_line.round_precision = value
	get:
		return lp_line.round_precision if lp_line else 8

## If true the polyline border will be antialiased
## Note: Antialiased polylines are not accelerated by batching
@export var border_antialiased: bool = false:
	set(value):
		if(lp_line): lp_line.antialiased = value
	get:
		return lp_line.antialiased if lp_line else false

#---------------------------------------------------------------------------------------------------
# VIRTUAL METHODS
#---------------------------------------------------------------------------------------------------

func _init() -> void:
	if(!lp_line):
		lp_line = Line2D.new()

func _ready() -> void:
	lp_clear_duplicated_internal_children()
	lp_line.set_meta("__lp2d_internal__", true)
	add_child(lp_line)
	if(!curve || curve.point_count < 2):
		curve = lp_create_default_curve(LP_DEFAULT_CURVE_SIZE)
	if(!lp_line.width_curve):
		lp_line.width_curve = lp_create_default_profile(LP_DEFAULT_CURVE_WIDTH)
	lp_build_line()
	if(curve && !curve.changed.is_connected(lp_build_line)):
		curve.changed.connect(lp_build_line)

#---------------------------------------------------------------------------------------------------
# PRIVATE METHODS
#---------------------------------------------------------------------------------------------------

func lp_create_default_curve(size:int) -> Curve2D:
	if(!LP_CREATE_DEFAULT_CURVE): return null
	var c = Curve2D.new()
	c.add_point(Vector2.ZERO, Vector2.ZERO, Vector2(size,0))
	c.add_point(Vector2(size,size), Vector2(-size,0), Vector2.ZERO)
	return c

func lp_create_default_profile(size:float) -> Curve:
	if(!LP_CREATE_DEFAULT_PROFILE): return null
	var c = Curve.new()
	c.add_point(Vector2.ZERO)
	c.add_point(Vector2(0.5,1))
	c.add_point(Vector2(1.0, 0))
	return c

func lp_build_line() -> void:
	if(!lp_line):
		return
	if(!curve || curve.point_count < 2): 
		lp_line.clear_points()
		return
	lp_line.points = curve.get_baked_points()

func lp_clear_duplicated_internal_children():
	for c in get_children(): 
		if(c.get_meta("__lp2d_internal__", false)):
			c.queue_free()


#---------------------------------------------------------------------------------------------------
# KNOWN BUGS/LIMITATIONS:
#
# *) Changing the 'Path2D.curve' in the editor will result in an unexpected behaviour
# 		TO-FIX: Overriding the default setter 'Path2D.set_curve(value)', it's not currently possible.
# 		PROPOSAL: https://github.com/godotengine/godot-proposals/issues/8045
