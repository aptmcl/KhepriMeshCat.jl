export meshcat,
       meshcat_material,
       meshcat_glass_material,
       meshcat_metal_material
import Base.convert

#=
ATTENTION!!!

Use Chrome debugger to visualize threeJS examples, break the execution and
evaluate in the console:

JSON.stringify(scene.toJSON(), undefined, 2)

=#


## Primitives

send_meshcat(vis::Visualizer, obj) =
  write(vis.core, pack(obj))

send_setobject(vis, path, obj) =
  let msg = (type="set_object", path=path, object=obj),
      data = pack(msg)
    #vis.core.tree[path].object = data
    write(vis.core, data)
    path
  end

send_settransform(vis, path, transform) =
  let msg = (type="set_transform", path=path, matrix=convert(Vector{Float32}, transform)),
      data = pack(msg)
    #vis.core.tree[path].transform = data
    write(vis.core, data)
    nothing
  end

send_setproperty(vis, path, property, value) =
  let msg = (type="set_property", path=path, property=property, value=value),
      data = pack(msg)
    #vis.core.tree[path].properties[property] = data
    write(vis.core, data)
    nothing
  end

send_setvisible(vis, path, value) =
  send_meshcat(vis, (type="set_property", path=path, property="visible", value=value))

#send_setproperty(connection(meshcat), "/Background/hide_background", "value", true)
#send_meshcat(connection(meshcat), (type="hide_background",))

send_delobject(vis, path) =
  send_meshcat(vis, (type="delete", path=path))

meshcat_point(p::Loc) =
  let p = in_world(p)
    [cx(p),cz(p),cy(p)]
  end

meshcat_transform(p::Loc) =
  # MeshCat swaps Y with Z
  let m = translated_cs(p.cs, p.x, p.y, p.z).transform*[1 0 0 0; 0 0 1 0; 0 1 0 0; 0 0 0 1]
    m[:]
  end

meshcat_metadata(type="Object") =
  (type=type, version=4.5)

meshcat_color(color) =
  "0x$(hex(color))"

meshcat_material(color) =
  (uuid=string(uuid1()),
   type="MeshLambertMaterial",
    #"vertexColors" => 0,
    #"transparent" => false,
    #"opacity" => 1.0,
    #"depthTest" => true,
    #"linewidth" => 1.0,
    #"depthFunc" => 3,
    side=2,
    color=meshcat_color(color),
    #color="0xAAAAAA",
    #"reflectivity" => 0.5,
    #depthWrite=true
    )
meshcat_glass_material(opacity=0.5, color=RGB(0.9,0.9,1.0)) =
  (uuid=string(uuid1()),
   type="MeshPhysicalMaterial",
    #"vertexColors" => 0,
   transparent=true,
   opacity=opacity,
    #"depthTest" => true,
    #"linewidth" => 1.0,
    #"depthFunc" => 3,
   side=2,
   color=meshcat_color(color),
   reflectivity=0.1,
    #depthWrite=true
  )
meshcat_metal_material(roughness=0.5, color=RGB(1.0,1.0,1.0)) =
  (uuid=string(uuid1()),
   type="MeshStandardMaterial",
   metalness=1,
   roughness=roughness,
   side=2,
   color=meshcat_color(color),
  )

meshcat_line_material(color) =
  (uuid=string(uuid1()),
   type="LineBasicMaterial",
   color=meshcat_color(color),
   #linewidth=2, Due to limitations of the OpenGL Core Profile with the WebGL renderer on most platforms linewidth will always be 1 regardless of the set value.
   #depthFunc=3,
   #depthTest=true,
   depthWrite=true,
   #stencilWrite=false,
   #stencilWriteMask=255,
   #stencilFunc=519,
   #stencilRef=0,
   #stencilFuncMask=255,
   #stencilFail=7680,
   #stencilZFail=7680,
   #stencilZPass=7680
   )

meshcat_object(type, geom, material, p=u0(world_cs)) =
  (metadata=meshcat_metadata(),
   geometries=[geom],
   materials=[material],
   object=(uuid=string(uuid1()),
           type=type,
           geometry=geom.uuid,
           material=material.uuid,
           matrix=meshcat_transform(p)))

