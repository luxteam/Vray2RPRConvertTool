
'''

	Vray to RadeonProRender Converter

	History:
	v.1.0 - First version


'''

import maya.mel as mel
import maya.cmds as cmds
import time
import math
import traceback

MAX_RAY_DEPTH = None

# log functions

def write_converted_property_log(rpr_name, rs_name, rpr_attr, rs_attr):

	try:
		file_path = cmds.file(q=True, sceneName=True) + ".log"
		with open(file_path, 'a') as f:
			f.write(u"    property {}.{} is converted to {}.{}   \r\n".format(rs_name, rs_attr, rpr_name, rpr_attr).encode('utf-8'))
	except Exception as ex:
		pass


def write_own_property_log(text):

	try:
		file_path = cmds.file(q=True, sceneName=True) + ".log"
		with open(file_path, 'a') as f:
			f.write("    {}   \r\n".format(text))
	except Exception as ex:
		pass


def start_log(rs, rpr):

	try:
		text  = u"Found node: \r\n    name: {} \r\n".format(rs).encode('utf-8')
		text += "type: {} \r\n".format(cmds.objectType(rs))
		text += u"Converting to: \r\n    name: {} \r\n".format(rpr).encode('utf-8')
		text += "type: {} \r\n".format(cmds.objectType(rpr))
		text += "Conversion details: \r\n"

		file_path = cmds.file(q=True, sceneName=True) + ".log"
		with open(file_path, 'a') as f:
			f.write(text)
	except Exception as ex:
		pass
	


def end_log(rs):

	try:
		text  = u"Conversion of {} is finished.\n\n \r\n".format(rs).encode('utf-8')

		file_path = cmds.file(q=True, sceneName=True) + ".log"
		with open(file_path, 'a') as f:
			f.write(text)
	except Exception as ex:
		pass
		

# additional fucntions

def copyProperty(rpr_name, conv_name, rpr_attr, conv_attr):

	# full name of attribute
	conv_field = conv_name + "." + conv_attr
	rpr_field = rpr_name + "." + rpr_attr
	vr_type = type(getProperty(conv_name, conv_attr))
	rpr_type = type(getProperty(rpr_name, rpr_attr))

	try:
		listConnections = cmds.listConnections(conv_field)
		# connection convert
		if listConnections and cmds.objectType(listConnections[0]) != "transform":
			obj, channel = cmds.connectionInfo(conv_field, sourceFromDestination=True).split('.')
			source_name, source_attr = convertMaterial(obj, channel).split('.')
			connectProperty(source_name, source_attr, rpr_name, rpr_attr)
		# complex color conversion for each channel (RGB/XYZ/HSV)
		elif not listConnections and vr_type == tuple:
			# changing attr
			if cmds.objectType(conv_name) == 'VRayMtl' and conv_attr == 'color':
				conv_attr = "diffuseColor"
				conv_field = conv_name + "." + conv_attr
			# RGB (vray)
			if cmds.objExists(conv_field + "R") and cmds.objExists(rpr_field + "R"):
				copyProperty(rpr_name, conv_name, rpr_attr + "R", conv_attr + "R")
				copyProperty(rpr_name, conv_name, rpr_attr + "G", conv_attr + "G")
				copyProperty(rpr_name, conv_name, rpr_attr + "B", conv_attr + "B")
			elif cmds.objExists(conv_field + "R") and cmds.objExists(rpr_field + "X"):
				copyProperty(rpr_name, conv_name, rpr_attr + "X", conv_attr + "R")
				copyProperty(rpr_name, conv_name, rpr_attr + "Y", conv_attr + "G")
				copyProperty(rpr_name, conv_name, rpr_attr + "Z", conv_attr + "B")
			elif cmds.objExists(conv_field + "R") and cmds.objExists(rpr_field + "H"):
				copyProperty(rpr_name, conv_name, rpr_attr + "H", conv_attr + "R")
				copyProperty(rpr_name, conv_name, rpr_attr + "S", conv_attr + "G")
				copyProperty(rpr_name, conv_name, rpr_attr + "V", conv_attr + "B")
			# XYZ (vray)
			elif cmds.objExists(conv_field + "X") and cmds.objExists(rpr_field + "R"):
				copyProperty(rpr_name, conv_name, rpr_attr + "R", conv_attr + "X")
				copyProperty(rpr_name, conv_name, rpr_attr + "G", conv_attr + "Y")
				copyProperty(rpr_name, conv_name, rpr_attr + "B", conv_attr + "Z")
			elif cmds.objExists(conv_field + "X") and cmds.objExists(rpr_field + "X"):
				copyProperty(rpr_name, conv_name, rpr_attr + "X", conv_attr + "X")
				copyProperty(rpr_name, conv_name, rpr_attr + "Y", conv_attr + "Y")
				copyProperty(rpr_name, conv_name, rpr_attr + "Z", conv_attr + "Z")
			elif cmds.objExists(conv_field + "X") and cmds.objExists(rpr_field + "H"):
				copyProperty(rpr_name, conv_name, rpr_attr + "H", conv_attr + "X")
				copyProperty(rpr_name, conv_name, rpr_attr + "S", conv_attr + "Y")
				copyProperty(rpr_name, conv_name, rpr_attr + "V", conv_attr + "Z")
			# HSV (vray)
			elif cmds.objExists(conv_field + "H") and cmds.objExists(rpr_field + "R"):
				copyProperty(rpr_name, conv_name, rpr_attr + "R", conv_attr + "H")
				copyProperty(rpr_name, conv_name, rpr_attr + "G", conv_attr + "S")
				copyProperty(rpr_name, conv_name, rpr_attr + "B", conv_attr + "V")
			elif cmds.objExists(conv_field + "H") and cmds.objExists(rpr_field + "X"):
				copyProperty(rpr_name, conv_name, rpr_attr + "X", conv_attr + "H")
				copyProperty(rpr_name, conv_name, rpr_attr + "Y", conv_attr + "S")
				copyProperty(rpr_name, conv_name, rpr_attr + "Z", conv_attr + "V")
			elif cmds.objExists(conv_field + "H") and cmds.objExists(rpr_field + "H"):
				copyProperty(rpr_name, conv_name, rpr_attr + "H", conv_attr + "H")
				copyProperty(rpr_name, conv_name, rpr_attr + "S", conv_attr + "S")
				copyProperty(rpr_name, conv_name, rpr_attr + "V", conv_attr + "V")
			else:
				print("Failed to find right variant for {}.{} conversion".format(conv_name, conv_attr))

		# field conversion
		else:
			if vr_type == rpr_type or vr_type == unicode:
				setProperty(rpr_name, rpr_attr, getProperty(conv_name, conv_attr))
			elif vr_type == tuple and rpr_type == float:
				if cmds.objExists(conv_field + "R"):
					conv_attr += "R"
				elif cmds.objExists(conv_field + "X"):
					conv_attr += "X"
				elif cmds.objExists(conv_field + "H"):
					conv_attr += "H"
				setProperty(rpr_name, rpr_attr, getProperty(conv_name, conv_attr))
			elif vr_type == float and rpr_type == tuple:
				if cmds.objExists(rpr_field + "R"):
					rpr_attr1 = rpr_attr + "R"
					rpr_attr2 = rpr_attr + "G"
					rpr_attr3 = rpr_attr + "B"
				elif cmds.objExists(rpr_field + "X"):
					rpr_attr1 = rpr_attr + "X"
					rpr_attr2 = rpr_attr + "Y"
					rpr_attr3 = rpr_attr + "Z"
				elif cmds.objExists(conv_field + "H"):
					rpr_attr1 = rpr_attr + "H"
					rpr_attr2 = rpr_attr + "S"
					rpr_attr3 = rpr_attr + "V"
				setProperty(rpr_name, rpr_attr1, getProperty(conv_name, conv_attr))
				setProperty(rpr_name, rpr_attr2, getProperty(conv_name, conv_attr))
				setProperty(rpr_name, rpr_attr3, getProperty(conv_name, conv_attr))

			write_converted_property_log(rpr_name, conv_name, rpr_attr, conv_attr)
	except Exception as ex:
		traceback.print_exc()
		print(u"Error while copying from {} to {}".format(conv_field, rpr_field).encode('utf-8'))


