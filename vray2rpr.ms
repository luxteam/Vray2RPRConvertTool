
/*

	Vray to RadeonProRender Converter

	History:
	v.1.0 - first release
	v.1.1 - VrayDirt, VrayNormalMap 
	v.1.2 - VraySun, VrayPhysicalCamera
	v.1.3 - VrayHDRI

	Supported materials:
	- VrayMtl
	- VrayLightMtl
	- VrayCarPaintMtl
	- VrayBlendMtl
	- VrayPluginNodeMtl (VrayMtl)

	Supported utilities:
	- VrayComptex
	- VrayBump2Normal
	- VrayColor
	- VrayDirt
	- VrayNormalMap
	- VrayHDRI
	- VrayCurvature

	Supported lights:
	- VrayLight
	- VrayIES
	- VraySun

	Supported cameras:
	- VrayPhysicalCamera

*/

orig_shps=#()
new_shps=#()
orig_mtls=#()
new_mtls=#()
orig_lights=#()
new_lights=#()
orig_cameras=#()
new_cameras=#()

unsupportedPostfixStr = "_unsupported"
rprPostfixStr = "_rpr"

log_file = maxFilePath + maxFileName + ".log"

fn write_own_property_log msg =(
	try (
		log_obj = openFile log_file mode: "a"
		format "%\r\n" (msg as string) to: log_obj
		flush log_obj
		close log_obj
		free log_obj
	) catch ()
)

-- conv = converting
fn write_converted_property_log rpr_obj conv_obj rpr_attr conv_attr =(
	try (
		log_obj = openFile log_file mode: "a"
		msg = StringStream ""
		format "\tProperty %.% is converted to %.%" (conv_obj as string) conv_attr (rpr_obj as string) rpr_attr to: msg
		format "%\r\n" (msg as string) to: log_obj
		flush log_obj
		close log_obj
		free log_obj
	) catch (
		print("Exception:" + getCurrentException())
		print("Stack trace: " + getCurrentExceptionStackTrace())
	)
)

fn startConversion =(
	msg = "START CONVERSION.\r\n"
	msg += "Start time: " + (localtime as string) + "\r\n"

	try (
		log_obj = openFile log_file mode: "w"
		format "%" (msg as string) to: log_obj
		flush log_obj
		close log_obj
		free log_obj
	) catch ()

)

fn finishConversion time =(
	msg = "\n\nCONVERSION IS FINISHED.\r\n"
	msg += "Total time: " + (time as string) + " seconds.\r\n"

	write_own_property_log msg
)

fn start_log conv_obj rpr_obj =(
	msg = "\n\nFound node:\r\n"
	msg += "\tname: " + (conv_obj as string) + "\r\n"
	msg += "\ttype: " + classof conv_obj as string + "\r\n"
	msg += "Converting to:\r\n" 
    msg += "\tname: " + (rpr_obj as string) + "\r\n"
    msg += "\ttype: " + classof rpr_obj as string + "\r\n"
    msg += "Conversion details:"

	write_own_property_log msg
)

fn end_log conv_obj =(
	msg = StringStream ""
	format "Conversion of % is finished. \r\n" (conv_obj as string) to: msg
	write_own_property_log msg
)

fn convertMaterial orig_mtl =()

fn get_property value_mat value_attr =(
	try (
		obj_value = getProperty value_mat value_attr
		return obj_value
	) catch (
		print("Exception:" + getCurrentException())
		print("Stack trace: " + getCurrentExceptionStackTrace())
		msg = StringStream ""
		format "[ERROR] There is no %.% field in this node. Check the field and try again." (value_mat as string) value_attr to: msg
		write_own_property_log msg
	)
)

fn set_property obj obj_property value =(
	try (
		msg = StringStream ""
		setProperty obj obj_property value
		format "\tSet value % to %.%" value (obj as string) obj_property to: msg
		write_own_property_log msg
	) catch (
		print("Exception:" + getCurrentException())
		print("Stack trace: " + getCurrentExceptionStackTrace())
		format "\t[ERROR] Set value % to %.% is failed. Check the values and their boundaries." value (obj as string) obj_property to: msg
		write_own_property_log msg
	)
)

fn copy_property rpr_mat conv_mat rpr_attr conv_attr =(
	try (
		rpr_value = get_property rpr_mat rpr_attr
		conv_value = get_property conv_mat conv_attr
		if classof rpr_value == UndefinedClass then (
			convObj = convertMaterial conv_value
			set_property rpr_mat rpr_attr convObj
		) else (
			set_property rpr_mat rpr_attr conv_value
		)
		write_converted_property_log rpr_mat conv_mat rpr_attr conv_attr
	) catch (
		print("Exception:" + getCurrentException())
		print("Stack trace: " + getCurrentExceptionStackTrace())
		msg = StringStream ""
		format "[ERROR] Error while converting from %.% to %.%" (conv_mat as string) conv_attr (rpr_mat as string) rpr_attr to: msg
		write_own_property_log msg
	)
)

fn errorCatching functionName orig =(
	errcls = classof orig
	try(
		out = functionName orig
	)catch(
		print ("Error occured in " + errcls as string + " : " + orig as string + "\r\n" + getCurrentException() ) 
		print ("Stack trace: " + getCurrentExceptionStackTrace())
		out = orig
	)
	out
)

fn remap_value currentValue maxInput minInput maxOutput minOutput =(

	if currentValue > maxInput do currentValue = maxInput
	if currentValue < minInput do currentValue = minInput

	inputDiff = maxInput - minInput
	outputDiff = maxOutput - minOutput

	remapped_value = minOutput + (((currentValue - minInput) as float / (inputDiff) as float) * outputDiff)

	remapped_value
)

fn convertTemperature temperature =(
	temperature = temperature / 100

	if temperature <= 66 then (
		colorR = 255
	) else (
		colorR = temperature - 60
		colorR = 329.698727446 * colorR ^ -0.1332047592
		if colorR < 0 do colorR = 0
		if colorR > 255 do colorR = 255
	)

	if temperature <= 66 then (
		colorG = temperature
		colorG = 99.4708025861 * log colorG - 161.1195681661
		if colorG < 0 do colorG = 0
		if colorG > 255 do colorG = 255
	) else (
		colorG = temperature - 60
		colorG = 288.1221695283 * colorG ^ -0.0755148492
		if colorG < 0 do colorG = 0
		if colorG > 255 do colorG = 255
	)

	if temperature >= 66 then (
		colorB = 255
	) else if temperature <= 19 then (
		colorB = 0
	) else (
		colorB = temperature - 10
		colorB = 138.5177312231 * log colorB - 305.0447927307
		if colorB < 0 do colorB = 0
		if colorB > 255 do colorB = 255
	)

	(color colorR colorG colorB)
)

fn defaultEnable rpr_obj rpr_attr orig_obj orig_attr orig_map =(
	orig_color = get_property orig_obj orig_attr
	if orig_color.red > 0 or orig_color.green > 0 or orig_color.blue > 0 or get_property orig_obj orig_map != undefined do (
		set_property rpr_obj rpr_attr true
	)
)