meshcat_object_2D(type, geom, shapes, material) =
 (metadata=meshcat_metadata(),
  shapes=shapes,
  geometries=[geom],
  materials=[material],
  object=(uuid=string(uuid1()),
          type=type,
          geometry=geom.uuid,
          material=material.uuid,
          matrix=(1, 0, 0, 0,
                  0, 1, 0, 0,
                  0, 0,-1, 0,
                  0, 0, 0, 1)))

meshcat_object_shapes(type, geom, shapes, material, p=u0(world_cs)) =
 (metadata=meshcat_metadata(),
  shapes=shapes,
  geometries=[geom],
  materials=[material],
  object=(uuid=string(uuid1()),
          type=type,
          geometry=geom.uuid,
          material=material.uuid,
          matrix=(translated_cs(p.cs, p.x, p.y, p.z).transform*[1 0 0 0; 0 1 0 0; 0 0 -1 0; 0 0 0 1])[:])) # meshcat_transform(p))) #(1, 0, 0, 0, 0, 1, 0, 0, 0, 0,-1, 0, 0, 0, 0, 1)))


meshcat_buffer_geometry_attributes_position(vertices) =
  (itemSize=3,
   type="Float32Array",
   array=convert(Vector{Float32}, reduce(vcat, meshcat_point.(vertices))))

meshcat_line(vertices, material) =
  let geom = (uuid=string(uuid1()),
              type="BufferGeometry",
              data=(
                attributes=(
                  position=meshcat_buffer_geometry_attributes_position(vertices),),))
    meshcat_object("Line", geom, material)
  end

#=
Three.js uses 2D locations and 3D locations
=#

abstract type Meshcat2D end

convert(::Type{Meshcat2D}, p::Loc) = (cx(p),cy(p))
meshcat_2d(p::Loc) = let z =  @assert(abs(cz(p)) < 1e-10); (cx(p),cy(p)) end
meshcat_3d(p::Loc) = (cx(p),cy(p),cz(p))
meshcat_line_curve_2d(v1::Loc, v2::Loc) =
  (type="LineCurve", v1=meshcat_2d(v1), v2=meshcat_2d(v2))
meshcat_line_curve_3d(v1::Loc, v2::Loc) =
  (type="LineCurve3", v1=meshcat_3d(v1), v2=meshcat_3d(v2))

#=
Three.js provides a hierarchy of curves.
Curve - Abstract
2D curves:
  ArcCurve
  CubicBezierCurve
  EllipseCurve
  LineCurve
  QuadraticBezierCurve
  SplineCurve
3D curves:
  CatmullRomCurve3
  CubicBezierCurve3
  LineCurve3
  QuadraticBezierCurve3
Sequences:
  CurvePath - Abstract
    Path
      Shape
=#
abstract type MeshcatCurve end
abstract type MeshcatCurve2D <: MeshcatCurve end
abstract type MeshcatCurve3D <: MeshcatCurve end
abstract type MeshcatCurvePath <: MeshcatCurve end
abstract type MeshcatPath <: MeshcatCurvePath end
abstract type MeshcatShape <: MeshcatPath end

abstract type MeshcatCurves end

meshcat_curve(path) = convert(MeshcatCurve, path)
convert(::Type{MeshcatCurve}, p::CircularPath) =
  (type="EllipseCurve",
   aX=cx(p.center), aY=cy(p.center),
   xRadius=p.radius, yRadius=p.radius,
   aStartAngle=0, aEndAngle=2π,
   aClockwise=false,
   aRotation=0)
convert(::Type{MeshcatCurve}, p::OpenPolygonalPath) =
  let ps = path_vertices(p)
    length(ps) == 2 ?
      meshcat_line_curve_2d(ps[1], ps[2]) :
      convert(MeshcatPath, p)
  end

meshcat_path(path) = convert(MeshcatPath, path)
convert(::Type{MeshcatPath}, path) =
  (type="Path",
   curves=meshcat_curves(path),
   autoclose=false,
   currentPoint=(0,0))

meshcat_curves(path) = convert(MeshcatCurves, path)
convert(::Type{MeshcatCurves}, path) =
  [meshcat_curve(path)]