def setProperty(rpr_name, rpr_attr, value):

	# full name of attribute
	rpr_field = rpr_name + "." + rpr_attr

	try:
		if type(value) == tuple:
			cmds.setAttr(rpr_field, value[0], value[1], value[2])
		elif type(value) == str or type(value) == unicode:
			cmds.setAttr(rpr_field, value, type="string")
		else:
			cmds.setAttr(rpr_field, value)
		write_own_property_log(u"Set value {} to {}.".format(value, rpr_field).encode('utf-8'))
	except Exception as ex:
		traceback.print_exc()
		print(u"Set value {} to {} is failed. Check the values and their boundaries. ".format(value, rpr_field).encode('utf-8'))
		write_own_property_log(u"Set value {} to {} is failed. Check the values and their boundaries. ".format(value, rpr_field).encode('utf-8'))


def getProperty(material, attr):

	# full name of attribute
	field = material + "." + attr
	try:
		value = cmds.getAttr(field)
		if type(value) == list:
			value = value[0]
	except Exception as ex:
		traceback.print_exc()
		write_own_property_log(u"There is no {} field in this node. Check the field and try again. ".format(field).encode('utf-8'))
		return

	return value


def mapDoesNotExist(rs_name, rs_attr):

	# full name of attribute
	rs_field = rs_name + "." + rs_attr

	try:
		if cmds.listConnections(rs_field):
			return 0
		elif cmds.objExists(rs_field + "R"):
			if cmds.listConnections(rs_field + "R") or cmds.listConnections(rs_field + "G") or cmds.listConnections(rs_field + "B"):
				return 0
		elif cmds.objExists(rs_field + "X"):
			if cmds.listConnections(rs_field + "X") or cmds.listConnections(rs_field + "Y") or cmds.listConnections(rs_field + "Z"):
				return 0
		elif cmds.objExists(rs_field + "H"):
			if cmds.listConnections(rs_field + "H") or cmds.listConnections(rs_field + "S")	or cmds.listConnections(rs_field + "V"):
				return 0
	except Exception as ex:
		traceback.print_exc()
		write_own_property_log(u"There is no {} field in this node. Check the field and try again. ".format(rs_field).encode('utf-8'))
		return

	return 1


def connectProperty(source_name, source_attr, rpr_name, rpr_attr):

	# full name of attribute
	source = source_name + "." + source_attr
	rpr_field = rpr_name + "." + rpr_attr

	try:
		source_type = type(getProperty(source_name, source_attr))
		dest_type = type(getProperty(rpr_name, rpr_attr))

		if rpr_attr in ("surfaceShader", "volumeShader"):
			cmds.connectAttr(source, rpr_field, force=True)

		elif cmds.objExists(source_name + ".outAlpha") and cmds.objExists(source_name + ".outColor"):

			if cmds.objectType(source_name) == "file":
				setProperty(source_name, "ignoreColorSpaceFileRules", 1)

			if source_type == dest_type:
				cmds.connectAttr(source, rpr_field, force=True)
			elif source_type == tuple and dest_type == float:
				source = source_name + ".outAlpha"
				cmds.connectAttr(source, rpr_field, force=True)
			elif source_type == float and dest_type == tuple:
				source = source_name + ".outColor"
				cmds.connectAttr(source, rpr_field, force=True)

		else:
			if source_type == dest_type:
				cmds.connectAttr(source, rpr_field, force=True)
			elif source_type == tuple and dest_type == float:
				if cmds.objExists(source + "R"):
					source += "R"
				elif cmds.objExists(source + "X"):
					source += "X"
				elif cmds.objExists(source + "X"):
					source += "H"
				cmds.connectAttr(source, rpr_field, force=True)
			elif source_type == float and dest_type == tuple:
				if cmds.objExists(rpr_field + "R"):
					rpr_field1 = rpr_field + "R"
					rpr_field2 = rpr_field + "G"
					rpr_field3 = rpr_field + "B"
				elif cmds.objExists(rpr_field + "X"):
					rpr_field1 = rpr_field + "X"
					rpr_field2 = rpr_field + "Y"
					rpr_field3 = rpr_field + "Z"
				elif cmds.objExists(rpr_field + "H"):
					rpr_field1 = rpr_field + "H"
					rpr_field2 = rpr_field + "S"
					rpr_field3 = rpr_field + "V"
				cmds.connectAttr(source, rpr_field1, force=True)
				cmds.connectAttr(source, rpr_field2, force=True)
				cmds.connectAttr(source, rpr_field3, force=True)

		write_own_property_log(u"Created connection from {} to {}.".format(source, rpr_field).encode('utf-8'))
	except Exception as ex:
		traceback.print_exc()
		print(u"Connection {} to {} is failed.".format(source, rpr_field).encode('utf-8'))
		write_own_property_log(u"Connection {} to {} is failed.".format(source, rpr_field).encode('utf-8'))


