class_name EffectType extends Resource
## A type of Effect - just holds the name and desc. For comparing two
## types, and allowing both sides to get the name & desc w/o caring about each other.

@export var name:String
@export_multiline() var description:String