fn invertMap rpr_obj orig_obj rpr_map orig_map =(
	if get_property orig_obj orig_map != undefined do (
		arith = RPR_Arithmetic()
		set_property arith "operator" 1
		set_property arith "Color1" (color 255 255 255)
		copy_property arith orig_obj "color1texmap" orig_map
		set_property rpr_obj rpr_map arith
	)
)


/* 
    MATERIALS
*/

fn convertUnsupportedMtl origMtl =(
	local r = RPR_Uber_Material()
	r.name = origMtl.name + unsupportedPostfixStr

	-- log to file 
	start_log origMtl r

	set_property r "diffuseColor" (color 0 45 0)

	-- logging
	end_log origMtl

	r
)

fn convertMultimaterial origMtl =(

	-- log to file 
	start_log origMtl origMtl

	materialList = get_property origMtl "materialList"
	for m=1 to materialList.count do (
		materialList[m] = convertMaterial materialList[m]
	)
	set_property origMtl "materialList" materialList

	-- logging
	end_log origMtl

	origMtl
)

fn convertVrayMtl origMtl =(
	r = RPR_Uber_Material()
	r.name = origMtl.name + rprPostfixStr

	-- log to file 
	start_log origMtl r

	useRoughness = get_property origMtl "brdf_useRoughness"

	-- diffuse
	copy_property r origMtl "diffuseColor" "diffuse"
	copy_property r origMtl "diffuseColorTexmap" "texmap_diffuse"
	copy_property r origMtl "diffuseRoughness" "diffuse_roughness"
	copy_property r origMtl "diffuseRoughnessTexmap" "texmap_roughness"

	-- reflection
	defaultEnable r "reflectionEnable" origMtl "reflection" "texmap_reflection"
	copy_property r origMtl "reflectionColor" "reflection"
	copy_property r origMtl "reflectionColorTexmap" "texmap_reflection"
	if useRoughness then (
		copy_property r origMtl "reflectionRoughness" "reflection_glossiness"
		copy_property r origMtl "reflectionRoughnessTexmap" "texmap_reflectionGlossiness"
	) else (
		set_property r "reflectionRoughness" (1 - get_property origMtl "reflection_glossiness")
		invertMap r origMtl "reflectionRoughnessTexmap" "texmap_reflectionGlossiness"
	)

	if get_property origMtl "reflection_metalness" > 0.01 do ( 
		set_property r "reflectionEnable" true
		set_property r "reflectionMode" 2
		copy_property r origMtl "reflectionColor" "diffuse"
		copy_property r origMtl "reflectionColorTexmap" "texmap_diffuse"
	)

	copy_property r origMtl "reflectionIor" "reflection_ior"
	copy_property r origMtl "reflectionIorTexmap" "texmap_reflectionIOR"
	copy_property r origMtl "reflectionMetalness" "reflection_metalness"
	copy_property r origMtl "reflectionMetalnessTexmap" "texmap_metalness"

	copy_property r origMtl "reflectionAnisotropy" "anisotropy"
	copy_property r origMtl "reflectionAnisotropyTexmap" "texmap_anisotropy"
	copy_property r origMtl "reflectionAnisotropyRotation" "anisotropy_rotation"
	copy_property r origMtl "reflectionAnisotropyRotationTexmap" "texmap_anisotropy_rotation"

	-- refraction
	defaultEnable r "refractionEnable" origMtl "refraction" "texmap_refraction"
	copy_property r origMtl "refractionColor" "refraction"
	copy_property r origMtl "refractionColorTexmap" "texmap_refraction"
	set_property r "refractionRoughness" (1 - get_property origMtl "refraction_glossiness")
	invertMap r origMtl "refractionRoughnessTexmap" "texmap_refractionGlossiness"
	
	copy_property r origMtl "refractionIor" "refraction_ior"
	copy_property r origMtl "refractionIorTexmap" "texmap_refractionIOR"

	copy_property r origMtl "refractionAbsorptionDistance" "refraction_fogMult"
	copy_property r origMtl "refractionAbsorptionColor" "refraction_fogColor"
	copy_property r origMtl "refractionAbsorptionColorTexmap" "texmap_refraction_fog"

	-- emission
	defaultEnable r "emissiveEnable" origMtl "selfIllumination" "texmap_self_illumination"
	copy_property r origMtl "emissiveColor" "selfIllumination"
	copy_property r origMtl "emissiveColorTexmap" "texmap_self_illumination"
	copy_property r origMtl "emissiveIntensity" "selfIllumination_multiplier"
	set_property r "emissiveWeight" 0.65

	if get_property origMtl "texmap_opacity" != undefined do (
		set_property r "TransparencyEnable" true
		invertMap r origMtl "transparencyTexmap" "texmap_opacity"
	)
	
	if get_property origMtl "texmap_bump_on" do (
		normal_map = RPR_Normal()
		set_property normal_map "isBump" true
		set_property normal_map "strength" (get_property origMtl "texmap_bump_multiplier" / 100)
		copy_property normal_map origMtl "map" "texmap_bump"
		set_property r "normalEnable" true
		set_property r "normalTexmap" normal_map
	)

	if get_property origMtl "texmap_displacement_on" do (
		set_property r "displacementEnable" true
		copy_property r origMtl "displacementTexmap" "texmap_displacement"
		set_property r "displacementMin" 0
		set_property r "displacementMax" (get_property origMtl "texmap_displacement_multiplier" / 10.0)
		set_property r "displacementSubdiv" 5
	)

	-- logging
	end_log origMtl

	r
)

fn convertVrayCarPaintMtl origMtl =(
	r = RPR_Uber_Material()
	r.name = origMtl.name + rprPostfixStr

	-- log to file 
	start_log origMtl r

	copy_property r origMtl "diffuseColor" "base_color"
	copy_property r origMtl "diffuseColorTexmap" "texmap_base_color"
	
	set_property r "reflectionEnable" true
	copy_property r origMtl "ReflectionWeight" "base_reflection"
	copy_property r origMtl "ReflectionWeightTexmap" "texmap_base_reflection"
	set_property r "reflectionRoughness" (1 - get_property origMtl "base_glossiness")
	invertMap r origMtl "reflectionRoughnessTexmap" "texmap_base_glossiness"
	
	set_property r "CoatingEnable" true
	copy_property r origMtl "CoatingColor" "coat_color"
	copy_property r origMtl "CoatingColorTexmap" "texmap_coat_color"
	set_property r "CoatingWeight" 1
	copy_property r origMtl "CoatingWeightTexmap" "texmap_coat_strength"
	set_property r "CoatingRoughness" (1 - get_property origMtl "coat_glossiness")
	invertMap r origMtl "CoatingRoughnessTexmap" "texmap_coat_glossiness"

	-- logging
	end_log origMtl

	r
)