convert(::Type{MeshcatCurves}, vs::Locs) =
  [meshcat_line_curve_2d(v1, v2)
   for (v1,v2) in zip(vs, circshift(vs, -1))]
convert(::Type{MeshcatCurves}, p::Union{RectangularPath, ClosedPolygonalPath}) =
  convert(MeshcatCurves, path_vertices(p))

meshcat_shape(path) = convert(MeshcatShape, path)
convert(::Type{MeshcatShape}, p::Region) =
  (uuid=string(uuid1()),
   type="Shape",
   curves=meshcat_curves(p.paths[1]),
   autoclose=false,
   currentPoint=(0,0),
   holes=meshcat_path.(p.paths[2:end]))
convert(::Type{MeshcatShape}, p::Path) =
  (uuid=string(uuid1()),
   type="Shape",
   curves=meshcat_curves(p),
   autoclose=false,
   currentPoint=(0,0),
   holes=[])

meshcat_surface_2d(path, material, p=u0(world_cs)) =
  let shape = meshcat_shape(path),
      geom = (uuid=string(uuid1()),
              type="ShapeBufferGeometry",
              shapes=[shape.uuid],
              curveSegments=64)
    meshcat_object_shapes("Mesh", geom, [shape], material, p)
  end

#=
backend(meshcat)
delete_all_shapes()
add_object(
  meshcat,
  meshcat_surface_polygon_2d(
    path_vertices(closed_polygonal_path(regular_polygon_vertices(5, u0(), 3))),
    [path_vertices(closed_polygonal_path(regular_polygon_vertices(4, u0(), 1)))],
  material(meshcat)))

dump(meshcat_surface_polygon_2d(
  path_vertices(closed_polygonal_path(regular_polygon_vertices(5, u0(), 3))),
  [path_vertices(closed_polygonal_path(regular_polygon_vertices(4, u0(), 1)))],
  material(meshcat)))
dump(meshcat_surface_2d(
    path_set(closed_polygonal_path(regular_polygon_vertices(5, u0(), 3)),
             closed_polygonal_path(regular_polygon_vertices(4, u0(), 1))),
    material(meshcat)))

add_object(meshcat, meshcat_surface_polygon(regular_polygon_vertices(5), material(meshcat)))
add_object(
  meshcat,
  meshcat_surface_2d(
    path_set(
      circular_path(u0(), 2),
      circular_path(u0(), 1)),
    material(meshcat)))

add_object(
 meshcat,
  meshcat_surface_2d(circular_path(u0(), 3), material(meshcat)))

add_object(
  meshcat,
  meshcat_surface_2d(
    closed_polygonal_path(regular_polygon_vertices(5, u0(), 5)),
    material(meshcat)))
add_object(
  meshcat,
  meshcat_surface_2d(
    closed_polygonal_path(regular_polygon_vertices(4, u0(), 1)),
    material(meshcat)))



add_object(
  meshcat,
  meshcat_surface_2d(
    path_set(
      closed_polygonal_path(regular_polygon_vertices(5, u0(), 3)),
      closed_polygonal_path(regular_polygon_vertices(4, u0(), 1))),
    material(meshcat)))


dump(meshcat_surface_polygon(regular_polygon_vertices(5), material(meshcat)))


dump(meshcat_surface_2d(
  path_set(
    circular_path(u0(), 5),
    circular_path(u0(), 1)),
  material(meshcat)))
=#

meshcat_surface_polygon(vertices, material) =
  let n = length(vertices)
    n <= 0 ?
      meshcat_mesh(vertices, n < 4 ? [(0,1,2)] : [(0,1,2),(2,3,0)], material) :
      let ps = in_world.(vertices),
          n = vertices_normal(ps),
          cs = cs_from_o_vz(ps[1], n),
          vs = [in_cs(v, cs) for v in vertices]
        meshcat_surface_2d(closed_polygonal_path(vs), material, u0(cs))
      end
  end

#=
reset_backend()
delete_all_shapes()
add_object(meshcat, meshcat_surface_polygon([x(1), x(3), xz(3,4), xz(1,4)], material(meshcat)))
=#

