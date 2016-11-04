[Mesh]
  # uniform_refine = 4
  type = FileMesh
  file = 20U3Si2-UN-01_mesh.inp
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
    initial_condition = 320
  [../]
  [./Tx_AEH] #Temperature used for the x-component of the AEH solve
    initial_condition = 320
    scaling = 1.0e4 #Scales residual to improve convergence
  [../]
  [./Ty_AEH] #Temperature used for the y-component of the AEH solve
    initial_condition = 320
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
    value = 320
  [../]
  [./right_flux] #Set heat flux on the right side
    type = NeumannBC
    variable = T
    boundary = right
    value = 1.5e-7
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
    value = 320
    boundary = 100
  [../]
  [./fix_y] #Fix Ty_AEH at a single point
    type = DirichletBC
    variable = Ty_AEH
    value = 320
    boundary = 100
  [../]
[]


[Materials]
  [./thcond] #The equation defining the thermal conductivity is defined here, using two ifs
    # The k in the bulk is k_b, in the precipitate k_p2, and across the interaface k_int
    type = ParsedMaterial
    block = 0
    constant_names = 'length_scale k_U3Si2'
    constant_expressions = '1e-6 8.34'
    function = '(k_U3Si2*length_scale)'
    outputs = exodus
    f_name = thermal_conductivity
  [../]
  [./thcond_2] #The equation defining the thermal conductivity is defined here, using two ifs
    # The k in the bulk is k_b, in the precipitate k_p2, and across the interaface k_int
    type = ParsedMaterial
    block = 1
    constant_names = 'length_scale k_UN'
    constant_expressions = '1e-6 14.96'
    function = '(k_UN*length_scale)'
    outputs = exodus
    f_name = thermal_conductivity
  [../]
  [./thcond_3] #The equation defining the thermal conductivity is defined here, using two ifs
    # The k in the bulk is k_b, in the precipitate k_p2, and across the interaface k_int
    type = ParsedMaterial
    block = 2
    constant_names = 'length_scale k_U3Si2'
    constant_expressions = '1e-6 8.34'
    function = '(k_U3Si2*length_scale)'
    outputs = exodus
    f_name = thermal_conductivity
  [../]
  [./thcond_4] #The equation defining the thermal conductivity is defined here, using two ifs
    # The k in the bulk is k_b, in the precipitate k_p2, and across the interaface k_int
    type = ParsedMaterial
    block = 3
    constant_names = 'length_scale k_UN'
    constant_expressions = '1e-6 14.96'
    function = '(k_UN*length_scale)'
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
      flux = 1.5e-7
      length_scale = 1e-6
      T_hot = 320
      dx = 1292
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