fn convertVrayOverrideMtl origMtl =(

	local baseMtl = get_property origMtl "baseMtl"
	if baseMtl == undefined do return RPR_Uber_Material()

	materials = #()
	if get_property origMtl "giMtl" != undefined do append materials (get_property origMtl "giMtl")
	if get_property origMtl "reflectMtl" != undefined do append materials (get_property origMtl "reflectMtl")
	if get_property origMtl "refractMtl" != undefined do append materials (get_property origMtl "refractMtl")

	local rpr_material = convertMaterial baseMtl

	if materials.count == 0 do return rpr_material

	local r = RPR_Blend_Material() 
	r.name = origMtl.name + rprPostfixStr

	-- log to file 
	start_log origMtl r

	set_property r "material1" rpr_material
	set_property r "weight" 0.5

	-- materials conversion
	first_material = true
	for i in materials do (
		if first_material then (
			set_property r "material2" (convertMaterial i)
			first_material = false
		) else (
			old_r = r
			r = RPR_Blend_Material()
			set_property r "material1" old_r
			set_property r "material2" (convertMaterial i)
			set_property r "weight" 0.5
		)
	)

	-- logging
	end_log origMtl

	r
)

fn convertVrayBlendMtl origMtl =(
	local r = RPR_Blend_Material()
	r.name = origMtl.name + rprPostfixStr

	-- log to file 
	start_log origMtl r

	baseMtl = get_property origMtl "baseMtl"
	set_property r "material1" (convertMaterial baseMtl)

	-- materials count
	materials_count = 0
	coatMtl = get_property origMtl "coatMtl"
	texmap_blend = get_property origMtl "texmap_blend"
	for i=1 to coatMtl.count do (
		if coatMtl[i] != undefined do (
			materials_count += 1
		)
	)

	-- materials conversion
	first_material = true
	for i=1 to coatMtl.count do (
		if coatMtl[i] != undefined do (
			if materials_count > 1 then (
				if first_material then (
					set_property r "material2" (convertMaterial coatMtl[i])
					set_property r "weightMap" (convertMaterial texmap_blend[i])
					first_material = false
				) else (
					old_r = r
					r = RPR_Blend_Material()
					set_property r "material1" old_r
					set_property r "material2" (convertMaterial coatMtl[i])
					set_property r "weightMap" (convertMaterial texmap_blend[i])
				)
			) else (
				set_property r "material2" (convertMaterial coatMtl[i])
				set_property r "weightMap" (convertMaterial texmap_blend[i])
			)
		)
	)
	
	-- logging
	end_log origMtl

	r
)

fn convertVrayBumpMtl origMtl =(
	
	local base_material = get_property origMtl "base_mtl"
	local rpr_material = convertMaterial base_material

	-- log to file 
	start_log origMtl rpr_material

	if classof rpr_material == RPR_Uber_Material do (
		rpr_normal_map = RPR_Normal()
		set_property rpr_normal_map "isBump" true
		copy_property rpr_normal_map origMtl "map" "bump_map"
		copy_property rpr_normal_map origMtl "strength" "bump_amount"

		set_property rpr_material "normalEnable" true
		set_property rpr_material "normalTexmap" rpr_normal_map
	)

	-- logging
	end_log origMtl

	rpr_material
)

fn convertVray2SidedMtl origMtl =(

	if get_property origMtl "frontMtl" != undefined then (
		local base_material = get_property origMtl "frontMtl"
	) else if get_property origMtl "backMtl" != undefined then(
		local base_material = get_property origMtl "backMtl"
	)

	local rpr_material = convertMaterial base_material

	-- log to file 
	start_log origMtl rpr_material

	if classof rpr_material == RPR_Uber_Material do (
		set_property rpr_material "diffuseBackscatteringWeight" 1
		set_property rpr_material "diffuseSeparateBackScatteringColor" true
		copy_property rpr_material origMtl "diffuseBackScatteringColor" "translucency"
		copy_property rpr_material origMtl "diffuseBackScatteringColorTexmap" "texmap_translucency"
	)

	-- logging
	end_log origMtl

	rpr_material
)

fn convertVrayFastSSS2 origMtl =(
	local r = RPR_Uber_Material()
	r.name = origMtl.name + rprPostfixStr

	-- log to file 
	start_log origMtl r

	-- diffuse
	copy_property r origMtl "diffuseColor" "diffuse_color"
	copy_property r origMtl "diffuseColorTexmap" "texmap_diffuse_color"
	set_property r "diffuseWeight" 1
	copy_property r origMtl "diffuseWeightTexmap" "texmap_diffuse_amount"
	
	set_property r "sssEnable" true
	copy_property r origMtl "sssColor" "sub_surface_color"
	copy_property r origMtl "sssColorTexmap" "texmap_sss_color"
	set_property r "diffuseSeparateBackScatteringColor" true
	set_property r "diffuseBackscatteringWeight" 0.25
	copy_property r origMtl "diffuseBackScatteringColor" "scatter_color"
	copy_property r origMtl "diffuseBackScatteringColorTexmap" "texmap_scatter_color"
	scatter_radius = get_property origMtl "scatter_radius"
	set_property r "sssRadius" (point3 scatter_radius scatter_radius scatter_radius)
	copy_property r origMtl "sssRadiusTexmap" "texmap_scatter_radius"

	defaultEnable r "reflectionEnable" origMtl "specular_color" "texmap_specular_color"
	copy_property r origMtl "reflectionColor" "specular_color"
	copy_property r origMtl "reflectionColorTexmap" "texmap_specular_color"

	set_property r "reflectionRoughness" (1 - get_property origMtl "specular_glossiness")
	invertMap r origMtl "reflectionRoughnessTexmap" "texmap_specular_color"
	
	if get_property origMtl "texmap_opacity" != undefined do (
		set_property r "TransparencyEnable" true
		invertMap r origMtl "transparencyTexmap" "texmap_opacity"
	)
	
	if get_property origMtl "texmap_bump_on" do (
		set_property r "normalEnable" true
		copy_property r origMtl "normalTexmap" "texmap_bump"
	)

	-- logging
	end_log origMtl

	r
)

fn convertVrayMtlWrapper origMtl =(
	local r = RPR_Shadow_Catcher_Material()
	r.name = origMtl.name + rprPostfixStr

	-- log to file 
	start_log origMtl r

	set_property r "shadowAlphaMul" 0.2
	if not get_property origMtl "matteSurface" do (
		set_property r "BackgroundIsEnvironment" false
		if classof get_property origMtl "baseMtl" == RPR_Uber_Material do (
			copy_property r origMtl.baseMtl "shadowColor" "diffuseColor"
			copy_property r origMtl.baseMtl "shadowColorTexmap" "diffuseColorTexmap"
		)
	)

	-- logging
	end_log origMtl

	r
)