meshcat_circle_mesh(center, radius, start_angle, amplitude, material) =
  let geom = (uuid=string(uuid1()),
              type="CircleBufferGeometry",
              radius=radius,
              segments=64,
              thetaStart=start_angle,
              thetaLength=amplitude),
      cs = cs_from_o_vz(center, vx(-1, center.cs))
    meshcat_object("Mesh", geom, material, u0(cs))
  end

meshcat_centered_box(p, dx, dy, dz, material) =
  let geom = (uuid=string(uuid1()),
              type="BoxBufferGeometry",
              width=dx,
              depth=dy,
              height=dz)
    meshcat_object("Mesh", geom, material, p)
  end

meshcat_box(p, dx, dy, dz, material) =
  meshcat_centered_box(p+vxyz(dx/2, dy/2, dz/2, p.cs), dx, dy, dz, material)

#=
send_delobject(v, "/meshcat")
send_setobject(v, "/meshcat/box1", meshcat_box(xyz(1,1,1), 1, 2, 3))
send_setobject(v, "/meshcat/box2", meshcat_box(loc_from_o_vx_vy(u0(), vxy(1,1), vxy(-1,1)), 1, 2, 3))
send_delobject(v, "/meshcat/box2")
=#

meshcat_sphere(p, r, material) =
  let geom = (uuid=string(uuid1()),
              type="SphereBufferGeometry",
              radius=r,
              widthSegments=64,
              heightSegments=64)
    meshcat_object("Mesh", geom, material, p)
  end

meshcat_torus(p, re, ri, material) =
  let geom = (uuid=string(uuid1()),
              type="TorusBufferGeometry",
              radius=re,
              tube=ri,
              radialSegments=64,
              tubularSegments=32)
    meshcat_object_shapes("Mesh", geom, [], material, p)
  end

meshcat_centered_cone(p, r, h, material) =
  let geom = (uuid=string(uuid1()),
              type="ConeBufferGeometry",
              radius=r,
              height=h,
              radialSegments=64)
    meshcat_object("Mesh", geom, material, p)
  end

meshcat_cone(p, r, h, material) =
  meshcat_centered_cone(p+vz(h/2, p.cs), r, h, material)

meshcat_centered_cone_frustum(p, rb, rt, h, material) =
  let geom = (uuid=string(uuid1()),
              type="CylinderBufferGeometry",
              radiusTop=rt,
              radiusBottom=rb,
              height=h,
              radialSegments=64)
    meshcat_object("Mesh", geom, material, p)
  end

meshcat_cone_frustum(p, rb, rt, h, material) =
  meshcat_centered_cone_frustum(p+vz(h/2, p.cs), rb, rt, h, material)

meshcat_cylinder(p, r, h, material) =
  meshcat_centered_cone_frustum(p+vz(h/2, p.cs), r, r, h, material)

meshcat_extrusion_z(profile, h, material, p=u0(world_cs)) =
  let shape = meshcat_shape(profile),
      geom = (uuid=string(uuid1()),
              type="ExtrudeBufferGeometry",
              shapes=[shape.uuid],
              options=(
                #steps=2,
                depth=-h,
                bevelEnabled=false,
                #bevelThickness=1,
                #bevelSize=1,
                #bevelOffset=0,
                #bevelSegments=1,
                #extrudePath=meshcat_path(path),
                curveSegments=64
                ))
    meshcat_object_shapes("Mesh", geom, [shape], material, p)
  end

meshcat_faces(si, sj, closed_u, closed_v) =
  let idx(i,j) = (i-1)*sj+(j-1),
      idxs = [],
      quad(a,b,c,d) = (push!(idxs, (a, b, d)); push!(idxs, (d, b, c)))
    for i in 1:si-1
      for j in 1:sj-1
        quad(idx(i,j), idx(i+1,j), idx(i+1,j+1), idx(i,j+1))
      end
      if closed_v
        quad(idx(i,sj), idx(i+1,sj), idx(i+1,1), idx(i,1))
      end
    end
    if closed_u
      for j in 1:sj-1
        quad(idx(si,j), idx(1,j), idx(1,j+1), idx(si,j+1))
      end
      if closed_v
        quad(idx(si,sj), idx(1,sj), idx(1,1), idx(si,1))
      end
    end
    idxs
  end
