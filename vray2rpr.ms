
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

	Supported utilities:
	- VrayComptex
	- VrayBump2Normal
	- VrayColor
	- VrayDirt
	- VrayNormalMap
	- VrayHDRI

	Supported lights:
	- VrayLight
	- VrayIES
	- VraySun

	Supported cameras:
	- VrayPhysicalCamera

*/

orig_mtls=#()
new_mtls=#()
orig_maps=#()
new_maps=#()
orig_lights=#()
new_lights=#()
orig_cameras=#()
new_cameras=#()

unsupportedPostfixStr = "_unsupported"
rprPostfixStr = "_rpr"

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

fn createOSLInvertColor =(

	osl_map = OSLMap()
	osl_map.OSLPath = GetDir #maxroot + "OSL\\ColorComp.osl"
	osl_map.OSLCode =  "// Complements a color.
						// ColorComp.osl, by Zap Andersson
						// Modified: 2018-02-08
						// Copyright 2018 Autodesk Inc, All rights reserved. This file is licensed under Apache 2.0 license
						//    https://github.com/ADN-DevTech/3dsMax-OSL-Shaders/blob/master/LICENSE.txt

						shader ColorComp
						[[ string help = \"Inverts (Complements) a color number (1 - Input)\",
						   string label= \"Invert (color)\",
						   string category = \"Math\Color\" ]]
						(
							color Input = 0.0,
							output color Out = 0.0,
						)
						{
							Out = 1 - Input;
						}
						"
	osl_map.OSLAutoUpdate = true
	
	osl_map
)

fn convertUnsupportedMtl origMtl =(
	r = RPR_Uber_Material()
	r.name = origMtl.name + unsupportedPostfixStr
	r.diffuseColor = color 0 45 0
	r
)

fn convertUnsupportedUtility origMtl =(
	r = RPR_Arithmetic()
	r.name = origMtl.name + unsupportedPostfixStr
	r
)

fn convertVrayMtl origMtl =(
	r = RPR_Uber_Material()
	r.name = origMtl.name + rprPostfixStr

	useRoughness = origMtl.brdf_useRoughness

	-- diffuse
	r.diffuseColor = origMtl.diffuse
	r.diffuseColorTexmap = origMtl.texmap_diffuse
	r.diffuseRoughness = origMtl.diffuse_roughness
	r.diffuseRoughnessTexmap = origMtl.texmap_roughness
	
	-- reflection
	if origMtl.reflection.red > 0 or origMtl.reflection.green > 0 or origMtl.reflection.blue > 0 do ( r.reflectionEnable = true )
	r.reflectionColor = origMtl.reflection
	r.reflectionColorTexmap = origMtl.texmap_reflection
	if useRoughness then (
		r.reflectionRoughness = origMtl.reflection_glossiness
		r.reflectionRoughnessTexmap = origMtl.texmap_reflectionGlossiness
	) else (
		r.reflectionRoughness = 1 - origMtl.reflection_glossiness
		if origMtl.texmap_reflectionGlossiness != undefined do (
			osl_map = createOSLInvertColor()
			osl_map.input_map = origMtl.texmap_reflectionGlossiness
			r.reflectionRoughnessTexmap = osl_map
		)
	)
	if origMtl.reflection_metalness > 0.01 do ( 
		r.reflectionEnable = true
		r.reflectionMode = 2
		r.reflectionColor = origMtl.diffuse
		r.reflectionColorTexmap = origMtl.texmap_diffuse
	)
	r.reflectionIor = origMtl.reflection_ior
	r.reflectionIorTexmap = origMtl.texmap_reflectionIOR
	r.reflectionMetalness = origMtl.reflection_metalness
	r.reflectionMetalnessTexmap = origMtl.texmap_metalness

	r.reflectionAnisotropy = origMtl.anisotropy
	r.reflectionAnisotropyTexmap = origMtl.texmap_anisotropy
	r.reflectionAnisotropyRotation = origMtl.anisotropy_rotation
	r.reflectionAnisotropyRotationTexmap = origMtl.texmap_anisotropy_rotation

	-- refraction
	if origMtl.refraction.red > 0 or origMtl.refraction.green > 0 or origMtl.refraction.blue > 0 do ( r.refractionEnable = true )
	r.refractionColor = origMtl.refraction
	r.refractionColorTexmap = origMtl.texmap_refraction
	r.refractionRoughness = 1 - origMtl.refraction_glossiness
	if origMtl.texmap_refractionGlossiness != undefined do (
		osl_map = createOSLInvertColor()
		osl_map.input_map = origMtl.texmap_refractionGlossiness
		r.refractionRoughnessTexmap.input_map = osl_map
	)
	r.refractionIor = origMtl.refraction_ior
	r.refractionIorTexmap = origMtl.texmap_refractionIOR

	r.refractionAbsorptionDistance = origMtl.refraction_fogMult
	r.refractionAbsorptionColor = origMtl.refraction_fogColor
	r.refractionAbsorptionColorTexmap = origMtl.texmap_refraction_fog

	-- emission
	if origMtl.selfIllumination.red > 0 or origMtl.selfIllumination.green > 0 or origMtl.selfIllumination.blue > 0 do ( r.emissiveEnable = true )
	r.emissiveColor = origMtl.selfIllumination
	r.emissiveColorTexmap = origMtl.texmap_self_illumination
	r.emissiveIntensity = origMtl.selfIllumination_multiplier
	r.emissiveWeight = 0.65

	if origMtl.texmap_opacity != undefined do (
		osl_map = createOSLInvertColor()
		osl_map.input_map = origMtl.texmap_opacity
		r.TransparencyTexmap.input_map = osl_map
	)

	if origMtl.texmap_bump_on do (
		r.normalEnable = true
		r.normalTexmap = origMtl.texmap_bump
	)

	r
)

fn convertVrayCarPaintMtl origMtl =(
	r = RPR_Uber_Material()
	r.name = origMtl.name + rprPostfixStr

	r.diffuseColor = origMtl.base_color
	
	r.reflectionEnable = true
	r.ReflectionWeight = origMtl.base_reflection
	r.ReflectionWeightTexmap = origMtl.texmap_base_reflection
	r.reflectionRoughness = 1 - origMtl.base_glossiness
	if origMtl.texmap_base_glossiness != undefined do (
		osl_map = createOSLInvertColor()
		osl_map.input_map = origMtl.texmap_base_glossiness
		r.reflectionRoughnessTexmap.input_map = osl_map
	)

	r.CoatingEnable = true
	r.CoatingColor = origMtl.coat_color
	r.CoatingColorTexmap = origMtl.texmap_coat_color
	r.CoatingWeight = origMtl.coat_strength
	r.CoatingWeightTexmap = origMtl.texmap_coat_strength
	r.CoatingRoughness = 1 - origMtl.coat_glossiness
	if origMtl.texmap_coat_glossiness != undefined do (
		osl_map = createOSLInvertColor()
		osl_map.input_map = origMtl.texmap_coat_glossiness
		r.CoatingRoughnessTexmap.input_map = osl_map
	)

	r
)

fn convertVrayBlendMtl origMtl =(
	r = RPR_Blend_Material()
	r.name = origMtl.name + rprPostfixStr

	r.material1 = origMtl.baseMtl
	r.material2 = origMtl.coatMtl[1]
	r.weight = origMtl.texmap_blend_multiplier[1]
	r.weightMap = origMtl.texmap_blend[1]

	r
)

fn convertVrayLightMtl origMtl =(
	r = RPR_Uber_Material()
	r.name = origMtl.name + rprPostfixStr

	-- emission
	if origMtl.color.red > 0 or origMtl.color.green > 0 or origMtl.color.blue > 0 do ( r.emissiveEnable = true )
	r.emissiveColor = origMtl.color
	r.emissiveColorTexmap = origMtl.texmap
	r.emissiveIntensity = origMtl.multiplier

	if origMtl.opacity_texmap != undefined do (
		osl_map = createOSLInvertColor()
		osl_map.input_map = origMtl.opacity_texmap
		r.TransparencyTexmap.input_map = osl_map
	)

	-- displacement
	if origMtl.displacement_texmap != undefined do ( r.displacementEnable = true )
	r.displacementTexmap = origMtl.displacement_texmap
	r.displacementMax = origMtl.displacement_multiplier
	if origMtl.directLight_subdivs > 8 then ( r.displacementSubdiv = 8 ) else ( r.displacementSubdiv = origMtl.directLight_subdivs )
	
	r
)

fn convertVrayIES origLight = (
	r = ies_light()
	r.name = origLight.name + rprPostfixStr
	
	-- OnOff, Include/exclude
	r.enabled = origLight.enabled
	r.targeted = origLight.targeted
	
	-- ies file
	if origLight.ies_file != "" and origLight.ies_file != undefined do (
		plugcfg = GetDir #plugcfg
		profile_path = plugcfg + "\\Radeon ProRender\\IES Profiles\\"
		makeDir (profile_path)
		ies_file = origLight.ies_file
		ies_name = (filterString ies_file "\\")[ies_name.count]
		copyFile (ies_file) (profile_path + ies_name)
		r.profile = ies_name
	)

	-- location
	r.rotationX = origLight.rotation_X
	r.rotationY = origLight.rotation_Y
	r.rotationZ = origLight.rotation_Z

	-- Intensitiy, Color, Texmap
	r.intensity = origLight.intensity_value
	r.colorMode = origLight.color_mode
	r.color = origLight.color
	r.temperature = origLight.color_temperature

	r
)

fn convertVrayLight origLight = (
	light_type = origLight.type
	if light_type != 1 then (
		r = physical_light()
		r.name = origLight.name + rprPostfixStr

		-- OnOff, Include/exclude
		r.enabled = origLight.on 
		if origLight.invisible then ( r.isVisible = false ) else ( r.isVisible = true ) -- visible
		r.lightType = 0 -- area light

		local areaShape = case light_type of (
			0: 3 -- Plane
			2: 2 -- Sphere
			3: 4 -- Mesh
			4: 0 -- Disc
			default: 1
		)
		r.areaShape = areaShape

		r.LightIntensity = origLight.multiplier
		r.colourMode = origLight.color_mode
		r.colourPicker = origLight.color
		r.temperature = origLight.color_temperature

		if areaShape == 2 or areaShape == 0 do (
			r.areaWidths = origLight.size0
		)
		if areaShape == 3 do (
			r.areaWidths = origLight.size1
			r.areaLength = origLight.sizeLength
		)
		
		if origLight.texmap != undefined and origLight.texmap_on == true do (
			r.EnableMap = true
			r.ColourMap = origLight.texmap
		)

	) else (
		r = "env"
		if origLight.on do (
			rpr = Radeon_ProRender()
			rpr.backgroundOverride = true
			rpr.backgroundType = 0
			if origLight.texmap != undefined and origLight.texmap_on == true do (
				rpr.useBackgroundMap = True
	    		rpr.backgroundMap =  origLight.texmap
			)
	    	rpr.backgroundIntensity = origLight.multiplier
	    	rpr.backgroundColor = origLight.color
	    )
	)
	
	r
)

fn convertVraySun origLight = (
	r = "env"
	
	if origLight.enabled do (
		rpr = Radeon_ProRender()
		rpr.backgroundOverride = true
		rpr.backgroundType = 1
		rpr.backgroundSkyType = 0
		rpr.backgroundSkyHaze = origLight.turbidity
		rpr.backgroundSkyFilterColor = origLight.filter_color
		rpr.backgroundSkySunDisc = origLight.size_multiplier
		rpr.backgroundSkyGroundAlbedo = origLight.ground_albedo
		rpr.backgroundSkyIntensity = origLight.intensity_multiplier * 49.5
    )

	-- clean scene
	delete origLight

    r
)

fn convertVrayAmbientLight origLight = (

	-- clean scene
	delete origLight

	r = "env"
	r
)

fn convertLights orig_light =(
	if ((superclassof orig_light)!=light) then return orig_light  -- check if this is a light; if not, just return the value
	
	local i=findItem orig_lights orig_light -- check if we have already converted this light
	if i>0 then return new_lights[i]  --if yes, just return the already converted one	
	
	cls=classof orig_light
	local new_light=case cls of (
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

fn convertVrayPhysicalCamera origCamera =(

	r = Freecamera()
	r.name = origCamera.name + rprPostfixStr

	r.targetDistance = origCamera.target_distance
	r.showCone = origCamera.show_camera_cone
	if origCamera.specify_fov do (
		r.fov = origCamera.fov
	)
	r.mpassEffect.useTargetDistance = origCamera.use_dof
	r.clipManually = origCamera.clip_on
	r.nearclip = origCamera.clip_near
	r.farclip = origCamera.clip_far
	r.nearrange = origCamera.environment_near
	r.farrange = origCamera.environment_far

	r
)

fn convertVrayDomeCamera origCamera =(

	r = Freecamera()
	r.name = origCamera.name + rprPostfixStr

	r
)

fn convertCameras orig_camera =(
	if ((superclassof orig_camera)!=camera) then return orig_camera 
	
	local i=findItem orig_cameras orig_camera 
	if i>0 then return new_cameras[i]  
	
	cls=classof orig_camera
	local new_camera=case cls of (
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

fn convertVrayCompTex origMap = (
	r = RPR_Arithmetic()
	r.name = origMap.name + rprPostfixStr
	
	r.color0texmap = origMap.sourceA 
	r.color1texmap = origMap.sourceB 
	r.operator = origMap.operator
	
	local rpr_operator = case origMap.operator of (
		0: 0
		1: 1
		3: 2
		4: 3
		5: 12
		6: 13
		default: 0
	)
	r.operator = rpr_operator

	r
)

fn convertVrayBump2Normal origMap = (
	r = RPR_Normal()
	r.name = origMap.name + rprPostfixStr
	
	r.isBump = true
	r.map = origMap.bump_map 
	r.strength = origMap.bump_map_mult 

	r
)

fn convertVrayNormalMap origMap = (
	r = RPR_Normal()
	r.name = origMap.name + rprPostfixStr
	
	if origMap.normal_map_on and not origMap.bump_map_on do (
		r.isBump = false
		r.map = origMap.normal_map
		r.strength = origMap.normal_map_multiplier  
	)

	if not origMap.normal_map_on and origMap.bump_map_on do (
		r.isBump = true
		r.map = origMap.bump_map 
		r.strength = origMap.bump_map_mult 
	)

	if origMap.normal_map_on and origMap.bump_map_on do (
		r.isBump = false
		r.map = origMap.normal_map
		r.strength = origMap.normal_map_multiplier  
	)

	r
)

fn convertVrayDirt origMap = (
	if origMap.mode == 0 then (
		r = RPR_Ambient_Occlusion()
		r.name = origMap.name + rprPostfixStr
		
		r.unoccluded_Color = origMap.unoccluded_color
		r.occluded_Color = origMap.occluded_color
		r.color0Texmap = origMap.texmap_unoccluded_color
		r.color1Texmap = origMap.texmap_occluded_color
		r.radius = origMap.radius
		
		r
	) else (
		origMap
	)	
)

fn convertVrayColor origMap = (
	r = RPR_Color_Value()
	r.name = origMap.name + rprPostfixStr
	
	r.color = origMap.color 
	
	r
)

fn convertVrayHDRI origMap = (
	r = BitmapTexture()
	r.name = origMap.name
	
	-- filename, output
	if origMap.HDRIMapName != "" and origMap.HDRIMapName != undefined do(
		r.fileName = origMap.HDRIMapName
	)
	
	r.output = origMap.Output
	if hasproperty origMap #coords then(
		r.coords = origMap.coords
	)
	
	-- Gamma handling
	if origMap.gamma != 1 do(
		r.bitmap = openBitmap r.bitmap.filename gamma:(1.0/origMap.gamma)
	)
	
	if origMap.mapType == 2 then(   -- spherical mode
		r.coords.mapping = 0 -- spherical
		r.coords.mappingType = 1 -- Environ
		r.coords.U_Offset = 0.25 + origMap.horizontalRotation / 360.0
		r.coords.V_Offset = origMap.verticalRotation / 180.0
		
		if origMap.horizontalFlip then(
			r.coords.U_Offset = 0.25 - origMap.horizontalRotation / 360.0
			r.coords.U_Tiling = -r.coords.U_Tiling
		)
		if origMap.verticalFlip then r.coords.V_Tiling = -r.coords.V_Tiling
	)
	
	-- alpha source, mono channel out, rgb channel out
	r.alphaSource = origMap.alphaSource
	r.monoOutput = origMap.monoOutput
	r.rgbOutput = if origMap.rgbOutput > 1 then 0 else origMap.rgbOutput
	
	-- crop/place
	r.apply = origMap.cropplace_on
	r.cropPlace = origMap.cropplace_mode
	r.clipu = origMap.cropplace_u
	r.clipv = origMap.cropplace_v
	r.clipw = origMap.cropplace_width
	r.cliph = origMap.cropplace_height
	
	r.output.output_amount *= origMap.multiplier * origMap.renderMultiplier
	
	r
	
)

fn convertVrayUtilities orig_map =(
	if ((superclassof orig_map)!=textureMap) then return orig_map  -- check if this is a material; if not, just return the value
	
	local i=findItem orig_maps orig_map -- check if we have already converted this map
	if i>0 then return new_maps[i]  --if yes, just return the already converted one	
	
	-- recurse into sub-maps, if any
	local sub_count=getNumSubTexmaps orig_map
	if sub_count >= 1 then (
		for i=1 to sub_count do (
			newMap = convertVrayUtilities (getSubTexmap orig_map i)
			setSubTexmap orig_map i newMap
		)
	)
	
	cls=classof orig_map
	
	local new_map=case cls of (
		VrayCompTex: errorCatching convertVrayCompTex orig_map
		VrayColor: errorCatching convertVrayColor orig_map
		VrayBump2Normal: errorCatching convertVrayBump2Normal orig_map
		VrayDirt: errorCatching convertVrayDirt orig_map
		VrayNormalMap: errorCatching convertVrayNormalMap orig_map
		VrayHDRI: errorCatching convertVrayHDRI orig_map

		VrayColor2Bump: errorCatching convertUnsupportedUtility orig_map
		VrayCurvature: errorCatching convertUnsupportedUtility orig_map
		VrayDistanceTex: errorCatching convertUnsupportedUtility orig_map
		VrayEdgesTex: errorCatching convertUnsupportedUtility orig_map
		VrayFakeFresnelTex: errorCatching convertUnsupportedUtility orig_map
		VrayGLSLTex: errorCatching convertUnsupportedUtility orig_map
		VrayHairInfoTex: errorCatching convertUnsupportedUtility orig_map
		VrayICC: errorCatching convertUnsupportedUtility orig_map
		VrayLut: errorCatching convertUnsupportedUtility orig_map
		VrayMultiSubTex: errorCatching convertUnsupportedUtility orig_map
		VrayNoiseTex: errorCatching convertUnsupportedUtility orig_map
		VrayOCIO: errorCatching convertUnsupportedUtility orig_map
		VrayOSLText: errorCatching convertUnsupportedUtility orig_map
		VrayParticleTex: errorCatching convertUnsupportedUtility orig_map
		VrayPluginNodeTex: errorCatching convertUnsupportedUtility orig_map
		VrayPtex: errorCatching convertUnsupportedUtility orig_map
		VraySamplerInfoTex: errorCatching convertUnsupportedUtility orig_map
		VraySky: errorCatching convertUnsupportedUtility orig_map
		VraySoftbox: errorCatching convertUnsupportedUtility orig_map
		VrayTriplanarTex: errorCatching convertUnsupportedUtility orig_map
		VrayUserColor: errorCatching convertUnsupportedUtility orig_map
		VrayUserScalar: errorCatching convertUnsupportedUtility orig_map
		
		default: orig_map
	)
	
	if new_map!=orig_map then ( 		-- if converted, add to the list of converted materials
		append orig_maps orig_map
		append new_maps new_map
	)
	new_map
)

fn convertVrayMaterial orig_mtl =(
	
	local i=findItem orig_mtls orig_mtl -- check if we have already converted this material
	if i>0 then return new_mtls[i]  --if yes, just return the already converted one	
	
	-- recurse into sub-materials, if any
	local sub_count=getNumSubMtls orig_mtl
	if sub_count >= 1 then (
		for i=1 to sub_count do (
			setSubMtl orig_mtl i (convertVrayMaterial (getSubMtl orig_mtl i))
		)
	)

	local sub_count=getNumSubTexmaps orig_mtl
	if sub_count >= 1 then (
		for i=1 to sub_count do (
			newMap = convertVrayUtilities (getSubTexmap orig_mtl i)
			setSubTexmap orig_mtl i newMap
		)
	)
	
	cls=classof orig_mtl
	local new_mtl=case cls of (
		VrayMtl: errorCatching convertVrayMtl orig_mtl
		VrayLightMtl: errorCatching convertVrayLightMtl orig_mtl 
		VrayBlendMtl: errorCatching convertVrayBlendMtl orig_mtl
		VrayCarPaintMtl: errorCatching convertVrayCarPaintMtl orig_mtl 
		VrayPluginNodeMtl: errorCatching convertUnsupportedMtl orig_mtl 
		
		--following materials will be replaced with default green rpr uber mat, will be supported later
		VrayMtlWrapper: errorCatching convertUnsupportedMtl orig_mtl 
		Vray2SidedMtl: errorCatching convertUnsupportedMtl orig_mtl 
		VrayALSurfaceMtl: errorCatching convertUnsupportedMtl orig_mtl 
		VrayBumpMtl: errorCatching convertUnsupportedMtl orig_mtl 
		VrayFlakesMtl: errorCatching convertUnsupportedMtl orig_mtl 
		VrayFastSSS2: errorCatching convertUnsupportedMtl orig_mtl 
		VrayScatterVolume: errorCatching convertUnsupportedMtl orig_mtl 
		VrayOverrideMtl: errorCatching convertUnsupportedMtl orig_mtl 
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
		
		default: orig_mtl
	)
	
	if new_mtl != orig_mtl then ( 		-- if converted, add to the list of converted materials
		append orig_mtls orig_mtl
		append new_mtls new_mtl
	)
	
	new_mtl
)

fn cleanUpConversionData =(

	delete (for elem in new_lights where (superclassof elem == light) and isvalidnode elem collect elem) 
	delete (for elem in new_cameras where (superclassof elem == camera) and isvalidnode elem collect elem) 

	orig_mtls=#()
	new_mtls=#()
	orig_maps=#()
	new_maps=#()
	orig_lights=#()
	new_lights=#()
	orig_cameras=#()
	new_cameras=#()
	
	clearUndoBuffer()
	true
)

fn convertScene =(
	
	start = timeStamp()
	
	-- material conversion
	matVray = for m in scenematerials where m.category == #vray and superclassof m == material collect m
	for i in matVray do(
		replaceInstances i (convertVrayMaterial i processMaps:false)
	)
	
	-- light conversion
	allLights = for o in objects where superclassof o == light and o.category == #vray collect o
	for i in allLights do(
		newLight = convertLights i
		if newLight != "env" do (
			replaceInstances i newLight
		)
	)
		
	-- camera conversion
	allCameras = for o in objects where superclassof o == camera collect o
	for i in allCameras do(
		newCamera = convertCameras i
		replaceInstances i newCamera	
	)
			
	end = timeStamp()
	print("Scene conversion took " +  ((end - start) / 1000.0) as string + " seconds ")
	print("Converted: " + new_mtls.count as string + " materials, " + new_maps.count as string + " utilities and " + new_lights.count as string + " lights.")

	renderers.current = Radeon_ProRender()
	renderers.current.raycastEpsilon = 0.001

	cleanUpConversionData()
	
)

convertScene()