fn convertVrayPluginNodeMtl origMtl =(
	if origMtl.plugin == "BRDFVRayMtl" then (
		r = RPR_Uber_Material()
		r.name = origMtl.name + rprPostfixStr

		useRoughness = origMtl.option_use_roughness

		-- diffuse
		if origMtl.diffuse_use do (
			r.diffuseColor = origMtl.diffuse_rgb
			r.diffuseColorTexmap = origMtl.diffuse
		) 
		if origMtl.roughness_use do (
			r.diffuseRoughnessTexmap = origMtl.roughness
			r.diffuseRoughness = origMtl.roughness_rgb
		)

		-- reflection
		if origMtl.reflect_use do (
			if origMtl.reflect_rgb.red > 0 or origMtl.reflect_rgb.green > 0 or origMtl.reflect_rgb.blue > 0 do ( r.reflectionEnable = true )
			r.reflectionColor = origMtl.reflect_rgb
			r.reflectionColorTexmap = origMtl.reflect
		)
		if origMtl.reflect_glossiness_use do (
			if useRoughness then (
				r.reflectionRoughness = origMtl.reflect_glossiness_rgb
				r.reflectionRoughnessTexmap = origMtl.reflect_glossiness
			) else (
				r.reflectionRoughness = 1 - origMtl.reflect_glossiness_rgb
				if origMtl.reflect_glossiness != undefined do (
					arith = RPR_Arithmetic()
					arith.operator = 1
					arith.Color1 = color 255 255 255
					arith.color1texmap = origMtl.reflect_glossiness
					r.reflectionRoughnessTexmap = arith
				)
			)
		)
		if origMtl.metalness_use and origMtl.metalness_rgb > 0.01 do ( 
			r.reflectionEnable = true
			r.reflectionMode = 2
			r.reflectionColor = origMtl.diffuse_rgb
			r.reflectionColorTexmap = origMtl.diffuse
		)
		if origMtl.fresnel and origMtl.fresnel_ior_use do (
			r.reflectionIor = origMtl.fresnel_ior_rgb
			r.reflectionIorTexmap = origMtl.fresnel_ior
		)
		if origMtl.metalness_use do (
			r.reflectionMetalness = origMtl.metalness_rgb
			r.reflectionMetalnessTexmap = origMtl.metalness
		)

		if origMtl.anisotropy_use do (
			r.reflectionAnisotropy = origMtl.anisotropy_rgb
			r.reflectionAnisotropyTexmap = origMtl.anisotropy
		)
		if origMtl.anisotropy_rotation_use do (
			r.reflectionAnisotropyRotation = origMtl.anisotropy_rotation_rgb
			r.reflectionAnisotropyRotationTexmap = origMtl.anisotropy_rotation
		)

		-- refraction
		if origMtl.refract_use do (
			if origMtl.refract_rgb.red > 0 or origMtl.refract_rgb.green > 0 or origMtl.refract_rgb.blue > 0 do ( r.refractionEnable = true )
			r.refractionColor = origMtl.refract_rgb
			r.refractionColorTexmap = origMtl.refract
		)
		if origMtl.refract_glossiness_use do (
			r.refractionRoughness = 1 - origMtl.refract_glossiness_rgb
			if origMtl.refract_glossiness != undefined do (
				arith = RPR_Arithmetic()
				arith.operator = 1
				arith.Color1 = color 255 255 255
				arith.color1texmap = origMtl.refract_glossiness
				r.refractionRoughnessTexmap = arith
			)
		)
		if origMtl.refract_ior_use do (
			r.refractionIor = origMtl.refract_ior_rgb
			r.refractionIorTexmap = origMtl.refract_ior
		)

		r.refractionAbsorptionDistance = origMtl.fog_mult
		if origMtl.fog_color_tex_use do (
			r.refractionAbsorptionColor = origMtl.fog_color
			r.refractionAbsorptionColorTexmap = origMtl.fog_color_tex
		)

		-- emission
		if origMtl.self_illumination_use do (
			if origMtl.self_illumination_rgb.red > 0 or origMtl.self_illumination_rgb.green > 0 or origMtl.self_illumination_rgb.blue > 0 do ( r.emissiveEnable = true )
			r.emissiveColor = origMtl.self_illumination_rgb
			r.emissiveColorTexmap = origMtl.self_illumination
			r.emissiveIntensity = origMtl.self_illumination_mul
			r.emissiveWeight = 0.65
		)

		if origMtl.opacity_use and origMtl.opacity != undefined do (
			r.TransparencyEnable = true
			arith = RPR_Arithmetic()
			arith.operator = 1
			arith.Color1 = color 255 255 255
			arith.color1texmap = origMtl.opacity
			r.transparencyTexmap = arith
		)

		r
	) else (
		r = convertUnsupportedMtl origMtl
		r
	)
)

fn convertVrayLightMtl origMtl =(
	local r = RPR_Uber_Material()
	r.name = origMtl.name + rprPostfixStr

	-- log to file 
	start_log origMtl r

	-- emission
	set_property r "emissiveEnable" true
	copy_property r origMtl "emissiveColor" "color"
	copy_property r origMtl "emissiveColorTexmap" "texmap"
	copy_property r origMtl "emissiveIntensity" "multiplier"

	if get_property origMtl "opacity_texmap" != undefined do (
		set_property r "TransparencyEnable" true
		arith = RPR_Arithmetic()
		set_property arith "operator" 1
		set_property arith "Color1" (color 255 255 255)
		copy_property arith origMtl "color1texmap" "opacity_texmap"
		set_property r "TransparencyTexmap" arith
	)

	-- displacement
	if get_property origMtl "displacement_texmap" != undefined do (set_property r "displacementEnable" true)
	copy_property r origMtl "displacementTexmap" "displacement_texmap"
	copy_property r origMtl "displacementMax" "displacement_multiplier"
	if get_property origMtl "directLight_subdivs" > 8 then (
		set_property r "displacementSubdiv" 8
	) else (
		copy_property r origMtl "displacementSubdiv" "directLight_subdivs" 
	)
	
	-- logging
	end_log origMtl

	r
)


/* 
    UTILITIES
*/

fn convertUnsupportedUtility origMtl =(
	local r = RPR_Arithmetic()
	r.name = origMtl.name + unsupportedPostfixStr

	-- log to file 
	start_log origMap r
	end_log origMap

	r
)

fn convertVrayCompTex origMap = (
	local r = RPR_Arithmetic()
	r.name = origMap.name + rprPostfixStr

	-- log to file 
	start_log origMap r
	
	copy_property r origMap "color0texmap" "sourceA"
	copy_property r origMap "color1texmap" "sourceB"
	copy_property r origMap "operator" "operator"

	local rpr_operator = case get_property origMap "operator" of (
		0: 0
		1: 1
		3: 2
		4: 3
		5: 12
		6: 13
		default: 0
	)
	set_property r "operator" rpr_operator

	-- logging
	end_log origMap

	r
)

fn convertVrayBump2Normal origMap = (
	local r = RPR_Normal()
	r.name = origMap.name + rprPostfixStr

	-- log to file 
	start_log origMap r
	
	set_property r "isBump" true
	copy_property r origMap "map" "bump_map"
	copy_property r origMap "strength" "bump_map_mult"

	-- logging
	end_log origMap

	r
)

fn convertVrayNormalMap origMap = (
	local r = RPR_Normal()
	r.name = origMap.name + rprPostfixStr

	-- log to file 
	start_log origMap r
	
	if get_property origMap "normal_map_on" then (
		set_property r "isBump" false
		copy_property r origMap "map" "normal_map"
		set_property r "strength" (get_property origMap "normal_map_multiplier" / 100.0)
	) else (
		set_property r "isBump" true
		copy_property r origMap "map" "bump_map"
		set_property r "strength" (get_property origMap "bump_map_mult" / 100.0)
	)

	-- logging
	end_log origMap

	r
)