def invertValue(rpr_name, conv_name, rpr_attr, conv_attr):
	connection = cmds.listConnections(conv_name + "." + conv_attr)
	if connection and cmds.objectType(connection[0]) == "reverse":
		if mapDoesNotExist(connection[0], "input"):
			setProperty(rpr_name, rpr_attr, getProperty(connection[0], "input"))
		else:
			if cmds.listConnections(connection[0] + ".input"):
				copyProperty(rpr_name, connection[0],  rpr_attr, "input")
			elif cmds.listConnections(connection[0] + ".inputX"):
				copyProperty(rpr_name, connection[0],  rpr_attr, "inputX")
			elif cmds.listConnections(connection[0] + ".inputY"):
				copyProperty(rpr_name, connection[0],  rpr_attr, "inputY")
			elif cmds.listConnections(connection[0] + ".inputZ"):
				copyProperty(rpr_name, connection[0],  rpr_attr, "inputZ")
	elif connection:
		reverse_arith = cmds.shadingNode("RPRArithmetic", asUtility=True)
		reverse_arith = cmds.rename(reverse_arith, "Reverse_arithmetic")
		setProperty(reverse_arith, "operation", 1)
		setProperty(reverse_arith, "inputA", (1, 1, 1))
		copyProperty(reverse_arith, conv_name, "inputB", conv_attr)
		connectProperty(reverse_arith, "out", rpr_name, rpr_attr)
	else:
		conv_value = getProperty(conv_name, conv_attr)
		if type(conv_value) == float:
			setProperty(rpr_name, rpr_attr, 1 - conv_value)
		elif type(conv_value) == tuple:
			setProperty(rpr_name, rpr_attr, (1 - conv_value[0], 1 - conv_value[1], 1 - conv_value[2]))

	

def convertbump2d(conv_name, source):

	if cmds.objExists(conv_name + "_rpr"):
		rpr = conv_name + "_rpr"
	else:
		bump_type = getProperty(conv_name, "bumpInterp")
		if not bump_type:
			rpr = cmds.shadingNode("RPRBump", asUtility=True)
			rpr = cmds.rename(rpr, conv_name + "_rpr")
		else:
			rpr = cmds.shadingNode("RPRNormal", asUtility=True)
			rpr = cmds.rename(rpr, conv_name + "_rpr")

		# Logging to file
		start_log(conv_name, rpr)

		# Fields conversion
		copyProperty(rpr, conv_name, "color", "bumpValue")
		copyProperty(rpr, conv_name, "strength", "bumpDepth")

		# Logging to file
		end_log(conv_name)

	conversion_map = {
		"outNormal": "out",
		"outNormalX": "outX",
		"outNormalY": "outY",
		"outNormalZ": "outZ"
	}

	rpr += "." + conversion_map[source]
	return rpr


def convertBlendColors(conv_name, source):

	if cmds.objExists(conv_name + "_rpr"):
		rpr = conv_name + "_rpr"
	else:
		rpr = cmds.shadingNode("RPRBlendValue", asUtility=True)
		rpr = cmds.rename(rpr, conv_name + "_rpr")

		# Logging to file
		start_log(conv_name, rpr)

		# Fields conversion
		copyProperty(rpr, conv_name, "inputA", "color1")
		copyProperty(rpr, conv_name, "inputB", "color2")
		copyProperty(rpr, conv_name, "weight", "blender")

		# Logging to file
		end_log(conv_name)

	conversion_map = {
		"output": "out",
		"outputR": "outR",
		"outputG": "outG",
		"outputB": "outB"
	}

	rpr += "." + conversion_map[source]
	return rpr


def convertLuminance(conv_name, source):

	if cmds.objExists(conv_name + "_rpr"):
		rpr = conv_name + "_rpr"
	else:
		rpr = cmds.shadingNode("RPRArithmetic", asUtility=True)
		rpr = cmds.rename(rpr, conv_name + "_rpr")

		# Logging to file
		start_log(conv_name, rpr)

		# Fields conversion
		copyProperty(rpr, conv_name, "inputA", "value")
		setProperty(rpr, "inputB", (0, 0, 0))
		setProperty(rpr, "operation", 19)

		# Logging to file
		end_log(conv_name)

	conversion_map = {
		"outValue": "outX"
	}

	rpr += "." + conversion_map[source]
	return rpr


