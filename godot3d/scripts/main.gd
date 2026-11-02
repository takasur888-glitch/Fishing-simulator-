extends Node3D

# Raft Survival 3D - first mobile-friendly scene.
# This is a visual foundation; gameplay systems will be added in later stages.

var raft: Node3D
var camera: Camera3D
var ocean_material: ShaderMaterial
var speed := 0.0
var target_speed := 0.0

const WATER_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform vec4 deep_water : source_color = vec4(0.015, 0.20, 0.31, 1.0);
uniform vec4 shallow_water : source_color = vec4(0.04, 0.48, 0.58, 1.0);
uniform float wave_scale = 0.055;
varying float wave_value;
void vertex() {
    float a = sin(VERTEX.x * 0.12 + TIME * 1.15);
    float b = cos(VERTEX.z * 0.16 + TIME * 0.82);
    float c = sin((VERTEX.x + VERTEX.z) * 0.07 + TIME * 0.55);
    VERTEX.y += (a * 0.22 + b * 0.14 + c * 0.12);
    wave_value = a * 0.5 + b * 0.3 + c * 0.2;
}
void fragment() {
    float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 2.0);
    vec3 water = mix(deep_water.rgb, shallow_water.rgb, clamp(wave_value * 0.5 + 0.48, 0.0, 1.0));
    ALBEDO = mix(water, vec3(0.32, 0.72, 0.78), fresnel * 0.28);
    ROUGHNESS = 0.22;
    METALLIC = 0.12;
}
"""

func _ready() -> void:
    _create_world()
    _create_ocean()
    _create_raft()
    _create_island()
    _create_camera()
    _create_sun()
    _create_hud()

func _process(delta: float) -> void:
    if raft == null:
        return
    speed = move_toward(speed, target_speed, delta * 2.2)
    raft.position.x += speed * delta
    if camera:
        var desired := raft.global_position + Vector3(0.0, 8.5, 15.5)
        camera.global_position = camera.global_position.lerp(desired, delta * 2.0)
        camera.look_at(raft.global_position + Vector3(0.0, 1.0, 0.0), Vector3.UP)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_A or event.keycode == KEY_LEFT:
            target_speed = -5.0
        elif event.keycode == KEY_D or event.keycode == KEY_RIGHT:
            target_speed = 5.0
        elif event.keycode == KEY_SPACE:
            target_speed = 0.0

func _create_world() -> void:
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color(0.08, 0.28, 0.52)
    sky_mat.sky_horizon_color = Color(0.55, 0.78, 0.88)
    sky_mat.ground_bottom_color = Color(0.035, 0.12, 0.16)
    sky_mat.ground_horizon_color = Color(0.34, 0.52, 0.57)
    sky.sky_material = sky_mat
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.ambient_light_energy = 0.65
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world.environment = env
    add_child(world)

func _create_ocean() -> void:
    var water := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(500.0, 500.0)
    plane.subdivide_width = 100
    plane.subdivide_depth = 100
    water.mesh = plane
    ocean_material = ShaderMaterial.new()
    var shader := Shader.new()
    shader.code = WATER_SHADER
    ocean_material.shader = shader
    water.material_override = ocean_material
    water.position.y = -0.25
    add_child(water)

func _create_raft() -> void:
    raft = Node3D.new()
    raft.position = Vector3(0.0, 0.0, 0.0)
    add_child(raft)

    # Main hull
    var hull := _box(Vector3(5.4, 0.75, 2.8), Color(0.30, 0.16, 0.075))
    hull.position.y = 0.15
    raft.add_child(hull)

    # Wooden deck planks
    for i in range(7):
        var plank := _box(Vector3(0.16, 0.12, 2.72), Color(0.55, 0.32, 0.14))
        plank.position = Vector3(-2.35 + i * 0.78, 0.58, 0.0)
        raft.add_child(plank)

    # Side rails and corner posts
    for side in [-1.0, 1.0]:
        var rail := _box(Vector3(5.1, 0.18, 0.16), Color(0.36, 0.20, 0.09))
        rail.position = Vector3(0.0, 0.82, side * 1.28)
        raft.add_child(rail)
        for x in [-2.35, 2.35]:
            var post := _box(Vector3(0.22, 0.65, 0.22), Color(0.42, 0.24, 0.10))
            post.position = Vector3(x, 0.9, side * 1.28)
            raft.add_child(post)

    # Small cabin / storage crate
    var crate := _box(Vector3(1.15, 0.72, 0.9), Color(0.42, 0.25, 0.12))
    crate.position = Vector3(-1.35, 1.05, -0.25)
    raft.add_child(crate)
    var lid := _box(Vector3(1.22, 0.12, 0.96), Color(0.62, 0.39, 0.19))
    lid.position = Vector3(-1.35, 1.47, -0.25)
    raft.add_child(lid)

    # Mast and simple sail
    var mast := _cylinder(0.10, 4.0, Color(0.30, 0.17, 0.08))
    mast.position = Vector3(1.15, 2.25, 0.0)
    raft.add_child(mast)
    var sail := _box(Vector3(0.12, 2.35, 1.7), Color(0.88, 0.84, 0.68))
    sail.position = Vector3(1.15, 2.65, -0.05)
    raft.add_child(sail)

func _create_island() -> void:
    var island := Node3D.new()
    island.position = Vector3(24.0, -1.4, -15.0)
    add_child(island)
    var sand := _sphere(Vector3(11.0, 2.0, 8.0), Color(0.78, 0.68, 0.43))
    island.add_child(sand)
    var green := _sphere(Vector3(9.2, 2.0, 6.7), Color(0.12, 0.34, 0.18))
    green.position.y = 1.0
    island.add_child(green)
    for i in range(5):
        var trunk := _cylinder(0.22, 3.3, Color(0.34, 0.20, 0.10))
        trunk.position = Vector3(-4.0 + i * 2.0, 3.1, sin(float(i)) * 2.2)
        trunk.rotation.z = -0.12
        island.add_child(trunk)
        var leaves := _sphere(Vector3(1.8, 1.1, 1.8), Color(0.10, 0.38, 0.17))
        leaves.position = trunk.position + Vector3(0.0, 2.0, 0.0)
        island.add_child(leaves)

func _create_camera() -> void:
    camera = Camera3D.new()
    camera.position = Vector3(0.0, 8.5, 15.5)
    camera.fov = 62.0
    add_child(camera)
    camera.look_at(Vector3(0.0, 0.8, 0.0), Vector3.UP)
    camera.current = true

func _create_sun() -> void:
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
    sun.light_energy = 1.25
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 55.0
    add_child(sun)

func _create_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var label := Label.new()
    label.text = "RAFT SURVIVAL 3D  |  Prototype\nA / D or ← / → to sail  •  SPACE to stop"
    label.position = Vector2(24, 20)
    label.add_theme_font_size_override("font_size", 22)
    label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
    layer.add_child(label)

func _box(size: Vector3, color: Color) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    item.mesh = mesh
    item.material_override = _material(color)
    return item

func _sphere(scale_value: Vector3, color: Color) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 1.0
    mesh.height = 2.0
    item.mesh = mesh
    item.scale = scale_value
    item.material_override = _material(color)
    return item

func _cylinder(radius: float, height: float, color: Color) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    item.mesh = mesh
    item.material_override = _material(color)
    return item

func _material(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.78
    return mat