fn convertVrayDirt origMap = (
	if origMap.mode == 0 then (
		local r = RPR_Ambient_Occlusion()
		r.name = origMap.name + rprPostfixStr
		
		-- log to file 
		start_log origMap r

		copy_property r origMap "unoccluded_Color" "unoccluded_color"
		copy_property r origMap "occluded_Color" "occluded_color"
		copy_property r origMap "color0Texmap" "texmap_unoccluded_color"
		copy_property r origMap "color1Texmap" "texmap_occluded_color"
		copy_property r origMap "radius" "radius"

		-- logging
		end_log origMap

		r
	) else (
		local r = convertUnsupportedUtility origMap
		r
	)	
)

fn convertVrayColor origMap = (
	local r = RPR_Color_Value()
	r.name = origMap.name + rprPostfixStr

	-- log to file 
	start_log origMap r
	
	copy_property r origMap "color" "color"

	-- logging
	end_log origMap
	
	r
)

fn convertVrayCurvature origMap = (
	local r = RPR_Ambient_Occlusion()
	r.name = origMap.name + rprPostfixStr

	-- log to file 
	start_log origMap r
	
	set_property r "side" 1
	min_color = remap_value (get_property origMap "out_color_min") 1 0 255 0
	set_property r "unoccluded_Color" (color min_color min_color min_color)
	max_color = remap_value (get_property origMap "out_color_max") 1 0 255 0
	set_property r "occluded_Color" (color max_color max_color max_color)
	set_property r "radius" (0.04 + get_property origMap "sample_spread" / 21)

	-- logging
	end_log origMap

	r
)

fn convertVrayUserColor origMap = (
	local r = rpr_color_value()
	r.name = origMap.name + rprPostfixStr

	-- log to file 
	start_log origMap r
	
	copy_property r origMap "Color" "default_color"
	copy_property r origMap "colorTexmap" "default_texmap"

	-- logging
	end_log origMap

	r
)

fn convertVrayDistanceTex origMap = (

	-- log to file 
	start_log origMap "Bitmap"
	end_log origMap

	if get_property origMap "texmap_near" != undefined do (
		return (get_property origMap "texmap_near")
	)
	if get_property origMap "texmap_far" != undefined do (
		return (get_property origMap "texmap_far")
	)
	if get_property origMap "texmap_inside" != undefined do (
		return (get_property origMap "texmap_inside")
	)
	if get_property origMap "texmap_distance" != undefined do (
		return (get_property origMap "texmap_distance")
	)
	if get_property origMap "texmap_outside" != undefined do (
		return (get_property origMap "texmap_outside")
	)
)

fn convertVrayOCIO origMap = (
	
	local r = get_property origMap "gen_basemap"

	-- log to file 
	start_log origMap r
	
	-- logging
	end_log origMap

	r
)

fn convertVrayHDRI origMap = (
	local r = BitmapTexture()
	r.name = origMap.name + rprPostfixStr

	-- log to file 
	start_log origMap r
	
	-- filename, output
	if get_property origMap "HDRIMapName" != "" and get_property origMap "HDRIMapName" != undefined do (
		copy_property r origMap "fileName" "HDRIMapName"
	)
	
	copy_property r origMap "output" "Output"
	if hasproperty origMap #coords then(
		copy_property r origMap "coords" "coords"
	)
	
	-- Gamma handling
	if get_property origMap "gamma" != 1 do (
		set_property r "bitmap" (openBitmap r.bitmap.filename gamma:(1.0 / get_property origMap "gamma"))
	)
	
	if get_property origMap "mapType" == 2 then(   -- spherical mode
		set_property r.coords "mapping" 0 -- spherical
		set_property r.coords "mappingType" 1 -- Environ
		set_property r.coords "U_Offset" (0.25 + get_property origMap "horizontalRotation" / 360.0)
		set_property r.coords "V_Offset" (get_property origMap "verticalRotation" / 180.0)

		if get_property origMap "horizontalFlip" then(
			set_property r.coords "U_Offset" (0.25 - get_property origMap "horizontalRotation" / 360.0)
			set_property r.coords "U_Tiling" (-get_property origMap.coords "U_Tiling")
		)
		if get_property origMap "verticalFlip" then set_property r.coords "V_Tiling" (-get_property origMap.coords "V_Tiling")
	)
	
	-- alpha source, mono channel out, rgb channel out
	copy_property r origMap "alphaSource" "alphaSource"
	copy_property r origMap "monoOutput" "monoOutput"
	set_property r "rgbOutput" (if get_property origMap "rgbOutput" > 1 then 0 else get_property origMap "rgbOutput")
	
	-- crop/place
	copy_property r origMap "apply" "cropplace_on"
	copy_property r origMap "cropPlace" "cropplace_mode"
	copy_property r origMap "clipu" "cropplace_u"
	copy_property r origMap "clipv" "cropplace_v"
	copy_property r origMap "clipw" "cropplace_width"
	copy_property r origMap "cliph" "cropplace_height"
	
	set_property r.output "output_amount" (get_property r.output "output_amount" * get_property origMap "multiplier" * get_property origMap "renderMultiplier")

	-- logging
	end_log origMap
	
	r
)

fn convertColorOSL origMap operator = (
	local r = RPR_Arithmetic()
	r.name = origMap.name + rprPostfixStr

	-- log to file 
	start_log origMap r

	set_property r "operator" operator
	copy_property arith origMap "Color1" "A"
	copy_property arith origMap "Color2" "B"
	copy_property arith origMap "color0texmap" "A_map"
	copy_property arith origMap "color1texmap" "B_map"

	-- logging
	end_log origMap

	r
)

fn convertColorClampOSL origMap = (
	local r = RPR_Arithmetic()
	r.name = origMap.name + rprPostfixStr

	-- log to file 
	start_log origMap r

	set_property r "operator" 12

	arith = RPR_Arithmetic()
	set_property arith "operator" 13
	copy_property arith origMap "Color1" "Input"
	copy_property arith origMap "Color2" "min"
	copy_property arith origMap "color0texmap" "Input_map"
	copy_property arith origMap "color1texmap" "Min_map"

	set_property r "color0texmap" arith
	copy_property r origMap "Color2" "max"
	copy_property r origMap "color1texmap" "Max_map"

	-- logging
	end_log origMap

	r
)

fn convertOSLMap origMap = (

	OSLPath = get_property origMap "OSLPath"
	OSLFile = (filterString OSLPath "\\")
	OSLFile = OSLFile[OSLFile.count]
	local new_osl = case OSLFile of (
		"ColorAdd.osl": convertColorOSL origMap 0
		"ColorSub.osl": convertColorOSL origMap 1
		"ColorMul.osl": convertColorOSL origMap 2
		"ColorDiv.osl": convertColorOSL origMap 3
		"ColorMin.osl": convertColorOSL origMap 12
		"ColorMax.osl": convertColorOSL origMap 13
		"ColorClamp.osl": convertColorClampOSL origMap

		default: origMap
	)

	new_osl
)


/* 
    LIGHTS
*/