def convertColorComposite(conv_name, source):

	operation = getProperty(conv_name, "operation")
	if operation == 2:
		if cmds.objExists(conv_name + "_rpr"):
			rpr = conv_name + "_rpr"
		else:
			rpr = cmds.shadingNode("RPRBlendValue", asUtility=True)
			rpr = cmds.rename(rpr, conv_name + "_rpr")

			# Logging to file
			start_log(conv_name, rpr)

			# Fields conversion
			copyProperty(rpr, conv_name, "inputA", "alphaA")
			copyProperty(rpr, conv_name, "inputB", "alphaB")
			copyProperty(rpr, conv_name, "weight", "factor")
			

			# Logging to file
			end_log(conv_name)

		conversion_map = {
			"outAlpha": "outR"
		}

		rpr += "." + conversion_map[source]
		return rpr

	else:

		if cmds.objExists(conv_name + "_rpr"):
			rpr = conv_name + "_rpr"
		else:
			rpr = cmds.shadingNode("RPRArithmetic", asUtility=True)
			rpr = cmds.rename(rpr, conv_name + "_rpr")

			# Logging to file
			start_log(conv_name, rpr)

			# Fields conversion
			if operation in (0, 4, 5):
				setProperty(rpr, "operation", 0)
				if source == "outAlpha":
					copyProperty(rpr, conv_name, "inputA", "alphaA")
					copyProperty(rpr, conv_name, "inputB", "alphaB")
				else:
					copyProperty(rpr, conv_name, "inputA", "colorA")
					copyProperty(rpr, conv_name, "inputB", "colorB")
			elif operation == 1:
				if source == "outAlpha":
					if mapDoesNotExist(conv_name, "alphaA") and mapDoesNotExist(conv_name, "alphaB"):
						alphaA = getProperty(conv_name, alphaA)
						alphaB = getProperty(conv_name, alphaB)
						if alphaA > alphaB:
							copyProperty(rpr, conv_name, "inputA", "alphaA")
							copyProperty(rpr, conv_name, "inputB", "alphaB")
						else:
							copyProperty(rpr, conv_name, "inputA", "alphaB")
							copyProperty(rpr, conv_name, "inputB", "alphaA")
					elif mapDoesNotExist(conv_name, "alphaA"):
						copyProperty(rpr, conv_name, "inputA", "alphaA")
						copyProperty(rpr, conv_name, "inputB", "alphaB")
					elif mapDoesNotExist(conv_name, "alphaB"):
						copyProperty(rpr, conv_name, "inputA", "alphaB")
						copyProperty(rpr, conv_name, "inputB", "alphaA")
					else:
						copyProperty(rpr, conv_name, "inputA", "alphaA")
						copyProperty(rpr, conv_name, "inputB", "alphaB")
				else:
					if mapDoesNotExist(conv_name, "colorA") and mapDoesNotExist(conv_name, "colorB"):
						colorA = getProperty(conv_name, alphaA)
						colorB = getProperty(conv_name, colorB)
						if colorA[0] > colorB[0] or colorA[1] > colorB[1] or colorA[2] > colorB[2]:
							copyProperty(rpr, conv_name, "inputA", "colorA")
							copyProperty(rpr, conv_name, "inputB", "colorB")
						else:
							copyProperty(rpr, conv_name, "inputA", "colorB")
							copyProperty(rpr, conv_name, "inputB", "colorA")
					elif mapDoesNotExist(conv_name, "colorA"):
						copyProperty(rpr, conv_name, "inputA", "colorA")
						copyProperty(rpr, conv_name, "inputB", "colorB")
					elif mapDoesNotExist(conv_name, "colorB"):
						copyProperty(rpr, conv_name, "inputA", "colorB")
						copyProperty(rpr, conv_name, "inputB", "colorA")
					else:
						copyProperty(rpr, conv_name, "inputA", "colorA")
						copyProperty(rpr, conv_name, "inputB", "colorB")
			elif operation == 3:
				setProperty(rpr, "operation", 2)
				if source == "outAlpha":
					copyProperty(rpr, conv_name, "inputA", "alphaA")
					copyProperty(rpr, conv_name, "inputB", "alphaB")
				else:
					copyProperty(rpr, conv_name, "inputA", "colorA")
					copyProperty(rpr, conv_name, "inputB", "colorB")
			elif operation == 6:
				setProperty(rpr, "operation", 1)
				if source == "outAlpha":
					if mapDoesNotExist(conv_name, "alphaA"):
						copyProperty(rpr, conv_name, "inputB", "alphaA")
						copyProperty(rpr, conv_name, "inputA", "alphaB")
					else:
						copyProperty(rpr, conv_name, "inputA", "alphaA")
						copyProperty(rpr, conv_name, "inputB", "alphaB")
				else:
					if mapDoesNotExist(conv_name, "alphaA"):
						copyProperty(rpr, conv_name, "inputB", "colorA")
						copyProperty(rpr, conv_name, "inputA", "colorB")
					else:
						copyProperty(rpr, conv_name, "inputA", "colorA")
						copyProperty(rpr, conv_name, "inputB", "colorB")
			elif operation == 7:
				setProperty(rpr, "operation", 25)
				if source == "outAlpha":
					copyProperty(rpr, conv_name, "inputA", "alphaB")
					copyProperty(rpr, conv_name, "inputB", "alphaA")
				else:
					copyProperty(rpr, conv_name, "inputA", "colorB")
					copyProperty(rpr, conv_name, "inputB", "colorA")
			elif operation == 8:
				setProperty(rpr, "operation", 20)
				if source == "outAlpha":
					copyProperty(rpr, conv_name, "inputA", "alphaA")
					copyProperty(rpr, conv_name, "inputB", "alphaB")
				else:
					copyProperty(rpr, conv_name, "inputA", "colorA")
					copyProperty(rpr, conv_name, "inputB", "colorB")


			# Logging to file
			end_log(conv_name)

		conversion_map = {
			"outAlpha": "outX",
			"outColor": "out",
			"outColorR": "outX",
			"outColorG": "outY",
			"outColorB": "outZ"
		}

		rpr += "." + conversion_map[source]
		return rpr


def convertReverse(conv_name, source):

	if cmds.objExists(conv_name + "_rpr"):
		rpr = conv_name + "_rpr"
	else:
		rpr = cmds.shadingNode("RPRArithmetic", asUtility=True)
		rpr = cmds.rename(rpr, conv_name + "_rpr")

		# Logging to file
		start_log(conv_name, rpr)

		# Fields conversion
		setProperty(rpr, "inputA", (1, 1, 1))
		copyProperty(rpr, conv_name, "inputB", "input")
		setProperty(rpr, "operation", 1)

		# Logging to file
		end_log(conv_name)

	conversion_map = {
		"output": "out",
		"outputX": "outX",
		"outputY": "outY",
		"outputZ": "outZ"
	}

	rpr += "." + conversion_map[source]
	return rpr


def convertPreMultiply(conv_name, source):

	if cmds.objExists(conv_name + "_rpr"):
		rpr = conv_name + "_rpr"
	else:
		rpr = cmds.shadingNode("RPRArithmetic", asUtility=True)
		rpr = cmds.rename(rpr, conv_name + "_rpr")

		# Logging to file
		start_log(conv_name, rpr)

		# Fields conversion
		copyProperty(rpr, conv_name, "inputA", "inColor")
		alpha = getProperty(conv_name, "inAlpha")
		setProperty(rpr, "inputB", (alpha, alpha, alpha))
		setProperty(rpr, "operation", 2)

		# Logging to file
		end_log(conv_name)

	conversion_map = {
		"outAlpha": "outX",
		"outColor": "out",
		"outColorR": "outX",
		"outColorG": "outY",
		"outColorB": "outZ"
	}

	rpr += "." + conversion_map[source]
	return rpr