#=
delete_all_shapes()
add_object(
  meshcat,
  meshcat_extrusion_z(
    path_set(
      circular_path(u0(), 2),
      circular_path(u0(), 1)),
    10,
    material(meshcat),
    y(10)))

delete_all_shapes()
add_object(
  meshcat,
  meshcat_extrusion(open_polygonal_path([x(0), z(10)]),
                    closed_polygonal_path(regular_polygon_vertices(5, u0(), 3)),
                    material(meshcat)))
dump(meshcat_extrusion(open_polygonal_path([x(0), z(10)]),
                  closed_polygonal_path(regular_polygon_vertices(5, u0(), 3)),
                  material(meshcat)))
=#

#=
send_setobject(v, "/meshcat/sphere1", meshcat_sphere(xyz(-2,-3,0), 1))
send_setobject(v, "/meshcat/cylinder1", meshcat_cylinder(loc_from_o_vx_vy(x(-3), vxy(1,1), vxz(-1,1)), 1, 5))
=#
meshcat_mesh(vertices, faces, material) =
  let geom = (uuid=string(uuid1()),
              type="BufferGeometry",
              data=(
                attributes=(
                  position=meshcat_buffer_geometry_attributes_position(vertices),
                  #uv=?
                  ),
                index=(
                  itemSize=3,
                  type="Uint32Array",
                  array=convert(Vector{UInt32}, collect(Iterators.flatten(faces))))))
    meshcat_object("Mesh", geom, material, u0(world_cs))
  end
#=
meshcat_extruded_surface_polygon(outer_vertices, holes_vertices, material) =
  let ps = in_world.(outer_vertices),
      n = vertices_normal(ps),
      cs = cs_from_o_vz(ps[1], n),
      vs = [in_cs(v, cs) for v in outer_vertices],
      hsvs = [[in_cs(v, cs) for v in hvs] for hvs in holes_vertices],
      curves = [(#metadata=meshcat_metadata("Curve"),
                 type="LineCurve",
                 v1=(cx(v1),cy(v1)), v2=(cx(v2),cy(v2)))
                for (v1,v2) in zip(vs, circshift(vs, -1))],
      shape = (uuid=string(uuid1()),
               type="Shape",
               curves=curves,
               autoclose=false,
               currentPoint=(cx(vs[1]), cy(vs[1])),
               holes=[],
               ),
      geom = (uuid=string(uuid1()),
              type="ShapeBufferGeometry",
              shapes=[shape.uuid],
              #curveSegments=12,
              )
    #meshcat_object_2D("Mesh", geom, [shape], material, )
    meshcat_object_shapes("Mesh", geom, [shape], material, u0(cs))
  end
=#

send_setview(v, camera::Loc, target::Loc, lens::Real, aperture::Real) =
  let (x1,y1,z1) = raw_point(camera),
      (x2,y2,z2) = raw_point(target)
    send_settransform(v, "/Cameras/default", [
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      x2, y2, z2, 1])
    send_setproperty(v, "/Cameras/default/rotated/<object>", "zoom", 1)
    send_setproperty(v, "/Cameras/default/rotated/<object>", "fov", view_angles(lens)[2])
    send_setproperty(v, "/Cameras/default/rotated/<object>", "position", [x1-x2,z1-z2,y2-y1])
  end

#send_setproperty(connection(meshcat), "/Orbit/<object>", "target", [2,0,0])
####################################################
abstract type MCATKey end
const MCATId = Union{String, NamedTuple} #Materials are tuples
const MCATRef = GenericRef{MCATKey, MCATId}
const MCATNativeRef = NativeRef{MCATKey, MCATId}
const MCATUnionRef = UnionRef{MCATKey, MCATId}
const MCATSubtractionRef = SubtractionRef{MCATKey, MCATId}

struct MCATLayer
  name
  material
  line_material
end

mcat_layer(name, color) =
  MCATLayer(name, meshcat_material(color), meshcat_line_material(color))

