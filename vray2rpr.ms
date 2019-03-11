
/*

	Vray to RadeonProRender Converter

	History:
	v.1.0 - first release

	Supported materials:
	- VrayMtl
	- VrayLightMtl
	- VrayCarPaintMtl
	- VrayBlendMtl

	Supported utilities:
	- VrayComptex
	- VrayBump2Normal
	- VrayColor

*/

supportedMtlClasses = #("VRayMtlWrapper", "VRayMtl", "VRayLightMtl", "VRay2SidedMtl", "VRayALSurfaceMtl", \
	"VRayBlendMtl", "VRayBumpMtl", "VRayCarPaintMtl", "VRayFlakesMtl", "VRayFastSSS2", "VRayScatterVolume", \
	"VRayOverrideMtl", "VRayGLSLMtl", "VRayHairMtl", "VRayHairNextMtl", "VRayMDLMtl", "VRayOSLMtl", "VRayPluginNodeMtl", \
	"VRayPointParticleMtl", "VRayScannedMtl", "VRayStochasticFlakesMtl", "VRaySwitchMtl", "VRayVectorDisplBake", "VRayVRmatMtl")

supportedMapClasses = #("VrayColor", "VrayDirt", "VrayBump2Normal", "VrayNormalMap", "VraySky", \
	"VRayCompTex", "VRayEdgesTex", "VRayGLSLTex", "VRaySoftbox", "VRayHDRI")

orig_mtls=#()
new_mtls=#()
orig_maps=#()
new_maps=#()
orig_lights=#()
new_lights=#()

useTryCatchBugReporting = true
userPostfixStr = "_rpr"

fn errorCatching functionName orig =(
	errcls = classof orig
	if useTryCatchBugReporting then(
		try(
			out = functionName orig
		)catch(
			print ("Error occured in " + errcls as string + " : " + orig as string + "\r\n" + getCurrentException() ) 
			print ("Stack trace: " + getCurrentExceptionStackTrace())
			out = orig
		)
	)else(
		out = functionName orig
	)
	out
)

fn convertUnsupportedMtl origMtl =(
	r = RPR_Uber_Material()
	r.name = origMtl.name + userPostfixStr
	r.diffuseColor = color 0 45 0
	r
)

