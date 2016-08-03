#Thermal gradient script for last mesh in series

[Mesh]
  file = x143_anisotropy_out.e
[]

[Adaptivity]
  max_h_level = 4
  initial_steps = 6
  cycles_per_step = 2
  initial_marker = error_marker
  marker = error_marker
  [./Indicators]
    [./eta_jump]
      type = GradientJumpIndicator
      variable = eta
    [../]
  [../]
  [./Markers]
    [./error_marker]
      type = ErrorFractionMarker
      indicator = eta_jump
      refine = 0.9
    [../]
  [../]
[]

[MeshModifiers] #Adds a new node set
  [./new_nodeset]
    type = AddExtraNodeset
    coord = '25 25'
    new_boundary = 100
  [../]
[]

[Variables]
  [./T]
    initial_condition = 293
  [../]
  [./Tx_AEH] #Temperature used for the x-component of the AEH solve
    initial_condition = 293
    scaling = 1.0e4 #Scales residual to improve convergence
  [../]
  [./Ty_AEH] #Temperature used for the y-component of the AEH solve
    initial_condition = 293
    scaling = 1.0e4  #Scales residual to improve convergence
  [../]
[]

[AuxVariables]
  [./eta]
    order = FIRST
    family = LAGRANGE
    # For reading a solution
    # from an ExodusII file
    initial_from_file_var = eta
    initial_from_file_timestep = LATEST
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
    value = 293
  [../]
  [./right_flux] #Set heat flux on the right side
    type = NeumannBC
    variable = T
    boundary = right
    value = 7e-7
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
    value = 293
    boundary = 100
  [../]
  [./fix_y] #Fix Ty_AEH at a single point
    type = DirichletBC
    variable = Ty_AEH
    value = 293
    boundary = 100
  [../]
[]

[Materials]
  [./thcond] #The equation defining the thermal conductivity is defined here, using two ifs
    # The k in the bulk is k_b, in the precipitate k_p2, and across the interaface k_int
    type = ParsedMaterial
    block = 0
    constant_names = 'length_scale k_b k_p2'
    constant_expressions = '1e-6 9.731 1.4'
    function = '(((1-eta)^2)*(k_b*length_scale))+(((eta)^2)*(k_p2*length_scale))'
    outputs = exodus
    f_name = thermal_conductivity
    args = eta
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
    flux = 7e-7
    length_scale = 1e-06
    T_hot = 293
    dx = 50
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
  l_max_its = 15
  solve_type = NEWTON
  petsc_options_iname = '-pc_type -pc_hypre_type -ksp_gmres_restart -pc_hypre_boomeramg_strong_threshold'
  petsc_options_value = 'hypre boomeramg 31 0.7'
  l_tol = 1e-04
[]

[Outputs]
  execute_on = 'timestep_end'
  exodus = true
  csv = true
[]
