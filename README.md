# SimpleGrassTextured
This plugin for Godot 4 allows you to add grass and plants to your scene in a simple way

https://icterusgames.itch.io/simple-grass-textured

![Preview Image](https://github.com/IcterusGames/SimpleGrassTexturedPreview/raw/main/previews/preview_03.jpg)


## How to install

### Using the AssetLib on Godot
* Open the AssetLib tab on Godot and search "Simple Grass Textured"
* Install the Simple Grass Textured plugin
* Enable SimpleGrassTextured in `Project -> Project Settings -> Plugins`

### Manual installation
* Clone or download this repository
* Copy the folder 'addons/simplegrasstextured' in your 'res://addons/' folder
  - ![Preview folder](https://github.com/IcterusGames/SimpleGrassTexturedPreview/raw/main/previews/folder.png)
* Enable SimpleGrassTextured in `Project -> Project Settings -> Plugins`

### Upgrade from previous version
* Close all your scenes
  > Especially those in which there is some SimpleGrassTextured
* Disable SimpleGrassTextured in `Project -> Project Settings -> Plugins`
* Delete the folder 'addons/simplegrasstextured' on your project
* Install the new SimpleGrassTextured version
* Enable SimpleGrassTextured in `Project -> Project Settings -> Plugins`
* Reload Godot

## How to use

Add a SimpleGrassTextured node to your terrain scene
> Your terrain scene must have a StaticBody3D in order to draw grass on top of the terrain
> - ![Preview scene](https://github.com/IcterusGames/SimpleGrassTexturedPreview/raw/main/previews/simple_scene.png)

Select the SimpleGrassTextured node on your scene and draw on the terrain

### How to enable interactive mode
- <picture>
  <img alt="" src="https://github.com/IcterusGames/SimpleGrassTexturedPreview/raw/main/previews/sgt2_interactive.gif">
</picture>


1. In the _ready function of your game scene you must enable the interactive mode by calling the function SimpleGrass.set_interactive(true)
   - ![Preview set interactive code](https://github.com/IcterusGames/SimpleGrassTexturedPreview/raw/main/previews/sgt2_set_interactive.png)
2. Next you must enable the character to be detected by the SimpleGrassTexture collision system, for this it is recommended to add a MeshInstance3D to the character (for example a sphere) at the height of the ground
   > you can adjust the size of the sphere so that the collision be detected more accurately
   - ![Preview character collision mesh](https://github.com/IcterusGames/SimpleGrassTexturedPreview/raw/main/previews/sgt2_character_collision_mesh.png)
3. In the render layers of the MeshInstance 3D, only layer 17 should be enabled
   - ![Preview character collision visual layers](https://github.com/IcterusGames/SimpleGrassTexturedPreview/raw/main/previews/sgt2_character_collision_layers.png)
   > Note: this same procedure can be done for each character or object that must interact with SimpleGrassTextured
4. In the active camera disable display layer 17 so that objects that are only interactable with SimpleGrassTexture are not visible
   - ![Preview camera cull mask](https://github.com/IcterusGames/SimpleGrassTexturedPreview/raw/main/previews/sgt2_camera_cull_mask.png)

### How to use a custom mesh

* Select the SimpleGrassTextured
* Using the inspector load your custom mesh on the mesh propierty
* On the Texture Albedo load your custom texture for the mesh
  > Optionally in the "Material parameters" section adjust the appearance of the material

  - ![Preview custom mesh](https://github.com/IcterusGames/SimpleGrassTexturedPreview/raw/main/previews/sgt2_custom_mesh.png)

## Optimization

### Disable shadows

* For short grasses in which it is not necessary to have shadows, they can be turned off via the SimpleGrassTextured menu in the top bar
  - ![Preview menu cast shadows](https://github.com/IcterusGames/SimpleGrassTexturedPreview/raw/main/previews/sgt2_optimization_shadows.png)

### Bake height map

* If you have enabled the interactive mode, can speed up the loading time by baking the heightmap (mainly if there are a large number of grasses), you can do it in the SimpleGrassTextured menu on the top bar
  > Be sure to do this if you make any changes to the grasses.
  - ![Preview menu bake height map](https://github.com/IcterusGames/SimpleGrassTexturedPreview/raw/main/previews/sgt2_optimization_bake_height_map.png)

### LOD optimization

* Use the "auto center position" tool in the SimpleGrassTextured menu to adjust the node position, this way you make sure Godot's LOD system works correctly
  - ![Preview menu auto center position](https://github.com/IcterusGames/SimpleGrassTexturedPreview/raw/main/previews/sgt2_optimization_auto_center_position.png)

* If your custom mesh does not display correctly try adjusting LOD Bias
  - ![Inspector lod 1](https://github.com/IcterusGames/SimpleGrassTexturedPreview/raw/main/previews/lod_bias_1.jpg)
    ![Inspector lod 5](https://github.com/IcterusGames/SimpleGrassTexturedPreview/raw/main/previews/lod_bias_5.jpg)

## Licence

MIT

### Assets Copyright/Attribution Notice:

Texture grassbushcc008.png, Licence CC0, by FabinhoSC https://opengameart.org/content/stylized-grass-and-bush-textures-0