def convertVectorProduct(conv_name, source):

	operation = getProperty(conv_name, "operation")
	if operation in (1, 2):
		if cmds.objExists(conv_name + "_rpr"):
			rpr = conv_name + "_rpr"
		else:
			rpr = cmds.shadingNode("RPRArithmetic", asUtility=True)
			rpr = cmds.rename(rpr, conv_name + "_rpr")

			# Logging to file
			start_log(conv_name, rpr)

			# Fields conversion
			if operation == 1:
				setProperty(rpr, "operation", 11)
			elif operation == 2:
				setProperty(rpr, "operation", 12)

			copyProperty(rpr, conv_name, "inputA", "input1")
			copyProperty(rpr, conv_name, "inputB", "input2")

			# Logging to file
			end_log(conv_name)

		conversion_map = {
			"output": "out",
			"outputX": "outX",
			"outputY": "outY",
			"outputZ": "outZ"
		}

		rpr += "." + conversion_map[source]
		return rpr
	else:
		conv_name += "." + source
		return conv_name


def convertChannels(conv_name, source):

	if "outColor" in source:

		if cmds.objExists(conv_name + "_color_rpr"):
			rpr = conv_name + "_color_rpr"
		else:

			rpr = cmds.shadingNode("RPRArithmetic", asUtility=True)
			rpr = cmds.rename(rpr, conv_name + "_color_rpr")

			# Logging to file
			start_log(conv_name, rpr)

			# Fields conversion
			copyProperty(rpr, conv_name, "inputA", "inColor")

			# Logging to file
			end_log(conv_name)

		conversion_map = {
			"outColor": "out",
			"outColorR": "outX",
			"outColorG": "outY",
			"outColorB": "outZ"
		}

		rpr += "." + conversion_map[source]
		return rpr

	elif "outAlpha" in source:

		if cmds.objExists(conv_name + "_alpha_rpr"):
			rpr = conv_name + "_alpha_rpr"
		else:

			rpr = cmds.shadingNode("RPRArithmetic", asUtility=True)
			rpr = cmds.rename(rpr, conv_name + "_alpha_rpr")

			# Logging to file
			start_log(conv_name, rpr)

			# Fields conversion
			copyProperty(rpr, conv_name, "inputA", "inAlpha")

			# Logging to file
			end_log(conv_name)

		conversion_map = {
			"outAlpha": "outX"
		}

		rpr += "." + conversion_map[source]
		return rpr


def convertmultiplyDivide(conv_name, source):

	if cmds.objExists(conv_name + "_rpr"):
		rpr = conv_name + "_rpr"
	else:
		rpr = cmds.shadingNode("RPRArithmetic", asUtility=True)
		rpr = cmds.rename(rpr, conv_name + "_rpr")

		# Logging to file
		start_log(conv_name, rpr)

		# Fields conversion
		operation = getProperty(conv_name, "operation")
		operation_map = {
			1: 2,
			2: 3,
			3: 15
		}
		setProperty(rpr, "operation", operation_map[operation])
		copyProperty(rpr, conv_name, "inputA", "input1")
		copyProperty(rpr, conv_name, "inputB", "input2")
		
		# Logging to file
		end_log(conv_name)

	conversion_map = {
		"output": "out",
		"outputX": "outX",
		"outputY": "outY",
		"outputZ": "outZ"
	}

	rpr += "." + conversion_map[source]
	return rpr


# standard utilities
def convertStandardNode(vrayMaterial, source):

	not_converted_list = ("materialInfo", "defaultShaderList", "shadingEngine", "place2dTexture")
	try:
		for attr in cmds.listAttr(vrayMaterial):
			connection = cmds.listConnections(vrayMaterial + "." + attr)
			if connection:
				if cmds.objectType(connection[0]) not in not_converted_list and attr not in (source, "message"):
					obj, channel = cmds.connectionInfo(vrayMaterial + "." + attr, sourceFromDestination=True).split('.')
					source_name, source_attr = convertMaterial(obj, channel).split('.')
					connectProperty(source_name, source_attr, vrayMaterial, attr)
	except Exception as ex:
		pass

	return vrayMaterial + "." + source


# unsupported utilities
def convertUnsupportedNode(vrayMaterial, source, postfix="_UNSUPPORTED_NODE"):

	if cmds.objExists(vrayMaterial + postfix):
		rpr = vrayMaterial + postfix
	else:
		rpr = cmds.shadingNode("RPRArithmetic", asUtility=True)
		rpr = cmds.rename(rpr, vrayMaterial + postfix)

		# Logging to file
		start_log(vrayMaterial, rpr)

		# 2 connection save
		try:
			setProperty(rpr, "operation", 0)
			unsupported_connections = 0
			for attr in cmds.listAttr(vrayMaterial):
				connection = cmds.listConnections(vrayMaterial + "." + attr)
				if connection:
					if cmds.objectType(connection[0]) not in ("materialInfo", "defaultShaderList", "shadingEngine") and attr not in (source, "message"):
						if unsupported_connections < 2:
							obj, channel = cmds.connectionInfo(vrayMaterial + "." + attr, sourceFromDestination=True).split('.')
							source_name, source_attr = convertMaterial(obj, channel).split('.')
							valueType = type(getProperty(vrayMaterial, attr))
							if valueType == tuple:
								if unsupported_connections < 1:
									connectProperty(source_name, source_attr, rpr, "inputA")
								else:
									connectProperty(source_name, source_attr, rpr, "inputB")
							else:
								if unsupported_connections < 1:
									connectProperty(source_name, source_attr, rpr, "inputAX")
								else:
									connectProperty(source_name, source_attr, rpr, "inputBX")
							unsupported_connections += 1
		except Exception as ex:
			traceback.print_exc()

		# Logging to file
		end_log(vrayMaterial)

	sourceType = type(getProperty(vrayMaterial, source))
	if sourceType == tuple:
		rpr += ".out"
	else:
		rpr += ".outX"

	return rpr


# Create default uber material for unsupported material
def convertUnsupportedMaterial(vrayMaterial, source):

	assigned = checkAssign(vrayMaterial)
	
	if cmds.objExists(vrayMaterial + "_rpr"):
		rprMaterial = vrayMaterial + "_rpr"
	else:
		# Creating new Uber material
		rprMaterial = cmds.shadingNode("RPRUberMaterial", asShader=True)
		rprMaterial = cmds.rename(rprMaterial, (vrayMaterial + "_UNSUPPORTED_MATERIAL"))

		# Check shading engine in vrayMaterial
		if assigned:
			sg = rprMaterial + "SG"
			cmds.sets(renderable=True, noSurfaceShader=True, empty=True, name=sg)
			connectProperty(rprMaterial, "outColor", sg, "surfaceShader")

		# Logging to file
		start_log(vrayMaterial, rprMaterial)

		# set green color
		setProperty(rprMaterial, "diffuseColor", (0, 1, 0))

		end_log(vrayMaterial)

	if source:
		rprMaterial += "." + source
	return rprMaterial