mutable struct MCATBackend{K,T} <: RemoteBackend{K,T}
  connection::Union{Missing,Visualizer}
  count::Int64
  layer::MCATLayer
  camera::Loc
  target::Loc
  lens::Real
  sun_altitude::Real
  sun_azimuth::Real
end

const MCAT = MCATBackend{MCATKey, MCATId}

material(b::MCAT) = b.layer.material
line_material(b::MCAT) = b.layer.line_material

KhepriBase.after_connecting(b::MCAT) =
  begin
    set_material(b, material_point, meshcat_material(RGB(0.1,0.1,0.9)))
    set_material(b, material_curve, meshcat_material(RGB(0.9,0.1,0.1)))
    set_material(b, material_surface, meshcat_material(RGB(0.1,0.9,0.1)))
    set_material(b, material_basic, meshcat_material(RGB(0.8,0.8,0.8)))
    set_material(b, material_glass, meshcat_glass_material())
	  set_material(b, material_metal, meshcat_metal_material())
	  set_material(b, material_wood, meshcat_material(RGB(0.5,0.5,0.5)))
	  set_material(b, material_concrete, meshcat_material(RGB(0.2,0.2,0.2)))
	  set_material(b, material_plaster, meshcat_material(RGB(0.7,0.7,0.7)))
	  set_material(b, material_grass, meshcat_material(RGB(0.1,0.7,0.1)))
  end

KhepriBase.start_connection(b::MCAT) =
  let (width, height) = render_size(),
      vis = Visualizer()
    display(MCATViewer(vis))
    send_setproperty(vis, "/Cameras/default/rotated/<object>", "far", 50000)
    vis
  end

meshcat = MCAT(missing,
               0,
               mcat_layer("default", RGB(1,1,1)),
               xyz(10,10,10),
               xyz(0,0,0),
               35,
               90,
               0)

KhepriBase.backend_name(b::MCAT) = "MeshCat"
#=
To visualize, we piggyback on Julia's display mechanisms
=#

display_meshcat(io, vis, (w, h)=render_size()) =
  let frame = vis.core
    print(io, """
    <div style="height: $(h)px; width: $(w)px; overflow-x: auto; overflow-y: hidden; resize: both">
    <iframe src="$(MeshCat.url(frame))" style="width: 100%; height: 100%; border: none"></iframe>
    </div>
    """)
    MeshCat.wait_for_server(frame)
  end

struct MCATViewer
  visualizer
end

Base.show(
  io::IO,
  ::Union{
    MIME"text/html",
    MIME"juliavscode/html",
    MIME"application/prs.juno.plotpane+html"},
  v::MCATViewer) = display_meshcat(io, v.visualizer)

export display_view
display_view(b::MCAT=current_backend()) = error("Needs specialization")
display_view(b::MCAT) = MCATViewer(connection(b))

const meshcat_root_path = "/Khepri"

next_id(b::MCATBackend{K,T}) where {K,T} =
  begin
      b.count += 1
      string(meshcat_root_path, "/", b.layer.name, "/", b.count - 1)
  end

add_object(b::MCAT, obj) =
  send_setobject(connection(b), next_id(b), obj)

has_boolean_ops(::Type{MCAT}) = HasBooleanOps{false}()
void_ref(b::MCAT) = MCATNativeRef("")

reset_backend(b::MCAT) =
  begin
    display(render(connection(b)))
    set_view(get_view(b)...)
  end

new_backend(b::MCAT) =
  begin
    reset(b.connection)
    display_view(b)
  end
#=
#@bdef(b_point(p, mat))
=#
KhepriBase.b_line(b::MCAT, ps, mat) =
  add_object(b, meshcat_line(ps, mat))
#=
KhepriBase.b_nurbs_curve(b::MCAT, order, ps, knots, weights, closed, mat) =
  b_line(b, ps, closed, mat)

KhepriBase.b_spline(b::MCAT, ps, v1, v2, interpolator, mat) =
  let ci = curve_interpolator(ps, false),
      cpts = curve_control_points(ci),
      n = length(cpts),
      knots = curve_knots(ci)
    b_nurbs_curve(b, 5, cpts, knots, fill(1.0, n), false, mat)
  end