fn convertVrayIES origLight = (
	local r = ies_light()
	r.name = origLight.name + rprPostfixStr
	
	-- log to file 
	start_log origLight r

	-- On/Off, Include/exclude
	copy_property r origLight "enabled" "enabled"
	copy_property r origLight "targeted" "targeted"

	-- position conversion
	set_property origLight "targeted" false
	copy_property r origLight "pos" "pos"
	copy_property r origLight "rotation" "rotation"
	copy_property r origLight "scale" "scale"
	copy_property r origLight "pivot" "pivot"
	copy_property r origLight "transform" "transform"
	copy_property r origLight "dir" "dir"

	-- rotate rpr ies to match vray ies
	rotate r (eulerangles -90 0 0)
	
	-- ies file
	if get_property origLight "ies_file" != "" and get_property origLight "ies_file" != undefined do (
		plugcfg = GetDir #plugcfg
		profile_path = plugcfg + "\\Radeon ProRender\\IES Profiles\\"
		makeDir (profile_path)
		ies_file = get_property origLight "ies_file"
		ies_name = (filterString ies_file "\\")
		ies_name = ies_name[ies_name.count]
		copyFile (ies_file) (profile_path + ies_name)
		set_property r "profile" ies_name
	)

	-- rotation XYZ
	copy_property r origLight "rotationX" "rotation_X"
	copy_property r origLight "rotationY" "rotation_Y"
	copy_property r origLight "rotationZ" "rotation_Z"

	-- Intensitiy, Color, Texmap
	if get_property origLight "intensity_type" == 0 then (
		intensity = get_property origLight "intensity_value"
	) else (
		intensity = get_property origLight "intensity_value" / 1.398
	)

	set_property r "intensity" (intensity / 999)
	copy_property r origLight "colorMode" "color_mode"
	copy_property r origLight "color" "color"
	copy_property r origLight "temperature" "color_temperature"

	-- logging
	end_log origLight

	r
)

fn convertVrayLight origLight = (
	if origLight.skylightPortal then return "no_replace"

	light_type = origLight.type
	if light_type != 1 then (
		local r = physical_light()
		r.name = origLight.name + rprPostfixStr

		-- log to file 
		start_log origLight r

		-- OnOff, Include/exclude
		copy_property r origLight "enabled" "on"
		if get_property origLight "invisible" then (set_property r "isVisible" false) else (set_property r "isVisible" true) -- visible
		
		-- position conversion
		set_property origLight "targeted" false
		copy_property r origLight "pos" "pos"
		copy_property r origLight "rotation" "rotation"
		copy_property r origLight "scale" "scale"
		copy_property r origLight "pivot" "pivot"
		copy_property r origLight "transform" "transform"
		copy_property r origLight "dir" "dir"

		set_property r "lightType" 0 -- area light

		local areaShape = case light_type of (
			0: 3 -- Plane
			2: 2 -- Sphere
			3: 4 -- Mesh
			4: 0 -- Disc
			default: 1
		)
		set_property r "areaShape" areaShape

		normalize_color = get_property origLight "normalizeColor"
		if normalize_color == 0 do ( -- image
			set_property r "UnitsType" 0
			set_property r "LightIntensity" (get_property origLight "multiplier" * 1.2)
		) 
		if normalize_color == 1 do ( -- luminous
			set_property r "UnitsType" 0
			set_property r "LightIntensity" (get_property origLight "multiplier" / 949999905)
		)
		if normalize_color == 2 do ( -- luminance
			set_property r "UnitsType" 0
			set_property r "LightIntensity" (get_property origLight "multiplier" / 397.7)
		)
		if normalize_color == 3 do ( -- radiant power
			set_property r "UnitsType" 1
			copy_property r origLight "LightIntensity" "multiplier"
			set_property r "LuminousEfficacy" 250
		)
		if normalize_color == 4 do ( -- radiance
			set_property r "UnitsType" 2
			set_property r "LightIntensity" (get_property origLight "multiplier" / 2)
		)

		copy_property r origLight "colourMode" "color_mode"
		copy_property r origLight "colourPicker" "color"
		copy_property r origLight "temperature" "color_temperature"
		copy_property r origLight "TemperatureColour" "color"

		if areaShape == 2 or areaShape == 0 do (
			copy_property r origLight "areaWidths" "sizeLength"
		)
		if areaShape == 3 do (
			copy_property r origLight "areaWidths" "sizeWidth"
			copy_property r origLight "areaLength" "sizeLength"
		)
		
		if get_property origLight "texmap" != undefined and get_property origLight "texmap_on" do (
			set_property r "EnableMap" true
			copy_property r origLight "ColourMap" "texmap"
		)

		-- logging
		end_log origLight

	) else (
		local r = "no_replace"

		if origLight.on do (
			rpr = Radeon_ProRender()

			-- log to file 
			start_log origLight rpr

			set_property rpr "backgroundOverride" true
			set_property rpr "backgroundType" 0
			if get_property origLight "texmap" != undefined and get_property origLight "texmap_on" do (
				set_property rpr "useBackgroundMap" true
				copy_property rpr origLight "backgroundMap" "texmap"
			)
			copy_property rpr origLight "backgroundIntensity" "multiplier"
			copy_property rpr origLight "backgroundColor" "color"

			transform_ibl = $RPREnv001
			copy_property transform_ibl origLight "rotation" "rotation"
			rotate transform_ibl (eulerangles 0 0 90)

			-- logging
			end_log origLight
		)

	)
	
	r
)

fn convertVraySun origLight = (

	if origLight.enabled do (
		rpr = Radeon_ProRender()

		-- log to file 
		start_log origLight rpr

		set_property rpr "backgroundOverride" true
		set_property rpr "backgroundType" 1
		set_property rpr "backgroundSkyType" 0
		copy_property rpr origLight "backgroundSkyHaze" "turbidity"
		copy_property rpr origLight "backgroundSkyFilterColor" "filter_color"
		copy_property rpr origLight "backgroundSkySunDisc" "size_multiplier"
		copy_property rpr origLight "backgroundSkyGroundAlbedo" "ground_albedo"
		set_property rpr "backgroundSkyIntensity" (get_property origLight "intensity_multiplier" * 20)
		
		-- logging
		end_log origLight
    )

    "no_replace"
)

fn convertVrayAmbientLight origLight = (
	local r = Skylight()
	r.name = origLight.name + rprPostfixStr

	-- log to file 
	start_log origLight r

	-- OnOff, Include/exclude
	copy_property r origLight "on" "enabled"
	
	-- position conversion
	copy_property r origLight "pos" "pos"
	copy_property r origLight "rotation" "rotation"
	copy_property r origLight "scale" "scale"
	copy_property r origLight "pivot" "pivot"
	copy_property r origLight "transform" "transform"
	copy_property r origLight "dir" "dir"

	copy_property r origLight "multiplier" "intensity"

	if get_property origLight "light_map_on" and get_property origLight "light_map" != undefined then (
		set_property r "sky_mode" 1
		set_property r "sky_color_map_on" true
		copy_property r origLight "color" "color" 
		copy_property r origLight "sky_color_map" "light_map" 
		copy_property r origLight "sky_color_map_amt" "light_map_multiplier"
	) else (
		set_property r "sky_mode" 0
		backgroundColor = (get_property origLight "color")
	)

	-- logging
	end_log origLight

	r
)


/* 
    SHAPES
*/