######################## 
##  VRayMtl
########################

def convertVRayMtl(vrMaterial, source):

	assigned = checkAssign(vrMaterial)
	
	if cmds.objExists(vrMaterial + "_rpr"):
		rprMaterial = vrMaterial + "_rpr"
	else:
		# Creating new Uber material
		rprMaterial = cmds.shadingNode("RPRUberMaterial", asShader=True)
		rprMaterial = cmds.rename(rprMaterial, vrMaterial + "_rpr")

		# Check shading engine in vrMaterial
		if assigned:
			sg = rprMaterial + "SG"
			cmds.sets(renderable=True, noSurfaceShader=True, empty=True, name=sg)
			connectProperty(rprMaterial, "outColor", sg, "surfaceShader")
			
		# Enable properties, which are default in VRay
		defaultEnable(rprMaterial, vrMaterial, "diffuse", "diffuseColorAmount")
		defaultEnable(rprMaterial, vrMaterial, "reflections", "reflectionColorAmount")
		defaultEnable(rprMaterial, vrMaterial, "refraction", "refractionColorAmount")
		
		# Logging to file
		start_log(vrMaterial, rprMaterial)

		# Basic parameters
		copyProperty(rprMaterial, vrMaterial, "diffuseColor", "color")
		copyProperty(rprMaterial, vrMaterial, "diffuseWeight", "diffuseColorAmount")
		copyProperty(rprMaterial, vrMaterial, "diffuseRoughness", "roughnessAmount")
		illumColor = getProperty(vrMaterial, 'illumColor')
		if illumColor[0] or illumColor[1] or illumColor[2]:
			setProperty(rprMaterial, 'emissive', 1)
			copyProperty(rprMaterial, vrMaterial, "emissiveColor", "illumColor")

		# opacity
		opacity_color = getProperty(vrMaterial, "opacityMap")
		if opacity_color[0] < 1 or opacity_color[1] < 1 or opacity_color[2] < 1:
			if mapDoesNotExist(vrMaterial, "opacityMap"):
				transparency = 1 - max(getProperty(vrMaterial, "opacityMap"))
				setProperty(rprMaterial, "transparencyLevel", transparency)
			else:
				invertValue(rprMaterial, vrMaterial, "transparencyLevel", "opacityMap")
			setProperty(rprMaterial, "transparencyEnable", 1)

		# reflection
		copyProperty(rprMaterial, vrMaterial, "reflectColor", "reflectionColor")
		copyProperty(rprMaterial, vrMaterial, "reflectWeight", "reflectionColorAmount")

		useRoughness = getProperty(vrMaterial, 'useRoughness')
		if useRoughness:
			copyProperty(rprMaterial, vrMaterial, "reflectRoughness", "reflectionGlossiness")
		else:
			invertValue(rprMaterial, vrMaterial, 'reflectRoughness', 'reflectionGlossiness')

		lockFresnelIORToRefractionIOR = getProperty(vrMaterial, 'lockFresnelIORToRefractionIOR')
		if lockFresnelIORToRefractionIOR:
			setProperty(rprMaterial, 'refraction', 1)
			setProperty(rprMaterial, 'refractLinkToReflect', 1)

		copyProperty(rprMaterial, vrMaterial, "reflectIOR", "fresnelIOR")
		fresnelIOR = getProperty(vrMaterial, 'fresnelIOR')
		if fresnelIOR < 0.1 or fresnelIOR > 10:
			setProperty(rprMaterial, 'reflectMetalMaterial') 

		copyProperty(rprMaterial, vrMaterial, "reflectAnisotropy", "anisotropy")
		anisotropyDerivation = getProperty(vrMaterial, 'anisotropyDerivation')
		if anisotropyDerivation:
			copyProperty(rprMaterial, vrMaterial, 'reflectAnisotropyRotation', 'anisotropyUVWGen')
		else:
			anisotropyRotation = getProperty(vrMaterial, 'anisotropyRotation')
			anisotropyRotation_mod = math.modf(anisotropyRotation)[0]
			anisotropyAxis = getProperty(vrMaterial, 'anisotropyAxis')
			if anisotropyAxis == 0:
				rprAnisotropyRotation = -0.403 * (anisotropyRotation_mod ** 3) + 0.5714 * (anisotropyRotation_mod ** 2) -1.086 * anisotropyRotation_mod - 0.1993
			elif anisotropyAxis == 1:
				rprAnisotropyRotation = -1 * anisotropyRotation_mod
			elif anisotropyAxis == 2:
				rprAnisotropyRotation = -1.5873 * anisotropyRotation_mod ** 3 + 2.4603 * anisotropyRotation_mod ** 2 - 1.373 * anisotropyRotation_mod + 0.7
				setProperty(rprMaterial, 'reflectAnisotropyRotation', rprAnisotropyRotation)

		global MAX_RAY_DEPTH

		reflectionsMaxDepth = getProperty(vrMaterial, 'reflectionsMaxDepth')
		if MAX_RAY_DEPTH and reflectionsMaxDepth < MAX_RAY_DEPTH:
			MAX_RAY_DEPTH = reflectionsMaxDepth

		refractionsMaxDepth = getProperty(vrMaterial, 'refractionsMaxDepth')
		if MAX_RAY_DEPTH and refractionsMaxDepth < MAX_RAY_DEPTH:
			MAX_RAY_DEPTH = refractionsMaxDepth

		copyProperty(rprMaterial, vrMaterial, 'refractWeight', 'refractionColorAmount')
		invertValue(rprMaterial, vrMaterial, 'refractRoughness', 'refractionGlossiness')
		copyProperty(rprMaterial, vrMaterial, 'refractIor', 'refractionIOR')

		fog_arith = cmds.shadingNode("RPRArithmetic", asUtility=True)
		fog_arith = cmds.rename(fog_arith, "Fog pow")
		setProperty(fog_arith, "operation", 15)
		copyProperty(fog_arith, vrMaterial, 'inputA', 'fogColor')
		copyProperty(fog_arith, vrMaterial, 'inputB', 'fogMult')

		refr_color = cmds.shadingNode("RPRArithmetic", asUtility=True)
		refr_color = cmds.rename(refr_color, "Refr mult")
		setProperty(refr_color, "operation", 2)
		copyProperty(refr_color, vrMaterial, 'inputA', 'refractionColor')
		connectProperty(fog_arith, 'out', refr_color, 'inputB')
		connectProperty(refr_color, 'out', rprMaterial, 'refractColor')

		traceRefractions = getProperty(vrMaterial, 'traceRefractions')
		if traceRefractions:
			setProperty(rprMaterial, 'refraction', 1)

		sssOn = getProperty(vrMaterial, 'sssOn')
		if sssOn:
			setProperty(rprMaterial, 'sssEnable', 1)

		bumpMapType = getProperty(vrMaterial, 'bumpMapType')
		if bumpMapType == 0 or bumpMapType == 1:
			setProperty(rprMaterial, 'normalMapEnable', 1)
			copyProperty(rprMaterial, vrMaterial, 'normalMap', 'bumpMap')

		end_log(vrMaterial)

	if source:
		rprMaterial += "." + source
	return rprMaterial


