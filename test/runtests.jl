# KhepriMeshCat tests - Tests for MeshCat 3D visualization backend

using KhepriMeshCat
using KhepriBase
using MeshCat: Visualizer
using Test

@testset "KhepriMeshCat.jl" begin

  @testset "Backend initialization" begin
    @testset "meshcat backend exists" begin
      @test meshcat isa KhepriBase.Backend
    end

    @testset "backend_name" begin
      @test KhepriBase.backend_name(meshcat) == "MeshCat"
    end

    @testset "void_ref" begin
      vr = KhepriBase.void_ref(meshcat)
      @test vr === ""
    end

    @testset "has refs field" begin
      @test hasfield(typeof(meshcat), :refs)
      @test meshcat.refs isa KhepriBase.References
    end

    @testset "has view field" begin
      @test hasfield(typeof(meshcat), :view)
    end

    @testset "has layer field" begin
      @test hasfield(typeof(meshcat), :layer)
    end
  end

  @testset "Type system" begin
    @testset "MCATKey type exists" begin
      @test isdefined(KhepriMeshCat, :MCATKey)
    end

    @testset "MCATId type exists" begin
      @test isdefined(KhepriMeshCat, :MCATId)
    end

    @testset "MCATRef type exists" begin
      @test isdefined(KhepriMeshCat, :MCATRef)
    end

    @testset "MCATNativeRef type exists" begin
      @test isdefined(KhepriMeshCat, :MCATNativeRef)
    end

    @testset "MCAT is alias for MCATBackend" begin
      @test KhepriMeshCat.MCAT === KhepriMeshCat.MCATBackend{KhepriMeshCat.MCATKey, KhepriMeshCat.MCATId}
    end
  end

  @testset "Material system" begin
    @testset "meshcat_material function exists" begin
      @test isdefined(KhepriMeshCat, :meshcat_material)
    end

    @testset "meshcat_glass_material function exists" begin
      @test isdefined(KhepriMeshCat, :meshcat_glass_material)
    end

    @testset "meshcat_metal_material function exists" begin
      @test isdefined(KhepriMeshCat, :meshcat_metal_material)
    end

    @testset "mcat_layer function exists" begin
      @test isdefined(KhepriMeshCat, :mcat_layer)
    end
  end

  @testset "Connection" begin
    @testset "has connection" begin
      conn = KhepriBase.connection(meshcat)
      @test !ismissing(conn)
    end

    @testset "connection is Visualizer" begin
      conn = KhepriBase.connection(meshcat)
      @test conn isa Visualizer
    end
  end

  @testset "Layer system" begin
    @testset "mcat_layer creates layer" begin
      layer = KhepriMeshCat.mcat_layer("test_layer", RGB(1,0,0))
      @test layer isa KhepriMeshCat.MCATLayer
    end

    @testset "layer has name" begin
      layer = KhepriMeshCat.mcat_layer("my_layer", RGB(0,1,0))
      @test layer.name == "my_layer"
    end
  end

  @testset "ID generation" begin
    @testset "next_id increments" begin
      initial = meshcat.count
      id1 = KhepriMeshCat.next_id(meshcat)
      id2 = KhepriMeshCat.next_id(meshcat)
      @test id2 > id1
    end
  end

  # Conformance tests
  @testset "Backend Conformance (MeshCat)" begin
    include(joinpath(dirname(pathof(KhepriBase)), "..", "test", "BackendConformanceTests.jl"))
    using .BackendConformanceTests

    run_conformance_tests(meshcat,
      reset! = () -> begin
        empty!(meshcat.refs)
      end,
      # MeshCat lacks transaction field -- skip tiers that use high-level shape API
      skip = [:curves, :triangles, :surfaces, :solids, :layers, :materials,
              :highlevel, :refs, :delete, :advanced]
    )
  end

end