fn convertVraySphere origShape = (
	local r = Sphere()
	r.name = origShape.name + rprPostfixStr

	-- log to file 
	start_log origShape r

	copy_property r origShape "pos" "pos"
	copy_property r origShape "scale" "scale"
	copy_property r origShape "rotation" "rotation"
	copy_property r origShape "radius" "radius"

	clearSelection()
	select r
	modPanel.addModToSelection (TurboSmooth ()) ui:on
	clearSelection()

	-- logging
	end_log origShape

	r
	
)

fn convertVrayPlane origShape = (
	local r = Plane()
	r.name = origShape.name + rprPostfixStr

	-- log to file 
	start_log origShape r

	copy_property r origShape "pos" "pos"
	copy_property r origShape "scale" "scale"
	copy_property r origShape "rotation" "rotation"

	set_property r "length" 1000000000.0
	set_property r "width" 1000000000.0

	shadow_catcher_exists = getUserProp origShape "VRay_Matte_Enable"
	if shadow_catcher_exists != undefined and shadow_catcher_exists != false do (
		shadow_catcher_mat = RPR_Shadow_Catcher_Material()
		set_property shadow_catcher_mat "shadowAlphaMul" 0.2
		set_property r "material" shadow_catcher_mat
	)

	-- logging
	end_log origShape

	r
	
)

fn convertPlane origShape = (

	-- log to file 
	start_log origShape origShape

	shadow_catcher_exists = getUserProp origShape "VRay_Matte_Enable"
	if shadow_catcher_exists != undefined and shadow_catcher_exists != false do (
		shadow_catcher_mat = RPR_Shadow_Catcher_Material()
		set_property shadow_catcher_mat "shadowAlphaMul" 0.2
		set_property origShape "material" shadow_catcher_mat
	)

	-- logging
	end_log origShape

	origShape
)

/* 
    CAMERAS
*/

fn convertVrayPhysicalCamera origCamera =(

	local r = Freecamera()
	r.name = origCamera.name + rprPostfixStr

	-- log to file 
	start_log origCamera r

	-- position conversion
	set_property origCamera "targeted" false
	copy_property r origCamera "pos" "pos"
	copy_property r origCamera "rotation" "rotation"
	copy_property r origCamera "scale" "scale"
	copy_property r origCamera "pivot" "pivot"
	copy_property r origCamera "transform" "transform"
	copy_property r origCamera "dir" "dir"

	copy_property r origCamera "targetDistance" "target_distance"
	copy_property r origCamera "showCone" "show_camera_cone"
	copy_property r origCamera "fov" "fov"
	copy_property r.mpassEffect origCamera "useTargetDistance" "use_dof"
	copy_property r origCamera "clipManually" "clip_on"
	copy_property r origCamera "nearclip" "clip_near"
	copy_property r origCamera "farclip" "clip_far"
	copy_property r origCamera "nearrange" "environment_near"
	copy_property r origCamera "farrange" "environment_far"

	-- logging
	end_log origCamera

	r
)

fn convertVrayDomeCamera origCamera =(

	local r = Freecamera()
	r.name = origCamera.name + unsupportedPostfixStr

	-- log to file 
	start_log origCamera r

	-- position conversion
	set_property origCamera "targeted" false
	copy_property r origCamera "pos" "pos"
	copy_property r origCamera "rotation" "rotation"
	copy_property r origCamera "scale" "scale"
	copy_property r origCamera "pivot" "pivot"
	copy_property r origCamera "transform" "transform"
	copy_property r origCamera "dir" "dir"

	-- logging
	end_log origCamera

	r
)


/*
 CONVERT FUNCTIONS
*/


fn convertLight orig_light =(
	if superclassof orig_light !=light then return orig_light  -- check if this is a light; if not, just return the value
	
	local i = findItem orig_lights orig_light -- check if we have already converted this light
	if i > 0 then return new_lights[i]  --if yes, just return the already converted one	
	
	cls=classof orig_light
	local new_light = case cls of (
		VrayLight: errorCatching convertVrayLight orig_light 
		VrayIES: errorCatching convertVrayIES orig_light 
		VraySun: errorCatching convertVraySun orig_light 
		VrayAmbientLight: errorCatching convertVrayAmbientLight orig_light 
		
		default: orig_light
	)
	
	if new_light != orig_light then ( 		-- if converted, add to the list of converted lights
		append orig_lights orig_light
		append new_lights new_light
	)
	
	new_light
)



fn convertCamera orig_camera =(
	if superclassof orig_camera != camera then return orig_camera 
	
	local i = findItem orig_cameras orig_camera 
	if i > 0 then return new_cameras[i]  
	
	cls=classof orig_camera
	local new_camera = case cls of (
		VrayDomeCamera: errorCatching convertVrayDomeCamera orig_camera 
		VrayPhysicalCamera: errorCatching convertVrayPhysicalCamera orig_camera 

		default: orig_camera
	)
	
	if new_camera != orig_camera then ( 
		append orig_cameras orig_camera
		append new_cameras new_camera
	)
	
	new_camera
)