KhepriBase.b_closed_spline(b::MCAT, ps, mat) =
  let ci = curve_interpolator(ps, true),
      cpts = curve_control_points(ci),
      n = length(cpts),
      knots = curve_knots(ci)
    b_nurbs_curve(b, 5, cpts, knots, fill(1.0, n), true, mat)
  end

KhepriBase.b_circle(b::MCAT, c, r, mat) =
  b_closed_spline(b, regular_polygon_vertices(32, c, r, 0, true), mat)

KhepriBase.b_arc(b::MCAT, c, r, α, Δα, mat) =
  b_spline(b,
    [center + vpol(r, a, center.cs)
     for a in division(α, α + Δα, Δα*32/2/π, false)],
    nothing, nothing, # THIS NEEDS TO BE FIXED
    mat)

KhepriBase.b_rectangle(b::MCAT, c, dx, dy, mat) =
  b_polygon(b, [c, add_x(c, dx), add_xy(c, dx, dy), add_y(c, dy)], mat)

# First tier: everything is a triangle or a set of triangles
=#
KhepriBase.b_trig(b::MCAT, p1, p2, p3, mat) =
  let ps = [p1, p2, p3]
    add_object(b, meshcat_mesh(ps, [(0,1,2)], mat))
  end
KhepriBase.b_quad(b::MCAT, p1, p2, p3, p4, mat) =
  let ps = [p1, p2, p3, p4]
    add_object(b, meshcat_mesh(ps, [(0,1,2),(2,3,0)], mat))
  end

#=

KhepriBase.b_ngon(b::MCAT, ps, pivot, smooth, mat) =
  [(b_trig(b, pivot, ps[i], ps[i+1], mat)
    for i in 1:size(ps,1)-1)...,
	 b_trig(b, pivot, ps[end], ps[1], mat)]

KhepriBase.b_quad_strip(b::MCAT, ps, qs, smooth, mat) =
  [b_quad(b, ps[i], ps[i+1], qs[i+1], qs[i], mat)
   for i in 1:size(ps,1)-1]

KhepriBase.b_quad_strip_closed(b::MCAT, ps, qs, smooth, mat) =
  b_quad_strip(b, [ps..., ps[1]], [qs..., qs[1]], smooth, mat)

=#
KhepriBase.b_surface_polygon(b::MCAT, ps, mat) =
  add_object(b, meshcat_surface_polygon(ps, mat))
KhepriBase.b_surface_circle(b::MCAT, c, r, mat) =
  add_object(b, meshcat_circle_mesh(c, r, 0, 2pi, mat))
KhepriBase.b_surface_arc(b::MCAT, c, r, α, Δα, mat) =
  add_object(b, meshcat_circle_mesh(c, r, α, Δα, mat))
KhepriBase.b_surface_grid(b::MCAT, ptss, closed_u, closed_v, smooth_u, smooth_v, mat) =
  let si = size(ptss, 1),
      sj = size(ptss, 2),
      idxs = meshcat_faces(si, sj, closed_u, closed_v)
    add_object(b, meshcat_mesh(reshape(permutedims(ptss),:), idxs, mat))
  end
KhepriBase.b_surface_mesh(b::MCAT, vertices, faces, mat) =
  add_object(b, meshcat_mesh(vertices, faces, mat))
#=

# Parametric surface
#=
parametric {
    function { sin(u)*cos(v) }
    function { sin(u)*sin(v) }
    function { cos(u) }

    <0,0>, <2*pi,pi>
    contained_by { sphere{0, 1.1} }
    max_gradient ??
    accuracy 0.0001
    precompute 10 x,y,z
    pigment {rgb 1}
  }
=#

=#
KhepriBase.b_cylinder(b::MCAT, cb, r, h, mat) =
	add_object(b, meshcat_cylinder(cb, r, h, mat))
KhepriBase.b_box(b::MCAT, c, dx, dy, dz, mat) =
  add_object(b, meshcat_box(c, dx, dy, dz, mat))
KhepriBase.b_sphere(b::MCAT, c, r, mat) =
  add_object(b, meshcat_sphere(c, r, mat))
