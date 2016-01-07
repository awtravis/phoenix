#Thermal conductivity script based on local oxygen concetration

[Mesh]
  file = MicroEvolution143_out.e
[]

[Adaptivity]
  max_h_level = 4
  initial_steps = 1
  cycles_per_step = 2
  initial_marker = error_marker
  marker = error_marker
  [./Indicators]
    [./c_jump]
      type = GradientJumpIndicator
      variable = c
    [../]
  [../]
  [./Markers]
    [./error_marker]
      type = ErrorFractionMarker
      indicator = c_jump
      refine = 0.9
    [../]
  [../]
[]


[Variables]
  [./T]
    initial_condition = 298
  [../]
[]

[AuxVariables]
  [./c]
    order = FIRST
    family = LAGRANGE
    # For reading a solution
    # from an ExodusII file
    initial_from_file_var = c
    initial_from_file_timestep = LATEST
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
    value = 298
  [../]
  [./right_flux] #Set heat flux on the right side
    type = NeumannBC
    variable = T
    boundary = right
    value = 5e-6
  [../]
[]

[Materials]
  [./thcond]
    type = keff
    block = 0
    concentration = c
    outputs = exodus
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
    type = ThermalCond
    variable = T
    flux = 5e-6
    length_scale = 1e-06
    T_hot = 298
    dx = 50
    boundary = right
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