fn convertMaterial orig_mtl =(
		
	local i = findItem orig_mtls orig_mtl -- check if we have already converted this material
	if i > 0 then return new_mtls[i]  --if yes, just return the already converted one	
	
	cls = classof orig_mtl
	local new_mtl = case cls of (
		-- MATERIALS
		Multimaterial: errorCatching convertMultimaterial orig_mtl
		VrayMtl: errorCatching convertVrayMtl orig_mtl
		VrayLightMtl: errorCatching convertVrayLightMtl orig_mtl 
		VrayBlendMtl: errorCatching convertVrayBlendMtl orig_mtl
		VrayCarPaintMtl: errorCatching convertVrayCarPaintMtl orig_mtl 
		VrayPluginNodeMtl: errorCatching convertVrayPluginNodeMtl orig_mtl 
		VrayFastSSS2: errorCatching convertVrayFastSSS2 orig_mtl 
		VrayBumpMtl: errorCatching convertVrayBumpMtl orig_mtl 
		Vray2SidedMtl: errorCatching convertVray2SidedMtl orig_mtl 
		VrayMtlWrapper: errorCatching convertVrayMtlWrapper orig_mtl
		VrayOverrideMtl: errorCatching convertVrayOverrideMtl orig_mtl  
		
		--following materials will be replaced with default green rpr uber mat, will be supported later
		VrayALSurfaceMtl: errorCatching convertUnsupportedMtl orig_mtl 
		VrayFlakesMtl: errorCatching convertUnsupportedMtl orig_mtl 
		VrayScatterVolume: errorCatching convertUnsupportedMtl orig_mtl 
		VrayGLSLMtl: errorCatching convertUnsupportedMtl orig_mtl 
		VrayHairMtl: convertUnsupportedMtl orig_mtl 
		VrayHairNextMtl: errorCatching convertUnsupportedMtl orig_mtl 
		VrayMDLMtl: errorCatching convertUnsupportedMtl orig_mtl 
		VrayOSLMtl: errorCatching convertUnsupportedMtl orig_mtl 
		VrayPointParticleMtl: errorCatching convertUnsupportedMtl orig_mtl 
		VrayScannedMtl: errorCatching convertUnsupportedMtl orig_mtl 
		VrayStochasticFlakesMtl: errorCatching convertUnsupportedMtl orig_mtl 
		VraySwitchMtl: errorCatching convertUnsupportedMtl orig_mtl 
		VrayVectorDisplBake: errorCatching convertUnsupportedMtl orig_mtl 
		VrayVrmatMtl: errorCatching convertUnsupportedMtl orig_mtl 

		-- UTILITIES
		VrayCompTex: errorCatching convertVrayCompTex orig_mtl
		VrayColor: errorCatching convertVrayColor orig_mtl
		VrayBump2Normal: errorCatching convertVrayBump2Normal orig_mtl
		VrayDirt: errorCatching convertVrayDirt orig_mtl
		VrayNormalMap: errorCatching convertVrayNormalMap orig_mtl
		VrayHDRI: errorCatching convertVrayHDRI orig_mtl
		VrayCurvature: errorCatching convertVrayCurvature orig_mtl
		VrayUserColor: errorCatching convertVrayUserColor orig_mtl
		VrayOCIO: errorCatching convertVrayOCIO orig_mtl
		VrayDistanceTex: errorCatching convertVrayDistanceTex orig_mtl
		OSLMap: errorCatching convertOSLMap orig_mtl

		--following utilies will be replaced with default rpr arithmetic node, will be supported later
		VrayColor2Bump: errorCatching convertUnsupportedUtility orig_mtl
		VrayEdgesTex: errorCatching convertUnsupportedUtility orig_mtl
		VrayFakeFresnelTex: errorCatching convertUnsupportedUtility orig_mtl
		VrayGLSLTex: errorCatching convertUnsupportedUtility orig_mtl
		VrayHairInfoTex: errorCatching convertUnsupportedUtility orig_mtl
		VrayICC: errorCatching convertUnsupportedUtility orig_mtl
		VrayLut: errorCatching convertUnsupportedUtility orig_mtl
		VrayMultiSubTex: errorCatching convertUnsupportedUtility orig_mtl
		VrayNoiseTex: errorCatching convertUnsupportedUtility orig_mtl
		VrayOSLText: errorCatching convertUnsupportedUtility orig_mtl
		VrayParticleTex: errorCatching convertUnsupportedUtility orig_mtl
		VrayPluginNodeTex: errorCatching convertUnsupportedUtility orig_mtl
		VrayPtex: errorCatching convertUnsupportedUtility orig_mtl
		VraySamplerInfoTex: errorCatching convertUnsupportedUtility orig_mtl
		VraySky: errorCatching convertUnsupportedUtility orig_mtl
		VraySoftbox: errorCatching convertUnsupportedUtility orig_mtl
		VrayTriplanarTex: errorCatching convertUnsupportedUtility orig_mtl
		VrayUserScalar: errorCatching convertUnsupportedUtility orig_mtl
		

		default: orig_mtl
	)
	
	if new_mtl != orig_mtl then ( 		-- if converted, add to the list of converted materials
		append orig_mtls orig_mtl
		append new_mtls new_mtl
	)
	
	new_mtl
)

fn convertShape orig_shp =(
	local i = findItem orig_shps orig_shp -- check if we have already converted this shape
	if i > 0 then return new_shps[i]  --if yes, just return the already converted one	
	
	cls = classof orig_shp
	local new_shp = case cls of (
		VraySphere: errorCatching convertVraySphere orig_shp
		VrayPlane: errorCatching convertVrayPlane orig_shp
		Plane: errorCatching convertPlane orig_shp
		
		default: orig_shp
	)
	
	if new_shp != orig_shp then ( 	-- if converted, add to the list of converted materials
		append orig_shps orig_shp
		append new_shps new_shp
	)
	
	new_shp
)

fn cleanUpConversionData =(

	delete (for elem in orig_lights where (superclassof elem == light) and isvalidnode elem collect elem) 
	delete (for elem in orig_cameras where (superclassof elem == camera) and isvalidnode elem collect elem) 
	delete (for elem in orig_shps where (superclassof elem == GeometryClass) and isvalidnode elem collect elem) 

	-- delete AOVs
	re = maxOps.GetCurRenderElementMgr()
    re.removeallrenderelements()

    orig_shps=#()
    new_shps=#()
	orig_mtls=#()
	new_mtls=#()
	orig_lights=#()
	new_lights=#()
	orig_cameras=#()
	new_cameras=#()
	
	clearUndoBuffer()
	true
)

--get all objects with such material
fn getObjsFromMaterial current_material  =(
	obj_arr = for o in geometry where o.material == current_material collect o
	return obj_arr
)

fn convertScene =(
	
	start = timeStamp()

	startConversion()

	-- shapes conversion
	vrayShapeInstances = for i in Geometry where classOf i == VrayPlane or classOf i == VraySphere or classOf i == Plane collect i
	for i in vrayShapeInstances do convertShape i
	
	-- material conversion
	vrayMtlClasses = #("Multimaterial", "VRayMtl", "VRayMtlWrapper", "VRayLightMtl", "VRay2SidedMtl", "VRayALSurfaceMtl", \
	"VRayBlendMtl", "VRayBumpMtl", "VRayCarPaintMtl", "VRayFlakesMtl", "VRayFastSSS2", "VRayScatterVolume", \
	"VRayOverrideMtl", "VRayGLSLMtl", "VRayHairMtl", "VRayHairNextMtl", "VRayMDLMtl", "VRayOSLMtl", "VRayPluginNodeMtl", \
	"VRayPointParticleMtl", "VRayScannedMtl", "VRayStochasticFlakesMtl", "VRaySwitchMtl", "VRayVectorDisplBake", "VRayVRmatMtl")

	for c in vrayMtlClasses do ( --where c.creatable 
		cls = execute c -- execute obj from string
		if classof cls == material do ( -- check superclass
			clssInst = getclassinstances cls -- get all class instances from scene
			for i in clssInst do (
				obj_arr = getObjsFromMaterial i -- get all geometry from this material
				if obj_arr.count > 0 do (
					newMat = convertMaterial i -- convert material
					if newMat != "no_replace" do (
						for g in obj_arr do g.material = newMat -- replace arnold material
					)
				)
			)
		)
	)
	
	-- light conversion
	allLights = for o in objects where superclassof o == light and o.category == #vray collect o
	for i in allLights do convertLight i
	
	-- camera conversion
	allCameras = for o in objects where superclassof o == camera collect o
	for i in allCameras do(
		newCamera = convertCamera i
		replaceInstances i newCamera	
	)
	

	vr = vray()
	if classof renderers.current == classof vr do (
		if not renderers.current.output_getsetsfrommax do (
			vray_render = renderers.current
			renderHeight = vray_render.output_height
			renderWidth = vray_render.output_width
			renderPiXelAspect = vray_render.output_aspect
			rendImageAspectRatio = vray_render.output_imageaspect
			renderSceneDialog.update()
		)
	)

	renderers.current = Radeon_ProRender()
	renderers.current.raycastEpsilon = 0.001
	renderers.current.texturecompression = true

	SceneExposureControl.exposureControl = undefined

	end = timeStamp()
	total_time = (end - start) / 1000.0
	print("Scene conversion took " + total_time as string + " seconds.")
	print("Converted: " + new_mtls.count as string + " materials, " + new_lights.count as string + " lights.")
	finishConversion total_time

	cleanUpConversionData()
	
)

if not globalVars.isglobal(#autoLaunch) do (
     convertScene()
)