fn convertVrayMtl origMtl =(
	r = RPR_Uber_Material()
	r.name = origMtl.name + userPostfixStr

	useRoughness = origMtl.brdf_useRoughness

	-- diffuse
	r.diffuseColor = origMtl.diffuse
	r.diffuseColorTexmap = origMtl.texmap_diffuse
	if useRoughness then (
		r.diffuseRoughness = origMtl.diffuse_roughness
		r.diffuseRoughnessTexmap = origMtl.texmap_roughness
	) else (
		r.diffuseRoughness = 1 - origMtl.diffuse_roughness
		if origMtl.texmap_roughness != undefined do (
			r.diffuseRoughnessTexmap = OSLMap()
			r.diffuseRoughnessTexmap.OSLPath = "{85E076D5-DF8A-45F3-80F5-55FD1AC31AE7}"
			r.diffuseRoughnessTexmap.OSLAutoUpdate = true
			r.diffuseRoughnessTexmap.input_map = origMtl.texmap_roughness
		)
	)
	
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
			r.reflectionRoughnessTexmap = OSLMap()
			r.reflectionRoughnessTexmap.OSLPath = "{85E076D5-DF8A-45F3-80F5-55FD1AC31AE7}"
			r.reflectionRoughnessTexmap.OSLAutoUpdate = true
			r.reflectionRoughnessTexmap.input_map = origMtl.texmap_reflectionGlossiness
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
	if useRoughness then (
		r.refractionRoughness = origMtl.refraction_glossiness
		r.refractionRoughnessTexmap = origMtl.texmap_refractionGlossiness
	) else (
		r.refractionRoughness = 1 - origMtl.refraction_glossiness
		if origMtl.texmap_refractionGlossiness != undefined do (
			r.refractionRoughnessTexmap = OSLMap()
			r.refractionRoughnessTexmap.OSLPath = "{85E076D5-DF8A-45F3-80F5-55FD1AC31AE7}"
			r.refractionRoughnessTexmap.OSLAutoUpdate = true
			r.refractionRoughnessTexmap.input_map = origMtl.texmap_refractionGlossiness
		)
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

	if origMtl.texmap_opacity != undefined do (
		r.TransparencyTexmap = OSLMap()
		r.TransparencyTexmap.OSLPath = "{85E076D5-DF8A-45F3-80F5-55FD1AC31AE7}"
		r.TransparencyTexmap.OSLAutoUpdate = true
		r.TransparencyTexmap.input_map = origMtl.texmap_opacity
	)

	r
)

fn convertVRayCarPaintMtl origMtl =(
	r = RPR_Uber_Material()
	r.name = origMtl.name + userPostfixStr

	r.diffuseColor = origMtl.base_color
	
	r.reflectionEnable = true
	r.ReflectionWeight = origMtl.base_reflection
	r.ReflectionWeightTexmap = origMtl.texmap_base_reflection
	r.reflectionRoughness = 1 - origMtl.base_glossiness
	if origMtl.texmap_base_glossiness != undefined do (
		r.reflectionRoughnessTexmap = OSLMap()
		r.reflectionRoughnessTexmap.OSLPath = "{85E076D5-DF8A-45F3-80F5-55FD1AC31AE7}"
		r.reflectionRoughnessTexmap.OSLAutoUpdate = true
		r.reflectionRoughnessTexmap.input_map = origMtl.texmap_base_glossiness
	)

	r.CoatingEnable = true
	r.CoatingColor = origMtl.coat_color
	r.CoatingColorTexmap = origMtl.texmap_coat_color
	r.CoatingWeight = origMtl.coat_strength
	r.CoatingWeightTexmap = origMtl.texmap_coat_strength
	r.CoatingRoughness = 1 - origMtl.coat_glossiness
	if origMtl.texmap_coat_glossiness != undefined do (
		r.CoatingRoughnessTexmap = OSLMap()
		r.CoatingRoughnessTexmap.OSLPath = "{85E076D5-DF8A-45F3-80F5-55FD1AC31AE7}"
		r.CoatingRoughnessTexmap.OSLAutoUpdate = true
		r.CoatingRoughnessTexmap.input_map = origMtl.texmap_coat_glossiness
	)

	r
)

fn convertVRayBlendMtl origMtl =(
	r = RPR_Blend_Material()
	r.name = origMtl.name + userPostfixStr

	r.material1 = origMtl.baseMtl
	r.material2 = origMtl.coatMtl[1]
	r.weight = origMtl.texmap_blend_multiplier[1]
	r.weightMap = origMtl.texmap_blend[1]

	r
)

fn convertVRayLightMtl origMtl =(
	r = RPR_Uber_Material()
	r.name = origMtl.name + userPostfixStr

	-- emission
	if origMtl.color.red > 0 or origMtl.color.green > 0 or origMtl.color.blue > 0 do ( r.emissiveEnable = true )
	r.emissiveColor = origMtl.color
	r.emissiveColorTexmap = origMtl.texmap
	r.emissiveIntensity = origMtl.multiplier

	if origMtl.opacity_texmap != undefined do (
		r.TransparencyTexmap = OSLMap()
		r.TransparencyTexmap.OSLPath = "{85E076D5-DF8A-45F3-80F5-55FD1AC31AE7}"
		r.TransparencyTexmap.OSLAutoUpdate = true
		r.TransparencyTexmap.input_map = origMtl.opacity_texmap
	)

	-- displacement
	if origMtl.displacement_texmap != undefined do ( r.displacementEnable = true )
	r.displacementTexmap = origMtl.displacement_texmap
	r.displacementMax = origMtl.displacement_multiplier
	if origMtl.directLight_subdivs > 8 then ( r.displacementSubdiv = 8 ) else ( r.displacementSubdiv = origMtl.directLight_subdivs )
	
	r
)

fn convertVrayIES origLight = (
	r=CoronaLight()
	r.name=(if owner.converterSettings.addCoronaPrefix then owner.converterSettings.userPrefixStr else "") + origLight.name
	
	-- OnOff, Include/exclude
	r.on = origLight.enabled
	r.targeted = origLight.targeted
	case of (
		(origLight.includeList != undefined and origLight.includeList.count != 0): (
			r.excludeIncludeMod = true
			r.excludeList = origLight.includeList
		)
		(origLight.excludeList != undefined and origLight.excludeList.count != 0): (
			r.excludeIncludeMod = false
			r.excludeList = origLight.excludeList
		)
		default: ()
	)
	
	-- Intensitiy, Color, Texmap
	r.intensity = origLight.power
	r.intensityUnits = 1 -- luminous (lm)
	
	
	r.colorMode = origLight.color_mode -- 0: direct color, 1: kelvin temp
	r.color = origLight.color
	if r.colorMode == 1 do r.blackbodyTemp = origLight.color_temperature -- kelvin
	
	-- shape   -- 0: sphere, 1: Rectangle, 2: Disk, 3: Cylinder
	case origLight.shape of (
		0:( r.shape = 0 -- point
			r.iesSharpnessFake = true
			r.width = 5
			r.height = 5
		)
		1:( r.shape = 1 -- Rectangle
			r.width = if origLight.width != 0 then origLight.width else 5.0
			r.height = if origLight.length != 0 then origLight.length else 5.0
		)
		2:( r.shape = 2 -- circle
			r.width = if origLight.diameter != 0 then origLight.diameter / 2.0 else 5.0
		) 
		3:( r.shape = 0 -- sphere 
			r.width = if origLight.diameter != 0 then origLight.diameter / 2.0 else 5.0
		) 
		4:( r.shape = 2 -- vertical cylinder
			r.width = if origLight.diameter != 0 then origLight.diameter / 2.0 else 5.0
		) 
		default:(
			r.shape = 0 -- for everything else
			r.iesSharpnessFake = true
			r.width = 5
			r.height = 5
		)
	)
	
	-- visibility
	r.visibleDirectly = false
	r.occludeOtherLights = origLight.castShadows
	
	-- IES
		r.iesOn = true
	if origLight.ies_file != undefined do(
		r.iesFile = origLight.ies_file
	)
	
	r
)

fn convertLights orig_light =(
	if ((superclassof orig_light)!=light) then return orig_light  -- check if this is a light; if not, just return the value
	
	local i=findItem orig_lights orig_light -- check if we have already converted this light
	if i>0 then return new_lights[i]  --if yes, just return the already converted one	
	
	cls=classof orig_light
	local new_light=case cls of (
		--VrayLight: errorCatching convertVrayLight orig_light 
		--VRayIES: errorCatching convertVrayIES orig_light 
		--VraySun: errorCatching convertVraySun orig_light 
		--VRayAmbientLight: errorCatching convertVRayAmbientLight orig_light 
		
		
		default: orig_light
	)
	
	if new_light != orig_light then ( 		-- if converted, add to the list of converted lights
		append orig_lights orig_light
		append new_lights new_light
	)
	
	new_light
)

fn convertVrayCompTex origMap = (
	r = RPR_Arithmetic()
	r.name = origMap.name + userPostfixStr
	
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
	r.name = origMap.name + userPostfixStr
	
	r.isBump = true
	r.map = origMap.bump_map 
	r.strength = origMap.bump_map_mult 

	r
)

fn convertVrayColor origMap = (
	r = RPR_Arithmetic()
	r.name = origMap.name + userPostfixStr
	
	r.Color1 = color origMap.red origMap.green origMap.blue 
	
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
		--VrayNormalMap: errorCatching convertFrom_VrayNormalMap orig_map
		--VRayHDRI: (if converterSettings.VrayHDRIToBitmaptexture then errorCatching convertFrom_VrayHDRI orig_map else orig_map)
		
		default: orig_map
	)
	
	if new_map!=orig_map then ( 		-- if converted, add to the list of converted materials
		append orig_maps orig_map
		append new_maps new_map
	)
	new_map
)