######################## 
##  VRayCarPaint
########################


######################## 
##  VRayBumpMtl
########################

def convertVRayBumpMtl(vrMaterial, source):

	baseMtl = cmds.listConnections(vrMaterial + '.base_material')[0]

	if cmds.objExists(baseMtl + "_rpr"):
		rprMaterial = baseMtl + "_rpr"
	else:
		rprMaterial = convertMaterial(baseMtl, "")

		sg = rprMaterial + "SG"
		cmds.sets(renderable=True, noSurfaceShader=True, empty=True, name=sg)
		connectProperty(rprMaterial, "outColor", sg, "surfaceShader")

		materialType = cmds.objectType(rprMaterial)
		if materialType == 'RPRUberMaterial':
			if not mapDoesNotExist(vrMaterial, 'bumpMap'):
				if mapDoesNotExist(rprMaterial, 'normalMap'):
					setProperty(rprMaterial,'normalMapEnable', 1)
					copyProperty(rprMaterial, vrMaterial, 'normalMap', 'bumpMap')
				else:
					bumps_blend = cmds.shadingNode("RPRBlendValue", asUtility=True)
					bumps_blend = cmds.rename(bumps_blend, "Blend bumps")
					copyProperty(bumps_blend, rprMaterial, 'inputA', 'normalMap')
					copyProperty(bumps_blend, vrMaterial, 'inputB', 'bumpMap')
					setProperty(rprMaterial,'normalMapEnable', 1)
					connectProperty(bumps_blend, 'out', rprMaterial, 'normalMap')

		if source:
			rprMaterial += "." + source
		return rprMaterial


# Convert material. Returns new material name.
def convertMaterial(material, source):

	material_type = cmds.objectType(material)

	conversion_func = {

		# VRay materials
		"VRayMtl": convertVRayMtl,
		"VRayBumpMtl": convertVRayBumpMtl,
		"VRayCarPaintMtl": convertUnsupportedMaterial,
		"VRayAlSurface": convertUnsupportedMaterial,
		"VRayBlendMtl": convertUnsupportedMaterial,
		"VRayFastSSS2Mtl": convertUnsupportedMaterial,
		"VRayFlakesMtl": convertUnsupportedMaterial,
		"VRayHairNextMtl": convertUnsupportedMaterial,
		"VRayLightMtl": convertUnsupportedMaterial,
		"VRayMeshMaterial": convertUnsupportedMaterial,
		"VRayMtl2Sided": convertUnsupportedMaterial,
		"VRayMtlGLSL": convertUnsupportedMaterial,
		"VRayHair3Mtl": convertUnsupportedMaterial,
		"VRayMtlMDL": convertUnsupportedMaterial,
		"VRayMtlOSL": convertUnsupportedMaterial,
		"VRayMtlRenderStats": convertUnsupportedMaterial,
		"VRayMtlWrapper": convertUnsupportedMaterial,
		"VRayPointParticleMtl": convertUnsupportedMaterial,
		"VRayScannedMtl": convertUnsupportedMaterial,
		"VRayStochasticFlakesMtl": convertUnsupportedMaterial,
		"VRaySwitchMtl": convertUnsupportedMaterial,
		"VRayToonMtl": convertUnsupportedMaterial,
		"VRayVRmatMtl": convertUnsupportedMaterial,

		# VRay Volumetric
		"VRayAerialPerspective": convertUnsupportedMaterial,
		"VRayEnvironmentFog": convertUnsupportedMaterial,
		"VRayScatterFog": convertUnsupportedMaterial,
		"VRaySimpleFog": convertUnsupportedMaterial,
		"VRaySphereFadeVolume": convertUnsupportedMaterial,

		# Standard utilities
		"clamp": convertUnsupportedNode,
		"colorCondition": convertUnsupportedNode,
		"colorComposite": convertColorComposite,
		"blendColors": convertBlendColors,
		"luminance": convertLuminance,
		"reverse": convertReverse,
		"premultiply": convertPreMultiply,
		"channels": convertChannels,
		"vectorProduct": convertVectorProduct,
		"multiplyDivide": convertmultiplyDivide,
		"bump2d": convertbump2d,

		# VRay utilities

	}

	if material_type in conversion_func:
		rpr = conversion_func[material_type](material, source)
	else:
		if isVRayType(material):
			rpr = convertUnsupportedNode(material, source)
		else:
			rpr = convertStandardNode(material, source)

	return rpr


# Convert light. Returns new light name.
def convertLight(light):

	light_type = cmds.objectType(light)

	conversion_func = {

		# VRay lights

		#"VRayLightRectShape": convertVRayLightRectShape,
		#"VRayLightDomeShape": convertVRayLightDomeShape,
		#"VRaySunShape": convertVRaySunShape,
		#"VRaySky": convertVRaySky,
		#"VRayLightSphereShape": convertVRayLightSphereShape,
		#"VRayLightMeshLightLinking": convertVRayLightMeshLightLinking,
		#"VRayLightIESShape": convertVRayLightIESShape,

	}

	conversion_func[light_type](light)


def isVRayType(obj):

	if cmds.objExists(obj):
		objType = cmds.objectType(obj)
		if "VRay" in objType:
			return 1
	return 0


