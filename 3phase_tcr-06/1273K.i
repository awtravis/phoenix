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
    initial_condition = 1273
  [../]
  [./Tx_AEH] #Temperature used for the x-component of the AEH solve
    initial_condition = 1273
    scaling = 1.0e4 #Scales residual to improve convergence
  [../]
  [./Ty_AEH] #Temperature used for the y-component of the AEH solve
    initial_condition = 1273
    scaling = 1.0e4  #Scales residual to improve convergence
  [../]
[]

[Kernels]
  [./HtCond] #Kernel for direct calculation of thermal cond
    type = HeatConduction
    variable = T
  [../]
  [./heat_x] #All other kernels are for AEH approach to calculate thermal cond.
    type = HeatConduction
    variable = Tx_AEH
  [../]
  [./heat_rhs_x]
    type = HomogenizedHeatConduction
    variable = Tx_AEH
    component = 0
  [../]
  [./heat_y]
    type = HeatConduction
    variable = Ty_AEH
  [../]
  [./heat_rhs_y]
    type = HomogenizedHeatConduction
    variable = Ty_AEH
    component = 1
  [../]
[]

[BCs]
  [./left] #Fix temperature on the left side
    type = DirichletBC
    variable = T
    boundary = left
    value = 1273
  [../]
  [./right_flux] #Set heat flux on the right side
    type = NeumannBC
    variable = T
    boundary = right
    value = 5e-8
  [../]
  [./Periodic]
    [./all]
      auto_direction = 'x y'
      variable = 'Tx_AEH Ty_AEH'
    [../]
  [../]
  [./fix_x] #Fix Tx_AEH at a single point
    type = DirichletBC
    variable = Tx_AEH
    value = 1273
    boundary = 100
  [../]
  [./fix_y] #Fix Ty_AEH at a single point
    type = DirichletBC
    variable = Ty_AEH
    value = 1273
    boundary = 100
  [../]
[]

[Materials]
  [./thcond] #The equation defining the thermal conductivity is defined here, using two ifs
    # The k in the bulk is k_b, in the precipitate k_p2, and across the interaface k_int
    type = ParsedMaterial
    block = 0
    constant_names = 'length_scale k_al2o3'
    constant_expressions = '1e-6 7.221'
    function = '(k_al2o3*length_scale)'
    outputs = exodus
    f_name = thermal_conductivity
  [../]
  [./thcond_2] #The equation defining the thermal conductivity is defined here, using two ifs
    # The k in the bulk is k_b, in the precipitate k_p2, and across the interaface k_int
    type = ParsedMaterial
    block = 1
    constant_names = 'length_scale k_mgal2o4'
    constant_expressions = '1e-6 5.027'
    function = '(k_mgal2o4*length_scale)'
    outputs = exodus
    f_name = thermal_conductivity
  [../]
  [./thcond_3] #The equation defining the thermal conductivity is defined here, using two ifs
    # The k in the bulk is k_b, in the precipitate k_p2, and across the interaface k_int
    type = ParsedMaterial
    block = 2
    constant_names = 'length_scale k_ysz'
    constant_expressions = '1e-6 2.00'
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
      T_hot = 1273
      dx = 2268
      boundary = right
    [../]
    [./k_x_AEH] #Effective thermal conductivity in x-direction from AEH
      type = HomogenizedThermalConductivity
      variable = Tx_AEH
      temp_x = Tx_AEH
      temp_y = Ty_AEH
      component = 0
      scale_factor = 1e6 #Scale due to length scale of problem
    [../]
    [./k_y_AEH] #Effective thermal conductivity in x-direction from AEH
      type = HomogenizedThermalConductivity
      variable = Ty_AEH
      temp_x = Tx_AEH
      temp_y = Ty_AEH
      component = 1
      scale_factor = 1e6 #Scale due to length scale of problem
    [../]
  []

  [Preconditioning]
    [./SMP]
      type = SMP
      off_diag_row = 'Tx_AEH Ty_AEH'
      off_diag_column = 'Ty_AEH Tx_AEH'
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
