[Mesh]
  # uniform_refine = 4
  type = FileMesh
  file = large_three_phase_1-mesh.inp
  construct_side_list_from_node_list = true
[]

[MeshModifiers] #Adds a new node set
  [./new_nodeset]
    type = AddExtraNodeset
    nodes = '0'
    new_boundary = 100
  [../]
[]

[Variables]
  [./T]
    initial_condition = 373
  [../]
[]

[Kernels]
  [./HtCond] #Kernel for direct calculation of thermal cond
    type = HeatConduction
    variable = T
  [../]
[]

[BCs]
  [./left] #Fix temperature on the left side
    type = DirichletBC
    variable = T
    boundary = left
    value = 373
  [../]
  [./right_flux] #Set heat flux on the right side
    type = NeumannBC
    variable = T
    boundary = right
    value = 5e-8
  [../]
[]

[ThermalContact]
  [./gap_conductivity]
    type = GapHeatTransfer
    variable = T
    master = 2
    slave = 3
    gap_conductivity = 0.01
  [../]
[]

[Materials]
  [./thcond] #The equation defining the thermal conductivity is defined here, using two ifs
    # The k in the bulk is k_b, in the precipitate k_p2, and across the interaface k_int
    type = ParsedMaterial
    block = 0
    constant_names = 'length_scale k_al2o3'
    constant_expressions = '1e-6 26.265'
    function = '(k_al2o3*length_scale)'
    outputs = exodus
    f_name = thermal_conductivity
  [../]
  [./thcond_2] #The equation defining the thermal conductivity is defined here, using two ifs
    # The k in the bulk is k_b, in the precipitate k_p2, and across the interaface k_int
    type = ParsedMaterial
    block = 1
    constant_names = 'length_scale k_mgal2o4'
    constant_expressions = '1e-6 14.735'
    function = '(k_mgal2o4*length_scale)'
    outputs = exodus
    f_name = thermal_conductivity
  [../]
  [./thcond_3] #The equation defining the thermal conductivity is defined here, using two ifs
    # The k in the bulk is k_b, in the precipitate k_p2, and across the interaface k_int
    type = ParsedMaterial
    block = 2
    constant_names = 'length_scale k_porosity'
    constant_expressions = '1e-6 0.1'
    function = '(k_porosity*length_scale)'
    outputs = exodus
    f_name = thermal_conductivity
  [../]
  [./thcond_4] #The equation defining the thermal conductivity is defined here, using two ifs
    # The k in the bulk is k_b, in the precipitate k_p2, and across the interaface k_int
    type = ParsedMaterial
    block = 3
    constant_names = 'length_scale k_ysz'
    constant_expressions = '1e-6 3.125'
    function = '(k_ysz*length_scale)'
    outputs = exodus
    f_name = thermal_conductivity
  [../]
[]

  [Postprocessors]
    [./right_T]
      type = SideAverageValue
      variable = T
      boundary = right
    [../]
    [./k_x_direct] #Effective thermal conductivity from direct method
      # This value is lower than the AEH value because it is impacted by second phase
      # on the right boundary
      type = ThermalConductivity
      variable = T
      flux = 5e-8
      length_scale = 1e-6
      T_hot = 373
      dx = 2266
      boundary = right
    [../]
  []

  [Executioner]
    type = Steady
    l_max_its = 20
    solve_type = NEWTON
    petsc_options_iname = '-pc_type -pc_hypre_type -ksp_gmres_restart -pc_hypre_boomeramg_strong_threshold'
    petsc_options_value = 'hypre boomeramg 31 0.7'
    l_tol = 1e-10
  []

  [Outputs]
    execute_on = 'timestep_end'
    exodus = true
    csv = true
  []
