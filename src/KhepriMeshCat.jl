module KhepriMeshCat
using KhepriBase
using MeshCat
using UUIDs, MsgPack
using Colors

# functions that need specialization
include(khepribase_interface_file())
include("MeshCat.jl")

function __init__()
  # Let's ensure we have the visualizer
  connection(meshcat)
  add_current_backend(meshcat)
end
end