def cleanScene():

	listMaterials= cmds.ls(materials=True)
	for material in listMaterials:
		if isVRayType(material):
			shEng = cmds.listConnections(material, type="shadingEngine")
			try:
				cmds.delete(shEng[0])
				cmds.delete(material)
			except Exception as ex:
				traceback.print_exc()

	listLights = cmds.ls(l=True, type=["VRayLightRectShape", "VRayLightDomeShape", "VRaySunShape", "VRaySky", "VRaySunTarget", "VRayLightSphereShape", \
		"VRayLightMeshLightLinking", "VRayLightIESShape"])
	for light in listLights:
		transform = cmds.listRelatives(light, p=True)
		try:
			cmds.delete(light)
			cmds.delete(transform[0])
		except Exception as ex:
			traceback.print_exc()

	listObjects = cmds.ls(l=True)
	for obj in listObjects:
		if isVRayType(object):
			try:
				cmds.delete(obj)
			except Exception as ex:
				traceback.print_exc()


def remap_value(value, maxInput, minInput, maxOutput, minOutput):

	value = maxInput if value > maxInput else value
	value = minInput if value < minInput else value

	inputDiff = maxInput - minInput
	outputDiff = maxOutput - minOutput

	remapped_value = minOutput + ((float(value - minInput) / float(inputDiff)) * outputDiff)

	return remapped_value


def clampValue(value, minValue, maxValue):
	return max(min(value, maxValue), minValue)


def checkAssign(material):

	if isVRayType(material):
		materialSG = cmds.listConnections(material, type="shadingEngine")
		if materialSG:
			cmds.hyperShade(objects=material)
			assigned = cmds.ls(sl=True)
			if assigned:
				return 1
	return 0


def defaultEnable(RPRmaterial, VRmaterial, enable, value):

	weight = getProperty(VRmaterial, value)
	if weight > 0:
		setProperty(RPRmaterial, enable, 1)
	else:
		setProperty(RPRmaterial, enable, 0)


def defaultEnableByColor(RPRmaterial, VRmaterial, enable, value):

	if mapDoesNotExist(VRmaterial, value):
		vr_value = getProperty(VRmaterial, value)
		vr_value_type = type(vr_value)
		if vr_value_type == tuple:
			if vr_value[0] > 0 and vr_value[1] > 0 and vr_value[2] > 0:
				setProperty(RPRmaterial, enable, 1)
		elif vr_value_type == float:
			if vr_value > 0:
				setProperty(RPRmaterial, enable, 1)
	else:
		setProperty(RPRmaterial, enable, 1)
	


def convertScene():

	# Check plugins
	if not cmds.pluginInfo("vrayformaya", q=True, loaded=True):
		try:
			cmds.loadPlugin("vrayformaya", quiet=True)
		except Exception as ex:
			response = cmds.confirmDialog(title="Error",
							  message=("V-Ray plugin is not installed.\nInstall V-Ray plugin before conversion."),
							  button=["OK"],
							  defaultButton="OK",
							  cancelButton="OK",
							  dismissString="OK")
			exit("V-Ray plugin is not installed")

	if not cmds.pluginInfo("RadeonProRender", q=True, loaded=True):
		try:
			cmds.loadPlugin("RadeonProRender", quiet=True)
		except Exception as ex:
			response = cmds.confirmDialog(title="Error",
							  message=("RadeonProRender plugin is not installed.\nInstall RadeonProRender plugin before conversion."),
							  button=["OK"],
							  defaultButton="OK",
							  cancelButton="OK",
							  dismissString="OK")
			exit("RadeonProRender plugin is not installed")

	# Vray engine set before conversion
	setProperty("defaultRenderGlobals","currentRenderer", "vray")

	# TODO Convert Vray Environment

	'''
	env = cmds.ls(type="VrayEnvironment")
	if env:
		try:
			convertVrayEnvironment(env[0])
		except Exception as ex:
			traceback.print_exc()
			print("Error while converting environment. ")
	'''

	# TODO Convert Vray PhysicalSky

	'''
	sky = cmds.ls(type="VrayPhysicalSky")
	if sky:
		try:
			convertVrayPhysicalSky(sky[0])
		except Exception as ex:
			traceback.print_exc()
			print("Error while converting physical sky. \n")
	'''

	# Get all lights from scene
	listLights = cmds.ls(l=True, type=["VRayLightRectShape", "VRayLightDomeShape", "VRaySunShape", "VRaySky", "VRayLightSphereShape", \
		"VRayLightMeshLightLinking", "VRayLightIESShape", "areaLight", "spotLight", "pointLight", "directionalLight"])

	# Convert lights
	for light in listLights:
		try:
			convertLight(light)
		except Exception as ex:
			traceback.print_exc()
			print("Error while converting {} light. \n".format(light))
		
	# Get all materials from scene
	listMaterials = cmds.ls(materials=True)
	materialsDict = {}
	for each in listMaterials:
		if checkAssign(each):
			materialsDict[each] = convertMaterial(each, "")

	for vr, rpr in materialsDict.items():
		try:
			cmds.hyperShade(objects=vr)
			rpr_sg = cmds.listConnections(rpr, type="shadingEngine")[0]
			cmds.sets(forceElement=rpr_sg)
		except Exception as ex:
			traceback.print_exc()
			print("Error while converting {} material. \n".format(vr))
	
	# globals conversion
	try:
		setProperty("defaultRenderGlobals","currentRenderer", "FireRender")
		setProperty("defaultRenderGlobals", "imageFormat", 8)

		# TODO iterations conversion

		# TODO check this
		setProperty("RadeonProRenderGlobals", "giClampIrradiance", 1)
		setProperty("RadeonProRenderGlobals", "giClampIrradianceValue", 5)
		setProperty("RadeonProRenderGlobals", "raycastEpsilon", 0.001)
		if MAX_RAY_DEPTH:
			setProperty("RadeonProRenderGlobals", "maxRayDepth", MAX_RAY_DEPTH)

		
		# TODO render settings conversion

	except:
		pass


def auto_launch():
	convertScene()
	cleanScene()

def manual_launch():
	print("Convertion start!")
	startTime = 0
	testTime = 0
	startTime = time.time()
	convertScene()
	testTime = time.time() - startTime
	print("Convertion finished! Time: " + str(testTime))

	response = cmds.confirmDialog(title="Convertation finished",
							  message=("Total time: " + str(testTime) + "\nDelete all V-Ray instances?"),
							  button=["Yes", "No"],
							  defaultButton="Yes",
							  cancelButton="No",
							  dismissString="No")

	if response == "Yes":
		cleanScene()


def onMayaDroppedPythonFile(empty):
	manual_launch()

if __name__ == "__main__":
	manual_launch()