fn convertVrayMaterial orig_mtl processMaps:true =(
	if ((superclassof orig_mtl)!=material) then return orig_mtl  -- check if this is a material; if not, just return the value
	
	local i=findItem orig_mtls orig_mtl -- check if we have already converted this material
	if i>0 then return new_mtls[i]  --if yes, just return the already converted one	
	
	-- recurse into sub-materials, if any
	local sub_count=getNumSubMtls orig_mtl
	if sub_count >= 1 then (
		for i=1 to sub_count do (
			setSubMtl orig_mtl i (convertVrayMaterial (getSubMtl orig_mtl i) processMaps:processMaps )
		)
	)

	if processMaps do( -- check if there are maps in this material and recurse into all subtexmaps
		local sub_count=getNumSubTexmaps orig_mtl
		if sub_count >= 1 then (
			for i=1 to sub_count do (
				newMap = convertVrayUtilities (getSubTexmap orig_mtl i)
				setSubTexmap orig_mtl i newMap
			)
		)
	)
	
	cls=classof orig_mtl
	local new_mtl=case cls of (
		VRayMtl: errorCatching convertVrayMtl orig_mtl
		VRayLightMtl: errorCatching convertVRayLightMtl orig_mtl 
		VRayBlendMtl: errorCatching convertVRayBlendMtl orig_mtl
		VRayCarPaintMtl: errorCatching convertVRayCarPaintMtl orig_mtl 
		VRayPluginNodeMtl: errorCatching convertUnsupportedMtl orig_mtl 
		
		--following materials will be replaced with default green rpr uber mat, will be supported later
		VRayMtlWrapper: errorCatching convertUnsupportedMtl orig_mtl 
		VRay2SidedMtl: errorCatching convertUnsupportedMtl orig_mtl 
		VRayALSurfaceMtl: errorCatching convertUnsupportedMtl orig_mtl 
		VRayBumpMtl: errorCatching convertUnsupportedMtl orig_mtl 
		VRayFlakesMtl: errorCatching convertUnsupportedMtl orig_mtl 
		VRayFastSSS2: errorCatching convertUnsupportedMtl orig_mtl 
		VRayScatterVolume: errorCatching convertUnsupportedMtl orig_mtl 
		VRayOverrideMtl: errorCatching convertUnsupportedMtl orig_mtl 
		VRayGLSLMtl: errorCatching convertUnsupportedMtl orig_mtl 
		VRayHairMtl: convertUnsupportedMtl orig_mtl 
		VRayHairNextMtl: errorCatching convertUnsupportedMtl orig_mtl 
		VRayMDLMtl: errorCatching convertUnsupportedMtl orig_mtl 
		VRayOSLMtl: errorCatching convertUnsupportedMtl orig_mtl 
		VRayPointParticleMtl: errorCatching convertUnsupportedMtl orig_mtl 
		VRayScannedMtl: errorCatching convertUnsupportedMtl orig_mtl 
		VRayStochasticFlakesMtl: errorCatching convertUnsupportedMtl orig_mtl 
		VRaySwitchMtl: errorCatching convertUnsupportedMtl orig_mtl 
		VRayVectorDisplBake: errorCatching convertUnsupportedMtl orig_mtl 
		VRayVRmatMtl: errorCatching convertUnsupportedMtl orig_mtl 
		
		default: orig_mtl
	)
	
	if new_mtl != orig_mtl then ( 		-- if converted, add to the list of converted materials
		append orig_mtls orig_mtl
		append new_mtls new_mtl
	)
	
	new_mtl
)