KhepriBase.b_cone(b::MCAT, cb, r, h, mat) =
	add_object(b, meshcat_cone(cb, r, h, mat))
KhepriBase.b_cone_frustum(b::MCAT, cb, rb, h, rt, mat) =
	add_object(b, meshcat_cone_frustum(cb, rb, rt, h, mat))
KhepriBase.b_torus(b::MCAT, c, ra, rb, mat) =
  add_object(b, meshcat_torus(c, ra, rb, mat))

KhepriBase.b_extrusion(b::MCAT, profile::Region, v, cb, bmat, tmat, smat) =
  let p = path_start(profile.paths[1]),
      cs = cs_from_o_vz(p, v)
    add_object(b, meshcat_extrusion_z(in_cs(profile, cs), norm(v), tmat, u0(cs)))
  end
#=
setprop!(
  connection(meshcat)["/Cameras/default/rotated/<object>"], #"Cameras","default","rotated","<object>"],
  "zoom",
  1.0)
=#

#=
MeshCat.setcontrol!(
  connection(meshcat)["Background"], #"Cameras","default","rotated","<object>"],
  "hide_background")

{
    type: "set_property",
    path: "/Cameras/default/rotated/<object>",
    property: "zoom",
    value: 2.0
}
=#

set_view(camera::Loc, target::Loc, lens::Real, aperture::Real, b::MCAT) =
  let v = connection(b)
    send_setview(v, camera, target, lens, aperture)
    b.camera = camera
    b.target = target
    b.lens = lens
  end

get_view(b::MCAT) =
  b.camera, b.target, b.lens

KhepriBase.b_delete_ref(b::MCAT, r::MCATId) =
  send_delobject(connection(b), r)

KhepriBase.b_delete_all_refs(b::MCAT) =
  send_delobject(connection(b), meshcat_root_path)
#=

backend_stroke(b::MCAT, path::OpenSplinePath) =
  if (path.v0 == false) && (path.v1 == false)
    add_object(b, meshcat_line(path_frames(path), line_material(b)))
  elseif (path.v0 != false) && (path.v1 != false)
    @remote(b, InterpSpline(path.vertices, path.v0, path.v1))
  else
    @remote(b, InterpSpline(
                     path.vertices,
                     path.v0 == false ? path.vertices[2]-path.vertices[1] : path.v0,
                     path.v1 == false ? path.vertices[end-1]-path.vertices[end] : path.v1))
  end
backend_stroke(b::MCAT, path::ClosedSplinePath) =
    add_object(b, meshcat_line(path_frames(path), line_material(b)))
backend_fill(b::MCAT, path::ClosedSplinePath) =
    add_object(b, meshcat_surface_polygon(path_frames(path), material(b)))

#=
smooth_pts(pts) = in_world.(path_frames(open_spline_path(pts)))

=#

# Layers
current_layer(b::MCAT) =
  b.layer

current_layer(layer, b::MCAT) =
  b.layer = layer

backend_create_layer(b::MCAT, name::String, active::Bool, color::RGB) =
  begin
    @assert active
    mcat_layer(name, color)
  end

#=
create_ground_plane(shapes, material=default_MCAT_ground_material()) =
  if shapes == []
    error("No shapes selected for analysis. Use add-MCAT-shape!.")
  else
    let (p0, p1) = bounding_box(union(shapes)),
        (center, ratio) = (quad_center(p0, p1, p2, p3),
                  distance(p0, p4)/distance(p0, p2));
     ratio == 0 ?
      error("Couldn"t compute height. Use add-MCAT-shape!.") :
      let pts = map(p -> intermediate_loc(center, p, ratio*10), [p0, p1, p2, p3]);
         create_surface_layer(pts, 0, ground_layer(), material)
        end
       end
  end
        w = max(floor_extra_factor()*distance(p0, p1), floor_extra_width())
        with(current_layer,floor_layer()) do
          box(xyz(min(p0.x, p1.x)-w, min(p0.y, p1.y)-w, p0.z-1-floor_distance()),
              xyz(max(p0.x, p1.x)+w, max(p0.y, p1.y)+w, p0.z-0-floor_distance()))
        end
      end
    end

=#

####################################################
=#