fn cleanUpConversionData =(
	orig_mtls=#()
	new_mtls=#()
	orig_maps=#()
	new_maps=#()
	orig_lights=#()
	new_lights=#()
	
	clearUndoBuffer()
	true
)

fn convertScene =(
	-- material conversion
	start = timeStamp()
	
	for c in supportedMtlClasses do ( --where c.creatable 
		cls = execute c
		if classof cls == material do(
			-- get all materials from scene
			clssInst = getclassinstances cls processAllAnimatables:false processChildren:false asTrackViewPick:false
			for i in clssInst do(
				replaceInstances i (convertVrayMaterial i processMaps:false)
			)
		)
	)
	
	-- map conversion
	for c in supportedMapClasses do(
		cls = execute c
		if classof cls == textureMap do(
			classInst = getclassinstances cls processAllAnimatables:false processChildren:false asTrackViewPick:false -- HUGE SLOW DOWN!!!!!!!!!!!!!
			for i in classInst do(
				newMap = convertVrayUtilities i
				if newMap != #NoReplacement then(
					replaceInstances i newMap
				)
			)
		)
	)

	-- light conversion
	allLights = for o in objects where superclassof o == light collect o
	for i in allLights do(
		if isValidNode i do(
			print(i)
			if i.parent != undefined and classof i.parent == DaylightAssemblyHead then() else(
				newLight = convertLights i
				replaceInstances i newLight
			)
		)
	)
	
	-- ???
	--delete (for elem in converterTempData.new_lights where (superclassof elem == light) and isvalidnode elem collect elem) 
			
	end = timeStamp()
	print("Scene conversion took " +  ((end - start) / 1000.0) as string + " seconds ")
	print("Converted: " + new_mtls.count as string + " materials and " + new_maps.count as string + " utilities.")

	renderers.current = Radeon_ProRender()
	cleanUpConversionData()
	
)

convertScene()
